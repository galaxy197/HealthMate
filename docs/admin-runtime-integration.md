# Tích hợp Android và admin — 27/10/2026

Phạm vi Giai đoạn 10: khắc phục cấu hình đóng gói thiếu admin controls và kiểm
thử khóa/mở, cấu hình bảo trì và AI. Không triển khai các module admin mở rộng.

Đã sửa `adminAppConfigProvider` theo dõi trạng thái tài khoản: khi đang chờ
xác nhận/bị khóa, không đọc cấu hình và tắt cờ tính năng; khi mở lại, tạo
listener mới. Trước sửa, cập nhật cấu hình lúc bị khóa làm listener nhận lỗi
permission-denied và không tự phục hồi sau mở khóa. Ca hồi quy tái hiện lỗi này
đã thất bại trước sửa và qua sau sửa, không thay đổi Rules để vượt kiểm thử.

## Chạy và đóng gói

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_android.ps1 -DeviceId emulator-5554
powershell -ExecutionPolicy Bypass -File tool/build_android.ps1
```

Hai script dùng chung `tool/android_app_arguments.ps1`, nạp
`config/admin-runtime.json` (cờ admin true), `config/chat-api.json` và token
App Check debug tại `%LOCALAPPDATA%/HealthMate/app-check-debug-token.txt`.
Không in token hoặc đưa token vào manifest. File chatbot không được đặt lại
cờ admin; script từ chối cấu hình chồng chéo. Không cần thêm dependency.

Script build kiểm thử runtime với đúng file cấu hình admin trước khi build,
chỉ sao chép APK sau khi Flutter trả exit 0. Đầu ra:

- `build/releases/healthmate-figma-admin-debug.apk`
- `build/releases/healthmate-figma-admin-debug.json`: SHA256, kích thước,
  thời điểm build và cờ admin; không chứa credential.

Đây là APK debug với UI Figma hiện tại, cần App Check debug token đã đăng ký.
Build store vẫn cần signing/release readiness riêng. Mặc định Dart không đổi;
lệnh `flutter build` bỏ qua cấu hình trên vẫn không bật admin controls.

APK đã build thành công ngày 27/10/2026, **236.844.262 byte**, SHA256
`07EB53A0DE0087818C2195BF6BFE0B7AD18D1E391899B1911E25446FB1DD9837`.
Manifest được đối chiếu lại với hash/kích thước tệp thật. Build exit 0,
Gradle 34,0 giây; log `build/admin-android-build-accepted.log`.

## Kiểm thử có thể chạy lại

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_admin_integration.ps1
```

Script chạy Auth `127.0.0.1:9098` và Firestore `127.0.0.1:8092`, project cố định
`demo-healthmate-admin`, seed fixture rồi chạy Rules, web SDK và Flutter SDK
trên Chrome. Không có cloud fallback; không dùng tài khoản thật. Môi trường
Java/Chrome/PATH được khôi phục và emulators:exec tự dừng emulator sau kiểm thử.

`test/admin_runtime_integration.dart` xác minh đồng bộ danh bạ tối thiểu,
khóa chặn đọc hồ sơ, mở lại không đăng nhập lại, bảo trì/AI cập nhật qua listener,
và admin không đọc được hồ sơ sức khỏe của người khác. Các kiểm thử widget
trong `test/admin_runtime_test.dart` kiểm tra đóng form khi khóa, trạng thái
offline và khôi phục giao diện.

Kết quả đã chạy trên Firebase Emulator, log
`build/admin-integration-accepted.log`: **77/77 Rules**, **4/4 web SDK**,
**3/3 Flutter SDK**. Web DOM/validation/list/XLSX: **20/20**, log
`build/admin-unit-accepted.log`. Flutter analyze: **No issues found**, log
`build/admin-analyze-accepted.log`. Lần tái hiện lỗi trước sửa giữ trong
`build/admin-integration-regression.log`.

Full Flutter suite: **656/656**, log `build/admin-flutter-tests-accepted.log`.
Kiểm thử runtime với file cấu hình build và assertion bắt buộc bật admin:
**7/7**, chạy tự động trong script build. Format ba file Dart 0 lệch;
PowerShell parser 4/4 script qua; `git diff --check` không có lỗi whitespace.

## Giới hạn và nghiệm thu

Chưa có thiết bị ADB để cài APK và thử thao tác từ admin production tới Android
thật. Không bật bảo trì, khóa tài khoản hoặc đổi cờ AI trên production để thử.
Firestore Rules/schema và hosting không cần triển khai lại cho phần sửa build.
Build còn cảnh báo KGP từ các plugin Firebase/mobile_scanner hiện có; không
nâng package trong lượt sửa tích hợp này.

Giới hạn danh sách 5.000 mục, lượt đọc vai trò theo UID và phân quyền nhiều vai
trò vẫn thuộc giai đoạn admin tiếp theo. Khóa hiện chặn dữ liệu HealthMate qua
Rules, không vô hiệu hóa Firebase Auth. Cờ AI trên app không phải hạn mức ở
máy chủ dịch vụ AI.
