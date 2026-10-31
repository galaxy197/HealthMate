// Opt-in SDK suite; deliberately excluded from the default _test.dart run.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:http/http.dart' as http;
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/data/meal_query_mode.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'support/emulator_email_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const project = 'demo-healthmate-rules';
  const root =
      'http://127.0.0.1:8080/v1/projects/$project/databases/(default)/documents';
  if (!const bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS')) {
    throw StateError('Only explicit local demo Auth/Firestore emulator tests.');
  }
  late FirebaseApp app;
  late FirebaseAuth auth;
  late FirebaseFirestore db;
  late String uid;
  final reads = <MealQueryRead>[];
  final metricReads = <BodyMetricQueryRead>[];
  late FirebaseNutritionRepository nutrition;
  late FirebaseHealthProfileRepository profile;

  Map<String, dynamic> wire(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': '$value'};
    if (value is num) return {'doubleValue': value};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(wire).toList()},
      };
    }
    throw StateError('Unsupported local synthetic fixture');
  }

  Future<void> seed(Map<String, Map<String, dynamic>> documents) async {
    final response = await http.post(
      Uri.parse('$root:commit'),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'writes': [
          for (final item in documents.entries)
            {
              'update': {
                'name':
                    'projects/$project/databases/(default)/documents/${item.key}',
                'fields': item.value.map(
                  (key, value) => MapEntry(key, wire(value)),
                ),
              },
            },
        ],
      }),
    );
    expect(
      response.statusCode,
      200,
      reason: 'Fixed loopback/demo fixture write',
    );
  }

  Future<void> marker(String state) => seed({
    'users/$uid/data_migrations/meal_date_key_v1': {
      'schemaVersion': 1,
      'state': state,
      'verifiedAt': DateTime.now(),
    },
  });
  Map<String, dynamic> meal(
    DateTime at,
    int kcal, {
    String? dateKey,
    String? partition,
  }) => {
    'consumedAt': at,
    'mealType': 'breakfast',
    'items': <Object>[],
    'totalKcal': kcal,
    'totalProteinG': 0,
    'totalCarbsG': 0,
    'totalFatG': 0,
    'source': 'manual',
    'schemaVersion': 2,
    'dateKey': ?dateKey,
    'queryPartition': ?partition,
  };
  Future<List<MealLog>> range(DateTime day) async {
    reads.clear();
    return nutrition.loadRange(
      uid,
      day,
      DateTime(day.year, day.month, day.day + 1),
    );
  }

  int dataReadCount() => reads
      .where((r) => r.branch != 'migration-marker')
      .fold(0, (n, r) => n + r.documentCount);

  setUpAll(() {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
  });
  setUp(() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    app = await Firebase.initializeApp(
      name: 'query-$suffix',
      options: const FirebaseOptions(
        apiKey: 'emulator-fake-key',
        appId: '1:123:web:query-test',
        messagingSenderId: '123',
        projectId: project,
        authDomain: 'localhost',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    await auth.setPersistence(Persistence.NONE);
    db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.createUserWithEmailAndPassword(
      email: 'query-$suffix@example.com',
      password: 'Emulator-only-test123!',
    );
    await verifyEmulatorEmail(auth, projectId: project, host: '127.0.0.1');
    uid = auth.currentUser!.uid;
    reads.clear();
    metricReads.clear();
    nutrition = FirebaseNutritionRepository(
      db,
      catalogLoader: () async => [],
      onQueryRead: reads.add,
    );
    profile = FirebaseHealthProfileRepository(
      db,
      onMetricQueryRead: metricReads.add,
    );
  });
  tearDown(() async {
    await db.enableNetwork();
    await auth.signOut();
    await db.terminate();
    await app.delete();
  });

  test(
    'verified routing removes duplicate downloads without losing current/legacy totals',
    () async {
      final day = DateTime(2026, 1, 2),
          key = localDateKey(DateTime(2026, 1, 2));
      final path = 'users/$uid/meal_logs';
      await seed({
        '$path/a': meal(day.add(const Duration(hours: 1)), 100, dateKey: key),
        '$path/b': meal(day.add(const Duration(hours: 2)), 200),
        '$path/c': meal(day.add(const Duration(hours: 3)), 300, dateKey: key),
      });
      final compatible = await range(day);
      expect(compatible.map((m) => m.id).toSet(), {'a', 'b', 'c'});
      expect(compatible.fold(0.0, (n, m) => n + m.totals.kcal), 600);
      expect(dataReadCount(), 5);
      await seed({
        '$path/a': meal(
          day.add(const Duration(hours: 1)),
          100,
          dateKey: key,
          partition: 'current',
        ),
        '$path/b': meal(
          day.add(const Duration(hours: 2)),
          200,
          partition: 'legacy',
        ),
        '$path/c': meal(
          day.add(const Duration(hours: 3)),
          300,
          dateKey: key,
          partition: 'current',
        ),
      });
      await marker('partitioned');
      final partitioned = await range(day);
      expect(partitioned.map((m) => m.id).toSet(), {'a', 'b', 'c'});
      expect(partitioned.fold(0.0, (n, m) => n + m.totals.kcal), 600);
      expect(dataReadCount(), 3);
      expect(reads.where((r) => r.branch != 'migration-marker').length, 2);
      await seed({
        '$path/b': meal(
          day.add(const Duration(hours: 2)),
          200,
          dateKey: key,
          partition: 'current',
        ),
      });
      await marker('complete');
      final complete = await range(day);
      expect(complete.map((m) => m.id).toSet(), {'a', 'b', 'c'});
      expect(complete.fold(0.0, (n, m) => n + m.totals.kcal), 600);
      expect(dataReadCount(), 3);
      expect(reads.where((r) => r.branch == 'legacy'), isEmpty);
      final empty = await range(DateTime(2026, 1, 3));
      expect(empty, isEmpty);
    },
  );

  test(
    'dateKey retains logged timezone at boundaries rather than regrouping by device timestamp',
    () async {
      final day = DateTime(2026, 1, 2);
      final key = localDateKey(day), path = 'users/$uid/meal_logs';
      await seed({
        '$path/logged-day': meal(
          day.subtract(const Duration(hours: 2)),
          150,
          dateKey: key,
          partition: 'current',
        ),
        '$path/legacy-midnight': meal(
          day.add(const Duration(minutes: 1)),
          50,
          partition: 'legacy',
        ),
      });
      await marker('partitioned');
      final meals = await range(day);
      expect(meals.map((m) => m.id).toSet(), {'logged-day', 'legacy-midnight'});
      expect(dataReadCount(), 2);
      final streamed = await nutrition
          .watchMealLogs(uid, day)
          .firstWhere((items) => items.length == 2);
      expect(streamed.map((m) => m.id).toSet(), {
        'logged-day',
        'legacy-midnight',
      });
    },
  );

  test(
    'multi-year history pages are bounded and tie-safe; latest and baseline each read one',
    () async {
      final path = 'users/$uid/body_metrics';
      await seed({
        for (var i = 0; i < 130; i++)
          '$path/m-${i.toString().padLeft(3, '0')}': {
            'weightKg': 60 + i / 100,
            'measuredAt': i < 60
                ? DateTime(2026, 1, 1)
                : DateTime(2020, 1, i - 59),
            'note': '',
          },
      });
      final latest = await profile
          .watchLatestBodyMetric(uid, DateTime(2026, 1, 2))
          .firstWhere(
            (items) => items.isNotEmpty && !metricReads.last.fromCache,
          );
      expect(latest.length, 1);
      expect(metricReads.last.documentCount, 1);
      final first = await profile
          .watchFirstBodyMetric(uid)
          .firstWhere(
            (items) => items.isNotEmpty && !metricReads.last.fromCache,
          );
      expect(first.single.id, 'm-060');
      expect(metricReads.last.documentCount, 1);
      final all = <String>[];
      BodyMetricCursor? after;
      do {
        final page = await profile
            .watchBodyMetricPage(uid, after: after)
            .firstWhere(
              (p) => p.metrics.isNotEmpty && !metricReads.last.fromCache,
            );
        expect(page.metrics.length, lessThanOrEqualTo(25));
        expect(metricReads.last.documentCount, lessThanOrEqualTo(26));
        all.addAll(page.metrics.map((m) => m.id));
        if (!page.hasMore) break;
        after = page.nextCursor;
      } while (true);
      expect(all.length, 130);
      expect(all.toSet().length, 130);
      final reported = await profile.loadBodyMetricsRange(
        uid,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
      );
      expect(
        reported.length,
        60,
        reason: 'Reports use full bounded date range, not page size',
      );
    },
  );

  test(
    'another UID cannot read history, migration marker or report data',
    () async {
      const other = 'victim-query-fixture';
      await seed({
        'users/$other/body_metrics/private': {
          'weightKg': 70,
          'measuredAt': DateTime(2026, 1, 1),
        },
      });
      await expectLater(
        profile.loadBodyMetricsRange(
          other,
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 2),
        ),
        throwsA(anything),
      );
      await expectLater(
        db
            .collection('users')
            .doc(other)
            .collection('data_migrations')
            .doc('meal_date_key_v1')
            .get(const GetOptions(source: Source.server)),
        throwsA(anything),
      );
      await expectLater(
        nutrition.loadRange(other, DateTime(2026, 1, 1), DateTime(2026, 1, 2)),
        throwsA(anything),
      );
    },
  );
}
