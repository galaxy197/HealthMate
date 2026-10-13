import 'health_goal.dart';

class OnboardingDraft {
  const OnboardingDraft({
    required this.displayName,
    required this.birthDate,
    required this.heightCm,
    required this.currentWeightKg,
    required this.healthGoal,
    required this.targetWeightKg,
  });

  final String displayName;
  final DateTime birthDate;
  final double heightCm;
  final double currentWeightKg;
  final HealthGoal healthGoal;
  final double? targetWeightKg;
}
