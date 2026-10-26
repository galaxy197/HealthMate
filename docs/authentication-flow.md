# Đăng nhập, Google và xác minh email — 24/10/2026

Phạm vi lượt này là auth trên app điện thoại. Web admin tạm gác; Facebook đã
được bỏ theo yêu cầu mới nhất, không thêm SDK hay cấu hình Facebook.

## Luồng hiện tại

- Email/mật khẩu: đăng ký kiểm tra email, mật khẩu tối thiểu 8 ký tự và nhập
  lại mật khẩu. Đăng nhập vẫn nhận mật khẩu cũ ngắn hơn để không khóa tài khoản
  hiện có. Quy tắc 8 ký tự của app không tự thay đổi password policy trên Console.
- Tài khoản chưa xác minh, kể cả tài khoản cũ: chuyển tới màn xác minh trước
  onboarding/dữ liệu riêng tư. App gửi yêu cầu email xác minh bằng Firebase,
  có trạng thái lỗi, gửi lại sau 60 giây và “Tôi đã xác minh”. Khi quay lại từ
  trình duyệt, app tự reload user và làm mới ID token.
- Điều kiện mở dữ liệu gồm cả `User.emailVerified` và claim `email_verified`
  trong token. Không chỉ tin việc người dùng bấm “Tôi đã xác minh”.
- Chưa xác minh thì không tạo/tải profile sức khỏe hoặc dùng AI. Rules local
  cũng chặn đọc/ghi owner data và catalog khi token chưa xác minh. Dữ liệu/UID
  cũ được giữ nguyên, không tạo lại hoặc chuyển nhật ký sang UID khác.
- Quên mật khẩu: dialog nhập email → Firebase `sendPasswordResetEmail` với
  ngôn ngữ `vi` → màn xác nhận yêu cầu, hướng dẫn hộp thư/thư rác, gửi lại sau
  60 giây → mở link Firebase trên trình duyệt và chọn mật khẩu mới → đăng nhập.
  Thông báo trung tính, không tiết lộ email có tồn tại. Chỉ báo gửi khi SDK
  thành công; lỗi mạng/hạn mức có thông báo. App không tự tạo OTP hoặc email.
- Google: nút gọi Firebase Google thật; Android dùng `google_sign_in` 7.2.0,
  `initialize` một lần và `authenticate` lấy ID token, rồi Firebase
  `signInWithCredential`. Web preview dùng Firebase popup. Không xin Drive,
  Contacts hoặc quyền Google API bổ sung. Không lưu Google token vào Firestore.
- Hủy đăng nhập, lỗi cấu hình và xung đột provider được xử lý riêng. Không
  tự nối tài khoản hoặc ghi đè dữ liệu bằng email. Firebase quyết định identity;
  tài khoản mới vẫn qua onboarding nếu chưa có hồ sơ.
- Google-only không hiện đổi mật khẩu HealthMate. Xóa tài khoản dùng xác thực
  lại bằng đúng Google user, giữ UID guard trước khi xóa dữ liệu/Auth.
- Cooldown trong app chỉ hỗ trợ UX và chống bấm lặp, không thay thế hạn mức
  chống lạm dụng của Firebase. Đăng xuất không thu hồi quyền Google khỏi tài khoản;
  không thực hiện `disconnect`/revoke consent.

## Google đã bật trên Firebase thật — 24/10/2026

Theo yêu cầu bật Google và xác nhận email hỗ trợ của người dùng, đã lưu provider
Google trên project `healthmate-app-20261013`, tên công khai HealthMate. Console
hiện Google Enabled; đọc lại API trả200, enabled=true và có client ID.
Email/Password tiếp tục bật. Không tạo tài khoản thử hoặc đổi dữ liệu người dùng.

Đã đăng ký SHA-1 debug; SHA-256 đã có sẵn. Đọc lại xác nhận đúng Android app
`1:471712188542:android:9aa12bdbac4605511eb02f`, package **com.example.healthmate**:

```text
SHA-1:
DD:56:B3:59:2C:28:B5:D7:5B:49:D9:D7:24:A1:DF:84:1C:41:BA:84
SHA-256:
93:90:6C:FC:05:B0:5E:63:F1:90:13:B2:F2:FD:5C:FB:FF:08:4A:9A:09:A9:CA:B7:16:A0:3C:F2:64:5B:D1:AA
```

Fingerprint là thông tin công khai của debug certificate trên máy này, không
phải private key. Release/Play App Signing có chứng chỉ khác; cần đăng ký đúng
chứng chỉ cho bản phát hành sau này, không dùng debug fingerprint thay thế.

Đã tải và thay `android/app/google-services.json` từ Firebase CLI, kiểm tra đúng
project/package/app ID, có Android OAuth client (`client_type: 1`) với SHA-1
trên và Web OAuth client (`client_type: 3`) để plugin tìm server client ID.
Không đặt client secret trong app. Có thể truyền public Web client ID bằng
`--dart-define=HEALTHMATE_GOOGLE_SERVER_CLIENT_ID=...` khi thật sự cần; không
dùng Android client ID hoặc client secret ở vị trí này.

Phải cài APK build lại sau cập nhật JSON; hot reload không cập nhật native
Google configuration. Cần thử chọn tài khoản, hủy, đăng xuất/chọn tài khoản khác,
email đã đăng ký trước đó và xác thực lại khi xóa tài khoản fixture.

Không có thiết bị ADB kết nối ở lượt này. APK đã build nhưng chưa cài lên điện
thoại. Build debug sau OAuth qua trong11,1s, log `build/google-enabled-android-build.log`;
resource `default_web_client_id` sinh bởi Gradle khớp Web OAuth client trong JSON.
Chưa thêm Apple/iOS setup hoặc provider ngoài Google.

## Email và Rules production — chưa thay đổi

Authentication → Templates: kiểm tra tên ứng dụng/người gửi, email xác minh và
đặt lại mật khẩu. Giữ liên kết hành động do Firebase tạo; có thể dùng trang xử
lý mặc định Firebase, chưa cần deep link hoặc hosting riêng. App đặt language
`vi`; giao thư thực tế còn phụ thuộc Firebase, hạn mức và hộp thư người nhận.
Không thể khẳng định email đã tới inbox chỉ dựa vào kết quả gửi API.

Nếu muốn áp dụng tối thiểu 8 ký tự cả trên trang đặt lại mật khẩu do Firebase
host, cấu hình password policy tương ứng trong Authentication Console. App
không tự đổi chính sách server hay nâng billing.

`firestore.rules` có thay đổi chưa deploy từ các lượt trước, gồm schema nhật ký
và admin. Cần rà soát/deploy đúng toàn bộ Rules trước khi tuyên bố email gate
được bảo vệ ở server production. Lượt này chỉ bật Google/cập nhật cấu hình OAuth
đã được yêu cầu; không push/deploy Rules, không gửi email thử tới tài khoản thật
và không thay đổi tài khoản người dùng.
App mới đã chặn UI; app cũ có thể vẫn dùng được Rules production cũ.

Khi tiếp tục web admin sau này, fixture Auth Emulator của admin cũng cần trạng
thái email đã xác minh để đọc catalog/config dưới Rules mới; role không thay
thế claim xác minh. Không tiếp tục phát triển web admin trong lượt auth này.

## Kiểm thử local

```powershell
# Terminal 1, tại thư mục gốc. Java 21 trên máy hiện tại:
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:Path
firebase emulators:start --config firebase.auth-emulators.json --only 'auth,firestore' --project demo-healthmate-auth

# Terminal 2:
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
npm --prefix rules-tests test
npm --prefix rules-tests run test:auth
flutter test test/auth_test.dart test/account_security_test.dart test/auth_completion_test.dart
```

`test:auth` chỉ gọi loopback 9099/8080 và project `demo-healthmate-auth` cố định.
Test tạo tài khoản tổng hợp, yêu cầu email OOB thật từ emulator, tiêu thụ code
xác minh, kiểm tra token cũ bị chặn/token mới được đọc, đặt lại mật khẩu, thử
mật khẩu cũ/mới và link dùng lại. Không xuất token/code hoặc gửi email thật.

Harness Android C6/H7 được cập nhật để tiêu thụ link xác minh của emulator thay
vì gán verified tùy ý. Chưa chạy lại native C6/H7 vì không có thiết bị. Snapshot
UI trong `docs/ux/auth/` dùng fake repositories và font thật, không phải ảnh
điện thoại hoặc bằng chứng giao email production.

## Nghiệm thu sau khi cấu hình

1. Đăng ký bằng một email người kiểm thử sở hữu → nhận thư → mở link → quay lại
   app → hoàn tất onboarding. Đóng/mở app trước khi xác minh vẫn phải bị chặn.
2. Quên mật khẩu → nhận thư → đổi mật khẩu → mật khẩu cũ thất bại, mật khẩu mới
   đăng nhập được. Thử email sai, mạng mất, gửi lại và link đã dùng/hết hạn.
3. Tiếp tục với Google → chọn tài khoản → vào hồ sơ hoặc onboarding phù hợp.
   Hủy không tạo dữ liệu. Kiểm tra cả tài khoản mới và email có tài khoản cũ.
4. Tài khoản cũ chưa xác minh được yêu cầu xác minh, dữ liệu sau xác minh vẫn
   đúng UID. Tài khoản B không đọc được dữ liệu A khi thay ID trực tiếp.

Nguồn chính thức đã kiểm tra:
[Firebase Flutter social sign-in](https://firebase.google.com/docs/auth/flutter/federated-auth),
[quản lý user/email](https://firebase.google.com/docs/auth/flutter/manage-users),
[Google Sign-In plugin](https://pub.dev/packages/google_sign_in),
[cấu hình Android](https://pub.dev/packages/google_sign_in_android),
[liên kết provider](https://firebase.google.com/docs/auth/flutter/account-linking).
