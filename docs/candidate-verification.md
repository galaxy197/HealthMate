# Truy vết candidate cải thiện Gói 8–10

Ngày kiểm tra: 31/10/2026, múi giờ báo cáo Asia/Saigon (UTC+7). Source chưa
commit; HEAD bắt đầu/kết thúc giữ `main@0e897eca3cbdb7907012197830b9d365763e4faf`.
Không có commit mới để gắn nhãn client release. Manifest cuối lưu danh sách
SHA-256 từng file và digest của source runtime/test/config (loại docs/build)
tại `build/improvement-packages8-10/verification.json`.

| Thành phần | Bản đã kiểm tra / giới hạn |
| --- | --- |
| Client | Working tree local trên HEAD nêu trên; chưa phát hành |
| Runtime source digest | `993ecf1f7fcc39a3b0995421578c270239bafd288fe3975426ca849d31433a2c` (path + SHA-256, 551 files; không gồm docs/build) |
| Package / version | `com.example.healthmate` / `1.0.0+1`, được chốt cho demo |
| Rules SHA-256 | 18eb97a726948fd350b1e43f06bac970af5f6ad068b0ec8761831174a8069ad6 |
| Indexes SHA-256 | 4c773ef4782165a86da895cb92494f5ca4577f98f1250740f1cfcce882d45a05 |
| Release config SHA-256 | 14814469acae3ce73129414976e22a6f6b1bd91e77d298ac19888f20db90829a |
| Default/SDK Flutter tests | Không dùng production AI flags; SDK opt-in `HEALTHMATE_EMULATOR_TESTS=true` |
| Release flags candidate | admin=true, premiumDemo=false, chatbot=false, foodScanner=true, gatewayURL rỗng |
| Ý nghĩa scanner flag | Giữ barcode entry; AI ảnh chưa có gateway và không fallback direct model |
| Signing / certificate | Chưa có key; preflight exit 1, `release-signing-missing` |
| APK / APK SHA-256 | Chưa build; chưa biết hash/certificate |
| GitHub hosted CI | Workflow đã thêm và kiểm local; chưa chạy trên GitHub |
| Rules/index/client deploy | Chưa deploy; hash source không chứng nhận ruleset production |

Môi trường kiểm tra: Windows, Flutter 3.44.1/Dart 3.12.1, Node.js 24.18.0,
Firebase CLI 15.22.4, Java từ Android Studio JBR, Google Chrome thực qua adapter
SDK test. Flutter chạy trong bản sao `D:/HealthMateMaintenanceQA/c6-workspace`
có đối chiếu hash; admin/chat/Rules tests chạy từ source tương ứng. QA không
copy credential/keystore hoặc ignored local config.

Hai cặp emulator do task tạo: demo Rules/Flutter SDK `127.0.0.1:8080/9099`,
admin demo `127.0.0.1:8092/9098`. Rules được hoàn thành trước các suite SDK có
reset database. Mỗi SDK suite chạy process riêng, reset/seed đúng demo trước
suite; không chia sẻ fixture khi suite plan tự reset. Chỉ dùng dữ liệu tổng
hợp. Không gọi model AI, xóa tài khoản thật hoặc migration production.

Kết quả/exit code cuối và lỗi trung gian: [test-report.md](test-report.md).
Trạng thái từng gói: [improvement-progress.md](improvement-progress.md).
Phần chưa nghiệm thu signed release/native và rollout/rollback:
[release-readiness.md](release-readiness.md). Emulator, widget test và source
contract của Gradle không thay thế kiểm chứng trên APK ký thật.
