# Triển khai admin production — 27/10/2026

Cập nhật 30/10/2026: địa chỉ quản trị chính là
**https://healthmate-admin-vn.web.app**. Hosting site mới trong cùng Firebase
project, dùng chung Auth/Firestore/quyền admin và web App Check key; không tạo
database hoặc tài khoản mới. Auth và reCAPTCHA đã cho phép hai hostname mới
`healthmate-admin-vn.web.app` / `healthmate-admin-vn.firebaseapp.com`.
Nội dung clone từ bản live gồm Premium demo; link cũ giữ hoạt động.
`prepare-release.cjs` nay xuất cấu hình Hosting site mới; cần readiness mới
có site này trước khi đóng gói. Các URL/hash bên dưới là lịch sử rollout 27/10.

Cập nhật 27/10: Rules production mới cho bộ 20 câu cá nhân hóa, hash `04a81618172e2a843e71c57b21208a080aa2643c14c55efce2dd24e6ab0c0428`, đọc lại khớp source. Hosting/App Check/role admin giữ nguyên. Xem [báo cáo bộ câu hỏi](personalization-questionnaire.md). Các hash rollout admin bên dưới là lịch sử trước cập nhật này.

**Giai đoạn:** cấu hình App Check, cấp quyền và nghiệm thu production theo yêu
cầu trực tiếp. Web đã phát hành tại **https://healthmate-app-20261013.web.app**.
Dùng **Tiếp tục với Google → luuxuantung285600@gmail.com**. Tài khoản này đã
xác minh, có provider Google và chưa có mật khẩu riêng; không cần cung cấp mật khẩu.

**Nghiệm thu server đã qua; trình duyệt còn chờ.** Người dùng chọn “Tôi sẽ thử
sau”. Chưa xác nhận popup Google, token App Check hợp lệ từ trình duyệt thật,
hiển thị responsive hoặc email reset tới inbox. HTTP/REST không thay cho UI QA.

## Đã thay đổi trên Firebase

- Project cố định `healthmate-app-20261013`, database hiện có. Không thêm backend,
  database, service-account key hoặc billing account; cuối lượt vẫn `billingEnabled:false`.
- Bật API reCAPTCHA Enterprise, tạo key SCORE **HealthMate Admin Web** cho đúng
  `healthmate-app-20261013.web.app` và `healthmate-app-20261013.firebaseapp.com`;
  gắn key với Web App Check. Không allow-all-domains, localhost/key testing hoặc
  hạ ngưỡng rủi ro 0,5. Public key không phải secret.
- Cấp `admin_roles/{UID}.enabled:true` cho đúng email đã chọn, đọc lại xác nhận.
  Không sửa provider, mật khẩu hoặc dữ liệu sức khỏe của tài khoản này.
- Deploy chỉ Rules và Hosting từ `build/admin-production-20261027/firebase.review.json`.
  Hosting trước đó 404/không có release, không ghi đè website đang vận hành.
  Không deploy indexes/Functions/Storage hoặc đổi Worker/API AI.
- Bổ sung Google sign-in bằng Firebase SDK và CSP cần thiết. Client chờ token
  App Check hợp lệ trước mở đăng nhập production, có timeout/lỗi/nút tải lại.

App Check AI hiện có **vẫn ENFORCED**. Không bật enforcement mới cho Firestore
hoặc Auth để tránh chặn mobile đang dùng trước khi có metrics/QA thiết bị.
REST tests bên dưới chỉ kiểm tra Auth/Rules; client gate không thay thế enforcement
phía dịch vụ. Không tuyên bố App Check server đã chặn mọi request Firestore.

Không hứa miễn phí vô hạn. [Billing chính thức](https://docs.cloud.google.com/recaptcha/docs/billing-information)
quy định hạn mức miễn phí cho project chưa gắn billing; vượt hạn mức có thể lỗi
quota. Không nâng gói hoặc thêm phương thức thanh toán trong lượt này.

## Bản đã phát hành

- Ruleset: `e4c952fa-ea34-4b5f-9043-f1851a991d82`.
- Release Rules: **02:00:38 ngày 27/10/2026, UTC+7**.
- SHA256 Rules chuẩn hóa LF/trim:
  `5d02e1873164ff3fba354b54b6787db149ec5e67377df2fc69d8877495bb0903`.
- Đọc lại server khớp local; indexes cũ không đổi. HTTPS **11/11 file** khớp byte
  gói phát hành; CSP/no-store/nosniff/no-referrer đúng, config không có emulator.
- Backup trước: `build/admin-rollout-backup-20261027`; đối chiếu sau:
  `build/admin-rollout-after-20261027`. Snapshot MVP trong `deploy/` là lịch sử.

## Kiểm thử thực tế

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `npm --prefix admin-web run check` | Qua |
| `npm --prefix admin-web test` | **20/20**, gồm xử lý Google popup bị chặn/hủy |
| `npm --prefix admin-web run test:sdk` | **4/4**, adapter thật + SDK 13.0.0 trên Emulator |
| Rules Emulator 8092 | **74/74**, 11,3 giây |
| `node admin-web/test/production-smoke.cjs --allow-production-qa` | **17/17** kiểm tra Firebase thật, cleanup không lỗi |
| Token App Check sai | HTTP **403**, “App attestation failed.” |
| HTTPS production | **11/11 file** và header khớp |
| `flutter test --no-pub --dart-define=HEALTHMATE_ENABLE_ADMIN_CONTROLS=true test/admin_runtime_test.dart` | **5/5** |
| Build Android debug với cờ admin true | Qua, Gradle **21,6 giây**; còn cảnh báo KGP cũ |

Production QA dùng **ID token end-user**, không dùng quyền chủ dự án để giả
Rules: admin đọc directory; member/anonymous bị chặn; member không tự cấp role;
ghi/đọc metric giả của chính UID; admin không đọc metric member; tạo/sửa món QA
có audit; member không ghi catalog; không hard delete món/audit; khóa chặn đọc,
mở lại khôi phục; thu hồi role chặn admin. OAuth CLI chỉ setup/cleanup fixture
và bootstrap role đã được yêu cầu.

Hai lần đầu lỗi **harness QA**, không nới Rules để vượt lỗi: metric dùng giờ máy
không phù hợp nên chuyển timestamp server; audit account_controls cần toàn bộ
field theo hợp đồng hiện có nên sửa đúng payload test. Lần cuối đủ 17 ca qua.
Tổng **6 danh tính QA** từ ba lượt đã xóa và kiểm tra không còn; role/control/
directory/metric/món QA đã dọn. **Giữ 7 audit QA thành công** để bảo toàn lịch sử;
không tính ID ghi thất bại là audit đã lưu. Không sửa nhật ký sức khỏe thật,
không bật bảo trì/tắt AI toàn app để thử.

Logs/báo cáo ignored: `build/admin-rollout-{unit,sdk,rules,deploy,runtime}.log`,
`build/admin-production-smoke-1793041420664.json`,
`build/admin-rollout-{http-check,final-check,security-after}.json`.
Production QA không chạy trong `npm test`; cần opt-in rõ ràng vì tạo/xóa fixture.
Không lưu password, ID token hoặc OAuth token vào báo cáo.

## APK nhận cấu hình admin

`build/releases/healthmate-admin-enabled-debug.apk`, **236.758.930 byte**,
SHA256 `d59c2bc61b9890314dabc876af4d1d5d588f9cf8689f177182d6b0067519ead7`.
Giữ báo cáo năm/cá nhân hóa/endpoint AI hiện có, chưa cài điện thoại. Đây là debug
có cấu hình App Check debug riêng, không phải bản store để phân phối công khai.

App cũ vẫn dùng MVP nhưng chưa tự nhận cấu hình/đồng bộ directory. Cài bản bật
`HEALTHMATE_ENABLE_ADMIN_CONTROLS=true` để khóa/bảo trì/tắt tính năng thể hiện
đầy đủ trong UI; tài khoản xuất hiện khi đăng nhập/tải hồ sơ. Directory không
phải toàn bộ Auth. Source cờ vẫn mặc định false. Từ bản sửa tích hợp 27/10, dùng
`tool/run_android.ps1` / `tool/build_android.ps1`: cả hai nạp
`config/admin-runtime.json` với define true. Build thô không nạp cấu hình này
vẫn là bản không nhận điều khiển admin.

APK và kết quả mới hơn: [kiểm thử tích hợp admin](admin-runtime-integration.md).

## Người dùng thử sau

1. Mở link, dùng Google đúng email đã cấp quyền; cho phép popup nếu bị chặn.
   Nếu App Check lỗi, ghi lại thông báo; không bỏ bảo vệ hoặc hạ ngưỡng để che lỗi.
2. Kiểm tra danh mục/tải lại/Excel/audit; không khóa/xóa dữ liệu thật để thử.
3. Khi sẵn sàng, cập nhật APK để thử đồng bộ directory/cấu hình.

Tiếp theo: nghiệm thu thủ công trình duyệt và APK khi người dùng sẵn sàng.
Không tự mở tính năng khác, commit/push hoặc thực hiện yêu cầu shutdown cũ.
