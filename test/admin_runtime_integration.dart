// Opt-in real Flutter Firebase SDK tests. Never connect to a cloud project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:healthmate/core/config/admin_runtime.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const project = 'demo-healthmate-admin';
  if (!const bool.fromEnvironment('HEALTHMATE_ADMIN_EMULATOR_TESTS') ||
      !adminRuntimeEnabled) {
    throw StateError(
      'Run via tool/test_admin_integration.ps1; no cloud fallback.',
    );
  }
  final apps = <FirebaseApp>[];
  final auths = <FirebaseAuth>[];
  late FirebaseFirestore memberDb, adminDb;
  late FirebaseAdminRuntimeRepository repository;
  late String memberUid, adminUid;
  late ProviderContainer container;
  var operation = 0;

  Future<void> waitUntil(bool Function() check) async {
    for (var i = 0; i < 200; i++) {
      if (check()) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    fail('Runtime did not reach the expected server-confirmed state.');
  }

  Future<void> mutate(
    String kind,
    String id,
    Map<String, Object> payload,
  ) async {
    final audit = adminDb.collection('admin_audit').doc();
    final data = <String, Object>{
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
      'lastAdminOperationId': audit.id,
    };
    final batch = adminDb.batch();
    batch.set(adminDb.collection(kind).doc(id), data);
    batch.set(audit, {
      'actorUid': adminUid,
      'entityType': kind,
      'entityId': id,
      'at': FieldValue.serverTimestamp(),
      'changedFields': data.keys.toList(),
      'reason': 'Flutter emulator integration ${++operation}',
    });
    await batch.commit();
  }

  Future<void> control(String status) => mutate('account_controls', memberUid, {
    'status': status,
    'reason': 'Flutter emulator $status',
  });
  Future<void> config({bool maintenance = false, bool ai = true}) =>
      mutate('app_config', 'runtime', {
        'chatbotEnabled': ai,
        'foodScannerEnabled': ai,
        'maintenanceMode': maintenance,
        'maintenanceMessage': maintenance ? 'Emulator maintenance' : '',
      });

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    for (final role in ['member', 'admin']) {
      final app = await Firebase.initializeApp(
        name: 'runtime-$role',
        options: const FirebaseOptions(
          apiKey: 'demo-key',
          appId: '1:123:web:runtime',
          messagingSenderId: '123',
          projectId: project,
          authDomain: 'localhost',
        ),
      );
      apps.add(app);
      final auth = FirebaseAuth.instanceFor(app: app);
      auths.add(auth);
      await auth.useAuthEmulator(
        '127.0.0.1',
        9098,
        automaticHostMapping: false,
      );
      await auth.setPersistence(Persistence.NONE);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.useFirestoreEmulator('127.0.0.1', 8092, automaticHostMapping: false);
      await auth.signInWithEmailAndPassword(
        email: '$role@healthmate.local',
        password: 'LocalHealthMate!2026',
      );
      expect(auth.currentUser!.emailVerified, isTrue);
      if (role == 'member') {
        memberDb = db;
        memberUid = auth.currentUser!.uid;
      } else {
        adminDb = db;
        adminUid = auth.currentUser!.uid;
      }
    }
    repository = FirebaseAdminRuntimeRepository(memberDb);
    container = ProviderContainer(
      overrides: [
        adminRuntimeRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(
            AuthUser(
              uid: memberUid,
              email: 'member@healthmate.local',
              emailVerified: true,
            ),
          ),
        ),
      ],
    );
    container.listen(authSessionProvider, (_, _) {});
    container.listen(appAccountAccessProvider, (_, _) {});
    container.listen(adminAppConfigProvider, (_, _) {});
    await container.read(authSessionProvider.future);
    await waitUntil(
      () => container.read(appAccountAccessProvider).value?.verified == true,
    );
    await waitUntil(
      () => container.read(adminAppConfigProvider).value?.verified == true,
    );
  });

  tearDownAll(() async {
    container.dispose();
    for (final auth in auths) {
      await auth.signOut();
    }
    for (final app in apps) {
      await app.delete();
    }
  });

  test(
    'directory sync keeps identity only and preserves its creation timestamp',
    () async {
      // Force the actual create transaction, rather than only testing a no-op.
      await memberDb.doc('user_directory/$memberUid').delete();
      await repository.syncDirectory(
        uid: memberUid,
        displayName: 'Người dùng kiểm thử',
        email: 'member@healthmate.local',
      );
      final before = await memberDb
          .doc('user_directory/$memberUid')
          .get(const GetOptions(source: Source.server));
      await repository.syncDirectory(
        uid: memberUid,
        displayName: 'Người dùng kiểm thử',
        email: 'member@healthmate.local',
      );
      final after = await memberDb
          .doc('user_directory/$memberUid')
          .get(const GetOptions(source: Source.server));
      expect(after.data()!.keys.toSet(), {
        'displayName',
        'email',
        'createdAt',
        'updatedAt',
      });
      expect(after.data()!['createdAt'], before.data()!['createdAt']);
      expect(after.data()!['updatedAt'], before.data()!['updatedAt']);
    },
  );

  test(
    'suspension blocks private reads; reopening restores runtime without signing in again',
    () async {
      await control('suspended');
      try {
        await waitUntil(
          () =>
              container.read(appAccountAccessProvider).value?.suspended == true,
        );
        await expectLater(
          memberDb
              .doc('users/$memberUid')
              .get(const GetOptions(source: Source.server)),
          throwsA(
            isA<FirebaseException>().having(
              (e) => e.code,
              'code',
              'permission-denied',
            ),
          ),
        );
        // Force Rules to re-evaluate the config listener while suspended.
        // Reopening must recover from its terminal permission error.
        await config(ai: false);
        await waitUntil(() {
          final state = container.read(adminAppConfigProvider);
          return state.hasError || state.value?.verified != true;
        });
        expect(container.read(appFeatureFlagsProvider).chatbotEnabled, isFalse);
      } finally {
        await control('active');
      }
      await waitUntil(
        () =>
            container.read(appAccountAccessProvider).value?.suspended == false,
      );
      await waitUntil(
        () =>
            !container.read(adminAppConfigProvider).hasError &&
            container.read(adminAppConfigProvider).value?.verified == true,
      );
      expect(
        (await memberDb
                .doc('users/$memberUid')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
    },
  );

  test(
    'server maintenance and AI switches reach the configured mobile providers',
    () async {
      try {
        await config(maintenance: true, ai: false);
        await waitUntil(
          () =>
              container.read(adminAppConfigProvider).value?.maintenanceMode ==
              true,
        );
        expect(
          container.read(adminAppConfigProvider).value!.maintenanceMessage,
          'Emulator maintenance',
        );
        expect(container.read(appFeatureFlagsProvider).chatbotEnabled, isFalse);
        expect(
          container.read(appFeatureFlagsProvider).foodScannerEnabled,
          isFalse,
        );
        await config(ai: false);
        await waitUntil(
          () =>
              container.read(adminAppConfigProvider).value?.maintenanceMode ==
              false,
        );
        expect(
          container.read(appFeatureFlagsProvider).foodScannerEnabled,
          isFalse,
        );
      } finally {
        await config();
      }
      await waitUntil(
        () => container.read(appFeatureFlagsProvider).foodScannerEnabled,
      );
      expect(container.read(appFeatureFlagsProvider).chatbotEnabled, isTrue);
      await expectLater(
        adminDb
            .doc('users/$memberUid')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
    },
  );
}
