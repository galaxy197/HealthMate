/// FAO/WHO/UNU Human Energy Requirements, tables 5.1 and 5.2 (Schofield).
/// This optional helper uses population estimates, never measured expenditure.
enum FormulaSex { male, female }

enum HabitualActivity {
  light('Ít vận động / nhẹ', 1.53, 'Phần lớn thời gian ngồi, đi lại nhẹ'),
  moderate('Vừa', 1.76, 'Thường xuyên đứng, đi lại và hoạt động vừa'),
  vigorous('Nặng', 2.25, 'Lao động thể lực đáng kể trong sinh hoạt hằng ngày');

  const HabitualActivity(this.label, this.factor, this.description);
  final String label, description;
  final double factor;
}

class EnergyEstimateInput {
  const EnergyEstimateInput({
    this.age,
    this.weightKg,
    this.sex,
    this.activity,
    this.eligible = false,
  });
  final int? age;
  final double? weightKg;
  final FormulaSex? sex;
  final HabitualActivity? activity;
  final bool eligible;

  String? validate() {
    if (!eligible) return 'Xác nhận phạm vi áp dụng hoặc quay về nhập tay.';
    if (age == null || age! < 18 || age! >= 60) {
      return 'Bản hướng dẫn này chỉ dùng cho tuổi 18–59. Ngoài phạm vi, hãy nhập tay cùng người có chuyên môn.';
    }
    if (weightKg == null ||
        !weightKg!.isFinite ||
        weightKg! < 20 ||
        weightKg! > 300) {
      return 'Nhập cân nặng hợp lệ từ 20 đến 300 kg; đây là giới hạn nhập liệu.';
    }
    if (sex == null || activity == null) {
      return 'Tự chọn hệ số sinh lý và mức hoạt động thường ngày; ứng dụng không đoán thay bạn.';
    }
    return null;
  }

  EnergyEstimate calculate() {
    final error = validate();
    if (error != null) throw FormatException(error);
    final young = age! < 30;
    final male = sex == FormulaSex.male;
    final slope = male ? (young ? 15.057 : 11.472) : (young ? 14.818 : 8.126);
    final intercept = male ? (young ? 692.2 : 873.1) : (young ? 486.6 : 845.6);
    final basal = slope * weightKg! + intercept;
    return EnergyEstimate(basal, activity!.factor);
  }
}

class EnergyEstimate {
  const EnergyEstimate(this.basalKcal, this.activityFactor);
  final double basalKcal, activityFactor;
  double get maintenanceKcal => basalKcal * activityFactor;
  double get roundedKcal => (maintenanceKcal / 10).round() * 10.0;
}
