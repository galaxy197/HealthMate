# Báo lỗi, góp ý và hỗ trợ khách hàng — 30/10/2026

Đợt mở rộng được người dùng yêu cầu: khách gửi báo lỗi/góp ý trong app và admin
trả lời trên web. Dùng Firebase Auth + Firestore hiện có, không thêm backend,
dependency, dịch vụ trả phí hoặc gửi email/push. Không chạy lại luồng Android
theo yêu cầu người dùng; kiểm thử tự động và build APK được thực hiện riêng.

## Luồng sử dụng

1. **App → Cá nhân → Báo lỗi & Góp ý → Gửi yêu cầu mới.** Chọn Báo lỗi hoặc
   Góp ý, nhập tiêu đề (120 ký tự), nội dung (2.000 ký tự), bấm Gửi yêu cầu.
   Form thông báo nội dung sẽ được admin xem và nhắc không gửi thông tin nhạy cảm.
2. Khách xem 50 yêu cầu cập nhật gần nhất, mở yêu cầu để xem nội dung gốc,
   trạng thái, phản hồi admin và gửi thêm thông tin. Cuộc trao đổi tự cập nhật
   từ Firestore khi màn hình mở. Ngày giờ hiển thị theo Việt Nam.
3. **[Web admin](https://healthmate-admin-vn.web.app) → Hỗ trợ khách hàng.**
   Tìm kiếm theo tiêu đề/nội dung/UID, lọc loại và trạng thái, phân trang 25 mục;
   bấm Xem & trả lời. Nhập nội dung rồi Gửi phản hồi; phản hồi hiển thị trong app.
   Bộ tải hiện có giới hạn 5.000 ticket và báo lỗi nếu chưa tải đủ.
4. Admin chọn Đã tiếp nhận / Đang xử lý / Đã giải quyết rồi Lưu trạng thái.
   Nếu khách bổ sung tin nhắn thì yêu cầu trở về Đã tiếp nhận. Trả lời không
   tự đóng yêu cầu; admin chủ động xác nhận trạng thái.

Mỗi cuộc trao đổi tối đa 100 tin nhắn sau nội dung gốc. Khi đủ, tạo yêu cầu mới.
Mỗi tin tối đa 2.000 ký tự; không có ảnh đính kèm, HTML, xóa/sửa tin đã gửi,
phân công nhân viên, đánh dấu đã đọc hoặc thông báo nền. Danh sách mobile giữ
50 yêu cầu cập nhật gần nhất để giới hạn đọc; chưa có trang lưu trữ yêu cầu cũ.

## Dữ liệu và phân quyền

`support_tickets/{20-char-auto-id}` chứa `uid`, `type:bug|suggestion`, `title`,
`description`, `status:open|in_progress|resolved`, `createdAt`, `updatedAt`,
`messageCount`, `lastMessageId`, `updatedBy`, `deleting`.

`support_tickets/{id}/messages/{20-char-auto-id}` chứa `authorUid`,
`role:customer|admin`, `text`, `sequence`, `createdAt`.

- Khách đã xác minh và không bị khóa chỉ tạo/đọc ticket của mình. Truy vấn
  danh sách mobile có điều kiện `uid == currentUid`; đổi UID bị Rules chặn.
- Admin đọc ticket và tin nhắn khách chủ động gửi; không được đọc nhật ký
  sức khỏe, sửa nội dung gốc hoặc giả danh khách. Khách không được tự đánh dấu
  giải quyết, sửa owner, giả vai trò admin hay đọc tin của UID khác.
- Message append-only và update ticket ghi cùng transaction. Rules buộc
  sequence tăng 1, parent khớp ID message, author đúng Auth, timestamp từ server.
  Không dùng array tăng không giới hạn. Các phản hồi lưu tác giả/thời điểm ngay
  trên message; không mở rộng quyền ghi `admin_audit` của tính năng khác.
- Status update kiểm phiên bản `updatedAt`; yêu cầu vừa thay đổi thì tải lại
  thay vì ghi đè. Retry gửi giữ ID cho tới khi nhận xác nhận để không gửi trùng.
  Nếu hai người gửi cùng lúc, một request có thể bị Rules từ chối trước khi
  SDK retry conflict; UI giữ nội dung/ID để người dùng bấm thử lại an toàn.
- Xóa tài khoản trong app: đánh dấu ticket `deleting:true` để chặn admin reply
  đồng thời, xóa messages rồi parent trước khi xóa Auth. Quy trình có thể chạy
  lại nếu mất mạng. Xóa Auth trực tiếp ngoài ứng dụng không tự chạy cleanup.
- Không gửi nội dung hỗ trợ đến AI hoặc thu thập email/ảnh/log thiết bị tự động.
  Thông tin nhạy cảm do khách tự nhập vẫn có thể xuất hiện trong nội dung, vì
  vậy form và trang quyền riêng tư nêu rõ người được xem và khuyến nghị tối thiểu.

Composite index: `support_tickets`, scope COLLECTION, `uid ASC`, `updatedAt DESC`.
Triển khai thêm đúng index này, giữ các index cũ. Listeners chỉ mở khi vào màn
hỗ trợ và auto-dispose khi rời màn; chưa có cơ chế chống spam/rate limit riêng.

## Kiểm chứng và bàn giao

- Flutter toàn bộ cuối: **707/707 qua**, khoảng 80s; analyzer **No issues found**.
  10 test mới cho validation, gửi/Hủy, draft và ID khi retry, phản hồi admin,
  đổi tài khoản, ngắt listener khi tab ẩn, lỗi tải lại, layout 320px chữ 1/1,5/2.
- Web admin **29/29 qua**, gồm DOM hỗ trợ, giữ draft/ID sau lỗi, status và
  không hiện dữ liệu tải muộn sau logout. Firestore Rules **91/91 qua**,
  gồm 7 test hỗ trợ về hai UID, admin, giả vai trò, ghi nguyên tử, giới hạn,
  xóa tài khoản và hai lượt gửi đồng thời + thử lại.
- Firebase Web SDK thật trên Auth/Firestore Emulator: **5/5 qua**, gồm tạo
  ticket, admin reply, retry cùng ID chỉ một tin, chặn status cũ, khách bổ sung,
  mở lại và cleanup. Không gửi phản hồi cho khách thật trong kiểm thử.
- APK cuối `build/releases/healthmate-support-debug.apk`, **222.973.794 byte**,
  SHA-256 `68D2B3F50ADDC5681FE4E589CA99E77CF53763A0096DFB1DFA2473C3A1A14854`.
  Giữ Premium demo; 7/7 kiểm cấu hình build qua; Gradle 21,8s, exit0.
  Warning KGP của dependency hiện có vẫn còn.

Log/build/backup triển khai ở `build/support-20261030/` và
`build/support-production-before-20261030/`. Trạng thái triển khai cuối cùng
ghi tại `docs/implementation-progress.md` và `docs/test-report.md`.

Đã triển khai Rules và web tại https://healthmate-admin-vn.web.app; đọc lại
Rules khớp source, 15/15 file HTTPS/hash đúng. Index UID/updatedAt đã **READY**,
index cũ giữ nguyên; billing false. Người dùng cài APK cuối và tải lại web để
nghiệm thu. Không tạo ticket/phản hồi thật hoặc đăng nhập thay khách/admin
trong quá trình kiểm thử production.
