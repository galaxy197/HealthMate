# Bảo trì HealthMate — 17/10/2026

## Phạm vi và checkout

Đợt sửa lỗi MVP theo tài liệu `Sửa lỗi`: F01–F06 và R01; không phát triển giai đoạn mới.
HEAD ban đầu và cuối lượt: `3e8e9cc756c0a8caf1a882f6829088216736e56b`, branch `main`.
Checkout sạch lúc bắt đầu; không có thay đổi chưa commit của người dùng phải loại bỏ.
Toàn bộ thay đổi đợt này được giữ trong working tree để review. Không stage, commit,
push, tạo PR, deploy Rules/indexes, chạy migration, bật billing hoặc sửa dữ liệu sức khỏe production.

## Kết quả theo lỗi

| ID | Nguyên nhân/bằng chứng | Thay đổi | Test/bằng chứng cuối | Trạng thái |
|---|---|---|---|---|
| F01 | Form đóng trước khi repository ghi; lỗi ghi làm mất bản nháp. Nước/vận động có cùng hành vi và được tái hiện bằng fake. | Giữ form tới khi Future ghi được xác nhận; hiển thị pending/lỗi ngay trên form; khóa gửi lặp/back khi pending; loại bỏ form khi đổi UID và bỏ qua kết quả cũ. | Test đỏ bữa 150g trước sửa; test xanh cho bữa/nước/vận động bị từ chối rồi retry; pending 20s, gửi lặp, đổi session và completion muộn. SDK emulator xác minh ghi offline chưa được coi là thành công và chỉ commit sau reconnect. | Đã sửa và xác minh bằng widget/fake + SDK emulator; chưa thao tác tài khoản thật trên điện thoại. |
| F02 | Sửa gram tìm lại món trong catalog hiện tại, thay dinh dưỡng lịch sử 130 thành 260 kcal. | Scale từ snapshot cũ, giữ ID/tên/nguồn/cờ ước tính; kiểm tra gram, macro hữu hạn và dữ liệu thiếu. Món mới vẫn lấy catalog hiện tại. | Test đỏ 100g/150g khi catalog đổi; xanh khi catalog còn/mất món, 130/195 kcal; món mới 150g=390 kcal; repository thật lưu/đọc lại trên emulator. | Đã sửa và xác minh local + SDK emulator; không migration lịch sử. |
| F03 | Đã đọc Rules đang triển khai bằng quyền sẵn có: thiếu match ghi `goals`, `daily_quests`, `chat_sessions`. Không có trace thao tác Quest từ tài khoản production trong lượt này. Provider còn thiếu phân loại nguồn lỗi và retry rõ ràng. | Chẩn đoán theo quest/goals/meals/water/activity-read và quest-create, mã lỗi an toàn; retry tải lại nguồn lỗi/đang kẹt; không thay lỗi bằng dữ liệu rỗng. Giữ document Quest theo ngày. Rules local đã có quyền phù hợp nên không cần sửa thêm. | 4 nguồn lỗi được test độc lập bằng fake và bấm Retry thật; Rules 31/31, SDK 6/6 bao gồm tạo/hoàn thành/mở lại Quest không mất trạng thái. | Đã sửa local; production còn bị chặn bởi Rules chưa triển khai và cần kiểm tra lại sau deploy được duyệt. |
| F04 | Android nhận App Check token khoảng 1,2s; có lượt cloud thành công, nhưng nhiều lượt không có response/first chunk trong 45s. Probe transport cuối đã tới HTTP send, chưa nhận status. Chưa đủ bằng chứng kết luận nguyên nhân mạng/backend/model/quota. | Thêm log thời gian theo giai đoạn, mã lỗi an toàn và probe Android có giới hạn thời gian; phân biệt lỗi sinh câu trả lời với lưu hội thoại. Không tăng timeout, đổi model/provider hay bypass App Check. | Một lượt Chat 14 chunks/18,151s, first chunk14,465s; Scanner service parse15,709s. Ba lượt khác Chat/Scanner timeout khoảng45s mỗi thao tác. | Chưa sửa dứt điểm; runtime cloud không ổn định. Không coi một lượt thành công là hết lỗi. |
| F05 | Mỗi ô tóm tắt rộng cố định145dp khiến màn hình hẹp xuống một cột dù có thể chia đôi. | Tính số cột/chiều rộng từ constraint và textScale; 2×2 ở cỡ chữ chuẩn, một cột khi chữ lớn/hẹp. | 24 tổ hợp kích thước/chữ/theme; xem ảnh render thực của component ở360/390/412/900dp. | Đã sửa và xác minh widget/render; chưa xem bằng mắt trên điện thoại vật lý. |
| F06 | Dòng phụ và nút nhanh dùng chung Row với ellipsis. | Dòng phụ hiển thị đầy đủ, nút +250ml ở hàng riêng; áp dụng widget dùng chung. | Kiểm tra không ellipsis/không vượt số dòng và xem ảnh sáng/tối ở scale1/1,5/2. | Đã sửa và xác minh widget/render. |
| R01 | SDK emulator tái hiện: hết15s repository báo lỗi nhưng reconnect vẫn tạo document. Kết hợp ID mới mỗi lần thử gây nguy cơ trùng; test trước sửa thất bại đúng ở trạng thái settledOffline. | Bỏ timeout giả định thất bại cho write; tạo ID một lần mỗi form mục tiêu; transaction create-if-absent cho retry cùng thao tác. Cùng ID khác nội dung phải báo tải lại, không báo lưu giả; thao tác mới có ID riêng. | SDK test giữ offline16s rồi reconnect, kiểm tra server; retry cùng ID không tăng số bản ghi, payload khác bị từ chối, mục tiêu chủ động tạo riêng vẫn tạo bản riêng. | Đã sửa và xác minh SDK emulator; chưa thử ghi mục tiêu production. |

## Các file chính

- `lib/core/widgets/confirmed_save.dart` (mới): vòng đời form/bản nháp, pending và ràng buộc session.
- `lib/features/journal/presentation/journal_screen.dart`, ba form meal/water/activity
  và ba controller tương ứng: thực hiện ghi trước khi đóng form, giữ dữ liệu khi lỗi,
  chống kết quả bất đồng bộ của UID cũ.
- `lib/features/nutrition/models/nutrition_models.dart`,
  `lib/features/nutrition/data/firebase_nutrition_repository.dart`, meal form:
  scale snapshot và nhận biết dữ liệu thiếu. `hasNutritionData` chỉ là cờ trong model,
  không thêm field Firestore hoặc thay schema server.
- `lib/features/goals/data/{goals_repository,firebase_goals_repository}.dart`,
  goal form/providers/failure và `daily_quest/presentation/quest_screen.dart`:
  retry có ID ổn định, chẩn đoán nguồn và thông báo lỗi có thể xử lý.
- `lib/core/errors/operation_diagnostics.dart` (mới), các service Chat/Scanner
  và Chat controller: log debug chỉ gồm area/stage/outcome/code/elapsedMs;
  không log UID, token, prompt, hồ sơ hoặc exception thô.
- `lib/core/widgets/metric_tile.dart`, `daily_summary_card.dart`: bố cục F05/F06.
- `test/maintenance_regression_test.dart`, `maintenance_quest_test.dart`,
  `maintenance_layout_test.dart` (mới); `test/firebase_repository_integration.dart`
  và fake Goals: kiểm thử hồi quy và dữ liệu thật trên backend giả lập.
- `integration_test/maintenance_ai_probe.dart` (mới): entrypoint QA tùy chọn,
  không phải bài Flutter integration binding đã được tuyên bố pass.
- `pubspec.yaml`, `pubspec.lock`: đưa `http`1.6.0 đã có bắc cầu thành dev dependency
  để probe ghi thời điểm gửi/status transport; `flutter pub get --offline` thành công,
  không nâng phiên bản dependency hoặc thêm dịch vụ/runtime backend.
- Tài liệu này và phần nối thêm vào `test-report.md`, `implementation-progress.md`.

## Kiểm thử thật trong lượt này

Môi trường: Windows, Flutter3.44.1/Dart3.12.1; Java21; Firebase Emulator Suite với
project cố định `demo-healthmate-rules`; SDK integration qua Chrome thật kết nối Auth/Firestore emulator.

| Lệnh/kiểm tra | Kết quả cuối |
|---|---|
| Baseline `flutter test --no-pub` trước sửa | 138/138 pass. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 145 file, 0 thay đổi, exit0. Chỉ format các file liên quan khi chỉnh sửa. |
| `flutter analyze --no-pub` | No issues found, 19,0s, exit0. |
| `flutter test --no-pub` | 176/176 pass, khoảng19s, exit0; không skip/hạ assertion. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass, 0 fail. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_emulators.ps1` | Rules31/31 + Firebase SDK integration6/6 pass, exit0. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công, assembleDebug52,1s; build app chính không có define debug token của probe. |
| `git -c core.safecrlf=false diff --check` | Sạch trước khi kết thúc. |

Các lượt test đỏ trước sửa là bằng chứng, không phải kết quả cuối: F01 form biến mất;
F02 catalog đổi làm sai130→260/195→390; R01 báo hết chờ nhưng write vẫn commit.
Một lượt toàn bộ suite trong quá trình sửa phát hiện thông báo lỗi mục tiêu thiếu câu
nhắc giữ bản nháp. Đã bổ sung câu đó trong sản phẩm, giữ assertion cũ và chạy lại176/176.
Harness F01 ban đầu thiếu ensureVisible cũng đã sửa trước khi tái hiện đỏ chính thức.

Build có cảnh báo các plugin Firebase còn áp dụng Kotlin Gradle Plugin, có thể cần
chuyển Built-in Kotlin trong Flutter tương lai. Đây là cảnh báo, build hiện tại thành công;
không nâng toàn bộ plugin/Gradle trong đợt sửa lỗi này. APK x64 chỉ dành cho emulator,
không coi là APK phù hợp điện thoại ARM hoặc bản release.

Log/ảnh cục bộ (ignored trong `build/`): `maintenance-baseline.log`,
`maintenance-f01-red.log`, `maintenance-red.log`, `maintenance-r01-red.log`,
`maintenance-all-tests.log`, `maintenance-emulators-final.log`,
`maintenance-analyze-final.log`, `maintenance-app-build.log`,
`maintenance-ai-sanitized.log`, `maintenance-ai-repeat-sanitized.log`,
`maintenance-ai-transport-sanitized.log`, `maintenance-layout/*.png`.
Chỉ chia sẻ log đã lọc; không cung cấp log Android thô hoặc APK probe chứa debug token.

## Android/AI: điều gì thực sự đã được xác minh

Không có điện thoại kết nối lúc khảo sát. Dùng AVD QA mới `HealthMateMaintenanceQA`,
`emulator-5580`, Android API30/x86_64, hồ sơ Pixel4, không có tài khoản/dữ liệu người dùng.
AVD và temp đặt tại `D:\HealthMateMaintenanceQA` do ổ C thiếu chỗ.
Kiểm tra `/data` còn9,4GB và app chưa có trước khi cài; chỉ cài qua adb chỉ định đúng
thiết bị, kiểm tra exit code. Không dùng fallback Flutter uninstall, pm clear hoặc wipe.
Sau build cuối ổ C còn khoảng1,6GB, D94,4GB; không cài thêm hoặc xóa dữ liệu để lấy chỗ.

Probe gửi đúng chủ đề kiến thức định sẵn balancedMeals và PNG đỏ tổng hợp1×1;
không dùng ảnh/ngữ cảnh sức khỏe thật, không đăng ký Auth hoặc ghi Firestore production.
App Check debug dùng token sẵn có ngoài repository; không in token. Probe chạy với
timeout thực45s mỗi thao tác và thời hạn host130–155s, không dựa vào đồng hồ test ảo.

| Lượt probe standalone | Chat | Scanner service |
|---|---|---|
| Không precheck | Timeout45,014s, 0 chunks | Timeout45,021s |
| Có platform headers + GET endpoint kiểm tra kết nối | Thành công18,151s, first chunk14,465s, 14 chunks | Parse thành công15,709s |
| Lặp lại không precheck | Timeout45,016s, 0 chunks | Timeout45,043s |
| Transport cùng model/config, không precheck | Đã HTTP send, không nhận status; timeout45,028s, 0 chunks | Timeout45,022s |

GET kiểm tra endpoint trả400 chỉ chứng minh endpoint có thể phản hồi, không chứng minh
request generation hợp lệ hoặc một cách sửa timeout. Không đưa warmup GET vào sản phẩm.
Harness integration binding thử khởi động trực tiếp bằng adb trước đó không có runner
phù hợp, đã dừng và thay bằng standalone; không tính harness đó là pass.

Cloud service/model đã hoạt động trên Android trong một lượt; chưa chứng minh ổn định.
Scanner với ảnh tổng hợp chỉ kiểm tra đường gọi/parse, **không** chứng minh nhận diện món,
camera/permissions, xác nhận khẩu phần và lưu bữa end-to-end. Các phần đó chưa chạy trên
điện thoại thật. Kiểm tra layout là ảnh Flutter component có font Be Vietnam Pro và
MaterialIcons, dùng fixture, không phải ảnh toàn bộ luồng ứng dụng Android.

## Backend thật và việc cần làm tiếp

Đã GET Rules release `cloud.firestore` bằng quyền đăng nhập hiện có; updateTime
`2026-10-13T06:25:21.345792Z`. Không có match `goals`, `daily_quests`, `chat_sessions`;
owner wildcard đọc/xóa không cấp quyền create/update. Local Rules đã có các phần này,
đã kiểm thử nhưng chưa deploy. Không có bằng chứng truy vết thao tác Quest của tài khoản
thật trong lượt này, nên không quy toàn bộ triệu chứng thực tế chỉ cho Rules.

App Check service `firebaseml.googleapis.com` đang ENFORCED; probe lấy được token.
Không nới enforcement. Không nhận403/404/429 ở các lượt generation timeout để khẳng định
lỗi quyền, model không tồn tại hoặc quota. Chưa xác định được nguyên nhân cuối cùng F04.

1. Chủ project review `firestore.rules` hiện có và kết quả31 Rules tests. Deploy cần yêu
   cầu riêng; chỉ triển khai Rules đã duyệt, không deploy indexes/dịch vụ khác kèm theo.
   Sau đó kiểm tra Quest/Goal/Chat bằng tài khoản QA được chỉ định: tạo, retry, mở lại,
   trạng thái hoàn thành/bỏ qua và quyền hai UID. Không thử phá dữ liệu tài khoản thật.
2. Trong Firebase Console, kiểm tra Firebase AI Logic/provider Gemini Developer API,
   App Check app Android đúng project, quota và log/status tương ứng thời điểm gọi.
   Không đổi model/provider/billing chỉ để thử mò; không gửi token/log thô ra ngoài.
3. Chạy lại probe có giới hạn thời gian trên mạng ổn định/Android QA, rồi kiểm tra
   scanner end-to-end và Chat lưu hội thoại sau khi Rules được duyệt. Không tăng45s
   để che timeout. Tiếp tục F04 dựa trên response/error cụ thể.
4. Trên điện thoại thật, cần xem form lưu lỗi giữ150g/loại bữa/thời điểm, mất mạng
   hiển thị pending, đổi session không giữ form cũ, và layout sáng/tối ở chữ1/1,5/2.

Không có thay đổi thiết kế dữ liệu server, migration hoặc nâng hạn mức. Dừng ở đợt
bảo trì này. Theo yêu cầu người dùng, sau khi lưu báo cáo và kết thúc kiểm tra sẽ
hẹn tắt laptop bằng shutdown bình thường, không dùng `/f`; ứng dụng có dữ liệu chưa
lưu có thể chặn thao tác tắt máy. Không đóng cưỡng bức ứng dụng của người dùng.
