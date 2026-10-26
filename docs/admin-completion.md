# Hoàn thiện web quản trị HealthMate — 27/10/2026

**Cập nhật sau yêu cầu triển khai:** App Check/role/Rules/Hosting đã cấu hình,
web đã publish và 17 kiểm tra production qua. Người dùng chọn thử giao diện sau.
Trạng thái mới ở [admin-production.md](admin-production.md). Ghi chú “chưa kích
hoạt/thiếu key” bên dưới là lịch sử hoàn thiện local trước rollout.

**Giai đoạn:** mở rộng admin theo yêu cầu mới, tiếp tục phần từng tạm gác.
Phần quản lý danh mục, tài khoản và cấu hình đã hoàn thiện/kiểm thử local.
**Chưa kích hoạt production**: thiếu public site key App Check cho web và chưa
thực hiện cấp role, deploy Rules/Hosting hoặc bật cờ mobile.

## Người quản trị làm được

| Khu vực | Hành vi hiện có |
| --- | --- |
| Tổng quan | Bốn số đếm từ Firestore: món, tài khoản đồng bộ, tài khoản bị khóa, thao tác quản trị; xem cấu hình tính năng |
| Danh mục | Tạo, xem, sửa thông tin/nguồn/khẩu phần/dinh dưỡng; xóa khỏi danh mục bằng archive, khôi phục; hỏi xác nhận và ghi lý do |
| Tài khoản | Xem tên/email/UID/vai trò; khóa/mở quyền dữ liệu HealthMate; bảo vệ chính admin hiện tại và UID có document role |
| Cấu hình | Quét món, chatbot, bảo trì/thông báo; validation và xác nhận trước ghi |
| Nhật ký | Xem/tìm thao tác có actor, thời điểm, đối tượng, trường thay đổi và lý do; không cho sửa/xóa |
| Các danh sách | STT, màu trạng thái, tìm có/không dấu, lọc nhóm/trạng thái/vai trò, 25 mục/trang; xuất XLSX toàn bộ kết quả lọc |
| Đăng nhập | Firebase Auth, yêu cầu email đã xác minh và role từ server; đăng xuất, quên mật khẩu qua email |

Xóa danh mục là `isActive:false`, không xóa vĩnh viễn document hoặc snapshot bữa ăn.
Mọi ghi danh mục/trạng thái/cấu hình có audit nguyên tử, kiểm tra phiên bản tới
nanosecond và đọc lại server trước báo thành công. Lỗi giữ form để thử lại.
Phiên/role thay đổi làm hủy dữ liệu đến trễ và xóa danh sách đang hiển thị.

Tìm/xuất chỉ bật sau khi tải đủ: cursor theo document ID, từng 200 mục, giới hạn
5.000 mục mỗi collection. Thiếu mạng/quá giới hạn không xuất một phần như toàn bộ.
Không phải truy vấn tìm kiếm server hoặc snapshot collection nguyên tử; bấm tải
lại khi có thay đổi. Tài khoản còn cần đọc controls và role cho UID đã biết.
XLSX là OOXML thật, giữ null khác 0, dữ liệu người dùng là text, không tạo formula.

## Quyền và giới hạn

- Admin không đọc được hồ sơ, nhật ký sức khỏe hoặc hội thoại của người khác.
- `user_directory` chỉ gồm tài khoản đã đồng bộ từ app có cờ admin. Chưa phải
  toàn bộ Firebase Authentication; không thêm Admin SDK/backend để liệt kê/xóa Auth.
- Role do chủ dự án quản lý qua Console/IAM. Client không tự cấp, sửa hoặc list
  role; admin chỉ GET role cho UID đã biết để bảo vệ tài khoản quản trị.
- Khóa Firestore chặn dữ liệu máy chủ; không xóa cache cũ, disable Firebase Auth
  hoặc thu hồi token. Không tuyên bố Rules chặn API AI/Worker riêng.
- Cấu hình/quyền từ xa trên mobile cần build với
  `HEALTHMATE_ENABLE_ADMIN_CONTROLS=true`, hiện vẫn mặc định false.
- Không thêm database, backend trả phí, Storage hoặc lưu ảnh gốc. Gói miễn phí
  của các dịch vụ đang dùng vẫn có hạn mức.

## Cấu hình dùng thật còn thiếu

Kiểm tra **chỉ đọc** với Firebase CLI đang đăng nhập đã xác nhận:

- Project `healthmate-app-20261013`; email `luuxuantung285600@gmail.com` tồn tại,
  đã xác minh. Chưa cấp role trong lượt này; UID chỉ nằm trong báo cáo ignored.
- Web App đã có public config. Cấu hình reCAPTCHA Enterprise hiện **không có
  siteKey**. Không bỏ chặn App Check hoặc tắt enforcement Android để chạy web.
- Hosting site `healthmate-app-20261013` đã tồn tại. Publish vào site này sẽ thay
  nội dung đang có; cần kiểm tra mục đích site trước triển khai.
- Rules đang deploy là MVP, SHA256
  `6a1762dd899ebdac732a9d55e4c4444a27e06a584c1fad982e36088f7108c374`.
  Bản sao read-only ở `build/admin-production-before-20261027`.

Trình tự hoàn tất triển khai:

1. Trong [App Check của dự án](https://console.firebase.google.com/project/healthmate-app-20261013/appcheck),
   đăng ký Web App với reCAPTCHA Enterprise site key kiểu Web/score-based và domain
   HTTPS sẽ host admin. Không cần cung cấp mật khẩu, App Secret hay token trong chat.
   Không nâng billing tự động; nếu Console yêu cầu thanh toán, dừng để xem lựa chọn.
2. Tạo gói mới bằng `admin-web/tool/prepare-release.cjs` theo README, dùng **public
   site key**. Kiểm tra public config, CSP/headers và site Hosting đúng mục đích.
3. Review toàn bộ Rules candidate, đối chiếu backup, chạy Rules tests; cấp role
   `admin_roles/{UID}` với `enabled:true` cho đúng tài khoản được chọn bằng quyền
   quản trị dự án đáng tin cậy; deploy Rules/Hosting theo phạm vi đã xác nhận.
4. Nghiệm thu HTTPS thực: App Check token, đăng nhập admin, người dùng thường bị
   chặn, tạo/sửa/archive, audit, khóa/mở, thu hồi role và email reset vào hộp thư.
5. Sau khi Rules sẵn sàng mới build mobile bật cờ; thử đồng bộ directory và trạng
   thái khóa/bảo trì trên thiết bị. Giữ nguyên dữ liệu đang có.

Gói hiện tại `build/admin-review-20261027` có nguồn, Rules, public config và manifest;
thiếu key nên `clientConfigured:false`, **không sinh Firebase deployment config**.
Tool không có thao tác mạng/deploy/cấp role. Không chia sẻ báo cáo readiness có UID
hoặc thư mục build như mã nguồn. Không commit/push/deploy trong lượt này.

Theo [hướng dẫn App Check Web](https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider),
key cần được đăng ký cho ứng dụng và domain dùng thật. Header Hosting được chuẩn bị
theo [cấu hình Hosting chính thức](https://firebase.google.com/docs/hosting/full-config).

## Kiểm thử thực tế

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `npm --prefix admin-web run check` | Syntax qua |
| `npm --prefix admin-web test` | **19/19**, gồm DOM với linkedom, validation, tải/tìm/phân trang/XLSX |
| `npm --prefix admin-web run test:sdk` | **4/4** trên Auth/Firestore Emulator; dùng adapter production và Firebase SDK 13.0.0 |
| `FIRESTORE_EMULATOR_HOST=127.0.0.1:8092`, `npm --prefix rules-tests test` | **74/74**, cả quyền admin, hai UID, audit và nghiệp vụ MVP |
| `flutter test --no-pub test/admin_runtime_test.dart` | **5/5**, gate/cờ/runtime/directory chỉ danh tính |
| `npm --prefix admin-web audit --omit=dev` | **0 vulnerabilities** |
| HTTP local | Asset/CSP/no-store/nosniff qua; traversal, URL lỗi và POST bị từ chối |
| XLSX qua openpyxl độc lập | Đọc được **67 dòng dữ liệu ×16 cột**, số 0/ô trống/text giống công thức đúng |

Lượt đầu Rules vướng suite wellness dùng cứng cổng 8080; sửa harness đọc biến môi
trường rồi chạy lại đủ 74 ca qua. DOM ban đầu thiếu API form của linkedom; bổ sung
adapter test, giữ assertion thật. Không bỏ test nghiệp vụ để làm xanh.
Log: `build/admin-completion-unit-final.log`, `admin-completion-sdk-final.log`,
`admin-completion-rules-2.log`, `admin-completion-runtime.log`.

Trình duyệt local đang bị tắt trong Work settings, nên chưa QA trực quan bản mới
trong trình duyệt. DOM/SDK/HTTP không thay cho kiểm tra hiển thị thực tế. Chưa chứng
minh email production tới inbox hoặc App Check production hoạt động. Không đổi
Dart trong lượt admin; bộ Flutter đầy đủ 639/639 và analyze 0 issues là kết quả của
lượt báo cáo năm trước đó, không gộp thành lần chạy mới ở đây.

## Đối chiếu yêu cầu môn học

Lượt này đáp ứng phần quản trị danh mục, phân quyền, bốn số liệu dashboard,
tìm/lọc/phân trang/STT/trạng thái, xác nhận xóa và xuất Excel danh sách. **Chưa đủ
để kết luận toàn bộ checklist môn học đã đạt**: bốn báo cáo có Pie/Bar và drill-down,
hai chức năng in, lưu trữ hình ảnh theo quyền riêng tư, Figma/SRS/Jira và bằng chứng
deploy cần rà soát/thực hiện riêng. Không cho admin quyền đọc sức khỏe cá nhân chỉ
để tạo báo cáo. Đề xuất tiếp theo: cấu hình và nghiệm thu admin production.
