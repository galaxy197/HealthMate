import 'health_goal.dart';
import 'personalization_answers.dart';

class OnboardingDraft {
  const OnboardingDraft({
    required this.displayName,
    required this.birthDate,
    required this.heightCm,
    required this.currentWeightKg,
    required this.healthGoal,
    required this.targetWeightKg,
    this.personalization,
    this.isProfileEdit = false,
    this.recordCurrentWeight = true,
  });

  final String displayName;
  final DateTime birthDate;
  final double heightCm;
  final double currentWeightKg;
  final HealthGoal healthGoal;
  final double? targetWeightKg;
  final PersonalizationAnswers? personalization;
  final bool isProfileEdit;
  final bool recordCurrentWeight;
}
