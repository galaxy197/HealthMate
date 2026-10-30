# Nghiệm thu Android — dinh dưỡng, 27/10/2026

Phạm vi Giai đoạn 10: nghiệm thu luồng dinh dưỡng hiện có và ba bổ sung theo yêu
cầu (thực phẩm cần tránh, thực đơn theo kcal, tên Việt USDA). Không mở rộng tính năng.

## Môi trường và cách chạy

- Android Emulator riêng `HealthMateMaintenanceQA`, Android 11/API30/x86_64,
  serial `emulator-5580`, múi giờ Asia/Ho_Chi_Minh, SwiftShader/Skia.
- Không có điện thoại vật lý kết nối tại thời điểm bắt đầu. Không coi kết quả
  máy ảo là nghiệm thu điện thoại, camera hoặc hiệu năng trên thiết bị thật.
- Named Firebase app `healthmate-nutrition-qa`, project cố định
  `demo-healthmate-rules`, Auth/Firestore Emulator local9099/8080.
- Tài khoản A/B được tạo riêng mỗi lượt với miền `example.test`. Hồ sơ thử
  nghiệm A: 55kg →60kg, thuần chay, tránh sữa/trứng; kcal2200 chỉ là dữ liệu QA.
- Dùng UI/repository/catalog/SQLite thật. SDK được nối backend local; HTTP USDA
  ngoài được trả danh sách trống trong harness, AI/scanner tắt bằng cờ rõ ràng.
  Không kiểm API USDA/Gemini hoặc dữ liệu production trong bài này.
- Bản sao QA ở ổ D để tránh ổ C ít dung lượng; script sync đối chiếu hash
  toàn bộ nguồn/config/assets được liệt kê, không lấy checkout cũ làm bằng chứng.

```powershell
# Từ repo gốc; bản sao có Flutter/Android config local sẵn.
.\tool\sync_qa_workspace.ps1
# Trong D:\HealthMateMaintenanceQA\c6-workspace
$env:TEMP = 'D:\HealthMateMaintenanceQA\tmp'
$env:TMP = $env:TEMP
.\tool\test_android_core.ps1 -DeviceId emulator-5580 -CrossDriveBuild -Suite nutrition
```

Runner chỉ cho phép AVD riêng nêu trên, chỉ backend demo. Không cài integration
APK lên điện thoại hoặc dùng nó thay APK bàn giao chạy `lib/main.dart`.

## Các điểm kiểm tra

| Mã | Tiêu chí |
|---|---|
|01|Đủ7.606 mục; tên gốc, nguyên liệu, phân loại và khẩu phần qua SQLite không mất metadata.|
|02|Đặt kcal2200 qua UI; repository xác nhận đúng ngày áp dụng.|
|03|Đổi Tất cả chế độ vẫn không thấy sữa đặc khi hồ sơ tránh sữa.|
|04|Tìm bằng `Apples, raw, without skin`, chọn tên Việt, mở tên gốc, nhập150g.|
|05|Chỉ sau xác nhận mới lưu snapshot; gram và kcal đúng catalog.|
|06|Sửa200g giữ ID bữa; tổng ngày cập nhật theo bản ghi thật và mục tiêu2200.|
|07|Preview thực đơn chưa ghi kế hoạch/nhật ký; Hủy không ghi.|
|08|Xác nhận28bữa/7ngày; tổng từng ngày trong±5% kcal2200; không có món cần tránh/chưa rõ.|
|09|Xác nhận đã ăn chuyển kế hoạch vào nhật ký với ID ổn định và đánh dấu kế hoạch.|
|10|Xóa bữa từ UI cập nhật nhật ký; kế hoạch vẫn giữ nguyên.|
|11|UID B có nhật ký trống; SDK đọc nhật ký UID A bị Rules từ chối.|

## Kết quả thực tế

**11/11 điểm nghiệp vụ đạt trên Android Emulator sau sửa Rules. Nghiệm thu có
điều kiện; chưa kết luận sẵn sàng phát hành hoặc đã kiểm điện thoại vật lý.**

- Suite native chạy giao diện/repository thật: `All tests passed`, exit0,
  khoảng74 giây cả teardown; Gradle14,8s. Một test xuyên suốt, 11 checkpoint,
  không phải11 test độc lập. Đủ10 ảnh cho checkpoint01–10; checkpoint11 là
  assertion lỗi `permission-denied` từ server khi tài khoản B đọc bản ghi A.
- Catalog7.606; decode lần đo trong test488ms, không coi đây là benchmark
  khởi động trên điện thoại thật. SQLite giữ metadata tên/nguồn/thành phần.
- Táo USDA `usda-sr-171689`:150g→72kcal; sửa200g→96kcal, giữ ID; tổng ngày
  bằng96kcal trên mục tiêu2200. Xóa bữa vừa xác nhận từ kế hoạch còn đúng một
  bữa táo, kế hoạch vẫn28bữa. Preview/Hủy chưa ghi kế hoạch hoặc nhật ký.
- Cả7ngày trong sai lệch±5% mục tiêu2200; ảnh preview thấy ví dụ2200,08kcal.
  Chỉ xác nhận đã ăn mới thêm nhật ký với ID `plan-...`, kế hoạch đổi sang
  trạng thái `Đã ghi nhật ký`. Không suy ra đã kiểm retry/offline mọi trường hợp.
- Firestore Rules:56/56 test qua, gồm regression mới cho lưu/sửa cá nhân hóa,
  nội dung sai và truy cập chéo. Lỗi permission-denied ở ca tấn công là mong đợi.
- `flutter analyze --no-pub`: sạch; format test mới0thay đổi; `git diff --check`
  không lỗi whitespace. Full Flutter678test ở lượt trước là bằng chứng lịch sử,
  không tính là đã chạy lại678test trong lượt nghiệm thu này.

## Lỗi được phát hiện và sửa

Rules `users/{uid}` trước đây chấp nhận `personalization` lúc create nhưng thiếu
trường này trong `affectedKeys().hasOnly(...)` lúc update. Hồ sơ tạo trước bởi
`ensureProfile` không hoàn tất onboarding có chế độ ăn/món tránh được. Chỉ thêm
field đó vào allowlist update; vẫn kiểm UID, email đã xác minh, trạng thái tài
khoản và toàn bộ `validPersonalization`. Native test sau sửa đã đi qua transaction
profile+body metric, sau đó hoàn tất cả luồng dinh dưỡng.

Những lần chưa đạt được giữ ở
`D:\HealthMateMaintenanceQA\nutrition-20261027\android-first.log` đến
`android-fifth.log`: hai lần đầu lỗi Rules; lần ba fixture chọn banana đã nằm
trong catalog nền nên không có `originalName` top-level; lần bốn thiếu pump sau
convert surface khi chụp ảnh; lần năm harness không mở lại IME sau chụp ảnh nên
chuỗi tìm kiếm không được thay. Đã sửa fixture/thao tác kiểm thử, không nới
assertion nghiệp vụ. Lượt sáu đi qua toàn bộ.

## Phát hiện còn lại và giới hạn nghiệm thu

1. **Chưa deploy Rules production.** Sửa local chưa tự sửa quyền trên Firebase
   đang phục vụ APK. Cần rollout Rules đã review tới đúng project trước nghiệm
   thu production; cài lại APK không thay thế thao tác này. Không thay backend,
   không tạo collection hay migration dữ liệu trong lượt này.
2. **Thực đơn mới đạt kcal, chưa đạt chất lượng thực đơn cân đối.** Ảnh08/09
   cho thấy ngày thử thuần chay tránh sữa/trứng có nhiều bún và cam; riêng bún
   khoảng1.772g/ngày (505,6+660+606,7g). Các phần vẫn dưới giới hạn kỹ thuật
   nhưng lớn, lặp và chưa cân bằng đạm/béo. Cần giai đoạn cải thiện độ đa dạng,
   khẩu phần thực tế và mục tiêu macro trước khi quảng bá là thực đơn cân đối.
3. **UI khi cuộn:** ảnh02 có nội dung đi dưới tiêu đề dashboard trong suốt.
   Không chặn thao tác trong bài này; cần polish nền header/khả năng đọc.
4. **Việt hóa khẩu phần chưa trọn vẹn:** ảnh04 còn `cốc USDA slices`.
   Tên món chính đã Việt hóa; không coi toàn bộ qualifier/nhãn nguồn đã dịch.
5. Chưa kiểm điện thoại vật lý, API USDA ngoài, AI/camera, Firebase production,
   App Check production, thông báo nền hoặc mọi trường hợp mất mạng. Sàng lọc
   nguyên liệu bằng metadata/từ khóa không chứng nhận an toàn dị ứng/nhiễm chéo.

Các mục2–4 là phát hiện để làm tiếp, không sửa UX/thuật toán ngoài phạm vi
nghiệm thu này. Không đổi Dart sản phẩm hoặc tạo APK bàn giao mới: thay đổi runtime
ở lượt này nằm trong Rules server; APK integration chỉ dùng cho AVD QA.

## File và bằng chứng

- `firestore.rules`, `rules-tests/firestore.rules.test.cjs`: sửa allowlist và
  regression. `tool/test_android_core.ps1`: thêm suite nutrition.
- `integration_test/nutrition_acceptance_test.dart`: luồng native, SQLite,
  số liệu thật và tài khoản A/B. `docs/database-design.md`,
  `docs/implementation-progress.md`, `docs/test-report.md`: cập nhật trạng thái.
- Log thành công: [android-passed.log](../build/android-nutrition-20261027/android-passed.log).
- Rules56/56: [firestore-rules.log](../build/android-nutrition-20261027/firestore-rules.log).
- Analyzer cuối: [analyze.log](../build/android-nutrition-20261027/analyze.log).
- Ảnh: [tên gốc/150g](../build/android-nutrition-20261027/c6-nutrition-04-vietnamese-original-grams.png),
  [sửa200g](../build/android-nutrition-20261027/c6-nutrition-06-edit-and-daily-total.png),
  [preview kcal](../build/android-nutrition-20261027/c6-nutrition-07-kcal-plan-preview-no-write.png),
  [28bữa](../build/android-nutrition-20261027/c6-nutrition-08-confirmed-plan-28-meals.png),
  [đã ghi nhật ký](../build/android-nutrition-20261027/c6-nutrition-09-plan-to-diary-once.png),
  [xóa bữa](../build/android-nutrition-20261027/c6-nutrition-10-delete-diary-preserves-plan.png).

`build/` là artifact local không commit; các đường dẫn ảnh/log cần giữ riêng khi
chia sẻ báo cáo. Backend emulators tự dừng sau runner; AVD QA được đóng sau khi
thu bằng chứng. Không tắt laptop, không push GitHub, không đụng dữ liệu thật.
