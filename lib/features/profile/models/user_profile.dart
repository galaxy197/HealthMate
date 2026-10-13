import 'health_goal.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.heightCm,
    required this.birthDate,
    required this.healthGoal,
    required this.targetWeightKg,
    required this.onboardingCompletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });

  final String uid;
  final String displayName;
  final String email;
  final double? heightCm;
  final DateTime? birthDate;
  final HealthGoal? healthGoal;
  final double? targetWeightKg;
  final DateTime? onboardingCompletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int schemaVersion;

  bool get hasRequiredOnboardingData =>
      displayName.trim().length >= 2 &&
      birthDate != null &&
      heightCm != null &&
      healthGoal != null &&
      (!healthGoal!.needsTargetWeight || targetWeightKg != null);

  bool get isOnboardingComplete =>
      onboardingCompletedAt != null && hasRequiredOnboardingData;
}

class UserProfileDraft {
  const UserProfileDraft({
    required this.displayName,
    required this.heightCm,
    required this.birthDate,
    required this.healthGoal,
    required this.targetWeightKg,
  });

  final String displayName;
  final double heightCm;
  final DateTime birthDate;
  final HealthGoal healthGoal;
  final double? targetWeightKg;
}
