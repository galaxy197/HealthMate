class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  factory AuthFailure.fromCode(String code) => AuthFailure(switch (code) {
    'sign-in-cancelled' ||
    'popup-closed-by-user' ||
    'cancelled-popup-request' =>
      'Bạn đã hủy đăng nhập. Có thể thử lại khi sẵn sàng.',
    'google-configuration' || 'missing-or-invalid-nonce' =>
      'Đăng nhập Google chưa được cấu hình đúng cho bản ứng dụng này. Vui lòng liên hệ quản trị.',
    'google-sign-in-failed' || 'sign-in-interrupted' =>
      'Chưa thể đăng nhập Google. Kiểm tra kết nối rồi thử lại.',
    'account-exists-with-different-credential' || 'credential-already-in-use' =>
      'Email này đã dùng cách đăng nhập khác. Hãy đăng nhập bằng cách đã dùng trước đó; không tạo tài khoản mới.',
    'user-mismatch' =>
      'Tài khoản được chọn không khớp. Hãy chọn đúng tài khoản đang sử dụng HealthMate.',
    'popup-blocked' =>
      'Trình duyệt đã chặn cửa sổ Google. Hãy cho phép cửa sổ đăng nhập rồi thử lại.',
    'unauthorized-domain' =>
      'Tên miền này chưa được cấu hình cho đăng nhập. Vui lòng liên hệ quản trị.',
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
