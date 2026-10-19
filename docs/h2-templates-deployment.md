# H2 — bữa mẫu và thay đổi dữ liệu, chưa deploy

## Schema và tương thích

Collection mới `users/{uid}/meal_templates/{id}`:
`name` (2–80 ký tự), `items` (1–5 snapshot như bữa ăn), `schemaVersion:1`,
`createdAt/updatedAt` server timestamps. Không lưu ngày/bữa mục tiêu trong mẫu;
khi dùng, các món được chép vào bản nháp ngày/bữa người dùng đang chọn. Vẫn được
sửa từng lượng/bỏ/thêm món trước khi ghi. Tối đa5món/bản ghi và6nguyên liệu/recipe
không đổi. Không gộp mẫu thành một recipe, không tham chiếu nguồn sống để sửa lịch sử.

CRUD repository có transaction, create với ID ổn định, retry cùng payload không
trùng; payload khác cùng ID báo xung đột, sửa mẫu đã xóa không tạo lại. Chỉ xác
nhận thành công sau read server. UID/generation guard bỏ kết quả A sau đổi sang B;
AccountBoundDialog bỏ form của A. Reader chờ server, pending/cache không bị coi
là dữ liệu mới đã xác nhận. Tải lỗi có retry và đường nhập tay vẫn hoạt động.

Mục bữa mẫu trong form cho tạo từ món đang chọn (gồm bữa cũ mở Sửa), tạo mới,
sửa tên/món/lượng, dùng và xóa. Xóa mẫu có xác nhận, không xóa nhật ký. Cleanup
tài khoản của client mới bao phủ meal_templates. **Client cũ chưa biết collection
này**, phải phối hợp nâng client trước khi cho ghi mẫu trên production để tránh
xóa tài khoản bằng client cũ bỏ sót dữ liệu mới. Không có migration dữ liệu cũ.

## Recent/Frequent

Chỉ dùng query20bản ghi gần nhất đã có, chia sẻ provider, tối đa8món gợi ý.
Hay dùng đếm số bản ghi chứa món, không đếm lặp hai dòng trong một bản ghi;
hòa xếp theo lần gần nhất và giữ lượng snapshot mới nhất. Nhãn nêu mẫu số thực,
không gọi là tần suất toàn lịch sử. Để chọn mặc định recent, form chủ động đọc
bounded window một lần; tài khoản chưa có bữa về Tìm món. Nguồn thư viện/yêu thích/
mẫu vẫn lazy; không thêm query lịch sử khác hoặc query theo mỗi lần gõ.

Dùng lại hiển thị lượng trước, thêm trực tiếp vào **bản nháp**, có Hoàn tác và
Sửa khẩu phần riêng trong các món đã chọn; chỉ Lưu mới gọi repository. Pending
chặn gửi lặp, ID bữa ổn định qua retry. H2 không tự tăng giới hạn món.

## Rules và triển khai

Rules local thêm match meal_templates, owner read/query/create/update/delete,
allowlist/type/range, timestamps immutable/REQUEST_TIME,1–5snapshot với tổng
kcal<=20000, tổng từng macro<=2000. Regex và let cache giữ đầy đủ validation
đồng thời nằm dưới giới hạn1.000biểu thức cho5món. Có test5món hợp lệ,6món/
fieldlạ/âm/null/timestamp/macrooverflow bị chặn và guest/B không truy cập A.

**Chưa deploy Rules/index hoặc import production trong H0–H2.** Rules production
đã được triển khai ở U2 là lịch sử, chưa chứa match mới này; tạo/sửa bữa mẫu trên
production chưa nghiệm thu và có thể bị từ chối cho tới deployment riêng.
Các đường ghi cũ không thêm schema mới trong H2. Không cần index composite mới:
mẫu dùng updatedAt DESC, limit40/80/.../200.

Khi được giao deploy riêng: review `git diff 1c258b3 -- firestore.rules`, toàn bộ
test-report H2, client cleanup và manifest catalog H1 riêng biệt; GET backup Rules
mới nhất bằng inspect tool, giữ ngoài build, chỉ deploy firestore:rules với project
healthmate-app-20261013 tường minh. Không apply catalog cùng lệnh. GET/hash sau
deploy và QA được cấp riêng; không suy production pass từ emulator.
Rollback dùng firebase.rollback.json của **backup mới ngay trước deploy**, chỉ
Rules, GET xác minh lại hash. Rollback sẽ chặn create/update bữa mẫu; không xóa
dữ liệu mẫu/nhật ký hoặc thay App Check để vượt lỗi.

## Test và bằng chứng

Kết quả thực tế theo mốc ở docs/test-report.md và docs/h-improvements.md.
Unit/widget, SDK/Rules Emulator và Android được tách riêng; không chạy QA cloud
hoặc xóa tài khoản thật. Bữa mẫu dùng snapshot kể cả nguồn đã mất; không gửi dữ
liệu cho AI và không bật chatbot/scanner.

Android final đạt176s,10checkpoint +kịch bản H2 thực; unit385/385,Rules48/48,SDK16/16; bằng chứng docs/ux/h2. Chưa production.
