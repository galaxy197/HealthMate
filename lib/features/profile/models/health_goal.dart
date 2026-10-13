enum HealthGoal {
  loseWeight('lose_weight', 'Giảm cân'),
  maintainWeight('maintain_weight', 'Duy trì cân nặng'),
  gainWeightOrMuscle('gain_weight_or_muscle', 'Tăng cân hoặc tăng cơ'),
  healthierHabits('healthier_habits', 'Cải thiện thói quen sức khỏe');

  const HealthGoal(this.value, this.label);

  final String value;
  final String label;

  bool get needsTargetWeight =>
      this == HealthGoal.loseWeight || this == HealthGoal.gainWeightOrMuscle;

  static HealthGoal? fromValue(Object? value) {
    for (final goal in values) {
      if (goal.value == value) return goal;
    }
    return null;
  }
}
