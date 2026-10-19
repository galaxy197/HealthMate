# H3 — Nhập nhãn và ghi nhanh, checkpoint 19/10/2026

## Hành vi

Form bữa ăn có Ghi nhanh kcal / nhập nhãn khác. Chọn cơ sở100g,100ml,một khẩu
phần hoặc tổng phần đã ăn; nhập lượng đúng đơn vị (khẩu phần thập phân được).
Ví dụ60kcal/100ml ×250ml =150kcal, không đổi250ml thành250g. Thêm vào bản nháp
chưa ghi Firestore; vẫn cần Lưu bữa ăn và server acknowledgement.
Kcal bắt buộc, tên tùy chọn; macro trống là chưa biết,0 có chủ ý được giữ. Sửa
lượng/copy/Gần đây/bữa mẫu dùng snapshot không phụ thuộc nguồn đang còn tồn tại.

## File/thiết kế chính

- nutrition_models.dart: coverage từng macro, snapshot quantity+unit, codec v3.
- firebase_nutrition_repository.dart: ghi schema2 cũ hoặc3 khi cần, read v3 tính
  subtotal từ snapshot; retry/UID/ack cũ giữ nguyên.
- quick_add_dialog.dart; meal_form_dialog.dart; food_portion_dialog.dart: form
  thực, preview/validation, chỉnh lượng đúng đơn vị. Nút Thêm dưới safe area để
  màn hẹp/chữ lớn vẫn thao tác được.
- food_library_models.dart, meal_template.dart/panel: codec thống nhất; template2
  giữ partial/non-gram; món riêng/công thức tiếp tục đủ macro theo gram.
- Tổng ngày/chi tiết/mục tiêu/Dashboard/WeeklyReflection hiển thị phần thiếu bằng
  —/Chưa đủ dữ liệu/≥subtotal, không tính macro còn thiếu như đã biết0.
- firestore.rules: macro nullable cho meal3/template2,1–5snapshot, đúng UID và
  giới hạn cũ. Numeric interval dùng abs(x-midpoint)<=midpoint tương đương khoảng
  đóng để giảm số biểu thức; không nới giới hạn hay bỏ test5món.
- test/h3_quick_add_test.dart, SDK integration, Rules và Android acceptance thêm
  nhánh H3. Chi tiết schema/rollout ở database-design.md.

## Kết quả đã có

- Format32Dart file đã thay đổi,6được format; focused cuối13/13 đạt4s, gồm daily
  overview calorie-only, bốn cơ sở, snapshot/copy/template/legacy, màn360/390/412
  chữ1/1.5/2× sáng/tối và thực sự xác nhận được form.
- Flutter toàn suite397/397 đạt52s trước khi thêm test daily overview cuối;
  test cuối13/13 chạy riêng sau đó. Không gọi là toàn suite398 nếu chưa chạy.
- flutter analyze --no-pub sạch9.8s; lần kiểm tra checkpoint đang chạy.
- tool/test_emulators.ps1 final:49/49Rules đạt13.2s; import151synthetic catalog,
  retry0creates/updates/conflicts; SDK17/17 đạt23s. SDK kiểm tra400kcal gồm250kcal
  chưa biết macro +250ml150kcal/P7.5/C0/Fchưa biết, wiregramsnull/totalmacroNull,
  readknownsubtotal+coverage, retrycùngID, copyngàytrước, template2 và cleanupA/B.
- Android H3 đang chạy trên emulator-5580/HealthMateMaintenanceQA/API30, named
  Firebase app/demo-healthmate-rules, bản saoQA đã đối chiếu243file gồm Rules.
  Chưa kết luận Android H3 đạt cho tới kết quả cuối.

## Những lần chưa đạt và sửa thật

- Full Flutter đầu389pass/2fail do selector trường chỉnh lượng chưa được lazy
  ListView dựng sau thêm QuickAdd. Dùng scrollUntilVisible ở đúng form, giữ mọi
  assertion snapshot cũ; focused15/15 và full397/397 sau đó đạt.
- Rules nhiều vòng đầu chạm1000expressions ở5món, gồm full/null/mixed. Cache field,
  tách validator/statistics, khoảng số tương đương bằngmath.abs; cuối full49đạt,
  gồm5món tạo+cập nhật, overflow/NaN/string/âm và A/B bị từ chối đúng.
- Một vòng sửa helper gây lỗi cú pháp regex do JS replacement string, đã sửa
  bằng patch tường minh; compiler/fullRules cuối đều đạt. Không che bằng bỏtest.
- Một vòng CLI bị dừng trong startup để lại tiến trình demoFirestore giữ8080;
  kiểm tra đúng PID/project rồi dừng orphan QA, fullEmulator sau đó đạt. Không
  dừng dịch vụ production/app thật, không thay backend khi test lỗi.

## Chưa triển khai production

Không migration bữa cũ. Client cũ không đọc được schema3/template2 và cleanupH2;
phối hợp nâng client trước rollout backend riêng, không downgrade làm mất null.
Chưa deploy Rules/indexes, chưa import catalog mới, không commit/push, không bật
AI hoặc thay billing/package ID. Vì backendproduction chưa có Rules mới, lưu H3
trên production có thể bị từ chối; đây chưa phải nghiệm thu production.

H4–H7 chưa được triển khai tại checkpoint này. Đã tra nguồn Mifflin/FAO/NIDDK để
chuẩn bị H4, chưa thêm công thức/thu thập dữ liệu sinh lý hay đổi luồng mục tiêu.

### H3 — xác minh cuối / dừng theo ngưỡng tài khoản

Hạn mức5giờ còn4% (used96%) lúc kiểm tra, đạt điều kiện người dùng yêu cầu dừng.
Không bắt đầu H4–H7. FullFlutter mới398/398 đạt56s; analyze sau format có1lint
curly braces, đã sửa và analyze cuối sạch9.5s; sau sửa giao diện13/13widget đạt3s,
analyze sạch10.2s. Rules cuối49/49 đạt13.5s (gồm sourceLabel trống tương thích
bữa cũ), SDK17/17 đã đạt23s. Test Rules phụ lần đầu sau sửa regex cú pháp thất
bại, đã sửa bằng patch và chạy lại49đạt; một lần Android phụ trùng cổng Rules
bị chặn startup, chưa chạy app và không tính là pass.
Android H3 chính đạt206s/10checkpoint +H2templates/H3QuickAdd, backenddemo/AVDQA.
Ảnh docs/ux/h3/volume-preview.png trước chỉnh spacing cho thấy helper sát field
và snackbar từ recent che nội dung. Đã thêm spacing/helperMaxLines và ẩn snackbar
khi mở QuickAdd; đang xác minh Android lần cuối cho chỉnh UI, chưa suy pass từ
ảnh cũ. Không claim máy thật/production đã kiểm tra. Không có deploy/push/import.

### H3 đạt; tiếp tục theo yêu cầu mới sau khi hạn mức reset

Android visual-final đạt200s, đủ10checkpoint/H2templates/H3QuickAdd. Đã xem ảnh
volume-preview mới: khoảng cách/hướng dẫn rõ và không còn snackbar cũ che form.
Nguồn243fileQAđối chiếu. H3 hoàn tất local/Emulator; chưa nghiệm thu production.
Người dùng gửi “tiếp tục đi” sau khoảng nghỉ; kiểm tra mới: hạn mức5h used0%,
còn100%. Chưa có lệnh shutdown nào được thực thi/lập lịch. Tiếp tục H4–H7 theo
lệnh mới, vẫn theo dõi điều kiện<5% và tắt máy ở cuối chuỗi hoặc tại ngưỡng đó.
Các mục “Android đang chạy” ở trên là checkpoint lịch sử, đã có kết quả cuối này.
