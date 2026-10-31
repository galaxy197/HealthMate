# Gói 6 — query nhật ký và lịch sử cân nặng

Candidate local ngày 31/10/2026. Không chạy migration hay deploy production.
Giữ nguyên snapshot dinh dưỡng và dữ liệu lịch sử của Gói 1–5.

## Vấn đề và quyết định

Query cũ lấy `dateKey` và một query `consumedAt` trùng nhau, rồi mới bỏ các
document đã có `dateKey` sau download. Cách đó bảo toàn legacy nhưng không
giảm số document đọc. Firestore không có query “field không tồn tại”; so sánh
với null không tự bắt được mọi document thiếu field.

Marker server-only `users/{uid}/data_migrations/meal_date_key_v1` có
`schemaVersion:1`, `state`, `targetState`, `checkpoint`,
`legacyTimezoneOffsetMinutes`, `updatedAt`, và `verifiedAt` khi đã xác minh.
Owner được đọc, không được tự tạo/cập nhật để giả migration đã hoàn thành.
Rules vẫn chặn mọi ghi sau deletion marker của Gói 4; cleanup xóa metadata này.

| Trạng thái | Query và bảo toàn dữ liệu |
| --- | --- |
| Chưa có marker, marker lỗi/không xác minh hoặc `migrating` | Giữ query tương thích cũ. Vẫn có đọc trùng; không tuyên bố tiết kiệm. |
| `partitioned` đã xác minh | Current: `queryPartition=current` + khoảng `dateKey`; legacy: `queryPartition=legacy` + khoảng `consumedAt`. Hai tập không giao nhau. |
| `complete` đã xác minh | Chỉ query `dateKey`, không tải nhánh legacy. |

Mỗi lần bắt đầu stream hoặc loadRange đọc marker từ server, giới hạn chờ
3 giây; nếu không xác nhận được thì dùng compatibility. Không cache marker
“complete” mù quáng qua UID hoặc dùng cached absence để bỏ legacy. Stream
đang mở dùng mode đã xác nhận lúc mở; mở lại sau migration để tối ưu. Trong
lúc migration, Rules khóa create/update meal; stream cũ phải đóng/mở trong
rollout, không dùng migration trực tiếp trên phiên đang phục vụ production.

Meal mới luôn có `queryPartition=current`; khi người dùng sửa meal legacy,
dateKey/offset hợp lệ đưa nó sang current. Không cho hạ route current về
legacy. Route là metadata, không phải business payload: retry idempotent
không tạo conflict chỉ vì migration thêm/đổi route. Timestamp/nutrition/item
snapshots của bữa đã ghi không bị migration sửa.

`dateKey` hiện có được giữ nguyên, kể cả timestamp nằm ngoài ngày theo múi
giờ thiết bị hiện tại. Legacy thiếu dateKey cần quyết định múi giờ cụ thể;
tool buộc truyền offset, ưu tiên offset đã có trên document. Không suy múi
giờ lịch sử từ laptop hiện tại. Đây là giả định migration phải được chủ dữ
liệu duyệt trước production, không có phép đo nào khôi phục được múi giờ đã mất.

## Migration dry-run và mô phỏng emulator

`tool/meal_query_migration.cjs` mặc định chỉ tính kế hoạch từ fixture JSON
`[{id,data}]` hoặc đọc inventory demo local. Không có cloud apply, Admin SDK,
service-account key hay credential production. Nội dung dry-run có thể chứa
ID và thời gian từ fixture, không ghi snapshot sức khỏe vào log tự động.

```powershell
node tool/meal_query_migration.cjs --fixture fixture.json --legacy-offset-minutes 420 --target complete

$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
node tool/meal_query_migration.cjs --uid UID_DEMO --legacy-offset-minutes 420 --target partitioned
node tool/meal_query_migration.cjs --uid UID_DEMO --legacy-offset-minutes 420 --target complete --apply-emulator
```

Apply chỉ tới URL cố định `127.0.0.1:8080`, project `demo-healthmate-rules`.
Kiểm account deletion trước mọi batch, từ chối migrate account đang xóa.
Preflight từ chối timestamp/dateKey/offset sai; đặt marker `migrating` để
Rules khóa ghi meal, liệt kê lại toàn bộ inventory, updateMask chỉ các field
route/dateKey/offset, batch 100 và checkpoint document ID. Retry luôn scan
lại tất cả, không tin checkpoint để skip. Không downgrade marker complete.
Xác minh toàn inventory và số lượng trước khi ghi `verifiedAt` + trạng thái
cuối. Lỗi giữ `migrating` cho review/resume, không báo thành công.

Tool này là chuẩn bị local, không phải infrastructure migration production.
Trước production cần identity đặc quyền có phạm vi tối thiểu, backup/dry-run,
chính sách múi giờ, đóng client cũ và kiểm Rules/index thực, lock/lease chống
hai worker cùng migrate, xử lý deletion race theo job server và rollback.
Rollback an toàn có thể đưa reader về compatibility; không xóa dateKey mới
để “hoàn tác” vì có thể đã có lượt chỉnh sửa hợp lệ. Giữ snapshot backup và
kiểm conflict trước bất kỳ rollback dữ liệu nào. Không xóa nhánh compatibility
chỉ vì code/tool đã có; marker từng UID phải chứng minh migrate hoàn tất.

## Cân nặng: query có giới hạn, không cắt báo cáo âm thầm

- `watchLatestBodyMetric` đã có `limit(1)`, nay onboarding và Quest cũng dùng
  nó. `watchFirstBodyMetric` dùng query tăng dần `limit(1)` cho baseline thật.
  Không tính tiến độ mục tiêu từ lần cân đầu của một trang tải thiếu.
- `watchBodyMetricPage`: thứ tự `measuredAt DESC, documentID DESC`, cursor
  giá trị timestamp/ID; tải tối đa 26 document để hiện 25 và biết còn trang.
  Timestamp trùng không gây mất/trùng; cursor vẫn dùng được nếu anchor bị xóa.
- Hồ sơ có nút Cũ hơn/Mới hơn và nhãn số trang. Biểu đồ nói rõ chỉ dùng tối
  đa 12 lần của trang đang xem. BMI/latest và baseline không đổi khi đổi trang.
  Đổi UID reset cursor; subscription autoDispose theo page/UID.
- Overview tái dùng stream trang đầu, không mở listener lịch sử toàn bộ.
  API `watchBodyMetrics` còn để tương thích, trả 25 mới nhất, được mô tả rõ.
- Báo cáo dùng `loadBodyMetricsRange`, không dùng dữ liệu phân trang. Giữ
  bound 1–90 ngày và trần 2.000 document/source; vượt trần báo lỗi, không trả
  tổng thiếu. Query meal range vẫn all-or-error nếu một nhánh lỗi.

Phân trang realtime không phải snapshot nguyên tử nhiều trang. Chèn/sửa cân
trong lúc chuyển trang có thể đổi vị trí; tải lại từ trang đầu để xem ổn định.
Không cộng các trang thành báo cáo lịch sử hoặc cam kết snapshot bất biến.

## Kiểm chứng và giới hạn phép đo

`tool/meal_query_migration.test.cjs` kiểm mixed schema, idempotency, resume
mô phỏng, biên ngày/offset, dữ liệu sai và guard không chạy production.
`tool/meal_query_migration.integration.cjs` chạy thật trên emulator với 205
records, apply/resume/idempotency và đối chiếu dinh dưỡng không thay đổi.
Hai file tổng **6/6 qua**, exit0; log `build/package6-migration-final.log`.
`test/query_history_test.dart` kiểm cursor tie, 500 measurements nhiều năm,
baseline/latest độc lập, UI older/newer/BMI. SDK opt-in
`test/query_repository_integration.dart` kiểm dữ liệu/đọc thật trên emulator:
compatibility tải 5 document cho 3 meals; partitioned tải 3; complete tải 3
với một query meal. Mỗi lần còn đọc marker riêng; đây là đếm document từ
snapshot SDK, chưa phải hóa đơn production, chưa tính reconnect/index billing.
SDK còn kiểm empty day, timezone/dateKey, history 130 records với timestamp
ties, page tối đa 26, latest/first mỗi query 1, báo cáo 60 records không cắt
theo page, và chặn UID khác. SDK **4/4 qua**, exit0, khoảng 1 giây;
log `D:/HealthMateMaintenanceQA/package6-sdk.log`. Unit/widget query history
**3/3 qua** trong full Flutter **780/780**; analyze không có lỗi.

Không phát hành APK hoặc chạy nghiệm thu Android trong Gói 6. Rules/indexes
và client cần rollout phối hợp. Client cũ không có route bị từ chối khi marker
đã tối ưu; dữ liệu chưa migrate vẫn dùng compatibility và vẫn tốn đọc trùng.
