# Gói 8 — yêu cầu hỗ trợ có hạn mức và lịch sử phân trang

Candidate ngày 31/10/2026. Chưa deploy Rules/client. Giữ Firebase/Firestore,
không thêm backend, dependency, credential hoặc dịch vụ trả phí.

## Chính sách đã chọn

Hạn mức áp dụng **tạo ticket mới**: tối đa **3 ticket/ngày Việt Nam UTC+7**,
hai ticket mới cách nhau ít nhất **60 giây** theo `request.time` của Rules.
Đây là giới hạn tần suất, không phải giới hạn số ticket chưa giải quyết.
Không khóa phản hồi, mở lại ticket đã giải quyết hoặc admin trả lời/status
khi khách dùng hết hạn mức tạo mới. Mỗi cuộc trao đổi vẫn tối đa 100 tin.

Các giá trị authority đặt tại Rules `supportDailyTicketLimit`,
`supportCreateInterval`, `supportDayStart`; Flutter dùng `SupportPolicy`
để hiển thị/preflight tương ứng. Khi thay chính sách phải đổi hai nơi và
chạy regression trước rollout; client không có quyền cấu hình authority.
Client cooldown chỉ giúp phản hồi sớm; sửa APK hoặc ghi Firestore trực tiếp
vẫn bị Rules kiểm thời gian và counter.

Client so sánh ngày bằng cùng thời điểm (`isAtSameMomentAs`), vì Timestamp
SDK trả DateTime local còn mốc ngày của policy là UTC. Lỗi nghiệp vụ trong
transaction được trả ra ngoài callback rồi mới ném `SupportFailure`, tránh
web SDK biến exception Dart thành `NativeError` và làm mất kiểu lỗi retry.

## Counter và transaction

`support_usage/{uid}` gồm `schemaVersion:1`, `dayStart` (Timestamp bắt đầu
ngày VN), `count` (1–3), `lastCreatedAt`, `lastTicketId`, `updatedAt`.
Counter chỉ chứa metadata hạn mức, không lưu tiêu đề/nội dung báo lỗi.

- Transaction tạo ticket đọc ticket theo operation ID ổn định trước. Nếu
  ticket đã có cùng UID/type/title/body thì thành công idempotent, không
  trừ thêm lượt; payload khác cùng ID bị từ chối.
- Khi ticket chưa có, transaction đọc counter rồi ghi ticket và counter
  cùng lượt. Timestamp tạo/cập nhật là serverTimestamp. Rules kiểm count
  tăng đúng 1 trong ngày, hoặc về 1 khi sang ngày mới thực, đủ 60 giây từ
  lượt trước và count không vượt 3.
- Chiều ticket→counter yêu cầu `getAfter` counter có đúng lastTicketId và
  thời điểm request. Chiều counter→ticket yêu cầu ticket chưa tồn tại trước
  request, tồn tại sau request, đúng UID và createdAt=request.time. Không
  thể tăng counter riêng, tạo ticket riêng, reuse ticket cũ hoặc tạo nhiều
  ticket trong một batch bằng một lượt.
- Owner không reset/delete counter trong sử dụng bình thường. Cleanup chỉ
  xóa sau tombstone account deletion; tombstone vẫn chặn tạo lại. UID khác,
  guest, chưa xác minh không đọc/sửa counter của nạn nhân.
- Hai thiết bị tranh lượt cuối tranh cùng counter. Một request thắng; lỗi
  quyền/conflict không được tự coi là đã gửi. UI giữ nội dung và operation ID
  để thử lại. Mất ACK có thể đọc ticket cùng ID để xác nhận mà không tăng count.

Không cần dựng count ticket mở từ dữ liệu cũ hoặc tin giá trị 0 do client
khai. Counter chưa có bắt đầu 1 ở request mới hợp lệ đầu tiên. **Ticket được
tạo trước rollout không được tính hồi tố vào 3 lượt trong ngày đó**; từ thời
điểm Rules mới có hiệu lực mọi lượt mới đều phải qua counter. Không sửa,
xóa hay đổi trạng thái nội dung support lịch sử. Không có job purge/TTL mới;
counter UID thuộc inventory xóa tài khoản, chính sách giữ audit vẫn như Gói4.

## Lịch sử người dùng

`watchTicketPage` query `uid==currentUid`, `updatedAt DESC, documentID DESC`,
`limit(26)` để hiển thị 25 và một lookahead. Cursor lưu seconds/nanoseconds/ID,
không dùng DateTime làm mất độ chính xác. Cursor giá trị vẫn đi tiếp được
khi document anchor bị xóa. Đang xóa ticket được ẩn khỏi UI nhưng cursor
theo raw query để không bị kẹt. `watchTickets` còn là compatibility first-page
API, không tuyên bố trả toàn bộ lịch sử.

UI có Cũ hơn/Mới hơn, số trang và Về mới nhất. Đổi UID reset cursor, provider
hủy listener trang cũ. Lỗi có tải lại; không dùng local-cache absence để báo
danh sách trống thành công. Index uid+updatedAt hiện có dùng implicit ID cùng
chiều DESC; production index cần kiểm khi rollout, không fallback tải toàn bộ.
Một trang realtime không phải snapshot nguyên tử nhiều trang; ticket được
reply có thể chuyển lên đầu. Tải lại mới nhất để xem thứ tự sau cập nhật.

Admin Gói7 đã phân trang 25 ticket; reply/status có hợp đồng cũ và không bị
counter tạo mới can thiệp. Khách vẫn đọc ticket cũ trên 25/50 qua cursor.

## Kiểm chứng chuẩn bị

- `rules-tests/support-quota.rules.test.cjs`: 8 ca direct-write/cooldown/
  daily window/reset/multiticket/race/UID/deletion. Support Rules cũ và deletion
  precheck được cập nhật tạo ticket bằng cặp counter đúng nghiệp vụ; giữ
  assertions reply/status/audit/cleanup.
- `test/support_test.dart`: thêm biên ngày VN và pagination UI; giữ các ca
  operation ID retry, đổi UID, loading/error, hidden listener và màn 320/chữ lớn.
- `test/support_repository_integration.dart`: opt-in Auth/Firestore demo,
  repository thật counter/idempotency; hai SDK tranh lượt cuối; lịch sử 70
  ticket 25/25/20 với timestamp trùng/anchor bị xóa; reply/reopen và retry khi
  quota tạo mới đã hết. Không gọi model hoặc viết production.

Kết quả chạy thật và log được root chốt ở `docs/test-report.md`; file này
không thay bằng chứng test. Chưa xác minh production hoặc native acceptance.

## Rollout và rollback

Client mới cần Rules mới cho `support_usage`; Rules mới từ chối client cũ
tạo ticket đơn lẻ. Cần rollout phối hợp và hướng dẫn cập nhật app, không
cho phép thiếu counter để tương thích vì sẽ mở lại bypass spam. Không migrate
payload ticket cũ; không reset counter để làm mới quota. Rollback client về bản
cũ trong khi giữ Rules sẽ không tạo mới được, nhưng lịch sử/reply vẫn được
bảo vệ. Nếu rollback Rules thì mất enforcement quota; phải ghi rõ đánh đổi,
review và quyết định production riêng. Không deploy trong gói này.
