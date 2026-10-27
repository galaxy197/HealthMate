import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/profile/providers/profile_providers.dart';
import 'admin_runtime_enabled.dart';
export 'admin_runtime_enabled.dart';

/// Enable only after deploying admin Rules and provisioning the initial admin.
final adminControlsEnabledProvider = Provider<bool>(
  (ref) => adminRuntimeEnabled,
);

class AppAccountAccess {
  const AppAccountAccess({
    this.verified = true,
    this.suspended = false,
    this.reason = '',
  });
  final bool verified, suspended;
  final String reason;
  factory AppAccountAccess.fromData(
    Map<String, dynamic>? data, {
    bool verified = true,
  }) {
    if (data != null && !['active', 'suspended'].contains(data['status'])) {
      throw const FormatException('Trạng thái tài khoản không hợp lệ.');
    }
    return AppAccountAccess(
      verified: verified,
      suspended: data?['status'] == 'suspended',
      reason: data?['reason'] is String ? data!['reason'] as String : '',
    );
  }
}

class AdminAppConfig {
  const AdminAppConfig({
    this.verified = true,
    this.chatbotEnabled = true,
    this.foodScannerEnabled = true,
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
  });
  final bool verified, chatbotEnabled, foodScannerEnabled, maintenanceMode;
  final String maintenanceMessage;
  factory AdminAppConfig.fromData(
    Map<String, dynamic>? data, {
    bool verified = true,
  }) {
    if (data == null) return AdminAppConfig(verified: verified);
    for (final key in [
      'chatbotEnabled',
      'foodScannerEnabled',
      'maintenanceMode',
    ]) {
      if (data[key] is! bool) {
        throw const FormatException('Cấu hình quản trị không hợp lệ.');
      }
    }
    if (data['maintenanceMessage'] is! String) {
      throw const FormatException('Thiếu nội dung bảo trì.');
    }
    return AdminAppConfig(
      verified: verified,
      chatbotEnabled: data['chatbotEnabled'] as bool,
      foodScannerEnabled: data['foodScannerEnabled'] as bool,
      maintenanceMode: data['maintenanceMode'] as bool,
      maintenanceMessage: data['maintenanceMessage'] as String,
    );
  }
}

abstract interface class AdminRuntimeRepository {
  Stream<AppAccountAccess> watchAccess(String uid);
  Stream<AdminAppConfig> watchConfig();
  Future<void> syncDirectory({
    required String uid,
    required String displayName,
    required String email,
  });
}

class FirebaseAdminRuntimeRepository implements AdminRuntimeRepository {
  FirebaseAdminRuntimeRepository(this.db);
  final FirebaseFirestore db;
  @override
  Stream<AppAccountAccess> watchAccess(String uid) => db
      .collection('account_controls')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => AppAccountAccess.fromData(
          s.data(),
          verified: !s.metadata.isFromCache,
        ),
      );
  @override
  Stream<AdminAppConfig> watchConfig() => db
      .collection('app_config')
      .doc('runtime')
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => AdminAppConfig.fromData(
          s.data(),
          verified: !s.metadata.isFromCache,
        ),
      );
  @override
  Future<void> syncDirectory({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final doc = db.collection('user_directory').doc(uid);
    await db.runTransaction((t) async {
      final old = await t.get(doc);
      if (old.data()?['displayName'] == displayName &&
          old.data()?['email'] == email) {
        return;
      }
      t.set(doc, {
        'displayName': displayName,
        'email': email,
        'createdAt': old.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

final adminRuntimeRepositoryProvider = Provider<AdminRuntimeRepository>(
  (ref) => FirebaseAdminRuntimeRepository(FirebaseFirestore.instance),
);
final appAccountAccessProvider = StreamProvider<AppAccountAccess>((ref) {
  if (!ref.watch(adminControlsEnabledProvider)) {
    return Stream.value(const AppAccountAccess());
  }
  final user = ref.watch(authSessionProvider).value;
  final uid = user?.emailVerified == true ? user?.uid : null;
  return uid == null
      ? Stream.value(const AppAccountAccess())
      : ref.watch(adminRuntimeRepositoryProvider).watchAccess(uid);
}, retry: (_, _) => null);
final adminAppConfigProvider = StreamProvider<AdminAppConfig>((ref) {
  if (!ref.watch(adminControlsEnabledProvider) ||
      ref.watch(authSessionProvider).value?.emailVerified != true) {
    return Stream.value(const AdminAppConfig());
  }
  // Firestore terminates app_config listeners when a suspended account loses
  // read access. Follow account status so reopening creates a fresh listener.
  final access = ref.watch(appAccountAccessProvider);
  if (access.isLoading ||
      access.hasError ||
      access.value?.verified != true ||
      access.value!.suspended) {
    return Stream.value(
      const AdminAppConfig(
        verified: false,
        chatbotEnabled: false,
        foodScannerEnabled: false,
      ),
    );
  }
  return ref.watch(adminRuntimeRepositoryProvider).watchConfig();
}, retry: (_, _) => null);
final adminDirectorySyncProvider = FutureProvider<void>((ref) async {
  if (!ref.watch(adminControlsEnabledProvider)) return;
  final uid = ref.watch(authSessionProvider).value?.uid;
  final profile = ref.watch(userProfileProvider).value;
  final access = ref.watch(appAccountAccessProvider).value;
  if (uid == null ||
      profile?.uid != uid ||
      access?.verified != true ||
      access!.suspended) {
    return;
  }
  await ref
      .watch(adminRuntimeRepositoryProvider)
      .syncDirectory(
        uid: uid,
        displayName: profile!.displayName,
        email: profile.email,
      );
}, retry: (_, _) => null);
