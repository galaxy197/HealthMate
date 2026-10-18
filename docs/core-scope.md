# HealthMate core — phạm vi và bàn giao C1–C6

## Quyết định phạm vi

Theo file `Sửa` và yêu cầu triển khai C1 của chủ sản phẩm: ưu tiên ghi dinh dưỡng,
cân nặng, nước, vận động cơ bản và tiến độ. C1–C6 thay thứ tự roadmap tính năng cũ
cho đợt core; các quy tắc bảo vệ dữ liệu/kiến trúc/test của AGENTS.md vẫn áp dụng.
Tài liệu này là đầu mối phạm vi core; báo cáo các giai đoạn cũ là lịch sử.

Phần khảo sát/kiểm thử C1 bên dưới được giữ làm lịch sử. Trạng thái hiện hành:
C1–C6 đã triển khai/kiểm thử local; chi tiết từng đợt ở cuối tài liệu.
C6 có E2E Android trên AVD QA/backend emulator và build debug ARM64. Production
và điện thoại thật chưa nghiệm thu; Rules triển khai còn thiếu.
Tại thời điểm C1 chưa thêm nutrition targets, thư viện,
tab Tiến độ rỗng, gym chi tiết, BMR/TDEE, AI, Quest mới hoặc thay đổi thương hiệu.
Chatbot/Scanner tạm tắt; mã nguồn, dependency, Firebase/App Check, lịch sử hội thoại
và snapshot bữa AI đã xác nhận vẫn được giữ. Không migration hoặc xóa dữ liệu.

## Checkout và khảo sát

Kiểm tra ngày17/10/2026, branch `main`, HEAD
`86238197a9f8e24a2222da2da9e74164c35844ea`; working tree sạch lúc bắt đầu.
Không reset/clean/checkout/pull ghi đè. Kết quả C1 nằm trong working tree để review;
không stage, commit, push hoặc deploy trong lượt C1.

Đã đọc AGENTS.md, pubspec/lockfile, Android/Firebase config, main/bootstrap,
router/Auth/onboarding, shell, Profile, Journal và model/provider/repository liên
quan, Rules/indexes và test/fake hiện có. Stack giữ nguyên Flutter/Riverpod/go_router/
Firebase; không thêm/nâng package. Baseline mới chạy176/176 Flutter tests pass (13s),
không dùng kết quả lượt bảo trì trước làm baseline của C1.

| Yêu cầu | Hiện trạng code kiểm tra | Phân loại và bước tiếp |
|---|---|---|
| Auth, hồ sơ, onboarding, cân nặng | Repository Firebase, gate session/profile/onboarding và CRUD BodyMetrics đã có; test và SDK emulator chạy trong C1. | Đã có/đạt local; chưa nghiệm thu điện thoại/production trong C1. |
| Catalog và bữa ăn thủ công | NutritionTotals/MealDraft/MealItemSnapshot, nguồn/ước tính, gram và CRUD Firebase đã có; tối đa5món/MealLog. | Giữ, không xây lại; C3 cải thiện tổ chức và tốc độ nhập. |
| Bản nháp, snapshot, session, retry | ConfirmedSave giữ form tới ack; scale snapshot cũ; controller bỏ qua completion UID cũ; Goals dùng ID ổn định. | Đã có, test hồi quy F01/F02/F05/F06/R01 được giữ và chạy lại. |
| Ngày và dữ liệu cũ | Meal query dateKey + query consumedAt trong khoảng ngày nửa mở cho bản cũ thiếu dateKey; dedup theo ID. Nước/vận động dateKey + offset. | Đã có, giữ nguyên; không fetch100bữa toàn lịch sử để lọc UI, không migration. |
| Nước/vận động | CRUD thật, quick water, tổng ngày chọn. | Đã có; không thêm gym chi tiết hoặc calo tiêu hao giả. |
| Mục tiêu dinh dưỡng | Goals hiện tại là thói quen/cân nặng; C2 thêm nutrition_targets riêng với lịch sử hiệu lực. | Đã triển khai C2 local, chưa deploy production. Không đổi Goals thành nutrition_targets. |
| Recent và sao chép | Recent snapshot và duplicate MealLog mở form đã có. | Có nền tảng, cần hoàn thiện trong C3, gồm nhóm theo bữa và ID thao tác copy ổn định. |
| Yêu thích/thư viện/công thức | Chưa có các collection riêng favorite_foods/custom_foods/recipes và CRUD tương ứng. | C3/C4; không tạo tab chưa hoạt động. |
| Tuần/tiến độ | Weekly Reflection và biểu đồ cân nặng đã có, dùng range queries; chưa có tab Tiến độ hoàn chỉnh theo phạm vi mới. | Có, cần mở rộng C5; chưa mặc định các yêu cầu mới về mẫu số/ngày tương lai đều đạt. |
| Ẩn AI hoàn toàn | Trước C1 còn menu Chat, route/chat, CTA scan ở Nhật ký và menu+. | Đã sửa C1 bằng cờ, gate route/UI/controller/service và test không khởi tạo AI ngầm. |
| Rules production | Có quyền đọc release; khác source, thiếu match ghi Goals/Quest/Chat. | Đã xác minh lại, chờ review/deploy; local pass không chứng minh production đạt. |

## C1 đã triển khai

`lib/core/config/app_feature_flags.dart` có hai cờ build cục bộ, mặc địnhfalse:

- `HEALTHMATE_ENABLE_CHATBOT` → `chatbotEnabled`.
- `HEALTHMATE_ENABLE_FOOD_SCANNER` → `foodScannerEnabled`.

Chạy `flutter run` thông thường là bản core; không cần define hoặc preference mới.
Muốn bật lại có thể dùng define=true trong bản riêng sau yêu cầu AI tiếp theo.
Hai cờ độc lập; test hồi quy AI bật rõ cờ bằng override trong fixture và chỉ dùng fake.
Không tự bật cờ để chạy cloud probe. Flags là cấu hình sản phẩm, không thay Security Rules.

Khi cờ tắt:

- Cá nhân không có menu Chat. Nhật ký không có nút Quét món. Menu+ chỉ có thêm bữa
  thủ công, nước, vận động và vẫn ghi rõ thao tác toàn cục dành cho hôm nay.
- `/chat`, query/trailing slash/subpath và return link từ Auth được chặn về Tổng quan
  sau khi hoàn thành gate Auth/profile/onboarding. Không bypass đăng nhập/onboarding.
  Scanner vốn dùng dialog/quick action, không có route riêng mới được tạo.
- Giữ5branch theo index cũ (Dashboard0, Journal1, Quest2, Chat3, Profile4),3tab hiện;
  Chat không preload. Test tab Cá nhân, Quest hiện có và Back sau blocked push vẫn đạt.
- ChatScreen không dựng nội dung/controller khi cờ tắt; controller dù bị đọc trực tiếp
  cũng không tải hội thoại, gửi câu hỏi hoặc lưu lượt. Knowledge provider trả service
  từ chối cục bộ, không khởi tạo FirebaseKnowledgeService.
- Scanner quick action không được xếp vào hàng đợi; `_scanFood` kiểm tra trước khi mở;
  dialog không chọn ảnh/phân tích nếu bị mở ngoài luồng; checked service từ chối trước
  khi đọc profile/khởi tạo FirebaseFoodScannerService.
- Không thay code nghiệp vụ AI, provider/model, App Check, quyền, schema hoặc cleanup
  lịch sử. Xóa tài khoản vẫn dọn cả chat_sessions/messages theo luồng đã có.

File chính: app_feature_flags mới; app_router, app_shell, profile_screen,
journal_screen/journal_quick_action_provider, meal_log_section;
ChatScreen/Chat providers và Scanner dialog/providers chỉ bổ sung gate;
`test/core_scope_test.dart` mới, test helper và fixture hồi quy bật AI rõ ràng;
README, database-design, implementation-progress và test-report.

## Kết quả thực tế C1

Windows, Flutter3.44.1/Dart3.12.1, Java21; không cài package.

| Kiểm tra | Kết quả |
|---|---|
| Baseline `flutter test --no-pub` | 176/176 pass,13s. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 147file,0thay đổi. |
| `flutter analyze --no-pub` | No issues found,10,7s. |
| `flutter test --no-pub` | 201/201 pass,18s; không skip/hạ assertion. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | Rules31/31 và Firebase SDK6/6 pass; project `demo-healthmate-rules`, Auth/Firestore emulator, SDK qua Chrome. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,assembleDebug11,8s; không truyền cờ bật AI hoặc App Check token. |
| `git -c core.safecrlf=false diff --check` | Sạch khi bàn giao. |

25test C1 mới kiểm tra defaults và từ chối trước Firebase; khởi động/tab/menu không
khởi tạo service/controller/picker AI; lịch sử giữ nguyên; route thường/cold deep link/
Auth return/Back/onboarding; controller trực tiếp và scan action cũ bị chặn; manual
form vẫn mở; hai cờ độc lập. Matrix18tổ hợp360/390/412dp × scale1/1,5/2 × sáng/tối.
Ảnh render dùng Be Vietnam Pro/MaterialIcons, đã xem3ảnh menu+ ở360/1/sáng,
390/1,5/tối và412/2/sáng; nhãn/hành động xuống dòng đầy đủ. Đây là Flutter fixture
render, không phải ảnh runtime điện thoại thật.

Trong quá trình làm: test component cũ cần fixture showScanner=true để giữ nguyên
assertion khi thử scanner; test default service đã điều chỉnh theo API lỗi cục bộ;
test tap Quest thêm chờ cuộn; test push dùng nội dung hiển thị vì imperative push
không phản ánh URL mặc định. Xuất ảnh ban đầu kẹt do fake clock đã dừng và chuyển
sang tester.runAsync. Hai lint mới đã sửa. Kết quả cuối201/201/analyze sạch như trên.

Rules/SDK test dùng tài khoản tổng hợp chỉ trên demo emulator, bao gồm CRUD/lưu đọc
lại, snapshot, offline/reconnect, retry Goals, quyền chéoUID và cleanup. Không gửi
ảnh/hồ sơ/câu hỏi đến AI; không gọi probe AI thật trong C1. SDK test có kiểm tra
lưu hội thoại fixture trên emulator để bảo vệ lịch sử, không gọi model.

`flutter devices` chỉ có Windows/Chrome/Edge; không có Android kết nối. Chỉ build
x64 cho QA emulator, không cài APK/uninstall/clear/wipe app, không chạm phiên người
dùng. Chưa chạy E2E Android hoặc điện thoại vật lý; nghiệm thu đầy đủ thuộc C6.
Build có cảnh báo plugin Firebase còn dùng KGP, chưa chặn build hiện tại; không nâng
hàng loạt Gradle/plugin. APK x64 không phải bản ARM/release cho điện thoại.

Log/ảnh cục bộ nằm trong ignored `build/c1-*.log`, `build/c1-layout/*.png`,
`build/c1-production-rules.json`; không đưa APK, token, log credential lên Git.

## Production và triển khai chưa thực hiện

GET read-only release `cloud.firestore` và ruleset qua Firebase CLI account hiện có
lúc **11:59 ngày17/10/2026 UTC+07**. Project `healthmate-app-20261013`, updateTime
`2026-10-13T06:25:21.345792Z`, normalized SHA256
`0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Source production có match body_metrics/meal_logs/water_logs/activity_logs;
không có match goals/daily_quests/chat_sessions. Wildcard đọc/xóa owner không cấp
create/update. Không coi việc thấy match là nghiệm thu toàn bộ chức năng production.
Trạng thái indexes production chưa xác minh trong C1.

Local Rules đã có các chức năng core hiện tại,31test pass, không cần sửa/nới thêm.
Không có diff Rules/indexes hoặc schema mới. Mục tiêu/Quest production chưa được
xác minh hoạt động; cần review source Rules rồi yêu cầu deploy riêng. Không dùng
production account tạo/xóa bản ghi thử, đăng ký tài khoản hoặc reset mật khẩu.

Hướng dẫn chuẩn bị (chưa chạy deploy):

1. Chủ project review `firestore.rules`, kết quả Rules/SDK và project ID; đây là
   toàn bộ source Rules hiện có, có cả quyền owner cho lịch sử Chat đã bảo toàn.
2. Nếu được yêu cầu deploy riêng, dùng lệnh chỉ Rules có project tường minh:
   `firebase deploy --only firestore:rules --project healthmate-app-20261013`.
   Không deploy indexes/billing hoặc dịch vụ khác kèm theo; không wildcard allow write.
3. Sau deploy được duyệt, kiểm tra core bằng tài khoản QA được chỉ định và đọc lại
   release. Không đánh dấu production đạt trước bước này. AI vẫn tắt.

## Schema dự kiến và kế hoạch C2–C6 (chưa triển khai)

Giữ users/profile, body_metrics, meal_logs với snapshot, water/activity, goals,
Quest và lịch sử Chat. C1 không tạo collection/field/index hoặc database thứ hai.

| Giai đoạn | Dữ liệu/triển khai dự kiến | Điều kiện nghiệm thu cần giữ |
|---|---|---|
| C2 | `users/{uid}/nutrition_targets/{effectiveFromDateKey}`: kcalTarget>0; proteinGTarget/carbsGTarget/fatGTarget cùngnull hoặc cùng số>=0; source=user_manual; createdAt/updatedAt/schemaVersion. | Chọn phiên bản hiệu lực lớn nhất≤ngàyD; không áp ngược trước bản đầu, không ghi lùi quá khứ từ UI; ID theo ngày; không tự sửa kcal bằng công thức macro4/4/9; validation hữu hạn/client+Rules, nhắc lệch>5% và xác nhận; cleanup+quyềnA/B+offline/test lưu đọc lại. |
| C3 | `favorite_foods/{stableFavoriteId}`: sourceKind=catalog,sourceId,timestamps/schemaVersion; nhóm MealLogs theo MealType; hoàn thiện recent/copy. | Không gộp lịch sử; copy mở draft, không mang ID/dateKey/offset nguồn; snapshot độc lập, hủy không ghi, ID thao tác retry ổn định; nguồn mất không thành0kcal. |
| C4 | `custom_foods/{foodId}`: per100g,defaultServingGrams,servingLabel+servingGrams cùng có/không; `recipes/{recipeId}`: snapshot nguyên liệu,yieldGrams,servingsCount tùy chọn,nguồn/ước tính,timestamps/schemaVersion; favorite mở custom/recipe. | Gram là chuẩn; công thức không lồng, tối đa20dòng nếu ngân sách Rules cho phép, kiểm tra mọi dòng; per100g=tổng×100/yield, phần=yield/sốphần; source namespace, lịch sử không đổi khi sửa/xóa nguồn; cleanup mọi collection mới. |
| C5 | Tiến độ/điều hướng cuối dùng lại nguồn tuần/cân nặng/targets, không thêm collection tổng ngày. | Tổng thật, mẫu số ngày có bữa rõ, phân biệt thiếu/tương lai/lỗi; mục tiêu đúngngày; <2điểm cân không kết luận; bounded queries, không listener trùng. |
| C6 | Nghiệm thu Android core và bàn giao, không có schema mới mặc định. | E2E tài khoảnQA, Rules/SDK/build/UI/ngày/mạng/session/cleanup; tách local/production, không thử AI đã tắt. |

Trước mỗi giai đoạn mới, cập nhật database-design và quyết định range/type/bounds/
serializer/Rules/index/cleanup tương ứng; bảng trên chỉ là thiết kế dự kiến, không
phải tính năng đã có. BMR/TDEE, gym chi tiết và phát triển lại AI cần yêu cầu riêng.

**Trạng thái C1: local đạt theo kiểm tra trên; production chưa nghiệm thu.**
Tiếp theo đề xuất C2 — mục tiêu kcal/macros theo ngày hiệu lực; chưa thực hiện.

## C2 — Mục tiêu kcal/macros theo ngày hiệu lực (17/10/2026)

**Trạng thái: local đạt; production chưa nghiệm thu/chưa có quyền ghi mục tiêu mới.**
HEAD vẫn `86238197a9f8e24a2222da2da9e74164c35844ea`. C1 đang có thay đổi chưa commit
khi bắt đầu C2 và được bảo toàn; không reset/clean, stage, commit, push hoặc deploy.
Baseline mới chạy trước C2:201/201 Flutter pass (16s). Không lấy số liệu C1 làm kết
quả kiểm tra của C2. Chỉ thực hiện C2, không làm C3–C6; AI tiếp tục tắt theo C1.

### Hành vi và dữ liệu

- Mở thiết lập từ Tổng quan hoặc Cá nhân, nhập kcal và tùy chọn đủ ba macro.
  Người cũ chưa có nutrition_targets không phải hoàn thành lại onboarding; không
  chỉnh UserProfile/Goals để giả làm mục tiêu dinh dưỡng. Vẫn ghi bữa khi chưa đặt.
- Chọn hôm nay hoặc tương lai. Khi đổi ngày áp dụng, form tải phiên bản của ngày
  đó trước khi chỉnh; có loading/lỗi/retry, không dùng lỗi như một bản thiết lập rỗng.
  Chọn ngày khác sẽ nạp lại giá trị (form đã ghi rõ). Qua nửa đêm, phải chọn ngày
  còn hợp lệ trước khi lưu. Không có thao tác UI sửa/xóa mục tiêu quá khứ.
- Cùng ngày hiệu lực cập nhật cùng document; giữ createdAt và dùng updatedAt phía
  server. NgàyD lấy phiên bản hiệu lực lớn nhất<=D, không áp ngược trước bản đầu.
  Lịch sử bữa/snapshot và phiên bản mục tiêu ngày trước không bị cập nhật hàng loạt.
- Ba macro cùngnull hoặc cùng số;0do người dùng nhập khác trường thiếu. Chấp nhận
  dấu phẩy/chấm, từ chối NaN/infinity, âm/giới hạn sai và dữ liệu không đủ ba chất.
  Bounds kỹ thuật: 0 < kcal ≤ 20000, mỗi macro0..5000g, không phải khuyến nghị y khoa.
- Nếu abs((4P+4C+9F)-kcal)/kcal>5%, phải chọn quay lại sửa hoặc xác nhận giữ số.
  Không tính BMR/TDEE, không tự sửa kcal/macros hay tư vấn mức thâm hụt.
- Tổng quan/Nhật ký hiển thị đã ghi/mục tiêu và còn/vượt đúng ngày.2000/1800 hiển
  thị vượt 200;1200/1800 còn 600; chỉ chặn progress ở100%, giữ số thật. Targetmacro0
  không chia cho0. Nhật ký loading/lỗi không được thay bằng0để tính còn/vượt.
  Nhãn so sánh nói rõ chỉ dựa trên dữ liệu đã ghi, không suy ra mức ăn thực tế.
- Future provider theo UID+dateKey dùng chung, query server limit1; không tải cả
  lịch sử hoặc thêm listener/counter ngày. Lỗi/offline đọc có retry, không báo
  chưa đặt. Sau save invalidate mục tiêu đang cache để các ngày chọn lại đúng bản.

Schema, bounds và ngày đã ghi trước khi triển khai tại database-design.md:
`users/{uid}/nutrition_targets/{effectiveFromDateKey}` với effectiveFromDateKey,
kcalTarget, proteinGTarget, carbsGTarget, fatGTarget, source=user_manual,
schemaVersion1, createdAt/updatedAt. Không thêm timezone field hoặc thay schema cũ.
Không cần composite index mới: where/orderBy cùng effectiveFromDateKey,limit1.
Cleanup tài khoản đã thêm nutrition_targets, không để lại collection mới khi xóa.

### Lưu, mạng và session

ConfirmedSave giữ form đến xác nhận, khóa nhấn lặp và giữ dữ liệu khi lỗi. Form
được AccountBoundDialog đóng khi UID thay đổi; controller theo generation/UID bỏ
qua completion cũ. Không cache mục tiêu giữa hai tài khoản. Bản nháp chỉ ởRAM,
không tuyên bố lưu qua việc đóng app.

Test SDK phát hiện trên web emulator: disableNetwork làm Source.server read lỗi,
nhưng transaction vẫn có thể tới server và hoàn tất. Bài kiểm tra ban đầu giả định
transaction không ghi gì đã thất bại: sau reconnect document thực tế tồn tại.
Repository C2 đã thêm server read-back kiểm tra đúng kcal/macros và metadata không
cache/pending trước khi trả success. Không báo thành công chỉ từ transaction callback.
Nếu xác nhận không được, báo chưa xác nhận, giữ draft; retry cùng ID ngày không tạo
phiên bản thứ hai. Không dùng timeout write để giả định hủy, không coi lỗi là rollback.

Test C2 mới đã cập nhật theo bằng chứng này: vẫn bắt repository từ chối ack khi
read-server lỗi; kiểm tra document thực tế sau reconnect và retry hai lần vẫn chỉ
một phiên bản đúng nội dung. Không sửa/hạ assertion hồi quy6bàiSDK cũ.
Thêm1lượt đọc sau mỗi save để xác nhận nội dung; không query lặp mỗi lần build.

### File chính C2

- Mới `lib/features/nutrition_targets/models/nutrition_target.dart`: model,
  validation, chọn phiên bản theo ngày và phép tính còn/vượt/progress.
- Mới `data/nutrition_target_repository.dart`, `data/firebase_nutrition_target_repository.dart`:
  interface, truy vấn một phiên bản, parser có kiểm tra, transaction upsert/read-back.
- Mới `providers/nutrition_target_providers.dart`: nguồn UID/ngày và controller save.
- Mới `presentation/nutrition_target_form.dart`, `nutrition_target_card.dart`:
  form, xác nhận lệch macro, thông báo lỗi/pending, so sánh theo ngày và entry.
- Sửa DashboardScreen/JournalScreen/ProfileScreen: ghép component, tái sử dụng
  mealLogsProvider đang có; không viết lại toàn màn hình hoặc đổi điều hướng.
- Sửa `firestore.rules`, `firebase_account_data_repository.dart`: quyền owner,
  schema/bounds/timestamps cho collection mới và cleanup.
- Mới `test/nutrition_targets_test.dart`, `test/support/fake_nutrition_target_repository.dart`;
  cập nhật helper clock/target injection, fake profile emit hỗ trợ đổiUID, SDK test
  và4Rules tests mới. Helper dùng clock kiểm soát; bài clock thật/resume cũ vẫn chạy.
- README, database-design, core-scope, implementation-progress, test-report.
  Không sửa dependency, Android/Firebase config hoặc indexes.

### Kiểm thử thực tế C2

Windows, Flutter3.44.1/Dart3.12.1, Java21; backend ghi/xóa kiểm thử chỉ là project
`demo-healthmate-rules` với Auth/Firestore Emulator, SDK Flutter qua Chrome thật.

| Lệnh | Kết quả cuối |
|---|---|
| Baseline `flutter test --no-pub` | 201/201pass,16s. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 155 file,0 thay đổi. |
| `flutter analyze --no-pub` | No issues found,11,6s. |
| `flutter test --no-pub` | 234/234 pass,24s;33 bài C2 mới, không skip. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | Rules35/35 + SDK7/7 pass, SDK 18 s. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,18,0s; không truyền cờ AI/token. |
| `git -c core.safecrlf=false diff --check` | Sạch lúc bàn giao. |

Bao phủ ngày trống/phiên bản tương lai/cuối tháng-năm, validation, thiếu/đủ/0macro,
macro mismatch giữ nguyên số, form lưu lỗi/retry/pending 20 s/double tap, đổiUID lúc
lưu và completion muộn, đổi ngày khi tải, qua nửa đêm, so sánh thật và lỗi nguồn.
SDK kiểm tra create/read/update cùng ID/createdAt, không áp ngược ngày, giữ lịch sử,
server read-back sau sự cố mạng và cleanup; Rules thử owner/guest/B khácUID với
document/collection/query, payload xấu, NaN/infinity/thiếu field/macro/date/schema/
createdAt/unknown fields và upper bounds. Quyền catalog/AI cũ không bị nới.

UI18 tổ hợp360/390/412dp × scale1/1,5/2 × sáng/tối, font Be Vietnam Pro/MaterialIcons.
Kiểm tra nútSave nằm trên vùngkeyboard 260 dp và không có layout exception; đã xem
3 ảnh ở build/c2-layout. Qua xem ảnh phát hiện đệm keyboard bị trùng và đã bỏ,
chạy lại format/analyze/toàn bộ234test/build. Đây là fixture có insets mô phỏng,
không phải E2E Android hay bàn phím thật. Chưa cài APK hoặc chạm dữ liệu/session
điện thoại. APKx64 dành cho emulator, không phải bản ARM/release.

Build còn cảnh báo các plugin Firebase áp dụng KGP, hiện build vẫn thành công.
Không nâng package/Gradle chỉ để xử lý cảnh báo tương lai. Không gọi cloudAI,
không tạo tài khoản/seed/xóa dữ liệu production hoặc chạy migration.
Log kết quả của C2 trong ignored build/c2-*.log; ảnh build/c2-layout/*.png.

### Production, blocker và điểm dừng

Đọc lại Rules production bằng GET read-only lúc **12:23 ngày17/10/2026 UTC+07**:
project `healthmate-app-20261013`, release updateTime
`2026-10-13T06:25:21.345792Z`; normalized SHA256 vẫn
`0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Không có match ghi nutrition_targets, goals, daily_quests hoặc chat_sessions.
**Lưu mục tiêu dinh dưỡng mới chưa được phép trên production** trước khi Rules
được review và triển khai. Local/Emulator pass không thay được bước này.

Việc cần làm khi có yêu cầu deploy riêng: review diff `firestore.rules`,35Rules+
7SDK tests và đúng project; sau đó chỉ deploy Rules bằng
`firebase deploy --only firestore:rules --project healthmate-app-20261013`.
Lệnh này chỉ là hướng dẫn, chưa chạy. Không có index mới phải deploy ởC2.
Sau deploy được duyệt, dùng tài khoảnQA được chỉ định để thử save/load/switchUID/
ngày và thử điện thoại thật. Không dùng tài khoản sức khỏe thật thử xóa/cleanup.

Không stage/commit/push/deploy/billing/migration trong lượtC2. Giữ nguyên các thay
đổiC1 chưa commit, AI vẫn tắt. Dừng ởC2. Tiếp theo đề xuất C3 — nhật ký nhanh,
yêu thích catalog và sao chép bữa bằng bản nháp; chưa triển khai C3.

## C3 — Nhật ký nhanh, món gần đây, yêu thích và sao chép bữa (17/10/2026)

### Giai đoạn và working tree

Chỉ C3 theo file prompt core `Sửa`. Bắt đầu từ main/HEAD
`86238197a9f8e24a2222da2da9e74164c35844ea` cùng toàn bộ thay đổi C1/C2 chưa commit.
Đã đọc AGENTS.md, phần C3/quy tắc chung của prompt, pubspec/Android/Firebase config,
luồng Journal/form/provider/repository, recent/copy cũ, Rules/cleanup và tests.
Baseline mới234/234 Flutter pass17s. Không reset, xóa, stage hoặc ghi đè C1/C2.

### Hành vi hoàn chỉnh

- Nhật ký ngày chia Sáng/Trưa/Tối/Phụ, tổng kcal/số bản ghi và Thêm cho từng nhóm.
  Nhiều MealLog cùng loại giữ độc lập, không gộp document. Nút Thêm giữ ngày đang
  chọn và đặt đúng loại bữa; sửa/xóa cập nhật tổng nhóm, tổng ngày và macro.
  Lỗi catalog không che nhật ký đã tải; loading/error/empty nhật ký vẫn riêng.
- Form có Tìm món/Gần đây/Yêu thích và nhập món ngoài danh mục một lần như cũ.
  Tìm kiếm không dấu, nguồn có loading/error/retry; recent cập nhật live khi đang
  mở, dùng chung provider giới hạn20bữa/tối đa8món khử trùng. Không bắt snapshot
  recent tại thời điểm mở form rồi để cũ. Chỉ mở listener nguồn khi cần.
- Lưu yêu thích catalog vào users/{uid}/favorite_foods/catalog_<sourceId>.
  Lặp thao tác Lưu vẫn một document; nút riêng Bỏ ở Yêu thích. Đang chờ xác nhận
  chặn gửi lặp, lỗi cho retry. Nguồn mất vẫn bỏ được, không sinh món0kcal. Catalog
  thiếu dinh dưỡng không được thêm. Danh sách40 và Xem thêm tăng40 rõ ràng.
  Cache được ghi nhãn, cache rỗng chưa bị kết luận là server không có dữ liệu.
- Sao chép mở draft có snapshot/type/source gốc, cho sửa ngày/giờ/loại bữa/gram
  rồi mới Lưu. Ngày/offset tính lại theo thời điểm địa phương mới; thời điểm tương
  lai bị chặn. Hủy không ghi. Bữa gốc và catalog đổi/mất không làm đổi snapshot.
  ID cấp một lần cho mỗi form mới/copy, retry cùng payload là no-op; nếu server
  đã có nội dung khác thì báo tải lại và dùng Sửa. Không ghi đè ngầm hoặc cấpIDmới
  sau lỗi ack. Chủ động mở copy lần khác là thao tác mới cóIDriêng.
- Tối đa5món/bản ghi, gram chuẩn, scale đủ bốn chất từ snapshot, chỉ làm tròn khi
  hiển thị. Không tạo Món của tôi/Công thức C4, không bật AI/Scanner.

### File chính và dữ liệu

Mới `lib/features/food_library/{models,data,providers,presentation}` cho favorite
reference, repository Firebase, controller UID/ack và nguồn món trong form.
Sửa `nutrition/{models/nutrition_models.dart,data/nutrition_repository.dart,
data/firebase_nutrition_repository.dart,providers/nutrition_providers.dart,
presentation/meal_form_dialog.dart,presentation/meal_log_section.dart}` và
`journal/presentation/journal_screen.dart`. Sửa `firestore.rules`, account cleanup;
mới `test/core_journal_test.dart`, fake favorite và cập nhật test/helper/SDK/Rules.
README, core-scope, database-design, progress, test-report đã cập nhật.

Schema favorite gồm sourceKind=catalog/sourceId/createdAt/updatedAt/schemaVersion1,
ID xác định theo nguồn; timestamps server, createdAt bất biến. Rules exact fields,
bounds/identity/UID, nguồn tồn tại khi tạo; owner vẫn đọc/xóa nguồn đã mất. Catalog
client vẫn chỉ đọc. Không đổi schema MealLog, indexes, package hoặc cấu hình backend.
Không migration dữ liệu cũ. favorite_foods thêm vào cleanup trước xóa Auth.
Chi tiết trong database-design; nhóm UI không tạo kho tổng hợp thứ hai.

### Test/build/E2E thực tế

Windows, Flutter3.44.1/Dart3.12.1/Java21, SDK qua Chrome; mọi write/seed/delete thử
chỉ tới Auth9099/Firestore8080 project `demo-healthmate-rules`. Fixture catalog
được seed REST emulator cố định localhost bằng owner token riêng của emulator;
không có credential production trong code hoặc request thử.

| Lệnh | Kết quả cuối C3 |
|---|---|
| Baseline `flutter test --no-pub` | 234/234 pass,17s. |
| `dart format lib test integration_test` rồi kiểm tra `--output=none --set-exit-if-changed` | 162files,0 thay đổi ở lượt kiểm tra cuối. |
| `flutter analyze --no-pub` | No issues found,8,2s. |
| `flutter test --no-pub` | 270/270 pass,22s;36 ca C3 mới, không skip. |
| `node --test tool/food_catalog.test.cjs` | 7/7pass,0fail/skip. |
| `tool/test_emulators.ps1` | 39/39Rules +9/9SDK pass; SDK19s. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,11,8s. |
| `git -c core.safecrlf=false diff --check` | Sạch. |

36ca C3 gồm modelID/copy qua tháng-năm/nửa đêm/offset/future, nhóm độc lập/tổng và
refresh sửa-xóa, add đúng ngày/loại, recent live/loading/error/cache/nguồn mất,
favorite idempotent/pending/error/retry/nguồn mất/page41/UIDA→B/completion muộn,
copycancel/unknown ack/sameID/newintentID/sửa ngày-giờ-loại-gram, catalog thiếu chất,
giới hạn5/6món;18tổhợp360/390/412dp ×scale1/1,5/2 ×sáng/tối có keyboardinsets260dp,
nguồn yêu thích/món mất và nút Save. Đã xem3ảnh fontBeVietnamPro/MaterialIcons trong
ignored build/c3-layout. Ảnh render/widget test không phải E2E Android.

HaiSDK C3 mới kiểm tra repository thật create/read/retry cùngID/createdAt, quyềnB
không đọc được A, catalog đổi không đổi copy, sửa/xóa copy không đổi nguồn, thời
điểm mới/dateKey/offset, serverread-back, unconfirmed transaction/offline/reconnect
và favorite delete chờ mạng. Cleanup xóa hết dữ liệu A rồi Auth; favorite B còn.
BốnRules C3 mới testguest/owner/B, document/collection/query, payload xấu/identity/
sourcekind/createdAt, catalog thiếu/mất, client không ghi catalog. Các hồi quy cũ
F01/F02/F05/F06/R01 và toàn bộ suite C1/C2 được giữ/chạy lại.

Các lần chạy đầu có lỗi thao tác test do vị trí cuộn thay đổi và assertion đếm
catalog cũ đã bỏ khỏi UI; đã dùng key/ensureVisible/scrollUntilVisible để thao tác
đúng vùng và giữ nguyên assertion195kcal,130kcal,150g/100g và số bản ghi. Test mới
cũng được sửa finderTooltip/disabled tap cho đúng FlutterSDK. Không sửa số liệu
hoặc test để che lỗi sản phẩm. Kết quả cuối ở bảng; log ignored build/c3-*.log.

### Local, production và blocker

**Local: đạt C3 trong phạm vi unit/widget/Rules/SDK emulator/build.** APKdebugx64
chỉ dành máy ảo x64, chưa phải bản ARM/release. Build còn cảnh báo KGP của plugins
Firebase đã có; không nâng dependency ngoài phạm vi. `flutter devices` hiện chỉ
Windows/Chrome/Edge, không Android; chưa cài APK/E2E Android hoặc dùng keyboardthật.
Không uninstall/clear dữ liệu, đăng xuất hay thay session người dùng trên máy thật.
Form giữ draft trongRAM khi lỗi, không phục hồi draft sau đóng app.

**Production: chưa đạt.** GET Rules read-only **12:45:30UTC+07,17/10/2026**:
project healthmate-app-20261013, releaseupdateTime2026-10-13T06:25:21.345792Z,
SHA256normalized `0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Chưa có matchfavorite_foods/nutrition_targets/goals/daily_quests/chat_sessions.
Vì vậy yêu thích mới và mục tiêuC2 chưa lưu được trên production trước khi review
và deploy Rules có chủ đích. Không đánh đồng emulatorpass với livepass.

Việc cần làm sau khi chủ sản phẩm yêu cầu deploy riêng: review Rulesdiff, chạy
39Rules+9SDK, xác nhận đúng project; lệnh dự kiến
`firebase deploy --only firestore:rules --project healthmate-app-20261013`.
Lệnh này chưa chạy. Không có index mới cần deploy. Sau đó thử bằng tài khoảnQA:
thêm hai bản ghi cùngbữa → recent/favorite → copy/sửa ngày-giờ/gram → hủy/retry →
kiểm tra tổng → switchUID; xem chữ lớn/sáng-tối/bàn phím trên Android thật. Không
dùng tài khoản sức khỏe thật thử cleanup/xóa tài khoản.

Không stage/commit/push/deploy/billing/migration hoặc gọiAI trong C3; HEAD giữ
nguyên, bảo toàn C1/C2. Dừng C3. Tiếp theo đề xuất **C4 — món cá nhân và công thức**,
chưa triển khai.

## C4 — Món cá nhân, công thức và khẩu phần (17/10/2026)

### Giai đoạn và working tree đã kiểm tra

Chỉ C4 theo prompt core `Sửa`, trên main/HEAD
`86238197a9f8e24a2222da2da9e74164c35844ea`. Bảo toàn toàn bộ thay đổi C1–C3 chưa
commit. Đã đọc AGENTS.md, yêu cầu core, manifest, router/Auth, hồ sơ, Journal,
form/repository/provider/model dinh dưỡng, favorite, Rules, cleanup và tests.
Baseline mới 270/270 Flutter pass, 19s. Không reset/clean/checkout/pull ghi đè.

### Hành vi người dùng giờ làm được

- Mở Thư viện món từ Cá nhân; tạo, sửa, xóa Món của tôi và Công thức. Form bữa ăn
  có đủ Tìm món/Gần đây/Yêu thích/Món của tôi/Công thức, không thêm tab chính.
- Món cá nhân nhập đủ kcal và ba macro trên 100g, tên khác, khối lượng mặc định,
  nguồn và cặp tên khẩu phần/gram tùy chọn. Số 0 cần được nhập chủ động; không dùng
  field thiếu làm 0. Luồng nhập ngoài catalog một lần vẫn là mặc định.
- Người dùng chủ động chọn Lưu vào Món của tôi khi nhập món ngoài catalog. Nguồn
  thư viện được xác nhận trước khi thêm snapshot vào draft bữa; thông báo bữa vẫn
  chưa lưu. Nếu lưu bữa lỗi, draft còn và retry chỉ bữa, không tạo lại nguồn.
- Công thức chọn nguyên liệu từ catalog hoặc món cá nhân, không lồng công thức;
  mỗi dòng giữ snapshot, sửa gram scale từ snapshot. Tối đa 6 dòng, yield thành
  phẩm có thể khác tổng nguyên liệu, số phần tùy chọn và cho số thập phân.
  Tổng bằng cộng snapshot; /100g = tổng*100/yield; gram/phần = yield/số phần.
- Khi thêm món/công thức vào bữa, chọn gram hoặc phần có quy đổi cụ thể; xem gram
  và bốn số dinh dưỡng trước khi xác nhận. Dấu phẩy/chấm đều được; NaN/Infinity,
  lượng không dương hoặc vượt giới hạn bị chặn. Hiển thị số bằng intl tiếng Việt.
  Snapshot nguồn mới dùng custom:<id>/recipe:<id>, không đổi ID bữa cũ.
- Yêu thích cả catalog/custom/recipe, ID có namespace nên cùng sourceId không va
  chạm. Private favorite đọc nguồn trực tiếp theo UID/ID, kể cả ngoài trang40.
  Lỗi đọc khác với nguồn mất; nguồn mất vẫn bỏ yêu thích được, không sinh món0kcal.
- Sửa/xóa nguồn không thay hoặc xóa MealLog và snapshot nguyên liệu đã ghi.
  Giữ tối đa5món/MealLog, chọn đúng ngày đang xem và cơ chế copy C3.

### Thay đổi chính và dữ liệu/Rules

Mới trong `lib/features/food_library/`:
- `models/food_library_models.dart`: PersonalFood/FoodRecipe, validation, snapshot,
  công thức/khẩu phần; input lists bất biến.
- `data/food_library_repository.dart`, `firebase_food_library_repository.dart`:
  CRUD thật, query bounded, parser, transaction và server read-back.
- `providers/food_library_providers.dart`: state theo UID/kind/limit/ID, lifecycle,
  hủy draft và bỏ completion cũ khi đổi tài khoản.
- `presentation/food_library_screen.dart`, `library_forms.dart`,
  `food_portion_dialog.dart`, `food_nutrition_text.dart`: quản lý thư viện, form,
  chọn nguyên liệu, khẩu phần và định dạng số.

Sửa các file favorite model/repository/provider và `meal_food_sources.dart`;
`nutrition_models.dart`, `meal_form_dialog.dart`, `custom_food_dialog.dart`;
JournalScreen, ProfileScreen; app_routes/app_router/auth_redirect;
`firestore.rules`, `firebase_account_data_repository.dart`.
Mới `test/food_library_test.dart`, `test/support/fake_food_library_repository.dart`;
cập nhật fake favorite, test_app, C3/maintenance/nutrition/6B tests, SDK harness,
Rules tests và README/core-scope/database-design/progress/test-report.

Thêm users/{uid}/custom_foods và recipes, mở favorite sourceKind, cleanup hai
collection trước Auth. Rules kiểm tra UID, allowlist, type, bounds, timestamp,
createdAt bất biến và mọi phần tử mảng. Không ghi client vào catalog. Không đổi
schema MealLog, package, backend config hoặc composite index; không migration.

Create cấp một ID/form; transaction create-if-absent và read-back server. Retry
cùng payload không trùng; nội dung khác báo tải lại/chọn Sửa. Edit không tự tạo
lại nguồn đã xóa. Delete chờ xác nhận. Lỗi ack không được coi là rollback.
Nguồn thư viện lỗi/loading/cache có nhãn và retry, không bị thay bằng dữ liệu giả.
Draft giữ trong RAM, không phục hồi sau khi đóng app.

### Test/build/E2E đã chạy

Windows, Flutter3.44.1/Dart3.12.1/Java21; SDK qua Chrome. Write/seed/delete thử chỉ
ở demo-healthmate-rules, Auth9099/Firestore8080; không dùng dữ liệu sức khỏe thật.

| Lệnh | Kết quả cuối C4 |
|---|---|
| Baseline `flutter test --no-pub` | 270/270 pass,19s. |
| `dart format lib test integration_test`, rồi kiểm tra `--output=none --set-exit-if-changed` | 172 file; kiểm tra cuối không còn thay đổi. |
| `flutter analyze --no-pub` | No issues found,7,4s. |
| `flutter test --no-pub` | 308/308 pass,39s;38 ca C4 mới, không skip. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | 47/47 Rules +11/11 SDK pass, SDK19s. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,45,5s; không bật AI. |
| `git -c core.safecrlf=false diff --check` | Sạch. |

38 ca mới gồm serialization/validation/snapshot/nutrition/yield/portion, UI CRUD,
recipe chọn hai nguồn, nhập phần thập phân đúng ngày, missing/cache/read error,
favorite3namespace, pagination41/direct lookup, pending20s/double tap/unknown ack/
retry cùngID, logout và async A→B, lưu thư viện thành công trong khi bữa lỗi,
nhập một lần không tự tạo thư viện, macro thiếu không bị gán0, route qua Auth.
18 tổ hợp 360/390/412dp × scale1/1,5/2 × sáng/tối thử cả hai form,6nguyên liệu,
chỉnh dòng cuối, form nhập một lần và keyboard insets260dp. Đã xem4ảnh font thật
trong build/c4-layout, gồm form món, công thức,6dòng và nhập một lần chữ lớn.
Đây là render/widget test; chưa phải E2E/keyboard Android thật.

8 Rules test mới kiểm tra owner create/read/query/update/delete, guest/B bị chặn,
field lạ/type xấu/thiếu chất/NaN/Infinity/portion pair/alias đầu-giữa-cuối,
createdAt, payload6dòng và vượt6, lỗi dòng0/2/5, nested recipe, favorite nguồn của
UID khác/mất nguồn; quyền catalog cũ giữ nguyên. 2 SDK test mới xác minh CRUD,
createdAt/retry,6dòng/fractional serving, nhật ký và ingredient snapshot không
đổi sau sửa/xóa nguồn, offline/unknown ack/reconnect và không ghi đè payload khác.
Cleanup SDK xác nhận xóa A trước Auth, món/công thức/favorite B còn nguyên.

Lượt đầu Rules6dòng vượt budget1.000; đã tối ưu validator, không giảm số dòng hay
bỏ kiểm tra. Test UI phát hiện confirm xóa dùng nhầm nested Navigator của nhánh
Cá nhân; đã sửa bằng dialogContext và chạy lại CRUD. Test cũ được cập nhật cuộn
đúng vùng sau khi có5nguồn; giữ assertion dinh dưỡng/số bản ghi F01/F02/F05/F06/R01.
Test nhập một lần giờ điền macro0 chủ động, không còn dựa vào default0 bị thiếu.
Một lượt full test lỗi môi trường errno112 khi compiler copy file tạm trên C;
đã chuyển TEMP/TMP sang D:\HealthMateMaintenanceQA\tmp và chạy lại thành công.
Không xóa cache/dữ liệu người dùng để che lỗi. Có một lượt compile bị ngắt giữa
chừng; kết quả cuối là lượt đầy đủ nêu trên. Log ignored build/c4-*.log.

### Trạng thái local

Đạt C4 trong phạm vi unit/widget/Rules/SDK Emulator/build. `flutter devices` chỉ
có Windows/Chrome/Edge, không Android; chưa cài APK hoặc nghiệm thu máy thật.
APK là debug android-x64, chưa phải ARM/release. Build còn warning KGP đã có của
plugin Firebase; chưa nâng dependency. C vẫn rất ít dung lượng trống nên các
lệnh Flutter QA cuối dùng TEMP/TMP trên D. Không clear/uninstall app, thay phiên
đăng nhập hoặc xóa dữ liệu điện thoại.

### Trạng thái production và bằng chứng

GET Rules read-only lúc **16:11:23 UTC+07,17/10/2026**, project
healthmate-app-20261013: release updateTime2026-10-13T06:25:21.345792Z,
normalized SHA256 `0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Chưa có match custom_foods/recipes/favorite_foods/nutrition_targets/goals/
daily_quests/chat_sessions. **Production chưa đạt, chưa lưu được thư viện mới.**
Local/Emulator pass không xác nhận backend production đã cho phép.

### Lỗi/blocker còn lại và việc cần làm

Cần review Rules diff,47Rules+11SDK và yêu cầu deploy riêng. Lệnh dự kiến, chưa chạy:
`firebase deploy --only firestore:rules --project healthmate-app-20261013`.
Không có index mới phải deploy. Sau deploy có chủ đích, dùng tài khoảnQA trên
Android: tạo món → recipe có yield khác tổng → chọn0,5phần → lưu bữa → sửa/xóa
nguồn → kiểm tra lịch sử → favorite nguồn mất → thử offline/retry/đổiUID.
Xem chữ lớn/sáng tối/bàn phím và nút lưu/xác nhận xóa trên máy thật. Không dùng
tài khoản sức khỏe thật thử cleanup. Draft qua đóng app chưa thuộc phạm vi này.

Không stage/commit/push/deploy/billing/migration hoặc gọi AI trong C4; giữ nguyên
HEAD và C1–C3, AI vẫn tắt. Dừng C4. Giai đoạn tiếp theo đề xuất:
**C5 — Tiến độ, cân nặng và tổng hợp tuần**, chưa thực hiện.


## C5 — Tiến độ, cân nặng và tổng hợp tuần (17/10/2026)

### Giai đoạn và working tree đã kiểm tra

Chỉ C5 theo file Sửa; đọc AGENTS.md, manifest, router/shell, range repositories,
weekly model/provider/card, mục tiêu và cân nặng, Rules/indexes và test liên quan.
Branch main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea` không đổi. Working tree
C1–C4 chưa commit được giữ; không reset/clean/checkout/pull hoặc stage/commit/push.
Baseline mới C5: 308/308 Flutter test pass,33s; không lấy kết quả C4 làm baseline.

Khảo sát: tổng hợp tuần/dateKey/legacy/denominator đã có, tái sử dụng; chưa có
màn Tiến độ, mục tiêu theo tuần và lối thêm cân từ nút+. Không tạo lại model tổng
hợp, kho số liệu hoặc màn Dashboard. Mọi phần AI vẫn mặc định tắt, Quest giữ nguyên.

### Hành vi người dùng giờ làm được

- Bốn tab Tổng quan / Nhật ký / Tiến độ / Cá nhân và nút+ ở giữa. Route Tiến độ
  `/progress` đi qua Auth/onboarding. Append branch5, giữ Dashboard0/Journal1/
  Quest2/Chat3/Profile4. Back/push/deep link và Cá nhân được test; Quest vẫn phụ.
- Tổng quan có nút Xem tiến độ tuần trước phần mục tiêu/Quest. Tiến độ mở tuần
  hiện tại, đổi tuần trước/tuần sau tới tuần hiện tại; giữ tuần khi chuyển tab.
  Tuần bắt đầu Thứ Hai và có ngày/năm, giờ thiết bị, giờ tải và nút tải lại.
- Tổng kcal/Đạm/Tinh bột/Béo đã ghi; nước, phút vận động; số ngày ghi từng loại;
  trung bình kcal chỉ chia cho ngày có bữa và nêu rõ mẫu số. Ngày chưa ghi không
  bị coi là ăn0, ghi0 có chủ ý vẫn là có ghi, tương lai không tính là thiếu ghi.
- Biểu đồ chọn kcal/nước/vận động; chi tiết ngày phân biệt có ghi/chưa ghi/tương
  lai. Chữ lớn vuốt ngang biểu đồ; không thu nhỏ chữ để giấu overflow.
- Cân nặng đúng thứ tự timestamp, khoảng cách trục x theo thời gian, ngày/giờ
  và kg thật, tối đa12 điểm gần nhất của tuần. Dưới2 điểm không kết luận thay đổi.
  Có2 điểm trở lên chỉ nêu chênh lệch đầu/cuối, không suy diễn nguyên nhân.
- Dinh dưỡng và mục tiêu từng ngày: đúng phiên bản hiệu lực, có chưa đặt kcal/
  chưa đặt macro, không áp mục tiêu mới ngược lịch sử. Loading/error/retry riêng
  cho mục tiêu; lỗi mục tiêu không che tổng nhật ký đã đọc thành công.
- Nút+ có bữa ăn/nước/vận động/cân nặng; form cân nặng mặc định hôm nay, có chọn
  ngày đo. Chờ xác nhận lưu, chặn nhấn lặp khi pending, giữ draft khi lỗi/thử lại,
  bỏ form khi đổi UID, làm mới tuần sau thành công. Không tự sửa ngày ở Nhật ký
  khi mở hành động cân; các hành động nhật ký toàn cục vẫn ghi rõ dành cho hôm nay.

### Thay đổi chính và dữ liệu/Rules

File chính C5 (các file khác trong git diff còn chứa C1–C4):

- Mới `lib/features/progress/presentation/progress_screen.dart`.
- Sửa `lib/core/router/app_router.dart`, `app_routes.dart`, `auth_redirect.dart`;
  `lib/core/widgets/app_shell.dart`; DashboardScreen thêm lối xem Tiến độ.
- Sửa `lib/features/weekly_reflection/presentation/weekly_reflection_card.dart`
  để dùng chung ở Dashboard và Tiến độ, mục tiêu ngày và trạng thái tải.
- Sửa `lib/features/profile/presentation/weight_chart.dart` và
  `body_metric_form_dialog.dart` (callback ConfirmedSave optional; luồng cũ giữ).
- Mở rộng interface/Firebase repository/provider trong nutrition_targets cho
  loadForRange và invalidate tuần. FakeNutritionTargetRepository có range counter.
- Mới `test/progress_test.dart`; cập nhật core_scope/dashboard/profile tests và
  `test/firebase_repository_integration.dart`; README và4tài liệu hiện có.

Không thêm schema/collection/Rules/index/dependency, không migration C5. Tái dùng
4 nguồn range một lần/UID/tuần (meal có2 query tương thích cũ), mục tiêu chỉ2 query
bounded và tối đa7 phiên bản/tuần. Không có listener riêng từng ngày ở Tiến độ,
không đọc toàn lịch sử hoặc cắt100bữa. Màn ẩn nhả consumer dữ liệu, quay lại tải
mới; Future Firestore đang chạy không bị hủy nhưng kết quả cũ không được hiển thị.
Chi tiết query, ngày, mục tiêu và cân nặng trong database-design.md phần C5.

### Test/build/E2E đã chạy và kết quả thật

| Lệnh | Kết quả cuối C5 |
|---|---|
| Baseline `flutter test --no-pub` | 308/308 pass,33s. |
| `dart format lib test integration_test`, kiểm tra `--output=none --set-exit-if-changed` | 174 file,0 đổi ở bước kiểm tra. |
| `flutter analyze --no-pub` | No issues found,7,1s. |
| `flutter test --no-pub` | 337/337 pass,41s; không skip,29 ca C5 mới. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | 47/47 Rules +13/13 Flutter SDK pass; SDK21s; project demo-healthmate-rules. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,21,6s, app-debug.apk. |
| `git -c core.safecrlf=false diff --check` | Sạch. |

29ca mới gồm năm mới/tuần Thứ Hai, mẫu số ngày ghi0, thiếu và tương lai, tổngmacro/
nước/vận động, timestamp/độ thưa cân nặng, một lần cân, loading/error/retry/timeout,
đổi tuần liên tục, đổi UID, Auth destination, quick weight lỗi/pending/nhấn lặp/
logout, cùng18tổ hợp360/390/412 × scale1/1,5/2 × sáng/tối. Matrix thử deep link,
push/back và chuyển tab; core_scope cũng đi qua tab mới và kiểm tra AI không chạy.
Hai SDK ca C5 dùng repository thật: lưu/đọc cân nặng và tất cả nhật ký tuần qua
năm mới; target range có base từ tuần trước/đổi trong tuần/biên end, sửa bản mới
không đổi bản cũ, từ chối khoảng sai/offline/UID B và dữ liệu hỏng. Rules owner A/B
và cleanup A trước Auth, giữ B, được chạy lại. Không seed/test tài khoản thật.

Lượt full đầu có1lỗi test Profile: scrollUntilVisible mặc định chọn nhầm khi đã có
thêm scroll ngang biểu đồ. Đổi sang ensureVisible đúng nút sửa/xóa, giữ mọi assert
CRUD; chạy lại337test pass. SDK bổ sung ban đầu sai tham số fixture MealItemSnapshot/
MealDraft, compile fail; sửa nutrition/source rồi13SDK pass. Không skip/hạ assert
hoặc đổi Rules để che lỗi. Có info lint ban đầu, đã sửa và analyze cuối sạch.
Đã xem ảnh font thật sáng100%/tối200% ở build/c5-layout, sửa padding tránh cắt nhãn
trục y và thêm gợi ý vuốt ngang khi chữ lớn. Đây là widget render, chưa Android E2E.

### Trạng thái local

C5 đạt trong phạm vi code/unit/widget/Rules/SDK Emulator/build. TEMP/TMP ở
D:\HealthMateMaintenanceQA\tmp do C ít dung lượng; không xóa cache/dữ liệu người dùng.
flutter devices chỉ Windows/Chrome/Edge, không Android. Chưa cài APK/đổi phiên/
clear/uninstall app. APK debugx64 chưa phải ARM/release. KGP warning Firebase plugins
đã có còn, chưa nâng dependency. Chưa nghiệm thu bàn phím/thao tác vật lý Android.

### Trạng thái production và bằng chứng

GET read-only lúc **16:33:55 UTC+07,17/10/2026**, project healthmate-app-20261013.
Release updateTime `2026-10-13T06:25:21.345792Z`, normalized SHA256
`0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Có body_metrics/meal_logs/water_logs/activity_logs; còn thiếu match nutrition_targets/
favorite_foods/custom_foods/recipes/goals/daily_quests/chat_sessions. Production
chưa đạt; phần mục tiêu tuần mới sẽ báo lỗi tải nếu backend vẫn dùng Rules này.
Pass emulator không chứng minh production đã được cấp quyền. Chưa deploy.

### Lỗi/blocker còn lại và việc người dùng cần xem

Cần review Rules C1–C4 và yêu cầu deploy riêng, sau đó nghiệm thu tài khoảnQA trên
Android: so tổng tuần với Nhật ký, đổi mục tiêu hôm nay rồi xem ngày cũ, cân ít
điểm/sparse, nút+ lưu/retry, offline/đổiUID. Xem thanh4tab, nhãn ngày, vuốt biểu đồ,
chữ100/150/200%, sáng/tối, bàn phím và safe area trên điện thoại thật. C6 chưa chạy.
Không dùng tài khoản thật thử cleanup. Báo cáo tuần cần mạng và refresh thủ công
sau sửa nhật ký; bản nháp chưa được lưu qua đóng app. Không tự bật billing hoặc AI.

Giai đoạn tiếp theo chỉ đề xuất **C6 — Nghiệm thu bản core trên Android và chuẩn
bị bàn giao**. Dừng C5; không tự commit/push/deploy hoặc thực hiện C6.

## C6 — Nghiệm thu Android core và bàn giao (17/10/2026)

### Giai đoạn và working tree đã kiểm tra

Chỉ C6 theo file Sửa. Branch main, HEAD86238197a9f8e24a2222da2da9e74164c35844ea
giữ nguyên. C1–C5 còn trong working tree, được bảo toàn; không stage/commit/push,
deploy, migration, bật billing hoặc bật/gọi AI. Không thêm/nâng dependency.
Baseline C6 là337/337 Flutter tests pass, không lấy kết quả C5 làm baseline mới.

### Hành vi đã nghiệm thu và sửa lỗi core

- Onboarding → mục tiêu → bữa150g/195kcal → sửa200g/260kcal → sao chép hôm qua
  với ID mới và snapshot giữ nguyên. Nhật ký ngày cũ dùng mục tiêu1800; hôm nay
  đặt2000 rồi2100 không đổi mục tiêu cũ.
- Ghi350ml nước,25phút vận động và69,5kg; tuần có520kcal từ2ngày ghi trước khi
  thêm bữa công thức, khớp repository thật. Thư viện món/công thức CRUD qua UI;
  0,5phần tương ứng20g/50kcal, sau sửa/xóa nguồn bữa đã ghi vẫn50kcal.
- Offline khi lưu mục tiêu: form giữ2100, reconnect/retry xác nhận đúng document;
  lịch sử vẫn chỉ2phiên bản theo ngày. Sáng/tối/chữ200%, native IME và4tab được
  chạy trên Android. Không biến trạng thái chưa xác nhận thành thành công giả.
- Đăng xuất A rồi đăng ký/onboard B: tuần B trống, không lẫn món của A; truy vấn
  target A từ B bị Firestore từ chối. AI service/controller không khởi tạo.
- ProfileController/AccountSecurityController gắn completion với UID/generation.
  Reauth/updatePassword/deleteCurrentUser kiểm tra expectedUid trong Firebase
  repository trước SDK mutation; cleanup vẫn data trước Auth sau và dừng bước
  tiếp khi phiên đổi. Kết quả cũ không thay trạng thái phiên mới.
- Form sửa hồ sơ/cân nặng tại Cá nhân chờ ack, giữ draft khi lỗi, bỏ draft khi
  đổi UID. BodyMetric mới giữ giờ hiện tại (không về00:00), sửa cân giữ timestamp
  gốc. Native E2E phát hiện cân sau onboarding cùng ngày trước đó không được
  nhận là lần cân mới nhất. Không viết lại dữ liệu cũ.
- Hủy async* Firestore listener khi logout có thể trả Future lỗi sau khi consumer
  đã rời đi. subscriptionStream xử lý riêng lỗi hủy tại các provider repository.
  Active errors vẫn truyền tới UI; có2test active error/cancellation. Không dùng
  global error handler hoặc biến lỗi đọc/ghi thành empty/success để giấu lỗi.

### Thay đổi chính và dữ liệu/Rules

Nhóm file C6: auth repository/Firebase implementation/providers; profile providers,
profile_screen, profile_form_dialog, body_metric_form_dialog; core/utils/
subscription_stream và provider stream nutrition/water/activity/goals/library/
favorites. test/core_acceptance_regression_test.dart có12test mới;
test/firebase_repository_integration.dart thêm1test expectedUid bằng SDK thật.
integration_test/core_acceptance_test.dart, test_driver/core_acceptance_driver.dart
và tool/test_android_core.ps1 tạo runner có guard AVD QA/backend demo.
Debug Android manifest + debug/res/xml mở HTTP chỉ loopback/emulator; không đổi
main/release manifest. README và4tài liệu core/database/progress/test được cập nhật.
Không thêm schema/index hoặc sửa Rules so với C5; không migration dữ liệu cũ.

### Test/build/E2E đã chạy

Format178file/0đổi; analyze No issues found10,8s; Flutter349/349pass37s;
catalog7/7pass; Rules47/47pass và Firebase SDK14/14pass22s. Có test cleanup đầy đủ
collection mới/subcollection, giữ dữ liệu B và data-before-Auth trên emulator.
Native E2E10/10checkpoints,137s, Firebase repositories thật (không fake health repo),
AVD HealthMateMaintenanceQA/emulator-5560/API30/x86_64/UTC+07. Bằng chứng4PNG và
log build/c6-android.log, PNG ở build/c6-android; chi tiết trong docs/test-report.md.
AVD do lượt này mở đã tắt sau kiểm tra; không clear/wipe app đang có phiên thật.

C ít dung lượng (~157MB): TEMP/TMP và native build ở D:\HealthMateMaintenanceQA.
Copy QA c6-workspace khớp SHA256 cả213file nguồn/test/asset/cấu hình đã đối chiếu;
metadata build/c6-snapshot-parity.json. Pub get --offline chỉ trong copy để tái tạo
.dart_tool với lock hiện có. Kotlin incremental khác ổ C/D tạm tắt trong copy và
khôi phục nguyên byte gradle.properties sau build/test, không đổi repo gốc.
APK debug ARM64 từ lib/main.dart build24,8s,150691276bytes:
D:\HealthMateMaintenanceQA\HealthMate-core-debug-arm64.apk. Không phải APK E2E,
không cài lên máy thật, chưa release signing. SHA256:
0a3a8ad877016891f532aeb68b6be95f7603985bb39267d56a99bf8c401ecd6e.

### Local và production

**C6 local đạt** trong phạm vi unit/widget/Rules/SDK/Android emulator/debug build.
Production **chưa nghiệm thu**. GET Rules chỉ đọc17:04:32UTC+07 ngày17/10/2026:
releaseUpdatedAt2026-10-13T06:25:21.345792Z; SHA256normalized
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade.
Thiếu match nutrition_targets/favorite_foods/custom_foods/recipes/goals/daily_quests/
chat_sessions. Water/activity composite indexes READY. Không deploy hoặc thử CRUD
dữ liệu sức khỏe production trong C6. Scan155file theo pattern private-key,
service-account/OAuth/GitHub token không phát hiện; không phải chứng minh tuyệt đối
không có mọi dạng secret.

### Blocker và bước tiếp theo chỉ đề xuất

Review Rules và yêu cầu deploy riêng, sau đó QA tài khoản thử trên điện thoại thật:
network/App Check, logout/relogin, lưu/offline/retry, mục tiêu ngày cũ, snapshot sau
xóa nguồn, keyboard/back/safe-area, sáng/tối/chữ100/150/200%, vuốt biểu đồ/danh sách
dài. Không dùng tài khoản sức khỏe thật thử cleanup. Chưa kiểm chứng Play Integrity,
release ký phát hành, process death hoặc draft qua đóng app (hiện giữ RAM). Báo cáo
tuần cần mạng/refresh sau sửa. KGP warning Firebase plugins còn; không tự nâng package.
Kiểm tra bổ sung release merged manifest offline bị chặn do chưa cache Flutter
release artifacts; không tuyên bố release build/merged manifest pass. Dừng C6.
