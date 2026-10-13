class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  factory AuthFailure.fromCode(String code) => AuthFailure(switch (code) {
    'invalid-email' => 'Email chưa đúng định dạng. Vui lòng kiểm tra lại.',
    'wrong-password' ||
    'user-not-found' ||
    'invalid-credential' ||
    'invalid-login-credentials' => 'Email hoặc mật khẩu chưa đúng.',
    'email-already-in-use' =>
      'Email này đã được đăng ký. Hãy chuyển sang đăng nhập.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'Mật khẩu chưa đáp ứng yêu cầu bảo mật. Hãy chọn mật khẩu mạnh hơn.',
    'network-request-failed' => 'Không thể kết nối. Kiểm tra mạng rồi thử lại.',
    'too-many-requests' =>
      'Bạn đã thử nhiều lần. Vui lòng chờ một lúc rồi thử lại.',
    'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
    'operation-not-allowed' =>
      'Đăng nhập bằng email hiện chưa được bật. Vui lòng thử lại sau.',
    'invalid-api-key' || 'app-not-authorized' || 'configuration-not-found' =>
      'Dịch vụ tài khoản chưa sẵn sàng. Vui lòng thử lại sau.',
    'requires-recent-login' || 'user-token-expired' =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    _ => 'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
  }, code: code);

  @override
  String toString() => message;
}
