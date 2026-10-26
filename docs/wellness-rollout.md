# Mục 1 — Triển khai Rules và chuẩn bị nghiệm thu điện thoại

**Cập nhật sau mục1:** mục2–3–4 đã có source/APK mới và Rules hai collection
riêng bổ sung. Ưu tiên [wellness-insights.md](wellness-insights.md) và APK
`healthmate-wellness-insights-debug.apk` khi cài điện thoại. Phần dưới là lịch sử mục1.

Ngày 26/10/2026, người dùng yêu cầu “làm mục 1”: triển khai Rules riêng cho app,
cài bản mới giữ dữ liệu và thử cảm biến bước chân/lưu giờ ngủ. Người dùng sau đó
chọn **“Tôi sẽ kết nối sau”**; phần cài và nghiệm thu điện thoại được hoãn theo
yêu cầu này. Không tự chuyển sang tính kcal từ bước chân hoặc phân tích giấc ngủ.

## Đã hoàn tất phần Firebase

- Đọc lại production trước khi sửa: đúng project `healthmate-app-20261013`,
  ruleset nền `4d084994-cde1-4c8f-b8bd-dbfb52611baa`, hash khớp baseline đã review.
- Lưu bản sao và cấu hình rollback tại `build/wellness-rollout-before-20261026/`.
  Không đọc nội dung nhật ký/hồ sơ hay tạo tài khoản/dữ liệu thử trong production.
- Chạy lại **61/61** ca trên đúng candidate MVP không có quyền quản trị; exit0,
  19,7 giây. Bao gồm verified email, chặn truy cập chéo, giới hạn dữ liệu và các
  collection ngủ/thực đơn/bước chân, snapshot dưỡng chất, nghiệp vụ cũ và chat50.
- Chỉ deploy `firestore:rules` từ `build/wellness-production-candidate/firebase.json`;
  không dùng file Rules local chứa admin đang tạm gác. Không deploy index,
  Hosting/Functions, không bật admin hoặc đổi quota/model/billing.
- Firebase compiler thành công; còn một cảnh báo `knownNumber` không dùng, không
  có lỗi biên dịch. Giữ nguyên candidate đã qua test, không sửa cosmetic giữa rollout.
- Release lúc **15:53:38 ngày 26/10/2026 (Asia/Saigon)**. Đọc lại Rules từ server
  sau deploy và xác nhận hash khớp tuyệt đối với candidate đã kiểm thử.

Ruleset mới: `8add3549-ea41-4a5d-9f5c-22d1b62808cc`.
SHA256 chuẩn hóa LF/trim:
`2bb6a4a230da4d516cb757c564944782924e875ff9cc1f3b7397951773d59f62`.

Rules đã có `users/{uid}/sleep_logs`, `wellness_state`, `meal_plans`, `step_logs`
và các định dạng snapshot dinh dưỡng hiện tại. Chỉ chủ tài khoản đã xác minh email
được phép truy cập; dữ liệu khách/chưa xác minh/UID khác bị chặn. Không migrate,
xóa hoặc viết lại dữ liệu hiện có; nhật ký cũ giữ nguyên snapshot.

Log triển khai: `build/wellness-rollout-deploy.log`; test:
`build/wellness-rollout-candidate-tests.log`; diff so với production cũ:
`build/wellness-rollout-rules.diff`. Bản đọc lại server và metadata:
`build/wellness-rollout-after-20261026/`.

## APK sẵn sàng cài

`build/releases/healthmate-wellness-debug.apk`, 236630807 bytes.
SHA256: `0B3A90A09D48F1ED6D76AC0926DB034656E953E0D609D3C4B9545616EDFCF84F`.

Đã kiểm tra lại hash và manifest trong APK: package `com.example.healthmate`,
entry activity `MainActivity`, có quyền Hoạt động thể chất/thông báo/health foreground
service; step counter là tính năng tùy chọn. Đây là APK app thật đã build và test ở
đợt mở rộng, không phải APK integration test. Không thay code Flutter/native trong
lượt rollout này; không chạy lại full597/analyze/build vì artifact không đổi.
Các kết quả597 Flutter/70 Rules/22 SDK/native ở [báo cáo trước](wellness-expansion.md)
là kết quả lịch sử đã có, không ghi thành kết quả vừa chạy lại trong lượt này.

## Chờ điện thoại — chưa nghiệm thu trên thiết bị thật

ADB không có thiết bị; người dùng chọn kết nối sau. **Chưa cài APK, chưa thử số
bước thực tế, quyền trên máy người dùng hoặc thao tác lưu/đọc qua app production.**
Đọc lại Rules thành công không thay thế kiểm thử toàn luồng trên điện thoại.

Khi người dùng kết nối lại:

1. Xác nhận đúng thiết bị/model và bản HealthMate đang cài; dùng `adb install -r`
   để cập nhật, không uninstall/clear-data. Nếu chữ ký không khớp, giữ nguyên app
   và dữ liệu, báo lỗi thay vì tự gỡ.
2. Mở app, đăng nhập tài khoản đã xác minh email; vào **Thêm → Thói quen & kế hoạch**.
3. Bước chân: bật/cấp quyền, xác nhận cảm biến có sẵn, ghi số đầu; mang điện thoại
   đi khoảng30–50 bước, kiểm tra số tăng, chuyển tab/tắt màn hình rồi thử tiếp.
   Kiểm tra đồng bộ/lịch sử sau mở lại và nút dừng. Không bơm sensor giả để nhận pass.
4. Giấc ngủ: bấm ngủ/dậy để thử thao tác, kiểm tra/sửa giờ trước khi lưu; mở lại app
   và kiểm tra lịch sử. Xóa riêng bản ghi thử do người dùng xác nhận nếu muốn.
5. Thực đơn: tạo một bữa dự kiến, kiểm tra lưu lại khi mở app, chưa tự cộng nhật ký;
   thử nhắc bữa bằng nút thông báo và xác nhận quyền nếu hệ điều hành yêu cầu.

Phần cảm biến cần thiết bị hỗ trợ; chưa có bằng chứng về độ chính xác, Doze/OEM
hoặc Android13+ trên máy người dùng. Không tự điều chỉnh mục tiêu kcal từ bước/ngủ.

Mục1 hoàn tất phần backend/artifact, còn nghiệm thu thiết bị theo lịch người dùng.
Không commit/push, không reset thay đổi chưa commit. Không lặp lại yêu cầu tắt laptop
của đợt trước trong lượt này.
