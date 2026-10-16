import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/profile/models/profile_validation.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/profile/providers/profile_providers.dart';

/// A local eligibility gate based on self-reported profile data, not proof of age.
class AiAccess {
  const AiAccess({required this.allowed, required this.message});
  final bool allowed;
  final String message;
}

AiAccess aiAccessFor(String? uid, UserProfile? profile, {DateTime? today}) {
  if (uid == null || profile == null || profile.uid != uid) {
    return const AiAccess(
      allowed: false,
      message: 'Hãy đăng nhập và tải hồ sơ của bạn trước khi sử dụng AI.',
    );
  }
  if (ProfileValidation.birthDate(profile.birthDate, today: today) != null) {
    return const AiAccess(
      allowed: false,
      message:
          'AI chỉ dành cho người từ 18 tuổi có ngày sinh hợp lệ trong hồ sơ.',
    );
  }
  if (!profile.isOnboardingCompleteAt(today ?? DateTime.now())) {
    return const AiAccess(
      allowed: false,
      message: 'Hãy hoàn tất thiết lập hồ sơ trước khi sử dụng AI.',
    );
  }
  return const AiAccess(allowed: true, message: '');
}

final aiAccessProvider = Provider<AiAccess>((ref) {
  final auth = ref.watch(authSessionProvider);
  final profile = ref.watch(userProfileProvider);
  if (auth.isLoading ||
      auth.hasError ||
      profile.isLoading ||
      profile.hasError) {
    return const AiAccess(
      allowed: false,
      message: 'Chưa xác nhận được điều kiện sử dụng AI. Hãy tải lại hồ sơ.',
    );
  }
  return aiAccessFor(auth.value?.uid, profile.value);
});
