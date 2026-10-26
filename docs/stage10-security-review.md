# Giai đoạn 10 — Rà soát bảo mật 25–26/10/2026

Phạm vi: kiểm thử và sửa lỗi trực tiếp ảnh hưởng MVP hiện có. Giữ toàn bộ thay
đổi chưa commit; admin vẫn tạm gác. Không đổi provider/model, quota, billing,
database; không push hoặc triển khai production trong đợt này.

## Lỗi đã sửa trong source

- Chi tiết USDA trả nutrient ID trong `foodNutrients[].nutrient.id`; parser cũ
  đọc sai cấp, có thể tạo món với dinh dưỡng bằng 0. Parser mới đọc đúng cấu
  trúc, kiểm tra đơn vị/giá trị và từ chối kết quả thiếu năng lượng. Macro thiếu
  vẫn là chưa biết; chất xơ bằng 0 vẫn là giá trị đã biết. Có regression tests.
- SQLite danh mục công khai chỉ nhận/đọc nguồn local hoặc USDA, không nhận món
  riêng theo UID. Các hàng cũ mang nguồn user bị ẩn khi đọc. Cache v2 vô hiệu
  hóa hàng USDA từ parser cũ để tải lại; không sửa/xóa nhật ký hoặc món riêng
  trên Firestore. Không lưu giá trị macro thiếu thành số 0 trong cache.
- Bỏ log exception thô của tìm món vì có thể chứa query/URI. Chỉ giữ thông báo
  hằng trong debug, không in nội dung truy vấn/token.
- Kiểm tra quyền admin local yêu cầu email đã xác minh, ngay cả khi có role.
  Thay đổi này chỉ được thử bằng Emulator; không kích hoạt admin production.
- Sửa fixture SDK dùng OOB xác minh email thực của Auth Emulator, không nới
  Rules để fixture chạy. Test marker onboarding dùng timestamp chắc chắn khác
  để tránh trùng serverTimestamp trong các lần ghi quá nhanh.
- Cập nhật bài thử Android theo disclosure Mục tiêu, tab Dưỡng chất và ngày
  hôm nay của nút + toàn app; giữ assertion số liệu, UID và lịch sử snapshot.
- Bộ chạy C6/H7 truyền rõ hai cờ AI=false; guard từ chối chạy nếu thiếu cờ.
  Lượt C6 trước đã đi tới bước cuối nhưng thất bại vì assert cờ AI mặc định
  đã đổi sang true ở app. Không nới assert; sửa runner. Các service AI chưa
  được tạo trong lượt đó theo assertion trước điểm thất bại, không gọi model.
- Thay các API opacity đã deprecated trong hai widget Dashboard; không đổi UI.

## Kết quả đã kiểm chứng

| Kiểm tra | Kết quả |
| --- | --- |
| `flutter analyze --no-pub` | 0 issues, 51,5 giây |
| `flutter test --no-pub` | 584/584, khoảng 68 giây |
| `tool/test_emulators.ps1` | 52 MVP Rules + 8 admin Rules; 19/19 Flutter SDK; import 155 món, retry bỏ qua 155, không ghi users |
| Admin Rules sau bổ sung email gate | 9/9; tổng Rules local hiện tại 52 + 9 = 61 ca đã kiểm tra |
| MVP production candidate Rules | 52/52 |
| `npm run test:auth --prefix rules-tests` qua Auth/Firestore Emulator | 1/1 kịch bản: email verification, JWT refresh, reset password, mã dùng một lần, mật khẩu cũ bị từ chối |
| Worker `npm test`, `npm run check`, `npm audit` | 21/21; syntax qua; 0 lỗ hổng dependency được npm báo |
| Endpoint Worker production, không gọi model | POST thiếu credentials401, GET405 |
| Rà source secret theo pattern | 406 file text, 0 findings; không phải kiểm toán APK/credential store |
| Android core và cache SQLite thật | Qua 10 checkpoint nghiệp vụ + SQLite round-trip/ẩn hàng riêng; 4 phút 13 giây, exit0, log round7 |
| Android H7 privacy, 2 pha và khởi động lại tiến trình thật | Cả hai qua; phase1 17giây, phase2 44giây, runner exit0 |
| APK debug với cấu hình chatbot thật | Build thành công, assembleDebug 15,1 giây |
| Format các Dart file sửa trong đợt này | 11 file, 0 thay đổi |
| Format check toàn lib/test/integration_test/tool | 271 file, 12 file ngoài phạm vi chưa đồng bộ format; exit1, `--output=none` không sửa chúng |

Android core đã kiểm tra register/verify/onboarding, mục tiêu có lịch sử,
thêm/sửa/nhân bản bữa, nước/vận động/cân nặng, CRUD món riêng/công thức và
snapshot sau xóa nguồn, offline/retry, bữa mẫu, quick-add partial macro/thể tích,
ước tính mục tiêu, báo cáo30/90ngày, chất xơ và đổi sang UID thứ hai không thấy
dữ liệu trước. AI service không được tạo và hai cờ AI=false được xác nhận.

H7 xác nhận bản nháp mã hóa tồn tại sau force-stop/mở lại mà chưa ghi server,
mất mạng giữ draft, retry chỉ ghi một bữa; xuất CSV bằng Android DocumentsUI
và đọc lại nội dung (gồm tiếng Việt, giá trị thiếu và chống công thức bảng tính).
UID thứ hai không đọc draft/server của UID trước; đổi UID trong lúc chọn tệp
không được xuất dữ liệu cũ. Xóa tài khoản dọn đúng draft/local và Firestore của
UID hiện tại, giữ dữ liệu UID khác tới khi chính tài khoản đó yêu cầu xóa.

Emulator dùng project demo cố định, tài khoản/nhật ký tổng hợp và AVD riêng
`HealthMateMaintenanceQA` API30. Không dùng tài khoản thật, không clear/uninstall
trên điện thoại của người dùng. Các lần native đầu thất bại do bài thử cũ chưa
theo UI hiện tại/ngày của quick action; log được giữ, không ghi nhận là đã qua.

APK: `build/releases/healthmate-stage10-debug.apk`, 236.547.388 byte, SHA-256:
`7EC5FCD80B9CD67FF042F475BFAA70D9210A59E808D8E40E828A375DB5A61205`.
Đây là bản phát triển, chưa cài lên điện thoại theo lựa chọn thử sau của người dùng.

## Production: điểm còn cần triển khai riêng

Đã đọc Rules và cấu hình bằng API chỉ đọc; không sửa tài liệu người dùng thật.
Snapshot Rules ở `build/stage10-production-review/`, metadata ghi thời điểm
25/10/2026 16:46 UTC, ruleset `4d084994-cde1-4c8f-b8bd-dbfb52611baa`, hash:
`873887eb91e67a19caaa063e4c8f0a8b0f36d5a08d81c7c124f61914e2f7590c`.

1. Production kiểm tra UID nhưng chưa kiểm tra `email_verified`. Tài khoản chưa
   xác minh vẫn có thể truy cập dữ liệu chính nó bằng SDK/API dù UI chặn. Chưa
   thấy bằng chứng truy cập chéo UID; đây là thiếu kiểm soát điều kiện xác minh.
2. Production chưa hỗ trợ đầy đủ các snapshot dinh dưỡng mới (partial macros,
   thể tích, chất xơ, template). App mới có thể bị `permission-denied` khi ghi
   các định dạng đó; không được coi kết quả Emulator là production đã sửa.
3. Cấu hình App Check AI trả `ENFORCED`; endpoint Firestore trả HTTP200 nhưng
   không có `enforcementMode`. Chưa xác nhận Firestore được enforce. Không tự bật
   vì cần xem lượng request hợp lệ và kiểm tra từng client trước khi chặn.
   Auth bật Email/Password và email enumeration protection theo cấu hình đọc được.

## Bản Rules có thể duyệt và rollback

`node tool/prepare_stage10_rules.cjs` tạo:

- `build/stage10-production-candidate/firestore.rules` cùng metadata/config;
- owner bắt buộc đăng nhập + đúng UID + email đã xác minh;
- hỗ trợ schema MVP hiện tại, giữ trần chat 100 messages/50 lượt;
- danh mục chỉ cho tài khoản đã xác minh đọc, không cho client ghi;
- loại toàn bộ root admin role/directory/account controls/app config/audit và
  các helper admin khỏi candidate. Không deploy cả `firestore.rules` local.

Candidate hash:
`6ee24c538f6673bd45ab9d2803f63383ec6877ec75cd3cabf1d5e63c0bbf4bef`.
Đã kiểm thử độc lập 52/52 Rules bằng
`tool/test_stage10_rules_candidate.cjs`. Script chuẩn bị không deploy.
Candidate chưa triển khai. Cần duyệt vì thay đổi điều kiện truy cập của tài
khoản chưa xác minh; không migrate hoặc xóa dữ liệu. Trước khi deploy cần đọc
lại hash production và so với baseline trên, dừng nếu đã thay đổi.

Sau khi được duyệt, chỉ deploy Rules candidate cho đúng project; đọc lại source
và hash để xác nhận. Snapshot và `firebase.rollback.json` trong thư mục review
cho phép phục hồi Rules trước nếu phát sinh lỗi. Rollback sẽ khôi phục cả thiếu
sót email gate, nên chỉ dùng khi cần khắc phục sự cố, không coi là bản an toàn hơn.

## Giới hạn nghiệm thu

- Chưa chạy signed release: `android/key.properties` chưa có. Gradle chặn release
  thiếu khóa; không dùng debug key thay thế. Application ID vẫn là
  `com.example.healthmate`, cần chốt trước phát hành.
- Camera/mã vạch/Google Sign-In và Play Integrity trên release chưa được kiểm
  thử lại trên điện thoại ở đợt này. Kết quả chat trên máy thật trước đó thuộc
  bản trước; không thay cho nghiệm thu APK mới.
- Emulator OOB xác nhận cơ chế Firebase, không chứng minh thư thật vào Inbox
  Gmail hoặc đo chất lượng nhà cung cấp email.
- Không dùng Storage để lưu ảnh gốc; camera/thư viện có thể để file tạm tại máy.
  Không tuyên bố đăng xuất xóa sạch byte cache của Firebase khỏi thiết bị.
- Không gọi AI 50 lượt để thử quota hoặc đánh giá độ chính xác dinh dưỡng.
  Worker tests/fixture không chứng minh mô hình luôn trả lời đúng.
- `npm audit` của cả Worker và dependencies kiểm thử Rules báo 0; đây là kết
  quả registry ở thời điểm chạy, không chứng minh không tồn tại mọi lỗ hổng.
- Native SQLite đã kiểm tra round-trip và ẩn hàng user cũ; chưa tạo fixture
  database v1 đầy đủ để kiểm thử nhánh migration riêng.
- USDA DEMO_KEY vẫn có hạn mức, không bảo đảm tìm món không giới hạn. Detail
  thiếu energy row được hỗ trợ sẽ bị từ chối an toàn; không tự suy ra kcal.

Log cục bộ nằm trong `build/stage10-*` và
`D:\HealthMateMaintenanceQA\stage10-android-round*.log`; không đưa token vào tài liệu.
Chưa chuyển sang Giai đoạn 11.
