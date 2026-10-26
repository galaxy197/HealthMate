# HealthMate Admin

Web quản trị nằm ngay trong repository HealthMate, mở/sửa được bằng VS Code.
HTML, CSS và JavaScript thuần; Firebase Web SDK 13.0.0 tải từ CDN chính thức.
Không cần React, bundler, Admin SDK, service-account hoặc backend riêng.

## Chức năng bản đầu

- Đăng nhập bằng Firebase Authentication; quyền đọc/ghi kiểm tra bằng Firestore Rules.
- Thêm/sửa/ẩn/hiện món dùng chung, dinh dưỡng trên 100 g, chất xơ và nguồn.
- Danh sách tài khoản đã đồng bộ: tên/email/UID; khóa/mở quyền dữ liệu HealthMate.
- Bật/tắt quét ảnh AI, chatbot, chế độ bảo trì và thông báo.
- Nhật ký quản trị ghi nguyên tử cùng thay đổi, không sửa/xóa từ client.
- Phân trang 25 mục. Ô tìm kiếm chỉ lọc trang đang tải, không tìm toàn bộ database.

Admin không được đọc hồ sơ, bữa ăn, cân nặng hoặc hội thoại của người khác.
Không có nút tự cấp quyền, xóa tài khoản Auth hoặc đổi mật khẩu người dùng.

## Mở trong VS Code và chạy bản local

Mở thư mục gốc **HealthMate 2** bằng File → Open Folder. Cần Node.js,
Firebase CLI và Java 21 trở lên. Web không cần `npm install`.
Thực hiện trong terminal PowerShell tại thư mục gốc, ba terminal riêng:

Terminal 1 — dịch vụ Firebase thử nghiệm:

```powershell
# Máy hiện tại có Java 21 trong Android Studio; đặt PATH để tránh Java cũ.
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:Path
firebase emulators:start --config firebase.admin-emulators.json --only 'auth,firestore' --project demo-healthmate-admin
```

Terminal 2 — tạo dữ liệu mẫu sau khi emulator báo sẵn sàng:

```powershell
node admin-web/seed-emulators.mjs
```

Script chỉ gọi `127.0.0.1:9098/8092` và project `demo-healthmate-admin` cố định.
Chạy lại giữ cùng tài khoản nhưng có thể đặt lại các document fixture; không
dùng script cho dữ liệu cần bảo toàn. Dữ liệu emulator mất khi dừng nếu không export.

Terminal 3 — chạy web:

```powershell
npm --prefix admin-web run dev
```

Mở <http://127.0.0.1:4173/>. Đăng nhập fixture:

| Vai trò local | Email | Mật khẩu fixture |
| --- | --- | --- |
| Admin | admin@healthmate.local | LocalHealthMate!2026 |
| Người dùng thường | member@healthmate.local | LocalHealthMate!2026 |

Đây chỉ là tài khoản giả lập, không phải thông tin đăng nhập production.
Script seed xác minh email hai tài khoản qua Auth Emulator để đáp ứng Rules;
không gửi email thật. Nếu đã đăng nhập trước khi seed hoàn tất, đăng xuất rồi đăng nhập lại để nhận token mới.
Tài khoản thường đăng nhập được nhưng bị từ chối màn hình quản trị.
Web cần mạng để tải Firebase SDK từ `www.gstatic.com`; dữ liệu thử nghiệm vẫn
được gửi tới emulator trên máy. Không mở `index.html` trực tiếp bằng `file://`.
Dừng từng server bằng Ctrl+C sau khi thử.

## File để chỉnh giao diện và hành vi

| File | Vai trò |
| --- | --- |
| `dist/index.html` | Trang gốc và dialog |
| `dist/style.css` | Giao diện, responsive, font Be Vietnam Pro |
| `dist/app.mjs` | Đăng nhập, danh sách, form và trạng thái UI |
| `dist/firebase.mjs` | Auth, truy vấn và transaction có audit |
| `dist/validation.mjs` | Kiểm tra dữ liệu, đơn vị, phiên bản document |
| `dist/config.js` | Mặc định kết nối emulator, chưa trỏ Firebase thật |
| `server.mjs` | Static server chỉ lắng nghe loopback, kèm CSP |

## Kết nối Firebase thật — chưa thực hiện

Đây là các bước thiết lập khi chủ dự án yêu cầu triển khai; không phải lệnh
cần chạy để thử bản local. Không dùng tài khoản fixture ở trên trong production.

1. Trong Firebase project HealthMate hiện có, đăng ký Web App, lấy **public web
   config**. Bật Email/Password nếu chưa có; chủ dự án tạo/chọn tài khoản admin
   và xác định UID chính xác trong Authentication.
2. Chủ dự án dùng Firebase Console/IAM tạo `admin_roles/{UID}` với đúng field
   `enabled: true`. Không đặt role trong `users`, không cấp từ web/mobile.
   Thu hồi bằng `enabled: false`; client không thể sửa role. Một UID có document
   `admin_roles`, kể cả đã thu hồi, được bảo vệ khỏi khóa trên web; chủ dự án
   quản lý vòng đời document này qua Console.
3. Rà soát/deploy **toàn bộ** `firestore.rules` hiện tại sau kiểm thử. File đang
   chứa cả thay đổi chưa deploy từ các lượt trước; không dán riêng một đoạn admin
   đè lên Rules khác. Xác nhận `firestore.indexes.json` theo môi trường. Không
   cần Cloud Functions hoặc thêm database.
4. Đăng ký tên miền HTTPS trong Firebase Auth Authorized domains. Đăng ký Web App
   với App Check/reCAPTCHA Enterprise, key kiểu Web/score-based, không checkbox.
   Không thêm localhost vào key production. Kiểm tra request metrics cho cả
   Android/web trước khi thay enforcement, không tắt bảo vệ Android hiện có.
5. Thay cấu hình `dist/config.js` bằng public config thực, xóa `emulators`, thêm
   `appCheckSiteKey`. Ví dụ cấu trúc (điền giá trị do Console cấp):

```javascript
window.HEALTHMATE_ADMIN_CONFIG = {
  firebase: {
    apiKey: 'PUBLIC_FIREBASE_WEB_API_KEY',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    appId: 'PUBLIC_FIREBASE_WEB_APP_ID'
  },
  appCheckSiteKey: 'PUBLIC_RECAPTCHA_ENTERPRISE_SITE_KEY'
};
```

Không đưa private key, service-account, Gemini key riêng, mật khẩu hoặc token
debug vào các file này. Public config và site key không thay thế Security Rules.

6. Host thư mục `dist` trên HTTPS sau khi được yêu cầu. Áp dụng các header CSP,
   nosniff/no-referrer/no-store của `server.mjs` trên hosting; không chỉ copy
   giao diện rồi bỏ các header. Chưa tạo hosting hoặc publish trong lượt này.
7. Sau khi Rules và quyền admin đã sẵn sàng, build bản mobile hỗ trợ:

```powershell
flutter build apk --debug --dart-define=HEALTHMATE_ENABLE_ADMIN_CONTROLS=true
```

Cờ mặc định **false** để bản đang dùng không gọi collection mới trước khi Rules
sẵn sàng. Bật cờ mới áp dụng cấu hình từ xa, màn hình khóa/bảo trì và đồng bộ
directory. Tài khoản cũ xuất hiện trong danh sách sau đăng nhập/tải hồ sơ ở bản
mobile có cờ này; đây không phải toàn bộ danh sách Firebase Authentication.

## Giới hạn vận hành cần hiểu

- Khóa qua Firestore chặn quyền đọc/ghi dữ liệu trên máy chủ, không vô hiệu hóa
  tài khoản Firebase Auth, không thu hồi token và không xóa dữ liệu đã cache trên
  thiết bị. Rules không khóa API Firebase AI Logic; bản mobile hỗ trợ chặn AI ở
  client. Không tuyên bố có thể ngăn client đã bị sửa hoặc app cũ gọi AI trực tiếp.
- Cấu hình bảo trì/tính năng có hiệu lực trên bản mobile bật cờ. Không thêm
  điều kiện bảo trì vào Rules của nhật ký; việc đang lưu có thể hoàn tất.
- Bản bật cờ cần xác minh trạng thái từ server. Cache, lỗi mạng hoặc cấu hình
  không hợp lệ chưa cho vào nội dung riêng tư; có kiểm tra lại/đăng xuất.
- Cập nhật danh mục không sửa snapshot của nhật ký cũ. Ẩn món áp dụng với app
  mới có bộ lọc `isActive`; app cũ có thể vẫn hiển thị.
- Transaction phát hiện document đã đổi theo timestamp tới nanosecond, yêu cầu
  tải lại thay vì ghi đè. Retry cùng thao tác giữ audit ID cho tới khi nhận ACK.
- Sử dụng hạn mức Firebase hiện có; không thêm backend trả phí, không nâng
  billing. Firestore/Auth/App Check vẫn có hạn mức; không hứa miễn phí vô hạn.
  App Check Enterprise có phần miễn phí và phí vượt quota theo cấu hình dự án.

## Kiểm thử

```powershell
npm --prefix admin-web run check
npm --prefix admin-web test
# Emulator ở terminal 1 phải đang chạy:
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8092'
npm --prefix rules-tests test
flutter test test/admin_runtime_test.dart
```

Nếu thiếu dependency cho Rules, chạy `npm --prefix rules-tests ci`; web vẫn
không cần cài package. Test Rules dùng project demo riêng, không xóa dữ liệu
fixture trong project web admin. Kết quả thực tế: xem `../docs/test-report.md`.

Tài liệu chính thức đã kiểm tra ngày 23/10/2026:
[Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions),
[App Check Web Enterprise và hạn mức](https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider),
[Auth Admin user management](https://firebase.google.com/docs/auth/admin/manage-users).
