abstract final class AuthValidation {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Vui lòng nhập email hợp lệ.';
    }
    return null;
  }

  static String? password(String? value, {required bool registering}) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (registering && (value.length < 8 || value.trim().isEmpty)) {
      return 'Dùng ít nhất 8 ký tự, không chỉ gồm khoảng trắng.';
    }
    return null;
  }

  static String? confirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập lại mật khẩu.';
    return value == password ? null : 'Hai mật khẩu chưa khớp.';
  }
}
