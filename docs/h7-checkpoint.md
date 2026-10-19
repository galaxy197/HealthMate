# H7 — Checkpoint lịch sử do hạn mức còn dưới 5%

**Đã tiếp tục và hoàn thành H7 local/Android Emulator sau checkpoint này.** Xem
[h7-private-data.md](h7-private-data.md) và phần H7 cuối test-report.md. Nội dung
bên dưới giữ trạng thái tại thời điểm dừng, không phải tiến độ hiện tại.

H0–H6 đã chốt local/Emulator. H7 **chưa hoàn thành**. Dừng theo yêu cầu người dùng
khi công cụ báo cửa sổ 5 giờ đã dùng 96%, còn 4%; không tự cố hoàn thành cả file.

## Phần đã làm

`lib/features/data_export/models/journal_csv.dart` là bộ mã hóa thuần, chưa nối
vào giao diện hoặc thao tác file. Nhận danh sách đã được repository giới hạn theo
chủ tài khoản; nó không phải lớp xác thực và chưa tự tải Firestore.

- Bữa ăn mỗi món một dòng, nước, vận động, cân nặng; không cộng lặp thêm dòng tổng.
- Khoảng lịch 1–90 ngày, đầu ngày cuối không thuộc khoảng; giữ dateKey/UTC/offset,
  schema xuất và schema nguồn/contract. Cân nặng/meal legacy ghi rõ timezone lấy
  từ thiết bị lúc xuất khi không có offset lịch sử, không giả là múi giờ đã lưu.
- Đơn vị g/ml/serving/entry giữ đúng snapshot; kcal và từng macro/chất xơ giữ
  known/partial/unknown. Giá trị thiếu là ô trống; 0 thật vẫn là số 0.
- UTF-8 BOM, CRLF, quote/escape dấu phẩy, xuống dòng và dấu ngoặc kép. Text có thể
  bị spreadsheet hiểu là công thức được thêm apostrophe, kể cả sau khoảng trắng,
  tab, BOM hoặc ký tự điều khiển. Số sinh từ kiểu num không bị biến thành text.
- Từ chối nguồn trùng mã, ngày/giá trị hỏng, số không hữu hạn và file trên 5 MB.

`flutter test --no-pub test/h7_csv_test.dart`: **4/4 qua**. Bao gồm tiếng Việt,
delimiter/newline, formula injection, ranh giới UTC/ngày lưu, null/0/lower bound,
nước, vận động, cân nặng, schema/timezone, khoảng trống, qua năm, ngày cuối và trùng ID.
Không dùng test thuần này để tuyên bố quyền UID hoặc Android export đã đạt.

## Còn phải làm để hoàn thành H7

1. Đánh giá rồi triển khai lưu nháp cục bộ có mã hóa, theo UID/ngày/bữa, có giới
   hạn/hết hạn/xóa. Không lưu dữ liệu sức khỏe trần trong SharedPreferences.
2. Lưu **operationId cùng draft trước lần gửi đầu tiên**, giữ ID khi phục hồi và
   retry để không tạo trùng nếu server đã lưu trước lúc process chết. Không xóa
   nháp trước server ack; xử lý xung đột payload, chuyển ngày/bữa và đổi UID.
3. Nối tất cả entry point mở MealFormDialog, có thông báo nháp chưa lưu và hành
   động khôi phục/bỏ; không tự submit sau đăng nhập. Cleanup đúng UID khi xóa Auth.
4. Controller xuất gọi các repository range có giới hạn của H5; giữ UID/generation
   xuyên suốt load và kiểm tra lại trước ghi file. Chưa có kiểm thử riêng phần này.
5. Màn chọn ngày/phạm vi và xác nhận riêng tư; cho người dùng chọn nơi lưu bằng
   Android document picker, hỗ trợ hủy/lỗi và kiểm tra đọc lại file. Không tự gửi
   email/upload. Nêu rõ phạm vi các loại dữ liệu xuất và file do người dùng quản lý.
6. Android thật trên AVD QA: process death/relaunch giữ nháp, A/B không lộ nháp,
   server commit trước crash không tạo trùng, export qua OS picker đúng bytes,
   đổi UID giữa lúc load/picker, cleanup riêng UID. Không dùng fake repository
   để thay kết luận SDK/Android. Cập nhật báo cáo, chỉ chốt H7 sau khi đạt.

Chưa thêm package, storage local, collection, Rules/index, route, nút xuất hoặc
Android channel trong H7. Chưa có APK ứng dụng thường mới; APK từ E2E là target
kiểm thử, không phải bản phát hành. Không commit/push/deploy/import production.

Khi tiếp tục: kiểm tra lại hạn mức, AGENTS.md, git status/diff và checkpoint này;
bảo toàn toàn bộ thay đổi H0–H6 và phần H7 hiện có. Không quay lại giả định repo sạch.


Chốt checkpoint H7: analyze cuối sạch (11.5s), format2file; CSV4/4. Bản sao323file nguồn/tài liệu và log nằm ở D:/HealthMateMaintenanceQA/h0-h6-h7-checkpoint-20261019; patchtracked riêng h0-h6-h7-working-tree.patch. H7 còn thiếu đúng như danh sách trên, không công bố hoàn tất.
