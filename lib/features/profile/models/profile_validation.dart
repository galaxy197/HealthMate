abstract final class ProfileValidation {
  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2) return 'Tên hiển thị cần ít nhất 2 ký tự.';
    if (name.length > 50) return 'Tên hiển thị không được quá 50 ký tự.';
    return null;
  }

  static String? height(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final height = parseDecimal(text);
    if (height == null) return 'Chiều cao phải là một số hợp lệ.';
    if (height < 80 || height > 250) {
      return 'Chiều cao cần nằm trong khoảng 80–250 cm.';
    }
    return null;
  }

  static String? weight(String? value) {
    final weight = parseDecimal(value?.trim() ?? '');
    if (weight == null) return 'Cân nặng phải là một số hợp lệ.';
    if (weight < 20 || weight > 500) {
      return 'Cân nặng cần nằm trong khoảng 20–500 kg.';
    }
    return null;
  }

  static String? note(String? value) {
    if ((value ?? '').trim().length > 200) {
      return 'Ghi chú không được quá 200 ký tự.';
    }
    return null;
  }

  static double? parseDecimal(String value) =>
      double.tryParse(value.replaceAll(',', '.'));

  static double? bmi({required double? heightCm, required double? weightKg}) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm < 80 ||
        heightCm > 250 ||
        weightKg < 20 ||
        weightKg > 500) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
}
