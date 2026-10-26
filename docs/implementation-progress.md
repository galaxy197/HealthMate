# Tiến độ HealthMate

## 26/10/2026 — Xuất bản mã nguồn và đề xuất giao diện

Phạm vi theo yêu cầu mới: commit/push mã nguồn Flutter, Worker và admin thử nghiệm
đang có; không triển khai backend hoặc cài điện thoại. Bổ sung ignore dependency,
credential/artifact và mẫu kiểm tra debug token dạng đối số. Lưu bản chụp Rules MVP
đã đọc lại trước đó tại `deploy/`; không thay đổi Rules hay dữ liệu trên server.

Tạo [đề xuất giao diện](ui-navigation-proposal.md): hồ sơ góc trái trên và năm mục
Hôm nay/Dinh dưỡng/Tập luyện/Tiến độ/Trợ lý. Chưa sửa UI hoặc làm buổi tập có hướng dẫn.
Kiểm tra trước commit: audit 441 tệp văn bản không phát hiện mẫu secret; diff
whitespace qua; bản Rules đúng hash đã ghi trong `deploy/README.md`.
Không chạy lại bộ 608 test/analyze/build vì không thay đổi code Flutter/native.
Các kết quả kiểm thử bên dưới là của đợt triển khai tính năng trước.

## Mới nhất26/10/2026 — Mục2–3–4: bước/calo, tiến độ và giấc ngủ

User yêu cầu cả3 mục. Đã nối ước tính bước chân và điều chỉnh xác nhận theo ngày
với ngân sách ở Tổng quan/Nhật ký/chat; màn hình tiến độ cân nặng7/30/90ngày;
biểu đồ ngủ7/30ngày, trung bình/độ đều, mục tiêu và nhắc giờ ngủ local opt-in.
Mặc định không cộng bước, không quy đổi giờ ngủ thành calo. Giữ dữ liệu gốc.

Files chính: model/repository/provider/UI mới dưới `features/wellness`; tích hợp
budget ở dashboard/journal/nutrition_targets/chat, liên kết Progress, sửa vòng đời
provider latest weight/activity; native BedtimeReminders/WellnessBridge/bootstrap,
Manifest và account cleanup; Rules/tests/runner candidate. Không thêm dependency.
Full608/608, Rules73/73,SDK23/23,candidate64/64,native51giâyqua,build24giâyqua.
Analyze cuối0issues,49,2giây;format34file0thayđổi;diffcheckqua;sourceaudit438file0.
Rules mới đã deploy và đọc lại khớp6a1762dd…; chỉ thêm2collectionriêng, không admin.
Chi tiết, file/log/giới hạn: [wellness-insights.md](wellness-insights.md).

APK mới ởbuild/releases/healthmate-wellness-insights-debug.apk; chưa cài máy thật
theo lựa chọn kết nối sau của user. Chưa đo độ chính xác bước/calo hoặc kiểm OEM.
Không push/commit/resetdirty, không billing/model/admin. Tiếp theo chỉ nghiệm thu
điện thoại khi user kết nối; không lặp lại shutdown hoặc tự làm giai đoạn khác.

## 26/10/2026 — Mục1: rollout Firebase, chờ nghiệm thu điện thoại

User yêu cầu “làm mục1”, sau đó chọn “Tôi sẽ kết nối sau”. Đã kiểm baseline và
backup Rules production, chạy lại61/61 ca của candidate không admin, deploy chỉ
`firestore:rules` đúng project và đọc lại server khớp hash. Ruleset mới
`8add3549-ea41-4a5d-9f5c-22d1b62808cc`, lúc15:53:38 UTC+7. Không bật admin,
không đổi dữ liệu/billing/model/index, không commit/push. Không sửa Flutter/native,
không cần build/test lại artifact không đổi; hash/manifest APK kiểm tra lại đúng.

Files tài liệu cập nhật: `wellness-rollout.md`, `wellness-expansion.md`, database,
test-report, handoff, README. Log/backup/hash và checklist máy thật trong
[báo cáo rollout](wellness-rollout.md). Compiler qua, có1warning unused knownNumber.
Chưa có ADB device nên chưa cài/thử sensor hoặc lưu/đọc production từ điện thoại;
không tuyên bố hoàn tất toàn bộ mục1. Chờ user kết nối, không triển khai mục2.

## Lịch sử trước rollout26/10/2026 — Đợt mở rộng theo yêu cầu: 6 tính năng

Đã hoàn thiện source/UI cho nhắc bữa local, 162 món Việt/tham chiếu và khẩu phần,
8 dưỡng chất, thực đơn7 ngày, step counter Android opt-in và ngủ/dậy thủ công có
sửa/lịch sử. Đây là một đợt mở rộng được user yêu cầu trực tiếp; không tự chuyển
giai đoạn hoặc tiếp tục web admin. Giữ mọi thay đổi chưa commit, không push/deploy.

Files chính: `lib/features/wellness/`, native `Wellness*.kt`, `MealReminders.kt`,
`StepTrackingService.kt`, Manifest/MainActivity, asset/dữ liệu recipe, model/parser/
cache dinh dưỡng, model món riêng/công thức/mẫu bữa/bản nháp; auth cleanup, router,
Profile entry, `firestore.rules`, tests và runner Android. Không thêm package.

Kết quả cuối: analyze0; Flutter597/597; Rules70/70; SDK22/22; catalog10/10;
candidate không admin61/61; Android native toàn luồng exit0. Debug APK đã build,
lưu `build/releases/healthmate-wellness-debug.apk`. Quét424file source không có
khớp mẫu secret. Chi tiết/log/hash: [wellness-expansion.md](wellness-expansion.md).

**Chưa live:** Rules production chưa có collection/schema mới, cần duyệt candidate
MVP trước triển khai; không deploy toàn bộ Rules local có admin. Chưa cài APK lên
điện thoại; cần thử sensor/quyềnAndroid13+/pinOEM trên máy thật. AVD không có cảm
biến và app báo đúng. Kế hoạch gợi ý chưa cá nhân hóa; ngủ không đo chất lượng.
Giai đoạn kế tiếp đề xuất: duyệt Rules và nghiệm thu thiết bị, chưa thực hiện.
User yêu cầu tắt laptop sau hoàn tất; lưu báo cáo/APK trước khi gửi shutdown thường.

## 25–26/10/2026 — Giai đoạn 10: kiểm thử tích hợp và bảo mật

Người dùng yêu cầu Giai đoạn 10. Đã sửa USDA detail parser, validation dữ liệu
thiếu/zero, chặn món riêng trong cache danh mục và làm mới cache USDA cũ ở v2;
bỏ exception tìm kiếm thô khỏi log. Chỉ thay đổi cache công khai, không sửa hoặc
xóa dữ liệu Firestore thật. Admin tiếp tục tạm gác; email gate của role admin
chỉ được củng cố trong source và thử với Emulator.

Files chính: `usda_api_service.dart`, `food_local_database.dart`,
`unified_food_search_service.dart`, `nutrition_models.dart`, hai widget Dashboard
đổi API deprecated; regression test USDA, fixture xác minh email, bài thử
Android và hai runner native; `firestore.rules`/Rules tests; các script audit,
read-only config và prepare/test candidate trong `tool/`.

Analyze toàn dự án 0 issues; Flutter 584/584; Rules 52 MVP + 9 admin; SDK 19/19;
OOB email verify/reset 1/1; Worker 21/21/syntax/audit qua; Rules dependency audit0.
MVP candidate 52/52. APK debug build15,1s,236.547.388byte, URL chat thật, chưa
cài điện thoại theo lựa chọn của người dùng. Android core qua10checkpoint và
cache SQLite (4phút13giây); H7 hai pha qua17giây/44giây: force-stop/recovery,
encrypted draft, offline/retry, CSV/readback, UID isolation và deletion. Các runner
đều exit0. [Báo cáo](stage10-security-review.md) ghi cả các lượt lỗi trước đó.

Đã đọc cấu hình production, không deploy: Rules thật còn thiếu verified email
gate và snapshot dinh dưỡng mới; AI App Check ENFORCED, Firestore chưa xác nhận
enforcement. Candidate riêng loại admin, giữ chat50; hash/baseline/rollback và
giới hạn release/điện thoại ở báo cáo. Cần duyệt trước khi chặn truy cập tài
khoản chưa xác minh; không deploy cả file Rules local. Chưa commit/push, bảo toàn
dirty tree. Giai đoạn11 chỉ đề xuất sau nghiệm thu/rollout MVP, chưa thực hiện.

## 25/10/2026 — Giai đoạn 9: 50 lượt/cuộc và tiếp tục hội thoại khi chuyển tab

Hoàn thành code và APK theo yêu cầu: 50 lượt (100 messages), tự mở cuộc đã chọn
hoặc cuộc mới nhất khi vào chat, giữ lựa chọn “Cuộc trò chuyện mới”, reset theo
UID và chặn lựa chọn cũ từ save hoàn tất muộn. Tra cứu nhanh dùng repository,
không gọi AI; loại bảng tham chiếu lặp khỏi history gửi AI. Không tăng rate,
đổi model/provider, bật billing hoặc thêm database. Người dùng sẽ cài/thử sau.

Files chính: chat_resume_provider.dart, chat_providers.dart, chat_models.dart,
firebase_chat_repository.dart, chat_screen.dart, assistant_request.dart;
chatbot_resume_test.dart/chatbot_api_test.dart/chatbot_test.dart;
firestore.rules, rules-tests/firestore.rules.test.cjs; hai script prepare/test
candidate Rules trong tool/. Bảo toàn toàn bộ thay đổi chưa commit từ trước.

Kiểm tra: format qua; focused chat 62/62; full Flutter 578/578 (67s);
analyze cuối 18info có sẵn/0warning/error; Rules local 52/52 và candidate chat
4/4; APK debug build42,2s,236.539.039bytes; diff-check/syntax qua. Lượt Rules
đầu có một assertion onboarding thất bại, chạy riêng baseline và full lại qua;
ghi nhận dấu hiệu phụ thuộc thời điểm, không sửa test che lỗi.

Đã deploy Rules production chỉ đổi trần chat40→100 trên snapshot production,
không deploy các thay đổi Rules khác đang chờ. Đọc lại source sau deploy khớp
hash candidate; không migrate/xóa lịch sử. APK build/releases/healthmate-chat-50-debug.apk.
Chưa cài/nghiệm thu APK mới trên điện thoại vì người dùng chọn thử sau.
Chi tiết và rollback backup: [báo cáo](chatbot-capacity-update.md).
Giai đoạn kế tiếp đề xuất:10 — security và kiểm thử tích hợp, chưa thực hiện.

## 25/10/2026 — Giai đoạn9, API Cloudflare thật và APK kết nối

Đã OAuth Wrangler, triển khai Worker tại URL trong config/chat-api.json; chọn
Qwen planner + Llama3.3 70B answer sau benchmark model thật. Không thêm database,
billing, scanner hoặc admin. Đã kiểm tra 21Worker tests, syntax, auditproduction0,
request thật thiếu/saiJWT401, build APK debug45,9s. Benchmark20fixture cuối đều
hoàn tất và đúng nguồn/khoảng ngày, median1,892s qua REST; không phải native E2E.
Files chính: chat-api/src/protocol.mjs,index.mjs,test/api.test.mjs,wrangler.jsonc,
tool/*.mjs; config/chat-api.json; tool/run_android.ps1 và tài liệu liên quan.
Người dùng đã nối USB, cài đè APK giữ dữ liệu thành công và app đã mở. Đã yêu cầu
thử câu hỏi đầu tiên: app báo "Phản hồi AI vượt giới hạn". Đã sửa SSE wire budget
32KB bị cộng envelope; capture45.817byte chỉ844chữ được Dart replay qua. Giữ
text3.800, wire2MiB/event16k.55focusedtests qua,APK sửa17,1s qua,analyze3file sạch.
Cài đè lần hai Success,lastUpdateTime25/10/2026 02:59:04; người dùng xác nhận câu
kiến thức chung trả lời đầy đủ; mục tiêu kcal và follow-up đạm khớp số liệu hoặc
báo thiếu dữ liệu đúng. Kết nối/luồng cốt lõi stage9 hiện tại hoàn tất trên máy.
Full analyze cuối8,9s:18info có sẵn,0warning/error; không còn lint mới.
Native mất mạng/quota/đổi UID/lịch sử mở lại chưa thử thủ công.
Chi tiết, lỗi model quan sát được và rủi ro: [báo cáo live](chatbot-live-qa.md).
Giai đoạn kế tiếp đề xuất:10 — security và kiểm thử tích hợp; không tự thực hiện.

## 2026-10-13 — Giai đoạn 1: Nền tảng Flutter và UI system

Trạng thái: **hoàn thành Giai đoạn 1**. Source, analyze, widget tests, build web,
APK debug và khởi chạy trên Android emulator đã được kiểm chứng.

### Hiện trạng đầu vào

Repository chỉ có `.git`, nhánh `main` chưa có commit hoặc remote.
Không có ứng dụng cũ để bảo tồn. Flutter SDK được tìm thấy tại
`D:\Flutter\flutter`: Flutter 3.44.1, Dart 3.12.1; chưa có trên PATH.

### Đã thực hiện

- Khởi tạo Flutter cho Android và web (web phục vụ kiểm tra UI).
- Theme Material 3 sáng/tối, typography, spacing, SafeArea và nội dung cuộn.
- 5 tab và trang Auth; navigation bar/rail theo chiều rộng, route lỗi có đường lui.
- Riverpod cho router và lựa chọn theme trong phiên; dispose router theo vòng đời.
- Trang khung ghi rõ đang chờ triển khai; không có dữ liệu sức khỏe giả,
  form đăng nhập giả, truy vấn Firestore hoặc lời gọi AI.
- Việt hóa Material localizations, tiêu đề app Android/web.
- Đặt bản nguyên văn AGENTS.md người dùng cung cấp tại gốc repository.
- README hướng dẫn môi trường, chạy Android/web, kiểm tra và giới hạn hiện tại.

### File chính

`AGENTS.md`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
`lib/main.dart`, `lib/app.dart`, `lib/core/router/*`, `lib/core/theme/*`,
`lib/core/widgets/*`, `lib/features/*/presentation/*`,
`lib/shared/providers/theme_mode_provider.dart`, `test/widget_test.dart`,
`android/*`, `web/*`, `README.md`, tài liệu này,
`docs/screenshots/dashboard-android.png` (ảnh chụp runtime thực tế).

### Dependencies

Thêm `flutter_riverpod` 3.4.3 (state/DI), `go_router` 18.0.2 (routing),
`flutter_localizations` từ SDK (tiếng Việt) và `cupertino_icons` 2.0.0 (font icon
được thư viện UI mà router tham chiếu sử dụng). Ban đầu bỏ icon package của
template vì màn hình chỉ dùng Material; build web phát hiện thiếu font
CupertinoIcons trong thư viện tham chiếu, nên đã thêm lại phiên bản do tooling
resolve tương thích để xử lý cảnh báo. Pub solver resolve thành công với SDK
hiện có; lockfile giữ phiên bản thực tế. Không thêm Firebase, AI, biểu đồ hoặc
image picker.

### Kiểm tra thực tế

- `flutter --version`: Flutter 3.44.1, Dart 3.12.1.
- `flutter doctor -v`: Android SDK 36.1.0 có sẵn; cảnh báo PATH, một số Android
  licenses chưa chấp nhận; Windows C++ toolchain thiếu (không là target giai đoạn này).
- `flutter create --project-name healthmate --platforms android,web --org com.example ... .`:
  thành công; resolve dependencies thành công.
- `flutter pub remove cupertino_icons` và `flutter pub add flutter_riverpod go_router
  "flutter_localizations:{sdk: flutter}"`: thành công.
- `dart format .`: đã định dạng 18 file Dart.
- `flutter analyze` và lần cuối `flutter analyze --no-pub`: không có vấn đề.
- `flutter test`: lần đầu 6/8 pass; phát hiện brand row tràn ngang khi chữ 200%
  và test theme bấm trước khi layout sau cuộn được cập nhật. Đã sửa UI bằng
  `Flexible` và test chờ frame sau cuộn. Chạy lại: **8/8 pass**.
- `dart format --output=none --set-exit-if-changed .` chạy trong lúc Gradle
  đang build gặp `PathNotFoundException` khi đọc thư mục build tạm. Đã đổi sang
  kiểm tra đúng source: `dart format --output=none --set-exit-if-changed lib test`:
  thành công, 18 file, 0 thay đổi. README dùng lệnh này để tránh quét build artifacts.
- `flutter build web`: thành công lần đầu (40.4s); sau khi thêm font dependency,
  build lại thành công (59.3s), không còn cảnh báo thiếu font.
- `flutter build apk --debug`: thành công lần đầu (128.9s), tạo
  `build/app/outputs/flutter-apk/app-debug.apk`; build lại với font dependency:
  thành công (9.1s).
- Kiểm tra cuối sau thay đổi dependencies: `flutter analyze --no-pub` không có
  vấn đề; `flutter test --no-pub` **8/8 pass**; format source 18 file, 0 thay đổi.
- Cài APK vào Pixel_4 read-only thất bại với `INSTALL_FAILED_INSUFFICIENT_STORAGE`.
  Không xóa ứng dụng/dữ liệu máy ảo người dùng. Đã dừng phiên read-only và tạo
  AVD tạm riêng trên D: để tiếp tục kiểm chứng chạy ứng dụng.
- Chạy thực tế trên AVD tạm Android 16 (API 36.1), port 5582:
  sau khi hệ điều hành boot xong, `adb install -r` trả `Success`;
  `adb shell am start -W -n com.example.healthmate/.MainActivity` trả
  `Status: ok`, `LaunchState: COLD`, `Complete`. Tiến trình ứng dụng có PID,
  ảnh chụp màn hình hiển thị UI HealthMate đúng; đã xem ảnh để kiểm tra trực quan.
  Bộ lọc log `flutter:E AndroidRuntime:E` không có lỗi tại thời điểm kiểm tra.
- Trong quá trình boot AVD mới, lần cài thử sớm báo chưa có package service;
  script chờ boot có một lần đọc property null. Sau khi boot hoàn tất,
  cài đặt/khởi chạy đã thành công; không sửa source để che lỗi môi trường.
- Ảnh runtime: [`screenshots/dashboard-android.png`](screenshots/dashboard-android.png).
  Máy ảo đã dừng; `avdmanager delete avd -n healthmate_stage1_check` trả
  `AVD 'healthmate_stage1_check' deleted.` và danh sách ADB không còn thiết bị.
  Dữ liệu AVD tạm đã xóa; chỉ còn log emulator (~9 KB) tại
  `D:\CodexTemp\healthmate-stage1-20261013-a54e1`, ngoài repository.

### Việc người dùng cần làm và giới hạn

- Thêm `D:\Flutter\flutter\bin` vào PATH hoặc dùng đường dẫn đầy đủ.
- Tự đọc/chấp nhận Android licenses còn thiếu khi cần, không tự chấp nhận thay người dùng.
- Mở emulator hoặc kết nối thiết bị Android khi chạy trên Android.
- Chốt application ID trước Giai đoạn 2; hiện `com.example.healthmate`.
- Theme preference chỉ trong bộ nhớ; restart về chế độ theo thiết bị.
- Icon còn là template; chưa có release signing. Các nghiệp vụ vẫn chờ triển khai.
- Chưa kiểm tra Firestore rules, Auth hoặc AI vì chưa triển khai các giai đoạn đó.

### Đề xuất sau khi kết thúc Giai đoạn 1

Giai đoạn 2 — Firebase setup và Authentication. Chưa thực hiện tại thời điểm
kết thúc Giai đoạn 1; kết quả triển khai được ghi ở mục tiếp theo.

## 2026-10-13 — Giai đoạn 2: Firebase setup và Authentication

Trạng thái: **hoàn thành Giai đoạn 2**. Ứng dụng đã kết nối Firebase thật cho
Android/web; Email/Password Auth đã được kiểm chứng ở backend thật, trong test UI
và qua hai bản build. Không thêm nghiệp vụ sức khỏe hoặc Firestore.

### Hiện trạng đầu vào

Repository chưa có Firebase project, `firebase_options.dart` hoặc dependency
Firebase. Firebase CLI và FlutterFire CLI có sẵn; Firebase CLI đã đăng nhập.
Sau khi kiểm tra danh sách project hiện có và tránh nối nhầm dữ liệu, người dùng
chọn tạo project mới tên HealthMate.

### Firebase thực tế

- Tạo Firebase project `healthmate-app-20261013`, project number
  `471712188542`, display name `HealthMate`.
- Chạy FlutterFire CLI cho Android và web; đăng ký Android app
  `com.example.healthmate` và web app, sinh `lib/firebase_options.dart`,
  `android/app/google-services.json` và `firebase.json`.
- Thêm `.firebaserc` với project mặc định `healthmate-app-20261013`.
- Người dùng đăng nhập Firebase Console và bật provider Email/Password.
- Kiểm tra lại bằng Firebase API: Email provider `enabled: true`, password bắt
  buộc, các authorized domain gồm `localhost`, domain Firebase Hosting và
  `firebaseapp.com` của project.
- Client configuration do FlutterFire sinh được giữ trong source theo cơ chế
  Firebase client SDK. Không thêm service account, Admin credential, private key
  hoặc secret server.

### Đã thực hiện

- Thêm `firebase_core` 4.15.0 và `firebase_auth` 6.7.0 bằng Flutter tooling;
  phiên bản thực tế được khóa trong `pubspec.lock`.
- Khởi tạo Firebase bất đồng bộ trước `runApp`; nếu khởi tạo thất bại, hiển thị
  màn hình lỗi thân thiện có nút thử lại thay vì vào app ở trạng thái giả.
- Tách `AuthRepository` khỏi Firebase SDK, ánh xạ Firebase user sang model nội bộ
  tối thiểu và ánh xạ mã lỗi sang thông báo tiếng Việt không lộ chi tiết SDK.
- Thêm đăng ký, đăng nhập, đăng xuất và theo dõi `authStateChanges`; form trim
  email nhưng không biến đổi mật khẩu.
- Validation email, mật khẩu đăng ký tối thiểu 6 ký tự và xác nhận mật khẩu;
  loading vô hiệu hóa thao tác lặp, hỗ trợ Autofill và ẩn/hiện mật khẩu.
- Route riêng tư đi qua màn hình chờ session. Người dùng chưa đăng nhập được đưa
  tới Auth; sau thành công quay lại đúng route nội bộ đã yêu cầu. Destination từ
  query được giới hạn vào các route nội bộ hợp lệ.
- Trang Tài khoản hiển thị email của session hiện tại và đăng xuất thật; lỗi đăng
  xuất giữ nguyên phiên để người dùng có thể thử lại.
- Thêm quyền Internet cho Android và input theme dùng chung. Không thêm profile,
  body metrics, nhật ký, Firestore, AI hoặc dữ liệu sức khỏe mẫu.

### File chính

`lib/main.dart`, `lib/firebase_options.dart`,
`lib/core/config/firebase_bootstrap.dart`, `lib/core/router/auth_redirect.dart`,
`lib/core/router/app_router.dart`, `lib/core/router/app_routes.dart`,
`lib/core/widgets/startup_error_app.dart`, `lib/features/auth/models/*`,
`lib/features/auth/data/*`, `lib/features/auth/providers/*`,
`lib/features/auth/presentation/*`,
`lib/features/profile/presentation/profile_screen.dart`,
`android/app/google-services.json`, Android Gradle config,
`android/app/src/main/AndroidManifest.xml`, `.firebaserc`, `firebase.json`,
`test/auth_test.dart`, `test/support/*`, `test/widget_test.dart`, `README.md` và
tài liệu này.

### Kiểm tra thực tế

- `flutterfire configure --project=healthmate-app-20261013
  --platforms=android,web --android-package-name=com.example.healthmate --yes`:
  thành công; hai Firebase app ở trạng thái ACTIVE.
- Kiểm thử trực tiếp Firebase Identity Toolkit bằng tài khoản ngẫu nhiên tạm:
  đăng ký thành công, mật khẩu sai bị từ chối, đăng nhập đúng thành công và tài
  khoản kiểm thử được xóa thành công ngay sau đó. Script tạm đã xóa khỏi workspace.
- `dart format --output=none --set-exit-if-changed lib test`: 32 file, 0 thay đổi.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **22/22 pass**. Test bao phủ validation và thông báo
  an toàn, route guard, session loading/error, login/register/logout, retry lỗi
  mạng/đăng xuất, chống gửi lặp, external sign-out, startup failure, màn hình nhỏ
  với text scale lớn/keyboard inset, cùng toàn bộ test điều hướng Giai đoạn 1.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Gradle phát cảnh báo các plugin Firebase hiện còn áp dụng Kotlin Gradle Plugin
  và một bản Flutter tương lai sẽ yêu cầu plugin hỗ trợ Built-in Kotlin. Đây là
  cảnh báo upstream; build hiện tại vẫn thành công và không cần ghim package cũ.

### Giới hạn và việc người dùng cần biết

- Cần giữ quyền truy cập Firebase project `healthmate-app-20261013` và kết nối
  mạng để Auth thật hoạt động.
- Android application ID vẫn là `com.example.healthmate`; nên đổi sang namespace
  thương hiệu trước khi phát hành, khi đó phải đăng ký lại Android app Firebase.
- Chưa có email verification, khôi phục mật khẩu, MFA hoặc xóa tài khoản vì nằm
  ngoài phạm vi Auth tối thiểu của Giai đoạn 2.
- Chưa có Firestore hoặc Security Rules; app hiện chỉ lưu trạng thái session theo
  cơ chế của Firebase Auth. Các trang sức khỏe vẫn là placeholder trung thực.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 3 — Hồ sơ và Body Metrics: profile theo UID, lịch sử thể trạng,
Firestore Security Rules và CRUD thật. Chưa triển khai trong lượt này.

## 2026-10-13 — Giai đoạn 3: Hồ sơ và Body Metrics

Trạng thái: **hoàn thành Giai đoạn 3**. Profile và lịch sử cân nặng đã CRUD trên
Cloud Firestore thật; dữ liệu được tách theo UID, Security Rules đã qua test chéo
UID trên emulator và đã deploy lên project production. Không triển khai dinh
dưỡng, nước, hoạt động, AI hoặc phạm vi Giai đoạn 4.

### Firestore thực tế

- Bật Cloud Firestore API và tạo database `(default)` Native mode, Standard
  edition tại `asia-southeast1` (Singapore) cho `healthmate-app-20261013`.
- Database đang dùng free tier, realtime updates bật, PITR và delete protection
  chưa bật.
- Thêm `cloud_firestore` 6.10.0 bằng Flutter tooling; lockfile giữ dependency
  thực tế tương thích với Flutter 3.44.1/Dart 3.12.1.
- Thêm `firestore.rules`, `firestore.indexes.json` và cấu hình emulator trong
  `firebase.json`; rules/indexes đã deploy thành công vào database mặc định.
- Không thêm service account, Admin credential hoặc secret vào repository.

### Mô hình dữ liệu và nghiệp vụ

- `users/{uid}` lưu `displayName`, email khớp Auth token, `heightCm`, server
  timestamps và `schemaVersion: 1`.
- Hồ sơ được bootstrap theo session ngay sau khi đăng nhập, không phụ thuộc người
  dùng có mở tab Cá nhân hay không. Quy trình chạy lại an toàn: chỉ tạo khi chưa
  tồn tại và chỉ đồng bộ email/schema khi cần.
- `users/{uid}/body_metrics/{metricId}` lưu cân nặng, ngày đo, ghi chú và server
  timestamps. Firestore tự sinh ID cho mỗi lần đo nên lịch sử không bị ghi đè.
- UI cho phép sửa hồ sơ, thêm/sửa/xóa lần đo, hiển thị loading/error/retry và
  trạng thái không dữ liệu. Ngày đo không cho chọn tương lai.
- Validation Flutter: tên 2–50 ký tự; chiều cao tùy chọn 80–250 cm; cân nặng
  20–500 kg; ghi chú tối đa 200 ký tự; hỗ trợ dấu phẩy thập phân.
- BMI chỉ tính khi chiều cao/cân nặng hợp lệ và luôn ghi nhãn “BMI tham khảo”,
  kèm thông báo không phải chẩn đoán y khoa.
- Chi tiết schema và quyền truy cập ghi tại `docs/database-design.md`.

### Security Rules

- Chỉ `request.auth.uid == uid` được đọc hoặc ghi profile/body metrics tương ứng.
- Email profile phải khớp email claim trong token; field ngoài schema bị từ chối.
- Rules kiểm tra kiểu dữ liệu, khoảng chiều cao/cân nặng, độ dài chuỗi, timestamp
  phía server và giữ `createdAt` bất biến.
- Client không được xóa profile; body metric chỉ chủ sở hữu mới được xóa.
- Mọi collection/path chưa khai báo bị từ chối mặc định.

### File chính

`pubspec.yaml`, `pubspec.lock`, `firebase.json`, `firestore.rules`,
`firestore.indexes.json`, `docs/database-design.md`, `lib/app.dart`,
`lib/features/profile/models/*`, `lib/features/profile/data/*`,
`lib/features/profile/providers/profile_providers.dart`,
`lib/features/profile/presentation/*`, `test/profile_test.dart`,
`test/support/fake_health_profile_repository.dart`, `test/support/test_app.dart`,
`rules-tests/package.json`, `rules-tests/package-lock.json`,
`rules-tests/firestore.rules.test.cjs`, `.gitignore`, `README.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test`: 43 file,
  0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **27/27 pass**. Ngoài regression Auth/navigation,
  test mới kiểm tra validation/BMI, profile bootstrap ngay sau chuyển trạng thái
  đăng nhập và toàn bộ thêm/sửa/xóa body metric qua repository giả.
- Firestore Emulator 1.21.0 chạy với Java 21 từ Android Studio và demo project
  `demo-healthmate-rules`: **5/5 rules tests pass**. Đã kiểm tra owner CRUD, client
  ẩn danh, đọc/ghi chéo hai UID, field ngoài schema, email/chiều cao/cân nặng sai,
  sửa `createdAt` và xóa profile trái phép.
- `firebase deploy --only firestore:rules,firestore:indexes`: rules compile và
  release thành công; indexes deploy thành công cho `(default)`.
- Kiểm thử production bằng Firebase web client SDK và tài khoản ngẫu nhiên tạm:
  tạo/cập nhật profile thành công; thêm, query có sắp xếp, sửa và xóa body metric
  thành công. Dữ liệu profile và tài khoản thử đã được xóa khỏi production ngay
  sau kiểm tra; script tạm đã xóa khỏi workspace.
- `npm audit --prefix rules-tests`: ban đầu phát hiện advisory của
  `@grpc/grpc-js` 1.13.5 trong test-only dependency. Thêm override lên 1.13.6,
  cài lại và kiểm tra cuối: **0 vulnerabilities**; 5/5 rules tests vẫn pass.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.

### Việc người dùng cần làm và giới hạn

- Không còn bước Firebase Console bắt buộc cho Giai đoạn 3. Khi đổi project hoặc
  môi trường, phải deploy lại `firestore.rules` và `firestore.indexes.json`.
- Java mặc định trên máy là Java 8, không chạy được Firestore Emulator hiện hành;
  README hướng dẫn đặt `JAVA_HOME` tạm sang JBR Java 21 của Android Studio.
- Gradle vẫn phát cảnh báo upstream về Firebase plugin áp dụng Kotlin Gradle
  Plugin và một bản Flutter tương lai sẽ yêu cầu Built-in Kotlin; build hiện tại
  thành công. `cloud_firestore` cũng phát một note Java unchecked ở code plugin.
- Android application ID vẫn là `com.example.healthmate`; cần đổi trước phát hành.
- Firestore PITR và database delete protection chưa bật. Chưa có UI xóa toàn bộ
  tài khoản/profile; profile delete từ client đang bị Security Rules chặn.
- Repository vẫn chưa có commit gốc nên toàn bộ source đang ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 4 — Food Catalog và nhật ký dinh dưỡng thủ công. Chưa triển khai trong
lượt này.

## 2026-10-13 — Giai đoạn 4 và 5: Nutrition + AI Food Scanner

Trạng thái: **hoàn thành Giai đoạn 4 và 5 theo yêu cầu gộp của người dùng**.

### Hành vi đã hoàn thành

- Seed 10 món tham khảo theo cơ sở 100 g, đơn vị gram, macro, nguồn USDA FoodData
  Central và `isEstimated: true`; catalog chỉ đọc với người dùng đã đăng nhập.
- Tìm/chọn món, nhập/sửa gram, loại bữa và ngày/giờ; tổng kcal/protein/carb/fat
  được tính từ catalog. Meal log lưu snapshot, nguồn manual/AI-assisted và hỗ trợ
  xem/sửa/xóa thật dưới `users/{uid}/meal_logs`.
- Chụp/chọn ảnh bằng `image_picker`; kiểm tra định dạng/kích thước tối đa 8 MB.
  Firebase AI Logic dùng Gemini Developer API free tier và model hiện hành
  `gemini-3.8-flash` (có thể override bằng `HEALTHMATE_AI_MODEL`).
- Gemini chỉ trả tên, mô tả, nguyên liệu và từ khóa đối chiếu. Người dùng có thể
  sửa tên, chọn món catalog và nhập khẩu phần; không tự lưu và không dùng AI để
  tạo số dinh dưỡng. Lỗi mạng/quota/JSON có thông báo và đường lui nhập thủ công.
- Ảnh chỉ giữ trong bộ nhớ của dialog, không có Cloud Storage và không lưu đường
  dẫn ảnh vào Firestore.

### Firebase thật

- Đã bật `firebasevertexai.googleapis.com`, `generativelanguage.googleapis.com`
  và `firebaseappcheck.googleapis.com`; Firebase AI Logic cấu hình Gemini
  Developer API.
- App Check Android: debug provider có token đăng ký riêng trên máy phát triển;
  release dùng Play Integrity. Đã đăng ký SHA-256 debug, cấu hình Play Integrity
  TTL 1 giờ và bật `ENFORCED` cho `firebaseml.googleapis.com`.
- Debug token được lưu ngoài repository tại Local AppData; `tool/run_android.ps1`
  nạp token qua `--dart-define`. Không có API key hoặc token trong source.
- Firestore Rules/indexes đã deploy lại. Rules bảo vệ catalog và meal logs theo
  Auth UID, schema/range/timestamp; giới hạn tối đa 5 item mỗi bữa.

### File chính

- `lib/features/nutrition/**`, `lib/features/food_scanner/**`,
  `lib/features/journal/presentation/journal_screen.dart`
- `lib/core/config/firebase_bootstrap.dart`, `pubspec.yaml`, `pubspec.lock`
- `firestore.rules`, `docs/database-design.md`, `README.md`
- `test/nutrition_test.dart`, `test/support/fake_nutrition_repository.dart`,
  `integration_test/firebase_ai_smoke_test.dart`, `tool/run_android.ps1`

### Kiểm tra thực tế trong quá trình triển khai

- `flutter analyze`: không có issue sau khi thêm feature.
- `flutter test --exclude-tags=integration`: **30/30 pass**, gồm toàn bộ regression
  Auth/Profile/navigation và test mới cho công thức, parser, layout và thêm bữa.
- Firestore Emulator với Java 21: 8/8 rules tests pass; rules/indexes deploy thật
  thành công vào `healthmate-app-20261013`.
- Android integration test đã build/cài APK trên API 36, gọi Gemini thật qua App
  Check enforcement và nhận structured JSON hợp lệ: 1/1 pass.
- Production smoke test tạo tài khoản tạm, đọc đủ 10 catalog item và thêm/sửa/xóa
  meal log qua rules thật: pass; tài khoản/dữ liệu thử được xóa sau kiểm tra.
- `flutter build web --no-pub` và `flutter build apk --debug --no-pub`: thành công.
  `npm audit --prefix rules-tests`: 0 vulnerabilities.
- Lượt emulator đầu tiên không cài được APK vì máy ảo hết dung lượng; chuyển sang
  emulator `Pixel_4` sạch và kiểm thử AI thành công. Đây không phải lỗi app.

### Giới hạn và việc phát hành

- Web chỉ là UI preview; scanner chủ động hướng dẫn nhập thủ công vì chưa có
  reCAPTCHA Enterprise site key/domain production. Android là nền tảng chính.
- Android application ID còn là `com.example.healthmate`. Trước phát hành cần đổi
  namespace, đăng ký lại app Firebase và SHA-256 release/Play App Signing.
- Gemini Developer API có free tier nhưng vẫn có quota; UI đã xử lý trường hợp
  chạm quota và không cam kết miễn phí vô hạn.
- Repository chưa có commit gốc nên toàn bộ source vẫn ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 6 — nhật ký nước uống và hoạt động. Chưa triển khai trong lượt này.

## 2026-10-13 — Giai đoạn 6: Nước uống và hoạt động

Trạng thái: **hoàn thành Giai đoạn 6**. Người dùng có thể chọn ngày và CRUD dữ
liệu thật cho nước uống/vận động; tổng trong ngày cập nhật theo dữ liệu hiện tại.

### Đã thực hiện

- Tách model, Firebase repository và Riverpod controller cho `water` và
  `activity`; mọi đường dẫn dữ liệu nằm dưới `users/{uid}`.
- Nhật ký nước lưu ml và thời điểm; nhật ký vận động lưu loại, phút, thời điểm và
  ghi chú tùy chọn. Form kiểm tra giới hạn trước khi ghi.
- Thêm bộ chọn ngày, loading/empty/error/success states, thêm/sửa/xóa và tổng ml,
  lít/phút theo ngày đã chọn.
- Chuẩn hóa `dateKey` theo ngày địa phương, lưu `timezoneOffsetMinutes`, tính lại
  khi sửa thời điểm. UI nói rõ dữ liệu do người dùng nhập, không tự đo bước chân
  hoặc khẳng định calories tiêu hao.
- Mở rộng Security Rules và composite indexes cho hai collection; rules/indexes
  đã deploy vào `healthmate-app-20261013`.

### File chính

`lib/core/utils/local_date_key.dart`, `lib/features/journal/**`,
`lib/features/water/**`, `lib/features/activity/**`, `firestore.rules`,
`firestore.indexes.json`, `rules-tests/firestore.rules.test.cjs`,
`test/daily_logs_test.dart`, `test/support/fake_water_repository.dart`,
`test/support/fake_activity_repository.dart`, `README.md`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test test/daily_logs_test.dart`: **4/4 pass**; kiểm tra date key,
  validation, tổng và luồng thêm/sửa/xóa nước cùng thêm hoạt động trên UI.
- Firestore Emulator với Java 21: **10/10 rules tests pass**, gồm CRUD chủ sở hữu,
  chặn UID khác, giá trị sai và thay đổi `createdAt` cho water/activity.
- `firebase deploy --only firestore:rules,firestore:indexes`: rules compile,
  indexes deploy và rules release thành công vào database `(default)`.
- `flutter test --no-pub --exclude-tags=integration`: **34/34 pass**, gồm toàn bộ
  regression Auth/Profile/Nutrition/navigation và test Giai đoạn 6.
- Production smoke test bằng tài khoản tạm: thêm, query theo `dateKey` có sắp xếp,
  sửa và xóa cả water/activity log qua rules thật thành công. Dữ liệu và tài
  khoản tạm đã xóa; script tạm không còn trong workspace.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `npm audit --prefix rules-tests`: **0 vulnerabilities**.

### Việc người dùng cần làm và giới hạn

- Không có bước Firebase Console bắt buộc cho Giai đoạn 6; cần kết nối mạng để
  đồng bộ Firestore. Index mới có thể cần ít phút để hoàn tất xây dựng.
- Nhật ký vận động chỉ dùng dữ liệu người dùng nhập; chưa tích hợp cảm biến,
  Health Connect, đo bước chân hoặc ước tính calories.
- Repository chưa có commit gốc nên toàn bộ source vẫn ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 7 — Goals và Daily Health Quest. Chưa triển khai trong lượt này.

## 2026-10-13 — Đợt 6.1: Củng cố tính toàn vẹn dữ liệu

Trạng thái: **hoàn thành Đợt 6.1**. Chỉ củng cố các chức năng của Giai đoạn 1–6;
không triển khai Đợt 6.2, Goals, Daily Health Quest, Dashboard nâng cao hoặc
Chatbot. Không deploy Rules/indexes, không dùng dữ liệu production và không
commit/push trong đợt này.

### Hiện trạng Git trước khi sửa

- Working tree sạch, nhánh `main`, remote `origin` trỏ tới
  `https://github.com/galaxy197/HealthMate.git`.
- Sau `git fetch origin`, local `HEAD` và `origin/main` cùng commit
  `900bee809d4dd508e5239d4ba6c1a8aee7bcf0e2`; ahead/behind là `0/0`.
- Không có thay đổi cục bộ hoặc file untracked cần bảo toàn. Các ghi chú cũ ở
  phần Giai đoạn 3–6 rằng repository chưa có commit chỉ là lịch sử tại thời điểm
  viết và không còn phản ánh hiện trạng Git.

### Đã thực hiện

- `validMealItems` kiểm tra có điều kiện mọi item đang tồn tại ở vị trí 0–4,
  giữ giới hạn 1–5 món, whitelist field và toàn bộ giới hạn giá trị hiện có.
- Rút gọn các phép kiểm tra kiểu số dư thừa: phép so sánh range trong Rules tự
  từ chối kiểu không tương thích và đã có test riêng cho kiểu chuỗi. Việc này giữ
  bảo vệ schema nhưng giúp bữa 5 món nằm dưới giới hạn 1.000 biểu thức Rules.
- Thêm test bữa 1/5 món hợp lệ; list rỗng/quá 5; sai item riêng ở từng vị trí;
  sai kiểu/field thừa; CRUD, chéo UID và `createdAt` bất biến.
- Rules của `dateKey` nay loại tháng ngoài 01–12 và ngày ngoài 01–31. Client có
  kiểm tra ngày lịch thực sự tồn tại, hàm suy ra ngày bằng timestamp + offset,
  kiểm tra quan hệ ba field và test ranh giới nửa đêm.
- `WaterLogDraft` và `ActivityLogDraft` suy ra `dateKey` bằng chính timestamp và
  offset sẽ ghi; repository tiếp tục tính lại các field này khi thêm/sửa.
- Cập nhật `docs/database-design.md` để tách rõ bảo đảm ở client và Rules, cùng
  các giới hạn còn lại.

### File chính đã sửa

`firestore.rules`, `rules-tests/firestore.rules.test.cjs`,
`lib/core/utils/local_date_key.dart`,
`lib/features/water/models/water_log.dart`,
`lib/features/activity/models/activity_log.dart`, `test/daily_logs_test.dart`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub --exclude-tags=integration`: **38/38 pass**.
- Firestore Emulator với Java 21 và demo project `demo-healthmate-rules`:
  **18/18 rules tests pass**. Có test riêng cho từng vị trí item 0–4 và toàn bộ
  regression profile/body metrics/water/activity.
- Lần thử rules đầu tiên với kiểm tra lặp nguyên trạng vượt giới hạn 1.000 biểu
  thức cho bữa 5 món. Rules được rút gọn mà không bỏ schema/range; lần chạy cuối
  chấp nhận 5 món hợp lệ và từ chối kiểu số sai.

### Rủi ro còn lại và việc người dùng cần làm

- Rules chưa cộng lại tổng dinh dưỡng từ 1–5 item. Làm vậy vừa tăng biểu thức khi
  rules đã gần giới hạn, vừa cần dung sai số thực nên không cho phép đối chiếu
  tuyệt đối. Client và test vẫn tính tổng từ snapshot, nhưng client tùy biến có
  thể gửi tổng khác chi tiết nếu tổng vẫn trong khoảng được phép.
- Rules chưa thể xác minh đầy đủ `dateKey` dạng chuỗi với timestamp + offset khi
  giữ schema hiện tại. Client chặn ngày không tồn tại và luôn tạo lại bộ field,
  nhưng client tùy biến vẫn có thể gửi bộ ba không nhất quán. Phương án chặt hơn
  cần schema ngày dạng số hoặc backend tin cậy và migration tương thích.
- Không có thao tác Firebase Console bắt buộc. Vì chưa deploy, production vẫn
  dùng phiên bản Rules trước Đợt 6.1; người dùng cần review diff và chủ động cho
  phép deploy trong một lượt riêng nếu muốn áp dụng bảo vệ mới.

### Bước kế tiếp đề xuất

Review và deploy riêng thay đổi Rules của Đợt 6.1 khi người dùng chấp thuận;
Đợt 6.2 chỉ thực hiện khi được yêu cầu rõ ràng.

## 2026-10-13 — Nhiệm vụ 6.2A: Nhật ký theo ngày đã chọn

Trạng thái: **hoàn thành 6.2A**. Chỉ sửa bộ chọn ngày và nguồn dữ liệu của Nhật
ký; không triển khai 6.2B–6.2H, Giai đoạn 7–9, không deploy Firebase và không
commit/push.

### Đã thực hiện

- `NutritionRepository.watchMealLogs` nhận ngày địa phương được chọn. Firebase
  query trực tiếp `consumedAt >= startOfDay` và `consumedAt < startOfNextDay`,
  sắp xếp giảm dần; bỏ truy vấn 100 meal mới nhất của toàn lịch sử.
- Khoảng ngày dùng hai mốc local calendar độc lập, không cộng cố định 24 giờ;
  bản ghi đúng đầu ngày được nhận và đúng đầu ngày kế tiếp bị loại.
- `mealLogsProvider` trở thành family theo ngày và tự hủy listener khi không còn
  được dùng. Đổi ngày tạo trạng thái tải riêng, nên kết quả stream ngày cũ không
  thể thay thế kết quả của ngày mới.
- `JournalScreen` đặt bộ chọn ngày trước các card và truyền cùng ngày cho meal;
  water/activity tiếp tục dùng cùng `dateKey`. Tổng kcal, protein, carbohydrate,
  chất béo, ml nước và phút vận động đều tính từ danh sách của ngày đang chọn.
- Empty state của meal nói rõ chưa có dữ liệu trong ngày; loading, error và retry
  hiện có được giữ lại, trong đó retry meal nhắm đúng provider của ngày hiện tại.
- Không sửa `firestore.indexes.json`: query meal chỉ range/order trên một field
  `consumedAt`, được phục vụ bởi single-field index mặc định.

### File chính đã sửa

`lib/core/utils/local_date_key.dart`,
`lib/features/nutrition/data/nutrition_repository.dart`,
`lib/features/nutrition/data/firebase_nutrition_repository.dart`,
`lib/features/nutrition/providers/nutrition_providers.dart`,
`lib/features/nutrition/models/nutrition_models.dart`,
`lib/features/journal/presentation/journal_screen.dart`,
`test/support/fake_nutrition_repository.dart`, `test/nutrition_test.dart`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `flutter test test/nutrition_test.dart --no-pub`: **6/6 pass**. Test mới bao
  phủ nhiều ngày, ngày trống, hai biên nửa đêm, tổng của meal/water/activity và
  đổi ngày khi meal stream vẫn đang tải.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub --exclude-tags=integration`: **41/41 pass**.

### Việc người dùng cần làm và giới hạn

- Không có thao tác Firebase Console bắt buộc và không có index mới cần deploy.
- Chưa chạy smoke test với dữ liệu production vì nhiệm vụ cấm thao tác production;
  hành vi truy vấn và chuyển ngày được xác minh bằng unit/widget test.
- Các thay đổi Đợt 6.1 vẫn còn nguyên trong working tree và chưa deploy. Nhiệm vụ
  6.2A cũng chưa commit hoặc push.

### Bước tiếp theo

Dừng tại 6.2A và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Nhiệm vụ 6.2B: Tái cấu trúc JournalScreen

Trạng thái: **hoàn thành 6.2B**. Đây chỉ là tái cấu trúc presentation; không đổi
nghiệp vụ, repository, provider, schema, Security Rules, indexes hoặc cấu hình
Firebase. Không triển khai 6.2C trở đi, không deploy, commit hoặc push.

### Cấu trúc sau tái cấu trúc

- `JournalScreen` giảm từ 802 xuống 292 dòng, tiếp tục đọc ngày/provider, mở các
  dialog, điều phối CRUD, xác nhận xóa và truyền state/callback xuống section.
- `MealLogSection` hiển thị tổng dinh dưỡng, danh sách meal, loading/error/empty,
  nút thêm thủ công, Food Scanner và callback sửa/xóa.
- `WaterLogSection` hiển thị tổng ml, danh sách water log và callback CRUD.
- `ActivityLogSection` hiển thị tổng phút, danh sách activity log và callback
  CRUD.
- `JournalDateSelector` chỉ hiển thị ngày cùng callback trước/sau/chọn ngày;
  `journalDateProvider` vẫn là nguồn trạng thái duy nhất.
- `DailyLogSectionCard` và `DailyLogEntryMenu` chứa UI dùng chung của water và
  activity, không đọc provider và không truy vấn dữ liệu.

Toàn bộ `ValueKey` đang được test (`add-meal`, `scan-food`, `add-water`,
`add-activity`, các nút chọn ngày, item water/activity và tổng dinh dưỡng) được
giữ nguyên.

### Hành vi được bảo toàn

- Meal vẫn lọc bằng khoảng nửa mở của ngày đã chọn; water/activity vẫn dùng
  `dateKey`, tổng của ba nhóm vẫn đổi đồng bộ theo ngày.
- Loading, error, retry, empty và đổi ngày trong lúc stream tải vẫn hoạt động.
- Thêm/sửa/xóa meal, water và activity vẫn đi qua controller hiện có.
- Food Scanner vẫn trả `FoodScanChoice` về `JournalScreen`, sau đó mở
  `MealFormDialog` với món gợi ý để người dùng xác nhận.
- Section widgets không chứa Firestore query, provider hoặc controller mới.

### File đã tạo

`lib/features/nutrition/presentation/meal_log_section.dart`,
`lib/features/water/presentation/water_log_section.dart`,
`lib/features/activity/presentation/activity_log_section.dart`,
`lib/features/journal/presentation/journal_date_selector.dart`,
`lib/features/journal/presentation/daily_log_section_card.dart` và
`test/journal_sections_test.dart`.

### File đã sửa

`lib/features/journal/presentation/journal_screen.dart`,
`test/nutrition_test.dart` và tài liệu này.

### Kiểm tra thực tế

- Test tập trung cho journal/nutrition/daily logs: **18/18 pass**.
- `dart format lib test`: 79 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **45/45 pass**.
- Test mới kiểm tra callback thêm/sửa/xóa của từng section, loading/error/empty,
  callback bộ chọn ngày và đường đi từ kết quả Food Scanner tới form xác nhận.

### Việc người dùng cần làm và vấn đề còn lại

- Không có cấu hình thủ công bắt buộc. Chưa chạy trên thiết bị thật vì thay đổi
  chỉ tách widget và toàn bộ widget/regression test đã đạt.
- Working tree vẫn chứa nguyên thay đổi 6.1 và 6.2A; toàn bộ thay đổi chưa được
  commit, push hoặc deploy.

### Bước tiếp theo

Dừng tại 6.2B và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Đợt 6.3: Onboarding và thiết lập mục tiêu sức khỏe

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ triển khai onboarding,
mở rộng hồ sơ và tích hợp điều hướng liên quan; không triển khai Dashboard,
Chatbot, Quest hoặc bất kỳ giai đoạn tiếp theo nào.

### Hành vi đã hoàn thành

- Tài khoản mới và tài khoản cũ chưa đủ thông tin được điều hướng tới onboarding
  sau khi Auth và hồ sơ tải xong. Tài khoản đã hoàn tất tiếp tục tới route đã yêu
  cầu và không phải thiết lập lại.
- Onboarding gồm bốn bước: thể trạng cơ bản, chọn mục tiêu, nhập cân nặng mục tiêu
  khi mục tiêu cần, rồi xem lại và xác nhận. Người dùng có thể quay lại mà không
  mất dữ liệu đã nhập.
- Validation kiểm tra tên, tuổi 13–120, chiều cao 80–250 cm, cân nặng hiện tại và
  cân nặng mục tiêu 20–500 kg. Ứng dụng không thu thập giới tính hoặc mức vận động
  vì chưa có nghiệp vụ sử dụng.
- Hoàn tất onboarding dùng Firestore transaction để cập nhật `users/{uid}` và
  upsert `body_metrics/onboarding-current`; ID ổn định ngăn retry tạo bản ghi cân
  nặng trùng.
- Trang Cá nhân cho phép sửa tên, ngày sinh, chiều cao, mục tiêu và cân nặng mục
  tiêu; cân nặng hiện tại tiếp tục được quản lý qua lịch sử Body Metrics.
- Lỗi tải/lưu có nội dung thân thiện, retry được; thao tác bị khóa trong lúc lưu.

### Schema và quyền truy cập

- Hồ sơ schema 2 thêm `birthDate`, `healthGoal`, `targetWeightKg` và
  `onboardingCompletedAt`. `ensureProfile` bổ sung field nullable cho hồ sơ cũ.
- Rules chỉ cho UID sở hữu đọc/ghi, kiểm tra whitelist mục tiêu, khoảng giá trị,
  dữ liệu bắt buộc khi hoàn tất và giữ `onboardingCompletedAt` bất biến sau lần
  ghi đầu tiên.
- Không cần Firestore index mới. Rules chỉ được sửa trong repository và **chưa
  deploy** lên Firebase production.

### File chính đã tạo/sửa

- Tạo `lib/features/profile/models/health_goal.dart`,
  `lib/features/profile/models/onboarding_draft.dart`,
  `lib/features/profile/presentation/onboarding_screen.dart` và
  `test/onboarding_test.dart`.
- Sửa router, session gate, profile model/repository/provider, form/trang hồ sơ,
  `firestore.rules`, rules test, Auth/Profile test và tài liệu database.
- Bảo toàn mọi thay đổi chưa commit của 6.1, 6.2A và 6.2B.

### Kiểm tra thực tế

- `dart format lib test`: **83 file, 0 thay đổi** ở lần chạy cuối.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **55/55 pass**.
- Firestore Emulator với JDK 21 đi kèm Android Studio:
  `firebase emulators:exec --only firestore "npm test --prefix rules-tests"`:
  **19/19 pass**.
- `git diff --check`: không có lỗi whitespace; Git chỉ cảnh báo quy đổi LF/CRLF
  trên Windows.

### Việc người dùng cần làm và vấn đề còn lại

- Trước khi dùng onboarding với Firebase production, cần review rồi deploy bản
  `firestore.rules` mới. Việc deploy cố ý chưa được thực hiện trong Đợt 6.3.
- Chưa chạy luồng onboarding thủ công trên thiết bị Android thật. Widget test,
  unit test và Rules emulator đều đạt.
- `java` mặc định của máy là Java 8; Firebase CLI cần Java 21. Lần kiểm thử này
  dùng `C:\Program Files\Android\Android Studio\jbr` cho riêng tiến trình, không
  thay đổi cấu hình hệ thống.
- Không commit, push hoặc deploy Firebase.

### Bước tiếp theo

Dừng tại Đợt 6.3 và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Giai đoạn 6A: Hoàn thiện tài khoản và quyền riêng tư

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ triển khai quản lý tài
khoản, lưu theme và nội dung quyền riêng tư; không triển khai Giai đoạn 7 trở
đi.

### Hành vi đã hoàn thành

- Màn đăng nhập có luồng quên mật khẩu, kiểm tra email và dùng thông báo trung
  tính để không tiết lộ email đã đăng ký hay chưa.
- Trang Cá nhân cho đổi mật khẩu sau khi xác thực lại bằng mật khẩu hiện tại.
  Mật khẩu mới được kiểm tra độ dài, xác nhận trùng khớp và phải khác mật khẩu
  cũ.
- Xóa tài khoản yêu cầu nhập lại mật khẩu và xác nhận hậu quả. Trình tự là xác
  thực lại, xóa dữ liệu Firestore theo lô, xóa hồ sơ, rồi mới xóa Firebase Auth.
  Nếu xóa dữ liệu hoặc Auth lỗi giữa chừng, tài khoản còn lại có thông báo rõ và
  thao tác có thể chạy lại an toàn. Người chưa hoàn tất onboarding cũng có nút
  xóa tài khoản.
- Theme sáng/tối/theo thiết bị được lưu bằng `shared_preferences` và nạp trước
  khi dựng `MaterialApp`.
- Ba route thật cho Giới thiệu, Quyền riêng tư và Lưu ý sức khỏe đã được nối từ
  trang Cá nhân.

### Dữ liệu và Security Rules

- Repository xóa toàn bộ collection riêng tư đang triển khai hoặc đã thiết kế:
  `body_metrics`, `meal_logs`, `water_logs`, `activity_logs`, `goals`,
  `daily_quests`, `chat_sessions/messages`, sau đó xóa `users/{uid}`.
- Rules cho phép chủ UID đọc để liệt kê và xóa dữ liệu con của chính mình, đồng
  thời tiếp tục chặn UID khác và không mở quyền create/update cho đường dẫn chưa
  có nghiệp vụ.
- Không dùng Cloud Functions, backend mới hoặc dịch vụ trả phí.

### File chính đã tạo/sửa

- Tạo account data repository, controller lỗi theo giai đoạn, ba dialog bảo mật,
  màn thông tin tài khoản, theme preference store và test tương ứng.
- Sửa Auth repository/provider/screen, Profile/Onboarding, router, `main.dart`,
  `firestore.rules`, rules tests, `pubspec.yaml` và tài liệu database.

### Kiểm tra thực tế

- `dart format lib test`: không còn thay đổi định dạng ở lần chạy cuối.
- `flutter analyze --no-pub`: **No issues found**.
- Test tập trung Auth/Profile/Onboarding/Theme: **47/47 pass**.
- Firestore Emulator với Java 21: **20/20 pass**, gồm xóa hồ sơ, dữ liệu lồng
  nhau và chặn xóa chéo UID.
- `flutter test --no-pub`: **65/65 pass**.
- `flutter build apk --debug --no-pub`: build thành công tại
  `build/app/outputs/flutter-apk/app-debug.apk`; Flutter cảnh báo các plugin
  Firebase hiện vẫn áp dụng Kotlin Gradle Plugin cũ, chưa phải lỗi build.
- Lần chạy `dart format lib test rules-tests` ban đầu đi vào `node_modules` bị
  thiếu một thư mục package trung gian; formatter sau đó được chạy đúng trên
  `lib test`. Đây không phải lỗi mã nguồn hay rules test.

### Deploy và việc còn lại

- Đã deploy **chỉ** `firestore.rules` lên project
  `healthmate-app-20261013`; Firebase xác nhận compile và release thành công.
  Không deploy indexes hoặc dịch vụ khác.
- Chưa cài/smoke test APK mới trên Android vì điện thoại ngắt khỏi ADB ở bước
  cài đặt cuối. Build APK và toàn bộ test tự động đều đạt.
- Không commit hoặc push. Mọi thay đổi chưa commit của 6.1–6.3 được bảo toàn.

### Bước tiếp theo

Dừng tại Giai đoạn 6A sau khi hoàn tất kiểm thử; không tự triển khai Giai đoạn 7.

## 2026-10-13 — Giai đoạn 6B: Hoàn thiện nhật ký

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ hoàn thiện meal/water/
activity journal và biểu đồ cân nặng; không triển khai Goals, Quest hoặc Chatbot.

### Hành vi đã hoàn thành

- Meal schema 2 lưu `dateKey` và `timezoneOffsetMinutes`, dùng cùng quy ước ngày
  với nước/vận động. Danh sách chính truy vấn equality theo ngày đang chọn và
  được sắp theo `consumedAt` tại client.
- Bữa schema 1 thiếu `dateKey` vẫn xuất hiện bằng truy vấn khoảng thời gian nửa
  mở giới hạn trong ngày. Hai nguồn được gộp theo document ID; sửa bữa cũ sẽ tự
  nâng document lên schema 2. Không chạy migration hàng loạt.
- Thẻ tóm tắt ngày hiển thị kcal, protein/carb/chất béo, ml nước và phút vận động
  từ đúng các log đã tải của ngày đang chọn. Trạng thái chưa tải/lỗi dùng dấu `—`
  thay vì coi là số 0.
- Form bữa ăn có món gần đây, món ngoài catalog có nhãn `Ước tính`, giữ bước xác
  nhận khẩu phần và validation. Menu bữa cho phép nhân bản sang ngày đang xem.
- Nước có nút ghi nhanh 250/350/500 ml và vẫn đi qua repository/controller thật.
- Trang Cá nhân có biểu đồ tối đa 12 lần đo cân nặng gần nhất bằng `fl_chart`.
- Ngày và số ở phần UI mới dùng `intl`, theo định dạng Việt Nam phù hợp.

### Schema, migration và indexes

- `meal_logs` schema 2 thêm `dateKey`, `timezoneOffsetMinutes`; Rules bắt buộc hai
  field này cho create/update mới và cho phép nâng cấp document schema 1 khi sửa.
- Chưa migration dữ liệu production. Kế hoạch backfill có kiểm soát được ghi tại
  `docs/database-design.md`; phải xin xác nhận trước khi chạy.
- Không cần index mới: equality một field cho meal và range/order trên cùng
  `consumedAt` đều dùng single-field index mặc định. `firestore.indexes.json`
  không thay đổi bởi Giai đoạn 6B.
- Firestore Rules chỉ được sửa trong repository và **không deploy** trong lượt
  này.

### File chính đã tạo/sửa

- Tạo `lib/features/journal/presentation/daily_summary_card.dart`,
  `lib/features/nutrition/presentation/custom_food_dialog.dart`,
  `lib/features/profile/presentation/weight_chart.dart` và
  `test/stage_6b_test.dart`.
- Sửa model/repository/provider/presentation của nutrition, `JournalScreen`,
  water/activity presentation, `ProfileScreen`, Rules/test Rules, dependency và
  tài liệu. Mọi thay đổi chưa commit từ các đợt trước được giữ nguyên.

### Kiểm tra thực tế

- `dart format lib test`: **97 file, không còn thay đổi định dạng**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **71/71 pass**.
- Firestore Emulator với JDK 21: **21/21 pass**, gồm quyền UID, schema meal v2,
  chặn date metadata sai và nâng cấp bữa schema 1.
- `flutter build apk --debug --no-pub`: thành công tại
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Build còn cảnh báo từ các Firebase plugin về cách áp dụng Kotlin Gradle Plugin
  cũ; đây chưa phải lỗi build.

### Việc người dùng cần làm và vấn đề còn lại

- Trước khi chạy code 6B với Firebase production, cần review và deploy
  `firestore.rules`; lượt này không deploy Firebase, không commit và không push.
- Truy vấn tương thích bữa cũ tạo thêm một listener giới hạn trong ngày. Chỉ bỏ
  listener này sau một migration đã được người dùng duyệt và xác minh đầy đủ.
- Chưa smoke test thủ công trên điện thoại thật trong lượt này; unit/widget/rules
  test và APK debug đều đạt.

### Bước tiếp theo

Dừng tại Giai đoạn 6B và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Giai đoạn 6D: UI nền tảng, Tổng quan và điều hướng nhanh

Trạng thái: **hoàn thành code và kiểm thử cục bộ theo phạm vi đã duyệt**. Chỉ
thực hiện token/component cần cho màn Tổng quan, màn Tổng quan dùng dữ liệu thật
và thanh điều hướng mới; không làm 6D-3 trở đi.

### Hành vi đã hoàn thành

- Theme sáng/tối dùng nền kem ấm hoặc xanh đen, xanh lá làm màu chính và màu
  nhấn riêng cho nước, bữa ăn, vận động và cân nặng. Font Be Vietnam Pro được
  đóng gói cục bộ với giấy phép SIL Open Font License 1.1.
- Tổng quan chào theo giờ và tên hồ sơ, hiển thị ngày địa phương, kcal và macro
  đã ghi, tổng nước, phút vận động, số bữa và cân nặng gần nhất.
- Tổng quan dùng trực tiếp `mealLogsProvider`, `waterLogsProvider`,
  `activityLogsProvider`, `userProfileProvider` và `bodyMetricsProvider`; không
  thêm repository hoặc query Firestore mới. Có loading, lỗi từng phần, retry và
  empty state hướng dẫn bắt đầu.
- Thẻ nước có nút ghi nhanh 250 ml và tiếp tục ghi qua `WaterController` thật.
- Thanh điều hướng di động dạng thẻ nổi chỉ hiển thị Tổng quan, Nhật ký và Cá
  nhân. Route/code Quest và Chat vẫn được giữ. Bố cục rộng tiếp tục dùng rail.
- Nút cộng mở bottom sheet đúng bốn hành động. Hành động chuyển sang Nhật ký và
  tái sử dụng dialog/controller hiện có; Quét món được nhấn mạnh nhưng không gắn
  nhãn nhà cung cấp AI trên giao diện.

### File chính đã tạo/sửa

- Tạo token màu, `AppCard`, `IconChip`, `MetricValue`, `MetricTile`, `EmptyState`
  và asset font tại `assets/fonts/be_vietnam_pro/`.
- Sửa `app_theme.dart`, `app_spacing.dart`, `app_shell.dart`,
  `dashboard_screen.dart`, `JournalScreen` và các nhãn hiển thị của luồng quét
  món.
- Tạo provider đồng hồ/ngày của Dashboard, provider lệnh nhanh một lần và
  `test/dashboard_test.dart`; cập nhật test router/auth/onboarding liên quan.

### Kiểm tra thực tế

- `dart format lib test`: **106 file, không còn thay đổi định dạng ở lần chạy
  cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **76/76 pass**.
- Test mới bao phủ Dashboard trống/có dữ liệu từ fake repository, ghi nhanh
  nước, điều hướng ở text scale 1.0/1.5, bốn hành động của bottom sheet và việc
  mở lại dialog Nhật ký hiện có.

### Việc người dùng cần xem và vấn đề còn lại

- Cần xem trên điện thoại thật ở theme sáng/tối: tương phản chữ, độ ấm của nền,
  độ cao thẻ khi tên dài, cuộn tới hàng metric thứ hai và vùng chạm của nút cộng.
- Cần thử cỡ chữ hệ thống mặc định và khoảng 150%, bàn phím khi mở bốn form, cùng
  thao tác back từ bottom sheet/dialog.
- Chưa chạy build APK hoặc smoke test thiết bị trong lượt này. Không sửa/deploy
  Firebase, không commit và không push.

### Bước tiếp theo

Dừng trước 6D-3 và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-16 — Giai đoạn 7: Goals và Daily Health Quest

Trạng thái: **hoàn thành code, kiểm thử cục bộ và build APK debug**. Chỉ làm
Giai đoạn 7; giữ nguyên các thay đổi chưa commit của đợt 6D.

### Hành vi và dữ liệu

- Mở **Cá nhân → Mục tiêu và nhiệm vụ hằng ngày** để thêm/sửa/xóa mục tiêu số
  bữa, ml nước, phút vận động theo ngày hoặc cân nặng theo thời hạn. Có giá trị,
  đơn vị, ngày bắt đầu/kết thúc và trạng thái active/paused/completed.
- Định hướng sức khỏe onboarding trong hồ sơ được giữ riêng. Không tự tạo mục
  tiêu định lượng hoặc di chuyển dữ liệu cũ.
- Tiến độ thói quen chỉ cộng nhật ký thực đúng ngày. Cân nặng dùng khoảng cách
  từ baseline đến target, hỗ trợ cả tăng/giảm và chỉ lấy lần cân trong thời hạn.
- Engine thuần tạo một gợi ý/ngày, có lý do hiển thị. Chỉ gợi ý nước/vận động
  khi người dùng đã đặt mục tiêu tương ứng. Không AI, điểm/phạt hoặc suy đoán
  tình trạng sức khỏe từ nhật ký trống.
- Quest lưu `users/{uid}/daily_quests/{dateKey}`. Transaction create-if-absent
  giữ nguyên gợi ý và trạng thái khi mở nhiều lần hoặc có thao tác đồng thời.
  Hoàn thành/bỏ qua được lưu, không tự ghi log hoặc cộng tiến độ.
- Có loading/error/empty/success, thử lại dữ liệu lỗi, giữ input khi lưu form
  thất bại. Ngày cập nhật theo đồng hồ địa phương; timer được hủy cùng provider.
- Rules chỉ cho chủ UID thao tác, kiểm tra schema/giá trị/đơn vị/ngày lịch thật,
  bảo vệ baseline/createdAt và chặn sửa nội dung hoặc mở lại quest đã kết thúc.
- Xóa tài khoản hiện có đã bao phủ goals/daily_quests. Không thêm package,
  composite index hoặc dịch vụ trả phí.

### File chính

- Tạo feature `lib/features/goals/`: model, validation/progress, repository
  Firestore/interface, Riverpod providers/controller và form.
- Tạo `daily_quest/models/daily_quest.dart`, `domain/quest_engine.dart`; thay
  nội dung trang Quest chờ triển khai bằng giao diện thật.
- Thêm một lối vào trong `ProfileScreen`; bổ sung Rules/test Rules, fake
  repository và `test/goals_quest_test.dart`.
- Cập nhật `README.md`, `docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format lib test` và kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **116 file, 0 thay
  đổi ở lần cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **89/89 pass**. Trong đó 13 test mới bao phủ các công
  thức tiến độ, validation, quy tắc có thể tái lập, dữ liệu trống/đang tải/lỗi,
  lưu/sửa/xóa/retry, terminal status khi mở lại, đổi ngày và màn nhỏ với chữ lớn.
- Firebase Emulator (project demo, JBR Java 21): **24/24 pass**. Test mới kiểm
  tra schema, hai UID/khách chưa đăng nhập, ngày không hợp lệ, immutable fields,
  chuyển trạng thái và tạo quest đồng thời cùng ID. Đây là Rules/JS transaction
  tests; widget tests dùng fake repositories.
- `flutter build apk --debug --no-pub`: **thành công** tại
  `build/app/outputs/flutter-apk/app-debug.apk` (assembleDebug 59,4 giây).
- Build còn cảnh báo Firebase plugins dùng Kotlin Gradle Plugin cũ. Không nâng
  dependencies trong giai đoạn này.

### Việc còn lại và triển khai

- **Chưa deploy Firebase Rules**. Cần review/deploy `firestore.rules` trước khi
  tạo mục tiêu/nhiệm vụ trên Firebase production; không cần index mới.
- Chưa smoke test trực tiếp trên điện thoại với Firebase thật. Cần thử tạo mục
  tiêu cả bốn loại, tiến độ khi thêm/xóa log, giữ trạng thái quest sau mở lại,
  lỗi mạng và cỡ chữ hệ thống lớn.
- Transaction cần mạng; dữ liệu Firestore không bị ghi sang backend khác.
  API đã đối chiếu tài liệu chính thức:
  https://firebase.google.com/docs/firestore/manage-data/transactions
- Không commit, push, migration hoặc deploy production. Các thay đổi có sẵn
  của đợt 6D được bảo toàn.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 8 — Dashboard và Weekly Reflection. Chưa triển khai.

## 2026-10-16 — Giai đoạn 8: Dashboard và Weekly Reflection

Trạng thái: **hoàn thành code, kiểm thử cục bộ và APK debug**. Chỉ làm Giai
đoạn 8, bảo toàn mọi thay đổi chưa commit của 6D và Giai đoạn 7.

### Hành vi đã hoàn thành

- Tổng quan giữ bố cục đã duyệt, lấy tổng kcal/macro, nước, phút vận động và số
  bữa từ provider ngày chung với Nhật ký. Thêm thẻ tiến độ mục tiêu và trạng thái
  nhiệm vụ đã lưu; có hành động mở màn Goals/Quest hiện có, không tự tạo quest
  chỉ vì mở Dashboard.
- Có ngày và nhãn múi giờ thiết bị. Đồng hồ dùng chung cập nhật qua phút/ngày,
  khi app trở lại foreground và được hủy khi không còn consumer.
- Nguồn chưa tải/lỗi hiển thị `—`, không coi lỗi là số 0. Tổng quan có trạng
  thái trống, dữ liệu thật, retry từng phần và thêm nhanh nước qua controller.
- Cân nặng Dashboard dùng listener `limit(1)` theo measuredAt. Lịch sử đầy đủ
  chỉ được dùng tại nơi cần quản lý hồ sơ; báo cáo dùng range tuần riêng.
- Mục **Nhìn lại tuần** chỉ truy vấn khi mở. Chọn tuần trước/hiện tại, xem tổng
  kcal/macro/ml/phút, số ngày có ghi nhận, trung bình kcal trên ngày có bữa và
  biểu đồ theo ngày bằng fl_chart. Có biểu đồ tối đa 12 lần cân trong tuần và
  chênh lệch số đo khi có ít nhất hai lần cân.
- Ngày trống ghi rõ chưa ghi; ngày chưa tới không cộng. Không giả dữ liệu,
  không chia bình quân mặc định 7 ngày, không suy đoán sức khỏe hoặc nguyên nhân
  biến động cân nặng.
- Báo cáo là snapshot lấy từ server: nhãn giờ tải, nút tải lại, lỗi khi thiếu
  một nguồn. Sau sửa log cần mở lại/làm mới báo cáo; không tạo listener báo cáo
  chạy nền hoặc ghi collection thống kê mới.

### Truy vấn và vòng đời

- Một lượt báo cáo gọi mỗi repository range đúng một lần: nutrition (2 query
  để giữ legacy), water (1), activity (1), body metrics (1), tổng cộng **5 query
  get**. Rebuild cùng UID/tuần không đọc lại; đóng/rời tab giải phóng cache.
- Khoảng ngày nửa mở; meal theo dateKey đã lưu, bữa cũ thiếu dateKey theo
  consumedAt địa phương và gộp theo ID. Không migration.
- Screen ngừng watch khi branch của indexed shell bị ẩn; autoDispose hủy các
  listener không còn consumer. Thẻ metric có chiều cao tự giãn để không tràn
  khi trở lại màn ở cỡ chữ lớn hoặc giá trị dài.
- Fake counters kiểm tra trước khi mở báo cáo có 0 lượt range; mở là 1 lượt
  mỗi repository; rebuild giữ 1; làm mới thành 2. Dashboard active có 1 listener
  meal/water/activity mỗi nguồn; rời sang Cá nhân còn 0 và quay lại là 1.
- Test xác nhận Dashboard không mở listener lịch sử cân nặng đầy đủ. Đây là số
  lần gọi và subscription đo trong fake tests; chưa đo billing/document reads
  Firebase production.

### File chính tạo/sửa

- Tạo `features/weekly_reflection/models/weekly_reflection.dart`,
  `providers/weekly_reflection_providers.dart`,
  `presentation/weekly_reflection_card.dart`.
- Tạo `dashboard/presentation/dashboard_goals_card.dart`, đồng hồ chung tại
  `shared/providers/local_clock_provider.dart`, `test/weekly_reflection_test.dart`.
- Sửa Dashboard/provider, range APIs và implementations của nutrition/water/
  activity/profile, providers lifecycle và guard nhỏ tại Journal/Profile/Quest.
- Sửa `MetricTile`, fake repositories/test harness, test Dashboard, thêm query
  range tests trên emulator; cập nhật README/database-design/progress.
- Không thêm package, không đổi Rules hoặc indexes trong Giai đoạn 8. Thay đổi
  Rules và font dependency có sẵn từ các đợt trước được giữ nguyên.

### Kiểm tra thực tế

- `dart format lib test` và kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **122 file, 0 thay
  đổi ở lần cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **103/103 pass** (14 test mới Giai đoạn 8).
- Nhóm mới gồm tổng/macro/đơn vị, tuần qua năm, ngày rỗng/ít dữ liệu/future,
  ranh giới nửa đêm, dateKey ưu tiên timestamp, dedupe, lỗi/retry, đổi tuần khi
  đang tải, số query/listener, Goal/Quest Dashboard, rollover/resume, theme
  sáng/tối và cỡ chữ 1.0/1.5 trên màn nhỏ.
- Firestore Emulator project demo, JBR Java 21: **25/25 pass**. Query test mới
  xác minh dateKey/timestamp ranges, legacy merge, cuối khoảng không lặp,
  cân nặng limit(1) và chặn UID khác. Không gọi Firebase production.
- `flutter build apk --debug --no-pub`: **thành công**, lần cuối assembleDebug
  15,3 giây; APK tại `build/app/outputs/flutter-apk/app-debug.apk`.
- Cảnh báo KGP cũ từ Firebase plugins vẫn còn, không phải lỗi build. Không nâng
  dependencies ngoài phạm vi.

### Việc người dùng cần làm và giới hạn

- Cần thử trên điện thoại thật: Tổng quan đối chiếu Nhật ký, thêm/sửa/xóa rồi
  tải lại báo cáo, cỡ chữ lớn, theme tối, nhãn múi giờ, mất mạng và back/dialog.
  Chưa chạy smoke test với Firebase thật hoặc profiling production.
- Báo cáo tuần cần mạng để lấy tập dữ liệu đầy đủ từ server. Dashboard vẫn theo
  cơ chế cache/realtime của SDK hiện có; không tuyên bố số liệu chưa ghi là đủ.
- Giai đoạn 8 không cần Rules/index mới. Rules Giai đoạn 7 trong source vẫn
  chưa deploy; cần review/deploy trước khi ghi mục tiêu/nhiệm vụ production.
- Không commit, push, deploy Firebase hoặc migration. Không làm Giai đoạn 9.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 9 — AI Health Chatbot có ngữ cảnh HealthMate. Chưa triển khai.

## Giai đoạn 9 — Trò chuyện HealthMate (16/10/2026)

### Trạng thái và phạm vi được xác nhận

Đã triển khai mã nguồn, kiểm thử tự động và build Android debug. Chưa kiểm thử
đầu cuối trên Android/Firebase AI thật vì `flutter devices` chỉ nhận Windows,
Chrome, Edge; chưa nhận điện thoại Android. Không tuyên bố production đã chạy.

Đã đọc toàn bộ AGENTS.md, kiểm tra code/dependencies/Android/Rules và Git trước
khi sửa. Có nhiều thay đổi chưa commit của 6D/7/8; giữ nguyên các thay đổi đó.
Không thêm/nâng cấp package, không đổi cấu hình Firebase/App Check hoặc indexes.

Sau khi đối chiếu điều khoản Gemini Developer API Unpaid Services hiện hành,
người dùng đã xác nhận: **giữ miễn phí; số liệu trả lời tại app, AI chỉ nhận câu
hỏi kiến thức chung định sẵn**. Đây là điều chỉnh rõ ràng so với phạm vi Giai
đoạn 9 ban đầu gửi ngữ cảnh cá nhân tới AI. Không có tùy chọn gửi sức khỏe cá
nhân tới model, không bật billing hoặc đổi sang dịch vụ trả phí.

### Hành vi đã triển khai

- Mở từ Cá nhân → Trò chuyện cùng HealthMate, giữ nguyên thanh điều hướng.
- Tra cứu kcal/macro, nước, phút vận động hoặc tóm tắt ngày bằng repository
  thật. Hỗ trợ hôm nay/hôm qua và chọn ngày; nhãn ngày/UTC offset/đơn vị rõ.
  Chỉ đọc nguồn liên quan; phân biệt dữ liệu trống với lỗi/giá trị bằng 0.
- AI chỉ nhận enum ba chủ đề: bữa ăn cân bằng, đọc nhãn dinh dưỡng, bắt đầu ghi
  nhật ký. System instruction riêng, không đưa nội dung tự nhập, UID, hồ sơ,
  nhật ký hoặc lịch sử hội thoại vào prompt. Không cấp tool/Firestore cho AI.
- Đã kiểm tra tài liệu chính thức Firebase AI Logic models/chat/thinking và
  Gemini terms ngày 16/10/2026. Model mặc định `gemini-3.8-flash`, override bằng
  `HEALTHMATE_CHAT_MODEL`; generation 2048 output tokens, thinking low. Chưa gọi
  model thật trong lượt này; không gửi dữ liệu sức khỏe thật đi kiểm thử.
- Có thông báo xử lý dữ liệu trước lần chọn AI đầu trong mỗi lần vào Chat,
  disclaimer, streaming, bản tạm chưa lưu, dừng nhận, timeout, retry và thông báo
  lỗi thân thiện. Không bảo đảm dừng request trên server/hoàn quota.
- Session/messages lưu dưới UID, 20 lượt mỗi phiên, tối đa 1000/6000 ký tự,
  tải 20 phiên gần nhất. Ghi nguyên tử theo cặp với ID ổn định; lỗi lưu giữ đáp
  án để retry cùng ID, không gọi AI lại. Chặn câu hỏi mới khi lưu chưa được xác
  nhận; người dùng có thể retry hoặc chủ động tạo phiên mới.
- Không thêm listener lịch sử. Khi rời nhánh hoặc đổi UID, hủy stream nhận và
  bỏ kết quả đến muộn; không chờ cleanup mạng để giao diện tiếp tục. Composer
  và consent tạm theo UID. Luồng xóa tài khoản cũ đã có xóa messages trước
  sessions nên được tái sử dụng, không sửa Auth/account deletion.
- Rules mới kiểm tra chủ UID, schema, role/source/độ dài, sequence, bộ đếm và
  cặp message; không cho cập nhật tin đã tạo. Rules không chứng thực nguồn AI
  ở phía máy chủ vì client ghi cả hai role; không dùng nhãn này để cấp quyền.

### File chính tạo/sửa trong Giai đoạn 9

- Tạo `lib/features/chatbot/models/chat_models.dart`.
- Tạo `lib/features/chatbot/data/chat_repository.dart`,
  `firebase_chat_repository.dart`, `knowledge_service.dart`,
  `firebase_knowledge_service.dart`.
- Tạo `lib/features/chatbot/domain/journal_chat_context.dart` và
  `lib/features/chatbot/providers/chat_providers.dart`.
- Thay placeholder `lib/features/chatbot/presentation/chat_screen.dart` bằng
  luồng Chat hoạt động; sửa nhỏ `profile_screen.dart` để thêm lối vào và
  `account_information_screen.dart` để giải thích quyền riêng tư.
- Cập nhật cục bộ `firestore.rules`, `rules-tests/firestore.rules.test.cjs`.
- Tạo `test/chatbot_test.dart`, `test/support/fake_chat_repository.dart`; thêm
  overrides test vào `test/support/test_app.dart` để test không gọi Firebase/AI.
- Tạo `docs/chatbot.md`; cập nhật README, database-design và báo cáo này.

### Kiểm tra thực tế cuối lượt

- `dart format lib test`: 131 file; kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **0 thay đổi**.
- `flutter analyze --no-pub`: **No issues found** (12,0 giây lần cuối).
- `flutter test --no-pub`: **121/121 pass** (18 test mới, tổng 17 giây).
  Bao phủ chọn ngày/ranh giới nửa đêm/tổng, ngày rỗng, nguồn lỗi/retry, không
  gửi text/context cá nhân tới AI, streaming/partial/trống/lỗi quota/timeout/
  hủy, đổi UID và rời nhánh lúc tải, retry ghi không trùng, giới hạn phiên,
  disclosure, sáng/tối, keyboard, textScale 1.0/1.5/2.0 và lối vào từ Profile.
- Firebase Firestore Emulator project `demo-healthmate-rules`:
  **29/29 pass** (4 test mới, 10,75 giây). Xác minh transaction cặp thật trên
  emulator, idempotency, read order, cross-UID/guest, immutable message, giới
  hạn/invalid schema và quy trình delete child/parent; không gọi production.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug 17,7 giây,
  APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Cảnh báo KGP của các Firebase plugins vẫn còn như Giai đoạn 8; không làm
  build thất bại. Không tự nâng SDK/dependencies ngoài phạm vi.
- `git -c core.safecrlf=false diff --check`: sạch. HEAD vẫn
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`, không stage thay đổi.

### Cần làm thủ công và giới hạn còn lại

- Review/deploy Rules mới trong một nhiệm vụ được yêu cầu riêng trước khi ghi
  Chat production; Rules Giai đoạn 7 trong source cũng còn chưa triển khai.
  Lượt này không deploy Rules/indexes, không commit/push, không migration.
- Cần Android thật để xác minh App Check/model/quota/streaming và lưu/tải lịch
  sử với tài khoản kiểm thử sau khi rule được triển khai. Web/desktop chỉ tra
  cứu nhật ký; gọi AI báo nền tảng chưa hỗ trợ.
- Kiểm tra bằng mắt: bố cục sáng/tối, chữ lớn/keyboard, nút dừng, auto scroll,
  mất mạng/retry, nhật ký nhiều ngày và đổi tài khoản. Checklist tại chatbot.md.
- Chưa hỗ trợ hội thoại AI tự do hoặc phân tích số liệu sức khỏe bằng model;
  đúng lựa chọn miễn phí đã xác nhận. Tra cứu hiện giới hạn tổng theo ngày cho
  bữa ăn/nước/vận động. Lịch sử là snapshot, không realtime hoặc phân trang
  hơn 20 phiên; chưa lưu bản nháp qua khởi động lại.
- AI vẫn có thể sai; các test giả lập không chứng minh chất lượng nội dung hay
  xác thực App Check của backend thật. Không tự bảo đảm miễn phí vô hạn.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 10 — Security, kiểm thử tích hợp và hoàn thiện MVP. Chưa triển khai.

## Giai đoạn 10 — Security, kiểm thử tích hợp và hoàn thiện MVP

Ngày: **16/10/2026**. Hoàn thành rà soát, sửa lỗi trong phạm vi và kiểm thử
cục bộ/emulator; APK debug build thành công. Demo Android thật và phát hành
production còn các bước thủ công, không tuyên bố đã xác minh live AI.

### Quyết định và thay đổi

- Đọc toàn bộ AGENTS.md, khảo sát source/dependencies/tests/Android, Git status
  và diff. Lưu baseline hash cục bộ để phân biệt thay đổi Phase 10 với các đợt
  6D/7/8/9 còn chưa commit; không bỏ hoặc ghi đè các thay đổi sẵn có.
- Người dùng đã duyệt **MVP/demo 18+** sau câu hỏi về điều khoản Gemini. Cập
  nhật validation/ngày sinh/onboarding, cổng AI dùng chung kiểm tra session,
  UID/profile và hoàn tất thiết lập; giữ dữ liệu cũ. Đây là tự khai, không phải
  chứng thực danh tính/tuổi. Onboarding lặp giữ completion marker đã có.
- Chặn NaN/Infinity/overflow ở dữ liệu nhập thể trạng/dinh dưỡng và BMI.
  Rules kiểm tra dateKey thực sự khớp timestamp + UTC offset, bao gồm ca
  nửa đêm/ngày nhuận. Không thêm field/index, không migration dữ liệu cũ.
- Scanner có picker injectable, kiểm tra size/MIME/decode/dimensions, re-encode
  PNG bỏ metadata gốc, đồng ý từng ảnh, xử lý quyền/lỗi/timeout45s, đóng/đổi UID
  không nhận kết quả muộn; vẫn nhập thủ công khi catalog rỗng. Tăng giới hạn
  output JSON có chặn kích thước; không tự lưu kết quả AI thành meal log.
- Thông báo journal đang chờ server xác nhận, khóa gửi nhanh lặp khi pending;
  không retry tự động tạo thêm record. Privacy giải thích cache/offline,
  ảnh tạm/provider processing và giới hạn free tier. Android loại dữ liệu
  app khỏi OS backup/cloud/device-transfer; APK compile cấu hình mới.
- Thêm runner Auth+Firestore emulator dùng project demo cố định; test Flutter
  gọi SDK/repository thật. Bốn plugin web đã có transitive được khai báo
  thêm dev dependency, pub get offline giữ nguyên version, không thêm runtime
  dependency hoặc nâng cấp hàng loạt.

### File chính của riêng Giai đoạn 10

- Mới: `lib/core/config/ai_access_policy.dart`,
  `lib/features/food_scanner/data/food_image_picker.dart`,
  `android/app/src/main/res/xml/data_extraction_rules.xml`,
  `firebase.emulators.json`, `tool/test_emulators.ps1`,
  `tool/chrome_test_adapter.cmd`, `tool/chrome_test_adapter.cjs`.
- Sửa: `firestore.rules`, `rules-tests/firestore.rules.test.cjs`,
  `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `pubspec.lock`;
  `lib/features/profile/models/profile_validation.dart`, `user_profile.dart`,
  `lib/features/profile/data/firebase_health_profile_repository.dart`,
  `lib/features/profile/presentation/onboarding_screen.dart`,
  `profile_form_dialog.dart`, `account_information_screen.dart`;
  `lib/features/nutrition/models/nutrition_validation.dart`,
  `lib/features/journal/presentation/journal_screen.dart`,
  `lib/features/chatbot/providers/chat_providers.dart`,
  `lib/features/food_scanner/data/firebase_food_scanner_service.dart`,
  `models/ai_food_suggestion.dart`, `presentation/food_scanner_dialog.dart`,
  `providers/food_scanner_providers.dart`.
- Test mới: `test/security_regression_test.dart`, `test/food_scanner_test.dart`,
  `test/firebase_repository_integration.dart` (opt-in, không tự discover).
  Sửa hỗ trợ `test/support/test_app.dart`, `fake_health_profile_repository.dart`.
- Tài liệu: tạo `docs/test-report.md`; cập nhật README,
  `docs/database-design.md`, `docs/chatbot.md` và báo cáo này.

### Kiểm thử thực tế

- `dart format lib test tool`: **136 file, 0 thay đổi** ở lần cuối.
- `flutter analyze --no-pub`: **No issues found**, 7,5 giây.
- `flutter test --no-pub`: **134/134 pass**, khoảng 14 giây, không skip;
  gồm 13 bài mới và chạy lại tất cả test cũ.
- `tool/test_emulators.ps1`: **31/31 Rules + 4/4 real SDK integration pass**,
  Auth9099/Firestore8080, project `demo-healthmate-rules`, không production.
  SDK xác minh lưu/tải profile/onboarding/logs/Goals/Quest/Chat, chặn UID khác,
  offline pending/reconnect chỉ ghi một lần và xóa dữ liệu trước Auth.
- SDK web test runner Windows từng lỗi CanvasKit404/path slash; adapter
  phục vụ file cache SDK nguyên bản trong Chrome test headless đã giải quyết.
  Không sửa SDK hay bỏ qua assertions. Runner portable cuối đã chạy thành công.
- `flutter pub get --offline`: thành công; 4 dependency đổi từ transitive
  sang direct dev trong lockfile, không đổi version.
- Kiểm tra cuối `dart format --output=none --set-exit-if-changed lib test tool`:
  136 file, 0 thay đổi; `git -c core.safecrlf=false diff --check`: sạch.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug16,2 giây.
  `build/app/outputs/flutter-apk/app-debug.apk`. Cảnh báo KGP Firebase plugins
  vẫn có như trước, chưa nâng SDK/plugin ngoài phạm vi.
- Rà soát secret source nonignored: không thấy private/service-account/key
  Gemini riêng; Firebase public config vẫn có. Không audit toàn Git history/
  ignored files. Storage không dùng, nên không có Storage Rules để test.

### Việc cần người dùng và giới hạn

- Không có Android kết nối khi kiểm tra. Cần thử camera/permissions, live
  App Check/Gemini/quota, offline kill/restart, sáng/tối/chữ lớn, đổi tài khoản
  và xóa tài khoản kiểm thử theo checklist README. Không chạy smoke test AI
  Android thật trong lượt này.
- Rules mới chưa deploy; cần review và yêu cầu riêng trước ghi Goals/Quest/
  Chat production. Không bật billing, thêm backend, đổi Firebase project,
  chạy migration, commit, stage hoặc push. HEAD vẫn
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`.
- Trước public release cần chốt application ID/icon/signing thay debug
  template và cấu hình SHA-256/Play Integrity. Native cache không tự xóa khi
  logout; backup/device transfer OEM chưa thử. Client cleanup phải được cập
  nhật khi thêm collection mới. Không gọi bản debug là sẵn sàng phát hành.
- Quyền UID/schema được test, không bảo đảm tính đúng dinh dưỡng/nguồn catalog
  hay tuổi tự khai. AI có thể sai, hủy chờ không hoàn quota. Các giới hạn và
  cách chạy lại được ghi đầy đủ trong `docs/test-report.md`.

### Giai đoạn kế tiếp đề xuất

Giai đoạn tùy chọn 11 — Thông báo và polish, chỉ sau kiểm tra Android thật và
khi người dùng yêu cầu. **Chưa triển khai.**

## Bổ sung Food Catalog — 16/10/2026

Theo yêu cầu thêm món Việt và các món cơ bản, chỉ mở rộng danh mục dinh dưỡng
(phạm vi Giai đoạn 4), không thực hiện Giai đoạn 11 hay tính năng khác.

### Đã hoàn thành

- Đọc lại AGENTS.md, kiểm tra Git/source/catalog repository/model/form/tests.
  Catalog production thực có 10 mục, UI chỉ cho thấy 8 kết quả mà chưa có xem
  tiếp. Lưu baseline hash cục bộ để giữ thay đổi các đợt trước.
- Bổ sung **148 mục**: 101 thực phẩm tham chiếu Viện Dinh dưỡng 2007, có
  mã/trang/basis; 47 món từ công thức HealthMate ước tính, có gram nguyên liệu
  và khối lượng thành phẩm. Tất cả mục mới có nhãn ước tính, `100 g`/`g`.
  Không coi một tô/ổ là 100 g; phân biệt sống/khô/chín. Không điền 0 cho số thiếu.
- Nạp quản trị bằng Firebase CLI login hiện có vào đúng `food_catalog` project
  `healthmate-app-20261013`. Commit nguyên tử/create-if-absent, không ghi đè
  mục cũ, không ghi đường dẫn `users/*`, không cập nhật meal snapshots.
- Đã đọc lại: tổng **158 mục**, **148/148 mục mới khớp dữ liệu**, có server
  timestamp; **10/10 document cũ giữ nguyên**, gồm timestamps. Dry-run lần nữa
  additions0/skipped148, không tạo trùng.
- Form tìm tiếng Việt không dấu/có dấu/NFD và alias; xem tiếp từng 12 món,
  tìm trên toàn bộ catalog, nhắc khối lượng và hiển thị ước tính. Không thêm
  query/Firestore listener. Danh mục vẫn từ repository Firestore hiện có.

### File chính

- Mới: `data/food_catalog/ingredients.json`, `data/food_catalog/recipes.json`,
  `tool/import_food_catalog.cjs`, `tool/food_catalog.test.cjs`,
  `lib/features/nutrition/models/food_catalog_search.dart`,
  `test/food_catalog_test.dart`, `docs/food-catalog.md`.
- Sửa: `lib/features/nutrition/presentation/meal_form_dialog.dart`, README,
  `docs/database-design.md` và báo cáo này. Không sửa Rules/index/dependencies.

### Kiểm thử thực tế

- `node --test tool/food_catalog.test.cjs`: **7/7 pass** (nguồn/đơn vị/số hữu
  hạn, công thức thành phẩm, tham chiếu công thức, idempotence/precondition và
  chặn đường dẫn ngoài catalog).
- `flutter test --no-pub test/food_catalog_test.dart`: **4/4 pass** (tìm kiếm,
  duyệt quá trang đầu ở textScale1.0/1.5, tìm mục chưa hiển thị và snapshot200g).
- `dart format lib test tool`; kiểm tra lại với `--output=none
  --set-exit-if-changed`: **138 file, 0 thay đổi** lần cuối.
- `flutter analyze --no-pub`: **No issues found**, 7,1 giây.
- `flutter test --no-pub`: **138/138 pass**, khoảng 12 giây.
- Nạp/read-back production và dry-run chống tạo trùng đã chạy thật như trên.
- `git -c core.safecrlf=false diff --check`: sạch. HEAD giữ nguyên
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`, không stage/commit/push.

### Giới hạn và cách xem

- Dinh dưỡng món chế biến là công thức giả định, chưa được phân tích/chuẩn hóa
  cho mọi quán hay nhãn hàng; khác lượng dầu/nước dùng/khẩu phần sẽ khác số liệu.
  Nguồn năm 2007, không gọi là nguồn mới nhất. Chi tiết tại `docs/food-catalog.md`.
- Mở lại **Thêm bữa ăn** khi có mạng để nhận catalog; chạy lại bản code mới để
  có tìm không dấu và nút Xem thêm. Thử `pho bo`, `com tam`, `dau phu`.
- Không build APK mới hoặc thử điện thoại trong lượt này. Không cần deploy
  Rules/index, không chạy migration, không thay cấu hình AI hoặc bật billing;
  chỉ catalog production được thêm theo yêu cầu.
- Chờ yêu cầu tiếp theo, không tự triển khai giai đoạn khác.

## 17/10/2026 — Bảo trì MVP F01–F06 và R01

Phạm vi theo tài liệu sửa lỗi do người dùng cung cấp; không triển khai giai đoạn mới.
Xem [báo cáo bảo trì](maintenance-2026-10-17.md) để biết từng file và bằng chứng.

- **Đã sửa local và kiểm chứng:** giữ bản nháp bữa/nước/vận động đến xác nhận ghi;
  chống gửi lặp và completion UID cũ; scale snapshot lịch sử; tóm tắt2×2 theo
  constraint; dòng phụ thẻ nước đầy đủ; mục tiêu retry với ID thao tác ổn định.
- **Quest:** thêm chẩn đoán nguồn và retry thực; Rules local/SDK emulator đạt.
  Rules đang deploy thiếu quyền ghi Goals/Quest/Chat, đọc xác nhận trong lượt này.
  Chờ review và yêu cầu deploy riêng, rồi kiểm tra backend thật.
- **AI:** thêm chẩn đoán an toàn + standalone QA probe. Cloud Android có một lượt
  thành công nhưng lặp lại timeout sau HTTP send, chưa có response/status;
  chưa xác định/sửa dứt điểm F04. Không đổi provider/model, timeout hay enforcement.
- **Kiểm tra cuối:** format145file/0thay đổi, analyze sạch, Flutter176/176,
  Node7/7, Rules31/31 + SDK6/6 (demo emulator), APK Android x64 debug build thành công.
- **File chính:** confirmed_save/operation_diagnostics mới; JournalScreen và form/controller
  meal/water/activity; nutrition snapshot/parser; Goals repository/form/provider;
  Quest screen; Chat/Scanner diagnostics; DailySummaryCard/MetricTile; ba bộ test
  maintenance, SDK integration và probe Android; tài liệu kết quả nối thêm.
- **Còn lại:** review Rules + deploy theo yêu cầu riêng; điều tra F04 bằng log/response
  cụ thể, retest QA Android và điện thoại thật. Không tự phát triển tính năng tiếp theo.
- Git HEAD giữ `3e8e9cc756c0a8caf1a882f6829088216736e56b`; thay đổi ở working tree,
  không stage/commit/push/PR hoặc production deploy/migration/billing.
- Người dùng đã yêu cầu tắt laptop sau khi hoàn thành: chỉ hẹn shutdown bình thường,
  không ép đóng chương trình có nội dung chưa lưu.

## 17/10/2026 — C1: nền tảng và chuyển sang phạm vi core

Yêu cầu C1 theo file `Sửa` của chủ sản phẩm thay thứ tự tính năng cũ trong đợt core.
Đầu mối hiện hành: [core-scope.md](core-scope.md), không ghi đè lịch sử ở trên.

- **Local đạt:** hai feature flags build cục bộ mặc địnhfalse cho Chatbot/Scanner;
  ẩn menu Cá nhân/CTA Nhật ký/quick action; chặn /chat/deep link/return link sau
  Auth/onboarding; giữ branch0–4, Profile4 và Quest hiện có.
- Không khởi tạo ngầm AI qua UI/điều hướng; controller Chat tắt không đọc lịch sử,
  checked service Scanner và knowledge service từ chối trước Firebase AI. Giữ code,
  dependency, Firebase/App Check, lịch sử Chat, snapshot AI và cleanup tài khoản.
- Giữ core CRUD/snapshot/pending/UID/dateKey+legacy, không đổi database/schema/index,
  không thêm mục tiêu kcal/macros, thư viện hoặc tab Tiến độ rỗng.
- File chính: app_feature_flags.dart mới; app_router/app_shell, Profile/Journal/
  MealLogSection, quick action; Chat/Scanner UI/provider gates; core_scope_test mới,
  helper và fixture hồi quy; README/database-design/test-report và tài liệu core.
- Kiểm tra mới: baseline176/176; cuối201/201Flutter, Node7/7, Rules31/31+SDK6/6
  demo emulator; format147file/0thay đổi, analyze sạch10,7s; debugAPK x64build11,8s.
  18tổ hợp UI và3ảnh đã xem, Auth/cold link/Back/noAI init; không gọi cloudAI.
- **Production chưa nghiệm thu:** đọc lại release11:59 UTC+07,17/10/2026;
  vẫn thiếu match ghi Goals/Quest/Chat, updateTime2026-10-13T06:25:21.345792Z.
  Cần review và yêu cầu deploy riêng, hướng dẫn project cụ thể ở core-scope.md.
- Không có Android kết nối: chưa E2E điện thoại, chỉ build, không cài/xóa app.
  Cảnh báoKGP còn; không nâng package/Gradle trong C1.
- HEAD giữ86238197a9f8e24a2222da2da9e74164c35844ea; không stage/commit/push/deploy,
  billing, migration hoặc sửa dữ liệu production. Không tự làm C2–C6.
- Tiếp theo đề xuất **C2 — mục tiêu kcal/macros có lịch sử hiệu lực theo ngày**.

## 17/10/2026 — C2: mục tiêu kcal/macros theo ngày hiệu lực

**Local đạt; production chưa nghiệm thu/chưa được cấp ghi collection mới.**
Chi tiết tại [core-scope.md](core-scope.md), schema tại database-design.md.

- Thêm feature nutrition_targets theoUID, IDyyyy-MM-dd, queryserver<=ngàyD giảm
  dầnlimit1; lịch sử không áp ngược. Kcal và đủ 3 macro hoặc cùngnull,0được giữ,
  bounds hữu hạn, cảnh báo lệch4P+4C+9F>5% cần xác nhận; không tự tínhBMR/TDEE.
- Form từ Tổng quan/Cá nhân, hôm nay/tương lai, nạp đúng phiên bản khi đổi ngày;
  so sánh Tổng quan/Nhật ký đã ghi/mục tiêu/còn/vượt. Lỗi/loading không thành0
  hay chưa đặt. Giữ form/pending/error, chốngdouble tap và completionUIDcũ.
- Repositorytransaction cùng ID, giữcreatedAt, serverread-back trước success;
  SDKđã tái hiện write có thể tới server dù normal reads bịdisableNetwork.
  Retry không nhân đôi; không coi lỗi ack là rollback.
- Ruleslocal nutrition_targets vớischema/UID/bounds/timestamps và cleanup account
  đã cập nhật, không đổiindexes/dependency/config hoặc dữ liệu cũ.
- File chính mới: models/data/providers/presentation dướifeatures/nutrition_targets;
  targetcard ghépDashboard/Journal/Profile; Rules/cleanup;33testsC2, fake/helper,
  thêm1SDK và4Rules tests; README/core-scope/database-design/test-report.
- Kiểm tra mới: baseline201; cuối234/234Flutter,35/35Rules+7/7SDK demo,
  7/7Nodecatalog; format155 file/0 thay đổi, analyze sạch11,6s,APKdebugx64build18,0s.
  Matrix18 UI và3 ảnh xem bằng mắt, keyboardmôphỏng; chưaE2Eđiệnthoại.
- ProductionGET12:23UTC+07 ngày17/10: RulesupdateTime2026-10-13T06:25:21.345792Z,
  thiếu quyền ghi nutrition_targets/Goals/Quest/Chat. Cầnreview và yêu cầu deploy riêng;
  hướng dẫn lệnh với project cụ thể trong core-scope, chưa chạy deploy.
- HEAD86238197a9f8e24a2222da2da9e74164c35844ea; giữ C1 chưa commit,
  không stage/commit/push/deploy/billing/migration. AI vẫn tắt; không làm C3–C6.
- Tiếp theo đề xuất **C3 — nhật ký nhanh, yêu thích catalog và sao chép bữa**.

## Core C3 — Nhật ký nhanh, yêu thích và sao chép (17/10/2026)

- **Local đạt** trong phạm vi unit/widget, Rules, SDK emulator và build. Chỉ làm C3;
  giữ toàn bộ C1/C2 chưa commit trên main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`.
- Nhật ký chia Sáng/Trưa/Tối/Phụ, mỗi nhóm có tổng kcal, số bản ghi và nút Thêm
  đúng ngày/loại. MealLog vẫn độc lập; sửa/xóa cập nhật tổng nhóm, ngày và macro.
  Lỗi catalog không che nhật ký đã tải.
- Form có Tìm món/Gần đây/Yêu thích. Recent cập nhật live, giới hạn 20 bữa/8 món;
  favorite catalog riêng theo UID, ID ổn định, tải 40 rồi tăng 40 theo yêu cầu.
  Có loading/error/retry/cache, xử lý nguồn mất, pending và đổi tài khoản.
  Không thay dữ liệu thiếu bằng 0 kcal hoặc tạo các nguồn C4 chưa hoạt động.
- Copy mở draft giữ snapshot/source; cho sửa ngày/giờ/loại/gram. Hủy không ghi.
  ID cấp một lần mỗi form; transaction create-if-absent và server read-back.
  Retry cùng payload không nhân đôi; payload khác báo tải lại/chọn Sửa. Vẫn tối đa
  5 món/bản ghi, gram chuẩn và nhập món ngoài catalog một lần. Draft chỉ giữ RAM.
- Mới features/food_library, core_journal_test.dart và fake favorite. Sửa nutrition
  model/repository/provider/form/section, JournalScreen, Rules, account cleanup,
  SDK/Rules tests, helper và tài liệu. Schema favorite chỉ gồm tham chiếu catalog,
  timestamps và schemaVersion dưới UID; cleanup đã có test tài khoản A/B.
  Không đổi schema MealLog, indexes, package hoặc cấu hình backend.
- Baseline 234/234; kết quả cuối: 270/270 Flutter, 39/39 Rules + 9/9 SDK trên
  demo-healthmate-rules, 7/7 catalog. Format 162 file, không còn thay đổi; analyze
  sạch; APK debug android-x64 build thành công. Thời gian chạy cuối và bằng chứng
  nằm trong docs/test-report.md. Có 18 tổ hợp UI và 3 ảnh đã xem, keyboard mô phỏng.
- `flutter devices` chỉ có Windows/Chrome/Edge, chưa E2E Android hoặc cài APK.
  Không uninstall/clear app hay thay session người dùng. Cảnh báo KGP đã có còn.
- **Production chưa đạt**: GET Rules read-only lúc 12:45:30 UTC+07 xác nhận release
  vẫn ngày 13/10/2026, chưa có favorite_foods/nutrition_targets/Goals/Quest/Chat.
  Cần review và yêu cầu deploy Rules riêng, sau đó QA Android bằng tài khoản thử.
- Không stage/commit/push/deploy/billing/migration hoặc gọi AI; AI vẫn tắt.
  Dừng C3. Tiếp theo chỉ đề xuất **C4 — món cá nhân và công thức**, chưa thực hiện.

## Core C4 — Món cá nhân, công thức và khẩu phần (17/10/2026)

- **Local đạt** unit/widget/Rules/SDK Emulator/build. Chỉ C4 trên main,
  HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`, giữ toàn bộ C1–C3 chưa commit.
  Baseline mới270/270 Flutter pass19s, không lấy kết quả C3 làm baseline thay thế.
- Thư viện từ Cá nhân, Món của tôi/Công thức trong form bữa. CRUD món cá nhân đủ
  bốn chất/100g, nguồn, tên khác, gram mặc định và cặp tên/gram khẩu phần tùy chọn.
  Nhập một lần giữ mặc định; lưu thư viện là lựa chọn chủ động và có ID ổn định.
- Recipe gồm1–6 snapshot catalog/món cá nhân, không lồng recipe. Yield có thể khác
  tổng nguyên liệu, số phần thập phân; cộng snapshot và scale theo yield, không
  cache tổng dẫn xuất. Dialog gram/phần kiểm tra cả số dinh dưỡng sau quy đổi.
- Sửa/xóa nguồn giữ MealLog và ingredient snapshot. Yêu thích cả3namespace, đọc
  nguồn private trực tiếp theo UID/ID, phân biệt lỗi/cache/missing; nguồn mất vẫn
  bỏ favorite được. Không đổi schema MealLog, giới hạn5món hoặc lịch sử cũ.
- Create retry cùngID/payload không trùng; server read-back trước ack. Edit không
  tự tạo lại nguồn đã xóa, delete chờ xác nhận. Form pending/error giữ draft RAM;
  logout/đổi UID đóng form và bỏ completion cũ. Library đã lưu nhưng bữa lỗi được
  báo riêng; retry bữa không tạo thêm món thư viện. Macro thiếu không tự thành0.
- Mới food_library_models, library repository/provider, library screen/forms,
  portion dialog/nutrition text, test/food_library_test.dart và fake library.
  Sửa favorite stack, Sources, Journal/nutrition forms/model, Profile/router,
  Rules/cleanup, SDK/Rules/fake/helper/regression tests và tài liệu hiện có.
- Thêm custom_foods/recipes dưới UID, mở favorite sourceKind; Rules exact fields,
  bounds/type/timestamps/createdAt và mọi dòng. Payload6 ban đầu vượt ngân sách
  Rules; đã tối ưu validator,47/47 Rules pass gồm dòng giữa/cuối và vượt giới hạn.
  Cleanup SDK xóa hai collection mới của A trước Auth, giữ dữ liệu B.
- Cuối308/308 Flutter pass39s, analyze sạch7,4s;47/47Rules+11/11SDK pass19s;
  7/7catalog; format172file không còn đổi; APKdebugandroid-x64 build45,5s.
  18tổ hợpUI cho hai form/6dòng/nhập một lần/keyboard;4ảnh đã xem. Lỗi test ban đầu
  errno112 do C thiếu chỗ đã xử lý bằng TEMP/TMP trên D rồi chạy lại đầy đủ.
- ProductionGET read-only16:11:23UTC+07: Rules vẫn13/10/2026, thiếu custom_foods/
  recipes/favorite_foods/nutrition_targets/Goals/Quest/Chat. **Production chưa đạt**,
  cần review và yêu cầu deploy riêng. Không Android trong flutterdevices, chưa
  E2E máy thật/ARM/release; KGP warning đã có còn. Không clear/uninstall/session thật.
- Không stage/commit/push/deploy/billing/migration/cloudAI hoặc nâng dependency.
  AI vẫn tắt. Chi tiết file/kết quả tại core-scope.md phầnC4 và test-report.md.
- DừngC4; chỉ đề xuất **C5 — Tiến độ, cân nặng và tổng hợp tuần**, chưa thực hiện.


## 2026-10-17 — Core C5: Tiến độ, cân nặng và tổng hợp tuần

- Hoàn thành C5 local; main/HEAD86238197 không đổi, C1–C4 uncommitted được giữ.
  Baseline mới308/308pass33s. Không chuyển sang C6, commit/push/deploy/migration.
- Thêm ProgressScreen/route branch5,4tab + nút thêm bữa/nước/vận động/cân nặng;
  giữ Profile4/Quest2/Chat3 và Auth/onboarding. Tổng quan có link Tiến độ.
- Dùng WeeklyReflectionCard, weeklyLogsProvider/summarizeWeek và nguồn cân hiện
  có; tổng/macros/số ngày/mẫu số đúng, tương lai không thành thiếu ghi. WeightChart
  sort/spacing timestamp, chi tiết ngày đo, ít hơn2điểm không mô tả thay đổi.
- Mục tiêu tuần2range query bounded, parser chung, chọn đúng phiên bản cho từng
  ngày. Loading/error/retry riêng không che tổng logs. Giữ tuần khi đổi tab nhưng
  nhả data consumer lúc ẩn; không listener ngày hoặc toàn lịch sử ở Progress.
- BodyMetricFormDialog có callback ConfirmedSave cho nút+; error giữ draft,
  pending chặn gửi lặp, AccountBoundDialog bỏ draft khi logout/đổiUID và refresh
  tuần khi thành công. Không thêm schema/Rules/index/package trong C5.
- File chính: progress/presentation/progress_screen mới; router/shell/dashboard,
  weekly_reflection_card, weight_chart/body_metric_form_dialog, nutrition_targets
  repository/provider; progress_test mới và core_scope/dashboard/profile/SDK/fake
  target tests. README/database-design/core-scope/test-report cập nhật.
- Cuối337/337Flutterpass41s; analyze sạch7,1s; format174file0đổi ở check;
  47/47Rules+13/13SDKpass21s;7/7catalog; APKdebugandroid-x64build21,6s;
  diff--check sạch.29test C5 mới,18tổ hợp layout; SDK có cân nặng/nhật ký thật qua
  năm mới, target history/ownership/offline/corrupt data. Không có Android kết nối.
- Full đầu lỗi test tìm vùng cuộn mơ hồ; đổi ensureVisible đúng nút, giữ assert.
  SDK mới đầu sai tham số fixture, đã sửa; các lượt cuối đủ337/13pass, không skip.
- Production GET read-only16:33:55UTC+07,17/10/2026, Rules release13/10/2026 vẫn
  thiếu nutrition_targets/favorite_foods/custom_foods/recipes/Goals/Quest/Chat.
  Production chưa đạt, chưa deploy. Chi tiết/hash/giới hạn trong core-scope C5.
- Cần review/deploy được yêu cầu riêng rồi QA Android (ngày/tuần/mục tiêu cũ,
  offline/UID, chữ lớn/sáng tối, bàn phím/safe area). TEMP/TMP dùng D, không clear/
  uninstall/session thật. KGP warning cũ còn; chưa ARM/release/Android E2E.
- Đề xuất tiếp **C6 — Nghiệm thu bản core trên Android và chuẩn bị bàn giao**;
  chưa thực hiện. AI vẫn tắt.

## Core C6 — Nghiệm thu Android và bàn giao (17/10/2026)

- **Local đạt**, production chưa nghiệm thu. Main/HEAD86238197 giữ nguyên;
  bảo toàn working tree C1–C5. Không stage/commit/push/deploy/migration/billing/AI.
- Sửa core phát hiện khi nghiệm thu: form Cá nhân giữ draft hồ sơ/cân khi lỗi,
  chờ ack và gắn UID; Profile/AccountSecurity controllers bỏ completion phiên cũ;
  SDK Auth kiểm tra expectedUid trước reauth/đổi mật khẩu/xóa. Cleanup vẫn xóa
  data trước Auth sau; test cũ về lỗi giữa chừng được giữ.
- Lần cân mới giữ giờ hiện tại, chỉnh cân không làm mất timestamp cũ. Sửa lỗi
  native sau onboarding cùng ngày cân mới không được coi là gần nhất.
- subscriptionStream sở hữu lỗi Future hủy stream khi logout, không bỏ lỗi đọc/
  ghi đang hoạt động. Áp dụng tại provider của các repository streaming liên quan.
- File chính: auth data/providers, profile providers/3form-screen, core/utils/
  subscription_stream.dart; nutrition/water/activity/goals/library/favorite
  providers; test/core_acceptance_regression_test.dart (12test mới), SDK test
  expectedUid, integration_test/core_acceptance_test.dart, test_driver và
  tool/test_android_core.ps1. Android debug network config chỉ cho HTTP localhost/
  10.0.2.2, không đổi release/main manifest. README/core-scope/database/test-report
  cập nhật. Không thay schema/Rules/index/dependency so với C5.
- Kết quả mới: baseline337pass34s; format178file0đổi; analyze sạch10,8s;
  Flutter349/349pass37s; catalog7/7pass; Rules47/47 + SDK14/14pass (SDK22s).
- Native Android API30/x86_64, AVD riêngHealthMateMaintenanceQA/UTC+07:
  10/10checkpoints E2E pass137s, repository Firebase thật qua emulator demo.
  Luồng đủ hồ sơ → target → thêm/sửa/copy bữa → nước/vận động/cân → tuần → đổi
  target/giữ lịch sử → libraryCRUD/giữ MealLog → offline/retry → logout/UID B.
  B bị chặn đọc A; AI không khởi tạo. Bốn PNG + log trong build/c6-android.
- Build normal lib/main.dart debug ARM64 pass24,8s; APK ở
  D:\HealthMateMaintenanceQA\HealthMate-core-debug-arm64.apk. Copy QA trên D khớp
  SHA256 của213file nguồn/asset/test/config với repo; gradle.properties tạm tắt
  incremental do khác ổ C/D đã khôi phục nguyên byte. Không cài máy thật.
  TEMP/TMP ở D do C còn ít dung lượng; QA AVD được tắt sau kiểm tra.
- Read-only production Rules17:04:32UTC+07: release13/10/2026 chưa đổi, thiếu
  targets/favorites/custom/recipes/Goals/Quest/Chat; water/activity indexes READY.
  Không deploy, không CRUD dữ liệu thật. Scan155file không thấy pattern private
  key/service-account/OAuth/GitHub token (giới hạn scan ghi rõ trong test-report).
- Chưa release signing/Play Integrity/điện thoại thật/process-death. Kiểm tra phụ
  release merged manifest offline không chạy hết vì thiếu Flutter release cache;
  KGP warning Firebase plugins còn. Không hạ dependency để giấu cảnh báo.
- Bước tiếp chỉ đề xuất: review backend và yêu cầu deploy riêng, rồi QA tài khoản
  thử trên máy thật (ngày/mục tiêu cũ, lưu/offline/UID, keyboard/safe-area, font
  100/150/200%, sáng/tối/vuốt chart). Chi tiết bằng chứng và lỗi đã sửa tại
  docs/test-report.md/core-scope.md phần C6. Dừng C6, không mở giai đoạn khác.

## U1 — UX Nhật ký/Tiến độ + chuẩn bị Firebase (18/10/2026)

- Local hoàn thành; production chưa deploy/nghiệm thu. Base main/fd2f72b, code
  U1 để working tree review, chưa commit/push. Không U2/billing/migration/AI.
- Nhật ký có overview kcal/macros/mục tiêu đúng ngày, trạng thái tải/lỗi độc lập;
  mục tiêu lỗi không chặn ghi, thiếu không tự điền số. Details sheet gắn UID.
  Header gọn, bữa/nút+ theo ngày chọn xuất hiện sớm; nước/vận động vẫn CRUD thật
  bên dưới, global+ vẫn hôm nay. Không gộp/xóa MealLog cũ.
- Tiến độ ưu tiên khoảng tuần/tổng/biểu đồ; hướng dẫn và lịch sử ngày mở khi cần.
  Giữ số ngày ghi/mẫu số, mục tiêu lịch sử, trọng số timestamp, query/vòng đời;
  target lỗi có retry ngoài vùng đóng. Không tạo aggregate/listener mới.
- File chính: FeaturePage; JournalScreen + journal_nutrition_overview mới;
  MealLogSection; ProgressScreen/WeeklyReflectionCard;21test mới trong u1_ux_test;
  finder/scroll/expand test cũ và native core_acceptance; tool inspect GET/backup;
  README/core-scope/test-report/firebase-deployment-plan và gallery docs/ux/u1.
- Baseline349/349pass36s; final format180file0đổi, analyze sạch43,8s,
  Flutter370/370pass64s, catalog7/7, Rules47/47 + SDK14/14pass24s. Android E2E
  API30/QA AVD/backend demo đủ10core + viewport/Gần đây pass164s.
- Viewport390×844/100%/sáng-tối/đủ macro/offset0: addBreakfast1319→497dp,
  toàn bộ nút đến545<748dp; chart888→362dp. Gần đây5bấm, không search; cuộn1→0.
  8ảnh trước/sau/JSON +2native ở docs/ux/u1.12matrix360/412×100/150/200%×2theme,
  keyboard260dp không che Lưu. Không ép chữ lớn đạt viewport100%.
- APK lib/main.dart debug ARM64 build39,6s:
  D:\HealthMateMaintenanceQA\HealthMate-U1-debug-arm64.apk (150690083bytes).
  Source copy D khớp217file; gradle.properties tạm override đã khôi phục. QA AVD
  đã tắt; không clear/wipe phiên thật. build/app cũ được giữ ở D:\HealthMateMaintenanceQA\
  archived-project-build-app-20261018 do C gần đầy; không mất source/APK C6.
- Rules/index không đổi; review47Rules/14SDK gồm ownership/schema/snapshot/cleanup.
  GET metadata19:12:59UTC+07 vẫn13/10/hash0b7a11…khác locald33e01…;
 7nhóm core chưa có create/update;2indexes READY. Tool/read-only backup và
  playbook đúng project/default DB/rollback đã chuẩn bị, chưa deploy/rollback.
- Còn QA điện thoại thật/Play Integrity/release/production. KGP warning và
  AVD Impeller/SwiftShader uniform warning được ghi rõ, ảnh/native E2E đã xem/pass.
  Bước sau chỉ đề xuất U2 khi được giao rõ, không tự làm.

## U2 — Triển khai Rules và nghiệm thu SDK production (18/10/2026)

- Chủ sản phẩm yêu cầu hoàn tất file UX/Firebase và cho phép đúng hai tài khoản
  QA tổng hợp; chỉ dọn dữ liệu QA. Base main/fd2f72b; giữ toàn bộ working tree U1,
  chưa stage/commit/push. Không đổi nghiệp vụ, schema, Rules source hoặc indexes.
- Backup source/metadata/config rollback trước deploy tại
  D:\HealthMateMaintenanceQA\u2-before-20261018-193138; bản copy được đối chiếu.
  Chạy lại 47/47 Rules + 14/14 SDK emulator, exit 0 (SDK 20 giây).
- Deploy đúng `firebase deploy --only firestore:rules --project healthmate-app-20261013`,
  exit 0. Release 2026-10-18T12:33:45.507953Z, ruleset 423ff6c8-79b7-4158-ba4f-2de9871a715d;
  GET sau deploy và cuối QA cùng hash LF-trim d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877,
  matchesLocal=true; hai composite nước/vận động READY. Không deploy index/rollback.
- Harness opt-in test/firebase_production_qa.dart và runner tool/test_production_qa.ps1:
  named Firebase apps QA A/B/guest, không default session/Admin SDK/emulator;
  email QA cố định, retry không tạo thêm tài khoản, credentials ngoài repo/ACL riêng.
- SDK production Chrome đạt 1 scenario / 10 checkpoint trong 27 giây, cả teardown:
  onboarding, mục tiêu lịch sử, favorite/custom/recipe, meal snapshot sau sửa/xóa
  nguồn, scale/copy ngày, daily queries/index, Goal/Quest, logout/login và offline
  3 giây/reconnect/retry cùng ID. 50 yêu cầu B/guest read/query/write/delete A bị
  chặn. Dọn/xác minh dữ liệu Firestore hai QA, A cleanup giữ B; giữ hai Auth QA.
- Format 180 file, 0 đổi; analyze final sạch 6,7 giây (lượt đầu có unnecessary
  dart:async ở harness mới, đã bỏ). Không thay app code sau U1; dùng kết quả U1
  370 Flutter / 7 catalog / Android E2E / APK đã ghi, không ghi thành lần chạy U2.
- Metadata/log không credential tại docs/firebase/u2; README/core-scope/test-report/
  deployment-plan cập nhật trạng thái hiện hành. Không đổi App Check/billing/AI,
  seed/migrate hoặc dữ liệu thật. Chưa kiểm chứng Android UI production/máy thật,
  Play Integrity, release signing. Hoàn tất U1/U2 trong file, dừng phạm vi này.

## H0 — 19/10/2026: kiểm thử theo identity và release guard

Đã sửa fixture để recipe là breakfast và chọn bữa mới theo ID; đủ 3 ID,
breakfast đúng ngày/200g/260kcal, ít nhất 2 breakfast hợp lệ. Không thay app clock.
Format 1 file/0 đổi, analyze sạch 33,8s, Flutter 370/370 pass 56s. Android QA
emulator-5580/HealthMateMaintenanceQA/API30 với Auth+Firestore demo-healthmate-rules:
10 checkpoint + viewport/recent pass 159s, debug build 42,7s. Runner trên QA copy D,
log D:\HealthMateMaintenanceQA\h0-android.log. KGP/SwiftShader warnings còn.
Release bỏ ký debug ngầm; private key.properties được ignore. Gradle dry-run release
thiếu khóa dừng đúng thông báo; chưa build release hoặc tạo keystore/đổi package.
Chi tiết docs/release-readiness.md và docs/h-improvements.md. Theo yêu cầu trực tiếp
thực hiện tuần tự H0–H7, chuyển H1 sau mốc H0 này; không deploy/import production.

## H1 — 19/10/2026: khẩu phần catalog, tìm kiếm và dữ liệu có nguồn

Hoàn thành code/data review, chưa import production. Reader khẩu phần tương thích
cũ, fallback gram khi metadata hỏng, không dùng basis/unit không hỗ trợ. Đổi đơn vị
giữ lượng, phần phân số preview/snapshot đúng. Tìm exact/alias/token trước substring;
giữ tìm dấu/không dấu/NFD. Ba dòng TH yogurt100g có nguồn nhà sản xuất;47 công thức
đề xuất phần tham khảo theo yield, không coi tô=100g. docs/h1-catalog-review.md.
Node9/9; Flutter379/379 (42s), focused51/51, H1 cuối9/9; analyze sạch9,6s.
Rules47/47 + SDK15/15 (21s); import emulator151create, retry0create/update/conflict.
Fixture import ban đầu bỏ pagination và fail; diagnostic xác định vn2007-9007,
sửa đọc nextPageToken rồi đạt. Benchmark tool đầu5lint imports/braces đã sửa.
Android QA emulator-5580/API30/demo-healthmate-rules đủ10checkpoint pass154s;
phần0,75 ×200g lưu150g/195kcal qua repository thật. Ảnh docs/ux/h1/catalog-fractional-portion.png
đã xem; benchmark19truy vấn có nhóm held-out/brand/missing,15positive+4rỗng có chủ đích,
19đúng first/empty, giữ và báo kết quả nhiễu. Dataset branch151 khác production158.
Dry-run production: existing158/create3/skip148/proposedMetadataUpdates47/conflict0;
manifest/benchmark ở docs/ux/h1. Tool --apply chỉcreate, metadataupdates cần review/
maintenance riêng. Không đổi Rules/index/schema nhật ký hoặc deploy/AI/billing.
Chưa máy thật/release ký. Hạn mức5h còn60%; chuyển H2 theo yêu cầu chuỗi.

## H2 — 19/10/2026: ghi quen nhanh và bữa mẫu, đạt local/emulator

Recent ưu tiên khi có lịch sử, tài khoản mới về Tìm món; dùng trực tiếp lượng
hiển thị vào bản nháp, Hoàn tác/Sửa riêng, Lưu mới ghi server. Hay dùng đếm theo
20 bản ghi gần nhất/tối đa8 món, không tải toàn lịch sử. Cùng fixture/điểm bắt
đầu đo3tap/0scroll/0gõ/0xác nhận lượng thay cho5tap; đúng ngày/bữa/gram/snapshot.
Bữa mẫu thuộc UID, CRUD tên+1–5snapshot, tạo từ bữa cũ/món đang chọn, dùng bản sao
vào ngày/bữa chọn và sửa từng món. Không gộp thành recipe, nguồn mất vẫn giữ lịch
sử. Cleanup client mới thêm meal_templates; cần nâng client trước enable backend
để client cũ không bỏ sót collection mới khi xóa tài khoản.
Format20file0đổi; analyze sạch11,4s; Flutter385/385 pass52s; targeted6/6 (UID+
pending/retry/bounds/widget100/150/200%). Rules48/48 + SDK16/16 pass25s; test A/B,
guest,5món/overflow/timestamps, offline/retry snapshot và cleanup A giữ B.
Rules đầu vượt1000expressions khi5món; dùng regex/let/sum bounded giữ đủ validation
rồi focused/full pass. UI test đầu chưa prewarm Auth làm dialog đóng, sau đó
x2 chữ dài đẩy ô tên khỏi lazy viewport: sửa harness auth và đưa tên lên trước
hướng dẫn ngắn; cuối6pass. UID test cần giữ subscription Auth trước await.future;
đã sửa và full385pass. Không bỏ assertion hoặc nới Rules lấy pass.
Android final: emulator-5580/HealthMateMaintenanceQA/API30/demo-healthmate-rules,
10checkpoint +H1portion/H2recent vàtemplate UI pass176s. Tạo mẫu2món từ draft,
hủy không log; dùng/chỉnh100g +20grecipe nguồn đã xóa =180kcal đúng ngày/Bữa tối;
xóa mẫu không đổi meal; logoutBriêng tư. Ảnh/flow ở docs/ux/h2.
Lượt Android đầu cần reveal trường lazy sau bố cục mới; lượt sau dùng Rules cũ
trong QA copy nên lưu bị từ chối. Thêm tool/sync_qa_workspace.ps1 đối chiếu241
source/config/asset gồm root Rules rồi final pass. Không deploy production để
sửa lỗi QA copy. Raw logs D:\HealthMateMaintenanceQA\h2-android*.log.
Schema/Rules/rollback và client compatibility trong h2-templates-deployment.md;
local Rules mới chưa deploy, catalog H1 mới chưa import. Không commit/push/AI/billing.
H3–H7 chưa triển khai tại mốc H2; tiếp tục tuần tự theo yêu cầu, còn40% hạn mức5h
ở lần kiểm tra trước Android final.

## H3 checkpoint 19/10/2026 — code/Rules/SDK đạt, Android đang chạy

Chi tiết hành vi, file, schema/rollout, log và các vòng lỗi/sửa trong
[H3 Quick Add](h3-quick-add.md). Ghi100g/100ml/khẩu phần/tổng, kcal-only/macro
optional, unknown khác0; nhật ký/copy/template/history dùng snapshot.
Format32file; analyze sạch9.8s; fullFlutter397/397(52s),focusedcuối13/13(4s);
Rules49/49(13.2s),SDK17/17(23s), importerEmulator151/0retrychanges.
Android H3 đang chạyQA AVDemulator-5580/demo-healthmate-rules, chưa kết luận đạt.
Production chưa ghi/import/deploy, Git chưacommit/push. H4–H7 chưa triển khai.
Hạn mức5h còn7% lần kiểm tra gần nhất; sẽ theo yêu cầu dừng/lưu/tắt máy khi<5%.

### H3 cập nhật kiểm chứng cuối

FullFlutter398/398(56s), analyze sạch10.2s sau fix UI, focused13/13(3s),
Rules49/49(13.5s), SDK17/17(23s). AndroidH3đủ10checkpoint pass206s; hiện chạy
lần cuối sau cải thiện spacing/helper/snackbar từ ảnh kiểm tra. Chi tiết cả lần
lỗi và sửa trong h3-quick-add.md. Hạn mức5h đã<5%(còn4%); chốtH3/dừngH4–H7,
lưu tiến độ và tắt laptop theo yêu cầu. Không commit/push/deploy/importproduction.

### H3 đạt; tiếp tục theo yêu cầu mới sau khi hạn mức reset

Android visual-final đạt200s, đủ10checkpoint/H2templates/H3QuickAdd. Đã xem ảnh
volume-preview mới: khoảng cách/hướng dẫn rõ và không còn snackbar cũ che form.
Nguồn243fileQAđối chiếu. H3 hoàn tất local/Emulator; chưa nghiệm thu production.
Người dùng gửi “tiếp tục đi” sau khoảng nghỉ; kiểm tra mới: hạn mức5h used0%,
còn100%. Chưa có lệnh shutdown nào được thực thi/lập lịch. Tiếp tục H4–H7 theo
lệnh mới, vẫn theo dõi điều kiện<5% và tắt máy ở cuối chuỗi hoặc tại ngưỡng đó.
Các mục “Android đang chạy” ở trên là checkpoint lịch sử, đã có kết quả cuối này.

## H4 — đạt local/Android Emulator

Helper tùy chọn mức duy trì từ FAO/WHO/UNU/Schofield; đầu vào tự chọn, chưa lưu
sinh lý, phạm vi18–59 và đường quay về nhập tay. Xem cách tính, đưa kcal vàoform,
chỉnh rồi xác nhận lưu với ngày hiệu lực; giữ macro/historical target. Không tự
thâm hụt/dư năng lượng hoặc cộng kcal vận động. Quyết định/nguồn/giới hạn và file
chính trong h4-goal-guidance.md; cần chuyên gia rà soát trước phát hành rộng.
Format10file/5đổi rồi9file0; analyze sạch12.9s; focused9/9(7s); full407/407(49s).
Android h4-android-final.log:10checkpoint +H1/H2/H3/H4pass235s trênAVDQA/API30,
demo-healthmate-rules. H4 UIxemkếtquả2670kcal chưa ghi, sửa2600rồiLưu, đọcSDK
đúng2600, ngàytrước1800khôngđổi; BkhôngđọcA. Ảnhdocs/ux/h4/maintenance-estimate.png.
Lượt nativeđầu bị guardchặn vìAVDđãđóng trong khoảngnghỉ; khởi độnglạiđúngAVDQA,
khôngchuyểnsangmáythật. KGP/SwiftShaderwarningscũcòn. H4khôngđổischema/Rules,
khôngdeploy/importproduction, khôngcommit/push, AIgiữtắt. TiếptheoH5.

## H5 — đạt local/Emulator

Báo cáo30/90, giữtuầncũ; mụctiêuđúnghiệulực; trạngtháixácnhậnđủbữa theoUID+
ngày+revision, không tự coi1bữa làđủ. Ngàytrống khônglà0kcalđãăn; macrothiếu giữ
coverage. Range2001sentinel/chặn>2000doc mỗiquery,1–90ngày; lỗi nguồn riêng,
refresh rõ, không thêmrealtime. Cân hiển thịđiểmthật/khoảngcáchthời gian/sốmẫu.
File/schema/rollout và lỗi đãsửa trongh5-period-reports.md. Cleanupday_reviews,
Rulesmớiđãtestnhưngchưadeploy, khôngindexmới/migration/AI/importproduction.
Focused53/53(19s); H5+UID11/11(13s), full417/417(122s) trước thêmtestUIDcuối;
analyze sạch39s. Rules50/50 vàSDK18/18(31s), kểcả2.001waterfixturebịbáooverflow,
xáoriêngfixturetrongfinally. NativeAndroid227s/10checkpoint+H1–H5đạttrênAVDQA/
demo-healthmate-rules: UIxácnhậnngày,30/90tổngkhớpSDK,1ngàyxácnhận, khoảngcũ
trống/next/trởvềvàBriêngtư. Ảnhdocs/ux/h5/period-30.png. Khôngcommit/push/deploy.
Tiếp theoH6; H7chưatriểnkhai. Hạnmức5h lần gầnnhất còn66%, tiếptụctheodõi.


## H6 — đạt local/Emulator, chưa triển khai production

Thêm chất xơ có nguồn, phân biệt 0 thật/thiếu/tổng biết một phần; giữ coverage khi
nhân khẩu phần, recipe yield, snapshot, sửa/copy/bữa mẫu và báo cáo. Nguồn 4 ID
USDA có sẵn; branch 155 mục, production dry-run 158 đang có/3 create/51 metadata/
0 conflict/152 skip, không apply. Hợp đồng meal4, custom/recipe2, template3,
chống hạ phiên bản và rollout/rollback xem h6-fiber.md và database-design.md.
File chính: nutrition_models/catalog_food_reader, firebase_nutrition_repository,
food_library models/forms/text/repository, quick_add_dialog, meal_templates,
journal/weekly summary, firestore.rules, legacy_usda.json, importer và tests.
Format 59 file/0 đổi ở kiểm tra cuối; analyze sạch (62.1s); Flutter423/423(67s);
unit H6 mới nhất5/5 sau thêm assert round-trip. Rules51/51, importer Emulator155
create/retry0change, Firebase Flutter Web SDK19/19(43s), gồm thiếu nguồn, retry,
A/B, cleanup và H5 overflow2.001rows. Android QA API30/emulator-5580 +
demo-healthmate-rules: 10checkpoint và H1–H6 đạt239s; 250ml/100ml ->3g, nguồn
recipe đã xóa nhưng bữa cũ vẫn0.5g, B riêng tư. Lượt native đầu221s thất bại do
assert nhầm recipe một nguyên liệu biết chất xơ thành thiếu; sửa kỳ vọng và đọc
lại bản ghi thật rồi chạy lại. Các lỗi Rules/codec phát triển ghi ở h6-fiber.md.
Ảnh h6/fiber-volume.png và ảnh H5 mới đã xem: nút xác nhận rõ, preview3g,
macro thiếu không thành0, nội dung báo cáo có thể cuộn. Còn cảnh báo KGP/
SwiftShader/Impeller cũ; cần xem thêm máy thật. Không commit/push/deploy/index/
import production/AI. H6 hoàn thành; tiếp H7 theo yêu cầu, theo dõi ngưỡng5%.


## H7 — checkpoint chưa hoàn thành, dừng do hạn mức còn 4%

Đã chốt lõi CSV thuần journal_csv.dart + test/h7_csv_test.dart:4/4 qua; định dạng
UTF-8 BOM/CRLF/quote, chặn formula injection, range1–90 ngày, dateKey/UTC/offset/
schema và missing/0/partial. Chưa nối UI/controller/file picker hoặc quyền UID
cho export; chưa lưu/phục hồi draft bền vững. Không gọi đây là H7 hoàn chỉnh.
Format2file; analyze lượt đầu1lint thiếu ngoặc, đã sửa; lượt cuối xem log và
h7-checkpoint.md. Không chạy lại toàn bộ suite sau4test mới; fullH6 trước đó423/423,
Rules51/51, SDK19/19, Android239s/10checkpoint+H1–H6 đã đạt. H7 chưa testAndroid.
Không có package/collection/Rules/index/localstorage mới cho H7, không production
write/commit/push. Còn lại và hướng nối tiếp ghi rõ h7-checkpoint.md. Theo chỉ thị
người dùng, lưu checkpoint và tắt máy bình thường sau khi chốt phần CSV này.


Chốt checkpoint H7: analyze cuối sạch (11.5s), format2file; CSV4/4. Bản sao323file nguồn/tài liệu và log nằm ở D:/HealthMateMaintenanceQA/h0-h6-h7-checkpoint-20261019; patchtracked riêng h0-h6-h7-working-tree.patch. H7 còn thiếu đúng như danh sách trên, không công bố hoàn tất.

## H7 — hoàn thành local/Android Emulator sau khi tiếp tục

Tiếp tục từ checkpoint 4% sau khi cửa sổ 5 giờ reset; H0–H6 và toàn bộ thay đổi
chưa commit được giữ. H7 hoàn thành, không tự chuyển mốc khác. Hạn mức được đọc
ở các mốc; không cần dùng lý do hạn mức để bỏ phần nghiệm thu còn lại.

- Android giữ nháp mã hóa AES-256/GCM, khóa AndroidKeyStore và AtomicFile trong
  noBackupFilesDir. UID/ngày/bữa, snapshot nguồn, unit, missing/0/partial, UTC,
  offset, operationId và minimum schema giữ xuyên restart. Tối đa20nháp/512KiB,
  TTL7ngày, dọn khi mở kho; khôi phục/bỏ nháp do người dùng chọn, không tự submit.
- Mọi entry point MealFormDialog nối cùng kho. Lưu operationId+payload local
  trước gửi Firestore; chỉ dọn sau ack. Gián đoạn có thể vẫn commit; retry giữ
  ID cũ, không mặc định lỗi Future đồng nghĩa chưa có bản ghi máy chủ.
- Cá nhân có Xuất nhật ký CSV, ngày1–90, bốn nguồn nhật ký/cân nặng, query giới
  hạn H5; không export profile/chat/goals/draft và không gọi đây là toàn bộ account.
  CSV BOM/CRLF/quote/chặn công thức, schema/đơn vị/timezone/basis và nutrient status.
  Consent riêng tư, Android document picker, kiểm tra UID trực tiếp SDK và phiên
  trước ghi bytes, native đọc lại khớp mới báo thành công. Không email/upload tự động.
- Xóa tài khoản dọn nháp đúng UID sau Firestore/trước Auth; lỗi giữa chừng giữ Auth
  cho retry, chặn callback trễ ghi lại. Không xóa B hoặc CSV người dùng đã xuất.
- Sửa hai guard ref.mounted ở userProfileProvider/bodyMetricsProvider: lỗi cũ được
  native H7 phát hiện khi đổi UID lúc bootstrap, trực tiếp chặn nghiệm thu A/B.
  Không refactor toàn bộ profile; regression có completer theo sự kiện thực.

File chính: core/data/private_local_data.dart; Android PrivateLocalData.kt và
MainActivity.kt; meal_drafts/data/meal_draft_store.dart, presentation/draft_picker.dart;
MealFormDialog, JournalScreen, MealDraft; data_export/models/journal_csv.dart,
data/journal_export_service.dart, presentation/journal_export_dialog.dart;
ProfileScreen, auth repository/currentUid và controller cleanup; profile_providers;
test/h7_csv_test.dart, h7_private_data_test.dart; integration_test/h7_private_data_test.dart;
tool/test_h7_android.ps1 và verify_h7_export.ps1. Đường dẫn/contract đầy đủ:
[h7-private-data.md](h7-private-data.md), ảnh và chứng cứ [ux/h7](ux/h7/README.md).

Kiểm tra cuối (19/10/2026):
- flutter test --no-pub: **454/454 qua, 43s**, build/h7-flutter-final-6.log.
- flutter analyze --no-pub: **No issues found, 17.4s**, build/h7-analyze-final-5.log.
- Native QA: **phase1 12s + phase2 32s, exit0**; D:/HealthMateMaintenanceQA/h7-android-final.log
  và c6-workspace/build/h7-android/phase-1.log, phase-2.log. Process death/restore,
  offline/uncertain commit/retry, OS picker/file readback, UID switch và A/B cleanup đều qua.
- tool/verify_h7_export.ps1: **file Downloads1554byte khớp từng byte** với CSV từ
  repository thật; BOM và đủ bốn loại dữ liệu. build/h7-export-final.log.
- H7 không sửa Rules/indexes. Bộ Rules51/51, Web SDK19/19 và native H0–H6 trước đó
  vẫn là kết quả lịch sử đã ghi, không giả là vừa chạy lại các suite đó trong H7.

Các lượt phát triển thất bại được giữ log: lỗi dùng navigator context của màn
thay dialog; thêm nút export làm test vị trí metric cần sửa layout; lỗi provider
đã disposed (đã thêm guard); runner Windows ExitCode/file sharing và chờ frame
khi OS picker mở (sửa harness). Một kỳ vọng offline=0 sau reconnect không đúng
hợp đồng acknowledgement; giữ assert chưa tự gửi trước Lưu, sau retry đúng một
ID trên server. Bài regression đầu có chờ theo thời gian bị flaky; đổi sang
completer/sự kiện bootstrap, full suite452qua. Script đọc CSV ban đầu quote sai
đường dẫn có khoảng trắng qua exec-out; đã sửa và đối chiếu byte thật, không bỏ assert.

Không thêm package, collection, Rules/index hoặc migration H7. Không commit/push,
không deploy Firebase/import production, không bật AI/billing hoặc sửa package ID.
Production vẫn cần review/ủy quyền rollout Rules/schema H2–H6 và catalog manifest
riêng; APK E2E trỏ demo không phải APK phát hành. Web/desktop chưa có nháp bền vững
hoặc lưu CSV; local không đồng bộ nhiều thiết bị, không xóa được bản sao offline
trên thiết bị khác, file CSV do người dùng quản lý. Cần QA điện thoại thật và cấu
hình release/signing còn thiếu như release-readiness.md. Đề xuất tiếp theo: review
rollout và kiểm tra máy thật; **không triển khai** trong lượt này.

Đóng kiểm tra: dart format --output=none --set-exit-if-changed trên toàn bộ76file
Dart thay đổi: 0file cần format, exit0. git diff --check với cr-at-eol phù hợp
Windows: exit0; không thay line ending hàng loạt. HEAD vẫn
1c258b37366d47ef562eed65f326e490efabae99, không stage/commit/push. Ảnh export đã xem
và lưu docs/ux/h7/export-android.png. Chỉ định tiếp theo là review/máy thật, không
chạy thêm giai đoạn hoặc deploy. Sau khi sao lưu, tắt máy bình thường theo chỉ thị
người dùng; không dùng /f để ép mất tài liệu đang mở.

Bổ sung chốt hồi quy H7 trên bố cục cuối:
- Android core H0–H6: 221s, đủ10checkpoint và H1–H6, exit0;
  D:/HealthMateMaintenanceQA/h7-core-regression-3.log. Recent vẫn3tap; U1 kiểm tra
  vùng bấm thêm bữa trong viewport đầu thật. Hai thao tác hủy hẳn trong fixture
  dùng Bỏ bản nháp để phù hợp UX H7, không bỏ các assert dữ liệu/ngày/snapshot.
- Lượt core đầu phát hiện nút nháp riêng đẩy nút thêm bữa xuống: chuyển thành icon
  cạnh Bữa ăn. Lượt sau cho thấy nút bỏ nháp trong body khó truy cập khi cuộn:
  đưa lên AppBar, chống bấm lặp. Test360/chữ2/tối phát hiện dropdown bữa tràn1.2px;
  isExpanded xử lý đúng, không giảm cỡ chữ/ẩn lỗi. Test xóa nháp lỗi rồi retry và
  xóa account lỗi server/local giữ Auth, giữ UID B đã bổ sung; full cuối454/454.
- H7 native chạy lại trên bố cục cuối:12s/32s, exit0. Đọc lại file Downloads thật
  sau lượt cuối vẫn1554byte khớp từng byte. Không dùng ảnh cũ để kết luận UI mới;
  ảnh journal-android.png lấy từ core lượt đã qua, đã kiểm tra bằng mắt.

Bản sao cuối gồm nguồn/tài liệu chưa commit và log kiểm chứng: D:\HealthMateMaintenanceQA\h0-h7-complete-20261019-191713. Hạn mức được kiểm tra trước tắt máy; không đợi xuống dưới5% vì công việc đã hoàn tất.

## 20/10/2026 — Sửa lỗi build barcode trên code GitHub hiện tại

Phạm vi: đồng bộ GitHub và sửa lỗi `await controller.dispose()` trong ảnh người
dùng gửi; không triển khai thêm giai đoạn hoặc refactor luồng tìm món.

- Đã đọc AGENTS.md, kiểm tra trạng thái/diff, Flutter, dependencies, Android và
  các caller của scanner. Working tree sạch trước khi sửa. `git fetch origin`
  và `git pull --ff-only origin main`: Already up to date, HEAD/origin/main đều
  `8702565` (không cần ghi đè hoặc merge thay đổi cục bộ).
- `pubspec.lock` và package_config cùng trỏ `mobile_scanner 4.0.1`.
  SDK cài trên máy khai báo `void MobileScannerController.dispose()`;
  dùng `await` với kết quả void gây lỗi compile, không phải lỗi Kotlin.
  BarcodeScannerService.dispose chuyển sang void và gọi controller.dispose()
  đồng bộ; giữ reset controller về null trước khi giải phóng. Caller trong
  State.dispose vốn không await nên không cần sửa màn hình.
- Analyze ban đầu có 8 error, 24 info. Ngoài scanner còn 7 lỗi truy cập
  FoodCatalogItem.per100g nullable trong test. Thêm non-null assertions cho
  các fixture vốn yêu cầu có dữ liệu dinh dưỡng; giữ nguyên expected values,
  không thay bằng 0, bỏ test hoặc đổi nullable contract của model.

File sửa:
- lib/features/food_scanner/data/barcode_scanner_service.dart
- integration_test/core_acceptance_test.dart
- test/firebase_production_qa.dart
- test/firebase_repository_integration.dart
- test/h6_fiber_test.dart
- docs/implementation-progress.md

Kiểm tra thực tế (Flutter 3.44.1, Dart 3.12.1):
- `dart format` 5 file Dart sửa: 0 file cần đổi định dạng, exit 0.
- `flutter analyze --no-pub`: **0 error, 0 warning, 23 info**, exit 1;
  chưa đạt analyze sạch. Info gồm withOpacity deprecated, avoid_print và http
  đang nằm ở dev_dependencies nhưng được import trong lib. Không tắt lint.
  Logs: build/barcode-analyze-before.log và barcode-analyze-after.log.
- `flutter test --no-pub --reporter expanded`: **406 qua, 48 lỗi**, 49s,
  exit 1. Log đầy đủ: build/barcode-flutter-test.log. Các nhóm lỗi:
  core_journal 9, core_scope 6, food_catalog 3, food_library 7,
  maintenance_regression 6, nutrition_targets 6, nutrition 1, progress 6,
  u1_ux 4. Có lỗi không tìm thấy widget/source cũ và RenderFlex overflow
  ở bố cục chữ lớn. Chưa sửa các nhóm này trong nhiệm vụ sửa build barcode.
- `flutter test --no-pub test/food_scanner_test.dart test/h6_fiber_test.dart
  --reporter expanded`: **12/12 qua**, exit 0;
  build/barcode-related-test.log. Đây là test scanner ảnh và fiber hiện có,
  không phải bằng chứng camera barcode đã được kiểm thử trên điện thoại.
  Log có fallback SQLite chưa init/USDA400 trong widget harness; test vẫn qua,
  không che những thông báo này hoặc coi đó là kiểm thử API thành công.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug 54.1s,
  exit 0; build/barcode-build-debug.log. APK tại
  build/app/outputs/flutter-apk/app-debug.apk.
  KGP warning với các plugin Firebase/mobile_scanner vẫn còn; không chặn
  build hiện tại. Không nâng package/AGP/Kotlin để xử lý cảnh báo riêng này.

Người dùng: dừng phiên debug lỗi rồi F5 lại, chọn điện thoại Android; cần thử
quyền camera và mở/đóng barcode trên máy thật. Chưa chạy/cài APK lên điện thoại
hoặc chạy các test emulator/production QA trong lượt này. Chưa xác nhận toàn bộ
app ổn định vì full suite còn 48 lỗi. Không thêm package, không sửa Rules/index,
không deploy Firebase, không commit/push thay đổi sửa lỗi. Đề xuất công việc
tiếp theo: xem xét riêng lỗi hồi quy giao diện/tìm món và khai báo dependency
http trong bản GitHub mới; chưa triển khai.

## 20/10/2026 — Sửa lỗi bảng màu sau commit giao diện ba0557d

Phạm vi: sửa các lỗi compile trong ảnh người dùng gửi sau khi chạy bản giao diện
mới. Git sạch trước sửa, HEAD ba0557d. Đã đối chiếu design_tokens.dart,
app_colors.dart, DashboardHeroSection, AppTheme và phiên bản tokens trước đó.

- Commit giao diện xóa thang cyan trong khi theme/hero vẫn tham chiếu các màu,
  đồng thời khai báo orange500 hai lần với cùng giá trị.
- Khôi phục cyan600/400/300/200/100/50 theo đúng giá trị trước commit; giữ
  cyan500, các màu navy/blue và các component MyFitnessPal mới. Bỏ duy nhất
  khai báo orange500 bị trùng, giữ màu orange500 hiện có cho macro/semantic.
- File nguồn sửa: lib/core/theme/design_tokens.dart. Chạy dart format trên
  file này; các thay đổi spacing comment khác trong diff do formatter.
- Tài liệu cập nhật: docs/implementation-progress.md. Không đổi nghiệp vụ,
  dependency, Android Gradle/Kotlin, Firebase Rules hoặc indexes.

Kiểm tra thực tế:
- `dart format lib/core/theme/design_tokens.dart`: thành công; kiểm tra lại
  `--output=none --set-exit-if-changed` không cần thay đổi.
- `flutter --no-version-check analyze --no-pub`: **0 error, 0 warning,
  23 info**, exit 1, 6.1s. Chưa đạt analyze sạch; vẫn có các lint withOpacity,
  print, http dependency đã nêu ở báo cáo sửa barcode. Logs:
  build/palette-analyze-before.log và build/palette-analyze-after.log.
- `flutter --no-version-check test --no-pub --reporter expanded`:
  **406 qua, 48 lỗi**, exit 1, 47s; build/palette-flutter-test.log.
  Đối chiếu chính xác tên từng case lỗi với build/barcode-flutter-test.log:
  hai tập cùng 48 case, không có case lỗi thêm/bớt. Chưa sửa các lỗi giao diện,
  tìm món/fixture cũ ngoài phạm vi khôi phục tokens; không bỏ test/đổi expected.
- `flutter --no-version-check build apk --debug --no-pub`: **thành công**,
  exit 0, assembleDebug 25.1s; build/palette-build-debug.log.
  APK: build/app/outputs/flutter-apk/app-debug.apk. KGP warning vẫn xuất hiện
  nhưng không chặn bản build này. Không tuyên bố đã kiểm thử trên máy thật.

Người dùng: dừng phiên debug lỗi rồi F5 lại từ lib/main.dart và chọn điện thoại.
Cần kiểm tra giao diện sáng/tối trên máy thật. Không commit/push hoặc deploy
Firebase trong lượt sửa lỗi này. Tiếp theo đề xuất: xử lý riêng 48 case hồi quy
đã ghi nhận và 23 info; không tự mở rộng nhiệm vụ sang các thay đổi đó.

## 20/10/2026 — Hoàn thành đợt UI/UX theo ảnh MyFitnessPal

1. **Giai đoạn:** tích hợp lại trải nghiệm theo năm ảnh tham chiếu người dùng;
   không triển khai giai đoạn backend khác. Bảo toàn bản sửa tokens chưa commit
   từ lượt trước. Nền Git vẫn ba0557d, không reset/pull đè thay đổi cục bộ.
2. **Đã hoàn thành:** Hôm nay chọn ngày, header giữ khi cuộn; calo/macro thật;
   bốn thẻ bữa, ghi bữa đúng loại/ngày, dùng lại bữa trước phải xác nhận; thêm nước
   nhanh; Hôm nay–Tiến độ–Thêm và +; tab biểu đồ năng lượng/chất/cân nặng/nước/
   vận động; chi tiết báo cáo, 30/90 ngày và nút xuất CSV thật. Mục tiêu/nhiệm vụ
   có nhãn ngày đang xem. Các route Auth/Nhật ký/Quest/Chat/Cá nhân vẫn được giữ.
3. **File chính:** core/theme/app_colors.dart, design_tokens.dart;
   core/widgets/app_shell.dart, tracking_page.dart; dashboard_screen.dart,
   dashboard_goals_card.dart và ba mfp_*_card.dart; progress_screen.dart,
   progress_overview.dart; journal_screen.dart, journal_meal_entry.dart;
   meal_form_dialog.dart, meal_food_sources.dart. Test mới mfp_ui_test.dart,
   mfp_search_test.dart, fake_food_search_service.dart; cập nhật các test UI và
   fixture ProviderScope/DI. Danh sách/thiết kế: [mfp-ui-redesign.md](mfp-ui-redesign.md).
4. **Kiểm thử cuối trên code cuối:**
   - Dart format trên 25 file Dart thay đổi: kiểm tra lại 0 file cần format.
   - `flutter --no-version-check test --no-pub --reporter expanded`:
     **468/468 qua, 52s, exit 0**, build/mfp-flutter-complete.log.
     Gồm 454 test cũ và 14 test mới; không bỏ case hoặc hạ expected để che lỗi.
   - `flutter --no-version-check analyze --no-pub`: **0 error, 0 warning,
     21 info**, 7.7s, **exit 1**, build/mfp-analyze-complete.log. Chưa analyze sạch:
     withOpacity cũ, print trong unified search, http nằm ở dev_dependencies.
     Không disable lint hoặc nâng dependencies để làm xanh báo cáo.
   - `flutter --no-version-check build apk --debug --no-pub`: **thành công,
     assembleDebug 16.4s, exit 0**, build/mfp-build-complete.log. APK:
     build/app/outputs/flutter-apk/app-debug.apk. KGP warning vẫn còn.
   - 24 ảnh widget QA: docs/ux/mfp/, sáng/tối, 390×844, textScale 1.0/1.5;
     dùng font asset thật, dữ liệu tổng hợp. Đã xem các ảnh Hôm nay, Bữa ăn,
     Tiến độ, Cân nặng, Macro. Suite cũ cũng chạy layout 360/390/412, chữ đến 2.0.
   - Test tương phản >=4.5:1 cho chữ chính/phụ, nút và bốn cặp màu chỉ số;
     ngày trống/loading/error, đổi ngày khi đang tải, mục tiêu lỗi riêng biệt;
     copy không ghi trước xác nhận; tab báo cáo chỉ một lần đọc range; export
     mở đúng dialog; hai test tìm kiếm trả kết quả đảo thứ tự vẫn giữ query mới.
5. **Cần người dùng làm:** dừng debug cũ, F5 từ lib/main.dart; chọn Thêm →
   Giao diện → Tối để xem kiểu tối trong ảnh. Kiểm tra máy thật theo checklist
   trong mfp-ui-redesign.md, đặc biệt bàn phím/chữ lớn/camera/offline/xuất CSV.
6. **Vấn đề/giới hạn:** 21 info chưa xử lý; chưa QA thiết bị thật hoặc xác minh
   USDA/Open Food Facts/mã vạch online trong lượt này. Widget test dùng fake
   external search để không truy cập API thật hoặc plugin SQLite trên host.
   Chưa chạy lại security emulator vì không đổi Rules. Không đổi schema,
   indexes, pubspec/dependencies, Android config, AI hoặc billing. Không commit,
   push, deploy Firebase hoặc nhập dữ liệu production.
7. **Tiếp theo đề xuất:** nghiệm thu trên điện thoại và chỉnh chi tiết theo phản
   hồi thực tế; chưa triển khai giai đoạn mới.

Những lỗi từng ghi ở đợt sửa build (406 qua/48 lỗi) là kết quả lịch sử trước đợt
UI này; trạng thái cuối hiện tại là 468/468 qua. Đã sửa luồng duyệt món trống,
search trả chậm, ProviderScope thiếu ở fixture cũ và layout/locator do đổi giao
điện; không che những lượt thất bại. Log phát triển, gồm fixture ảnh cân nặng
thiếu createdAt/updatedAt trước khi được bổ sung, được giữ trong build/mfp-*.

### 2026-10-20 — Điều hướng 5 ô và hiển thị lại tính năng

1. **Phạm vi:** yêu cầu bổ sung sau đợt UI MyFitnessPal; chỉ sửa điều hướng và
   khả năng tìm thấy tính năng sẵn có, không triển khai giai đoạn nghiệp vụ mới.
2. **Đã hoàn thành:** thanh điện thoại có đúng 5 ô Hôm nay / Nhật ký / + / Tiến độ /
   Thêm, + ở giữa. Menu + có Quét món, thêm bữa/nước/vận động/cân nặng và lối tắt
   Mục tiêu/Nhiệm vụ, Chat. Hai mục sau cũng được đưa lên đầu màn Cá nhân (Thêm).
   Khi mở Quest/Chat, Thêm vẫn được đánh dấu đang chọn. Quét mã vạch được đưa ra
   phần chung của form bữa ăn nên không bị ẩn khi dùng MealFoodSources.
   Nút này chặn mở khi đang lưu/bỏ nháp và khi đã đủ 5 món.
3. **File chính:** lib/core/widgets/app_shell.dart,
   lib/core/config/app_feature_flags.dart,
   lib/features/dashboard/presentation/dashboard_screen.dart (đổi key icon nhật ký
   trên header để tránh trùng key tab mới),
   lib/features/profile/presentation/profile_screen.dart,
   lib/features/nutrition/presentation/meal_form_dialog.dart,
   test/navigation_features_test.dart, test/core_scope_test.dart,
   test/core_journal_test.dart, README.md và docs/mfp-ui-redesign.md.
4. **Kiểm thử thực tế:** dart format 8 file Dart của đợt này qua, kiểm tra lại 0 file
   thay đổi; flutter test --no-pub --reporter expanded qua **485/485** trong 60 giây;
   flutter analyze --no-pub còn **21 info, 0 warning, 0 error**, exit 1;
   flutter build apk --debug --no-pub qua, assembleDebug 26,3 giây. Log nằm ở
   build/navigation-full-test-final.log, build/navigation-analyze-final.log,
   build/navigation-build.log. Bộ điều hướng/core ban đầu qua 50 test.
   Một lượt full trước đó có 484 qua/1 lỗi locator sửa khẩu phần ở dưới vùng nhìn;
   test được bổ sung thao tác cuộn thật, không bỏ assertion dữ liệu; 36 test nhật ký
   sau sửa và toàn bộ suite sau cùng đều qua.
5. **Cần người dùng làm:** dừng phiên chạy cũ và F5 lại (để áp dụng cờ compile-time);
   kiểm tra camera quét ảnh/mã vạch, điều kiện AI, mạng/App Check trên máy thật.
   Mặc định Scanner/Chat hiển thị, không cần define=true; nếu launch cũ truyền
   define=false thì bỏ chúng. Vẫn hỗ trợ build core-only qua hai define=false.
6. **Giới hạn:** chưa QA camera hoặc gọi dịch vụ AI/API mã vạch thật trong lượt này.
   Việc hiện nút không chứng minh cloud/camera đã hoạt động. Kiểm tra hồ sơ 18+,
   consent trước gửi AI, quyền UID, luồng xác nhận lưu bữa vẫn được giữ. Mở tab/menu
   không tự gửi ảnh/câu hỏi. 21 info và cảnh báo Kotlin plugin còn tồn tại.
   Giữ toàn bộ thay đổi chưa commit trước đó; không sửa package/schema/Rules/index,
   không commit/push/deploy hoặc thay dữ liệu Firebase production.
7. **Tiếp theo đề xuất:** nghiệm thu 5 ô và scanner/chat trên điện thoại; chưa thực hiện
   giai đoạn mới.

### 2026-10-20 — Rút gọn thông tin ở các màn chính

1. **Phạm vi:** phản hồi UI quá nhiều thông tin; chỉ tinh gọn trình bày và cách mở
   chi tiết, không đổi nghiệp vụ hay triển khai giai đoạn mới.
2. **Đã hoàn thành:** Hôm nay ưu tiên kcal/macro/bữa/ghi nhanh. Mục tiêu dinh dưỡng,
   Goal/Quest và tổng kết tuần chuyển vào “Mục tiêu và tổng kết” mặc định đóng,
   chỉ dựng nội dung khi mở. Bỏ nút tiến độ trùng với tab, dòng UTC cố định chuyển
   vào tooltip ngày. Thẻ chỉ số nhỏ hơn, bớt nhãn lặp; thẻ bữa bớt câu rỗng và giới
   hạn tên dài (nhật ký vẫn xem đủ). Nút ⓘ mở hướng dẫn dinh dưỡng/nước/vận động/
   khẩu phần. Nước chỉ hiện ml; form bữa đếm n/5 ngắn. Cá nhân bỏ email lặp.
   Thanh dưới 5 ô và Scanner/Chat vẫn được giữ. Thông báo lỗi, thao tác lưu, xác
   nhận và consent AI/nhãn ước tính không bị ẩn. Dấu — vẫn phân biệt với 0.
3. **File:** danh sách đầy đủ theo khu vực ở docs/compact-ui.md; 2 widget chung mới
   details_disclosure.dart và information_button.dart; các màn Dashboard/Journal,
   meal_form_dialog/meal_log_section, water_log_section, Profile; thêm
   test/compact_ui_test.dart và cập nhật thao tác mở chi tiết/nhãn trong test cũ.
4. **Kiểm thử:** dart format 20 file Dart thuộc lượt này, kiểm tra lại 0 thay đổi;
   flutter test --no-pub --reporter expanded **490/490 qua**, 65 giây, exit 0;
   flutter analyze --no-pub **21 info, 0 warning/error**, exit 1 (21,7 giây);
   flutter build apk --debug --no-pub qua, assembleDebug 49,1 giây, exit 0.
   Log build/compact-full-final.log, compact-analyze.log, compact-build.log.
   Các lượt phát triển có lỗi text/locator sau đổi chữ và mở chi tiết; đã sửa cách
   thao tác/giới hạn finder, không bỏ assertion tính toán, không skip test. Lượt
   full trước cuối 489 qua/1 lỗi nhãn thiếu macro; cuối cùng giữ giải thích ngắn
   “Dấu —: chưa có số liệu, không phải 0.” và toàn bộ test qua.
5. **Cần người dùng làm:** chạy lại app, kiểm tra bố cục/cỡ chữ/sáng tối trên điện
   thoại; bấm mục mở rộng và ⓘ khi cần chi tiết. Hướng dẫn ở docs/compact-ui.md.
6. **Giới hạn:** chỉ QA widget/render và build; chưa thử tương tác thiết bị thật,
   camera hoặc gọi API AI/mã vạch. 21 info và cảnh báo Kotlin plugin còn tồn tại.
   Không đổi nguồn dữ liệu, package, schema, Rules/indexes, không commit/push/
   deploy hay cập nhật dữ liệu Firebase production; bảo toàn thay đổi trước đó.
7. **Tiếp theo đề xuất:** nghiệm thu trực quan trên điện thoại, chờ phản hồi;
   không tự triển khai thêm.

## 23/10/2026 — Giai đoạn 5: sửa quét mã vạch, mở rộng kết quả ảnh và lưu món riêng

1. **Trạng thái/phạm vi:** hoàn thành mã nguồn và kiểm thử local theo yêu cầu mới.
   Sửa lỗi barcode liên quan; chưa nghiệm thu thiết bị/cloud AI/production.
   Nền Git `63cda3f`, working tree sạch trước khi bắt đầu; không commit/push/deploy.
2. **Hành vi:** giữ đúng khẩu phần barcode, tính kcal/macros/chất xơ theo gram,
   chặn input không hợp lệ, giữ missing khác 0, phân biệt lỗi mạng/quota và không
   tìm thấy. Quét ảnh trả tên/mô tả/thành phần, kcal/macros/chất xơ trên 100 g và
   theo khẩu phần. Catalog ưu tiên, AI chỉ ước tính; unknown giữ null/chưa có dữ
   liệu. Món chưa có mở form kiểm tra và lưu vào Món của tôi, có UID guard/retry
   cùng ID. Lưu thư viện riêng rồi mới xác nhận và lưu bữa với đúng gram/snapshot.
3. **File chính:** `lib/features/food_scanner/{data,models,presentation}`;
   `food_library/presentation/library_forms.dart`; form bữa ăn và hai file
   journal meal entry/screen; `test/barcode_scanner_test.dart`,
   `test/food_scanner_test.dart`; README, database-design và scanner-update.md.
4. **Kiểm thử thực tế:**
   - Dart format các file liên quan: thành công; kiểm tra cuối ghi ở test-report.
   - `flutter --no-version-check test --no-pub --reporter expanded`:
     **501/501 qua**, 54 giây, exit 0; `build/scanner-full-test.log`.
   - `flutter --no-version-check analyze --no-pub`: **20 info, 0 warning/error**,
     exit 1, 11,1 giây; `build/scanner-analyze.log`. Không có lint mới; đã sửa
     withOpacity trong barcode screen đang chỉnh. Các info cũ còn ở glass/skeleton,
     print search và http nằm trong dev_dependencies. Không gọi analyze sạch.
   - `flutter --no-version-check build apk --debug --no-pub`: **qua**, 37,6 giây,
     exit 0; `build/scanner-build.log`; APK `build/app/outputs/flutter-apk/app-debug.apk`.
   - Firestore demo emulator: **51/51 qua**, không skip; `build/scanner-rules.log`.
     Có kiểm tra hai UID, custom_foods, macro thiếu, chất xơ và schema hiện có.
5. **Cần người dùng làm:** chạy lại app trên Android, kiểm tra camera/quyền,
   App Check debug token hợp lệ và kết quả AI thật. Kiểm tra đồng bộ Rules
   production với schema H0–H7 trước nghiệm thu lưu dữ liệu mới (chưa deploy).
6. **Giới hạn:** không có thiết bị/emulator kết nối qua ADB trong chat này.
   Không gọi AI cloud, tạo tài khoản, thay billing/App Check hoặc dữ liệu production.
   Không cam kết AI suy ra mọi vi chất/dị ứng từ ảnh. Vitamin/khoáng chất chưa
   xác minh hiển thị rõ; mô tả/thành phần quét chưa lưu thêm field trong thư viện.
   Luồng barcode nhập gram, không suy ra mật độ từ ml. Cảnh báo KGP vẫn còn.
7. **Tiếp theo đề xuất:** nghiệm thu Android và kiểm tra/đồng bộ Rules production
   trong yêu cầu riêng; không tự thực hiện giai đoạn khác.

### 2026-10-23 — Đồng bộ mã nguồn theo yêu cầu GitHub

- Phạm vi: commit/push toàn bộ thay đổi UI/test/tài liệu đang có; không làm giai đoạn mới.
- Đã fetch và kiểm tra main không lệch origin/main trước khi gom commit; giữ nguyên
  nội dung sửa trước đó, không reset/clean hoặc loại bỏ chức năng.
- Kiểm tra trước commit: format 40 file không cần sửa; toàn suite 490/490 qua,
  analyze 21 info cũ, 0 warning/error (exit 1); kiểm tra diff whitespace qua.
- Nội dung gồm UI Hôm nay/Tiến độ, thanh 5 ô, lối vào Scanner/Chat/Quest, tìm món,
  phần chi tiết thu gọn, test/fake repository, ảnh fixture và docs/chat-handoff.md.
- Danh sách/rủi ro chi tiết ở docs/mfp-ui-redesign.md, docs/compact-ui.md,
  docs/test-report.md. Không cài dependency, đổi schema/Rules/indexes hoặc deploy
  Firebase. Mã commit và xác nhận remote được cung cấp sau khi push thành công.

## 23/10/2026 — Giai đoạn 5: sửa lỗi phân tích ảnh trên điện thoại

1. **Trạng thái:** hoàn thành bản sửa scanner và xác minh một lượt ảnh thật trên
   Android; người dùng xác nhận “Đã ra kết quả món ăn”. Bảo toàn toàn bộ thay đổi
   chưa commit; không commit/push/deploy backend hoặc chuyển giai đoạn khác.
2. **Hành vi:** scanner mặc định dùng gemini-3.5-flash-lite, thinking minimal;
   ảnh tối đa cạnh 1024 px. Kiểm tra App Check, giới hạn service 40 giây, đóng
   HTTP client khi kết thúc và hiển thị lỗi theo nguyên nhân. Giữ kết quả dinh
   dưỡng/khẩu phần ước tính, catalog ưu tiên và bước xác nhận của người dùng.
3. **File chính:** firebase_food_scanner_service.dart, food_scanner_service.dart,
   food_image_picker.dart, test/scanner_runtime_test.dart, pubspec.yaml/lock,
   README, scanner-update.md và các tài liệu tiến độ/kiểm thử. Chuyển http sang
   runtime dependency cùng phiên bản; không nâng package hay đổi chatbot.
4. **Kiểm thử thực tế:** toàn suite **504/504 qua** (91 giây); analyze **18 info,
   0 warning/error** (exit 1, 7,6 giây); debug APK build qua (57,1 giây). Format
   4 file Dart của bản sửa: 0 thay đổi. Test mới kiểm tra cấu hình/schema,
   phân loại lỗi và HTTP transport/close; parser kiểm tra response cloud thật.
   Không chạy lại rules emulator vì không thay Rules/schema (lượt trước 51/51).
5. **Thiết bị:** cập nhật bằng adb install -r -t thành công, giữ dữ liệu ứng dụng.
   App Check 44 ms, HTTP 200 tại 6743 ms, parse thành công tại 6767 ms; người dùng
   xác nhận đã thấy kết quả. Bằng chứng và giới hạn ở scanner-update.md.
6. **Giới hạn/cấu hình:** chưa xác định được mã lỗi gốc của lượt SDK cũ sau 8,868
   giây; các probe model cũ timeout 30 giây, model mới trả kết quả. Một lượt điện
   thoại thành công không phải cam kết tốc độ hay độ chính xác dinh dưỡng.
   Camera capture và lưu production chưa nghiệm thu lại; Rules H0–H7 production
   vẫn cần kiểm tra riêng. Không thay billing, enforcement App Check hoặc ghi
   dữ liệu production. Analyze còn info cũ và build còn cảnh báo Kotlin Gradle.
7. **Tiếp theo đề xuất:** nghiệm thu camera và lưu món/nhật ký trên Android khi
   được yêu cầu; không tự thực hiện trong lượt sửa phân tích ảnh này.

## 23/10/2026 — Kiểm tra chênh lệch kết quả hai món theo yêu cầu

- Phạm vi Giai đoạn 5: chỉ chẩn đoán kết quả, chưa sửa code hoặc cài lại APK.
- Xác nhận lỗi ghép Cơm trắng chín cho cả đĩa cơm tấm 450 g; lỗi nằm ở substring
  matching, tự chọn phần tử đầu và ưu tiên số catalog dù không cùng phạm vi món.
- Mẫu bít tết quy đổi và hiển thị đúng số AI; chưa có dữ liệu đo để phân xử AI
  nào chính xác. Kết quả app khác không được dùng làm chuẩn dinh dưỡng mặc định.
- Hai widget probe tái hiện qua (2/2); chi tiết ở scanner-update.md/test-report.md.
- Chỉ bổ sung tài liệu, giữ mọi thay đổi chưa commit; không push/deploy.
- Tiếp theo đề xuất: sửa chọn nguồn cho món nhiều thành phần; chưa thực hiện.

## 23/10/2026 — Giai đoạn 5: sửa ghép nguồn dinh dưỡng cho món nhiều thành phần

1. **Trạng thái:** hoàn thành bản sửa mã nguồn và kiểm thử; APK debug đã build.
   Chưa cài lên điện thoại vì cả hai lần `adb devices` đều không có thiết bị.
   Giữ toàn bộ thay đổi trước đó; không commit/push/deploy hoặc chuyển giai đoạn.
2. **Hành vi:** tên/tên tương đương cả món phải khớp đầy đủ; chỉ một kết quả mới
   được tự chọn. SearchTerms, substring và tên nguyên liệu không còn chọn nguồn
   cả đĩa. Nhiều kết quả cần chọn rõ; đổi tên xóa lựa chọn cũ. Chưa khớp giữ
   ước tính AI toàn món; có thể lưu qua form kiểm tra rồi ghi bữa đúng gram.
   Nêu rõ món/nguồn và có nút dùng lại ước tính AI thay cho catalog. Prompt nhắc
   xét toàn đĩa và không cộng dầu hai lần; không đổi model/API/schema/provider.
3. **File chính:** models/food_scan_catalog_matcher.dart mới;
   presentation/food_scanner_dialog.dart và data/firebase_food_scanner_service.dart;
   test/food_scan_catalog_matcher_test.dart mới, test/food_scanner_test.dart;
   README, scanner-update.md và tài liệu tiến độ/kiểm thử.
4. **Kiểm thử:** nhóm scanner **25/25 qua** (13 giây); full suite **512/512 qua**
   (68 giây); analyze cuối **18 info cũ, 0 warning/error**, exit 1 (7,1 giây);
   build APK debug **qua**, assembleDebug 28,4 giây. Format 5 file: 0 thay đổi;
   git diff whitespace check qua. Log chi tiết ở test-report.md.
5. **Cần người dùng làm:** kết nối lại điện thoại USB để cập nhật APK giữ dữ
   liệu và nghiệm thu ảnh thật. Chưa xác nhận bản sửa này chạy trên điện thoại.
6. **Giới hạn:** không đo độ chính xác dinh dưỡng, không cố khớp số Calz/Foodvisor.
   Khớp chặt có thể không tìm thấy món cùng nghĩa nhưng khác tên; vẫn có đường
   tìm rộng/nhập tay. Kết quả chưa tách khối lượng từng nguyên liệu. Chưa gọi lại
   AI cloud trong lượt này. Không đổi dependencies, Rules, schema, billing hoặc
   App Check; cảnh báo Kotlin Gradle còn. Không sửa nhật ký/món đã lưu trước đó.
7. **Tiếp theo đề xuất:** nghiệm thu hai ảnh trên điện thoại và luồng lưu món;
   chưa tự triển khai giai đoạn hay tính năng tiếp theo.

## 23/10/2026 — Giai đoạn 5: hợp nhất thêm bữa ăn, quét ảnh và yêu thích

1. **Trạng thái:** hoàn thành mã nguồn UI, kiểm thử và APK debug theo ảnh tham
   khảo. Cùng một MealFormDialog có Nhập tay/Ảnh/Yêu thích; chưa cài/nghiệm thu
   camera thật vì ADB không có thiết bị. Bảo toàn mọi thay đổi chưa commit.
2. **Hành vi:** nhập tay và lối tắt Quét món mở hai tab của cùng bản nháp. Camera
   preview, nút chụp/thư viện và mã vạch; gửi ảnh chỉ sau consent + Phân tích.
   Kết quả xác nhận hoặc món yêu thích được thêm vào bữa đang có, không mở bữa
   khác. Giữ ngày/loại bữa, giới hạn 5 món, snapshot, UID guard, lưu chờ máy chủ
   và nháp mã hóa. Camera đóng khi đổi tab/xuống nền/chuyển barcode; lỗi quyền
   vẫn có nhập tay/chọn ảnh. Giữ bản sửa nguồn dinh dưỡng cho cả món.
3. **File chính:** food_camera_service.dart, food_camera_view.dart mới;
   meal_form_dialog.dart, food_scanner_dialog.dart, barcode_scanner_screen.dart,
   journal_meal_entry.dart/journal_screen.dart, meal_food_sources.dart, app_shell;
   pubspec.yaml/lock, AndroidManifest.xml; fake camera/test unified meal mới và
   các test scanner/nutrition/navigation/layout; docs/unified-meal-entry.md.
4. **Kiểm thử thực tế:** test mới **6/6 qua**, nhóm hồi quy **70/70** và **18/18**
   qua; full suite cuối **518/518 qua** (67 giây); analyze **18 info cũ, 0
   warning/error**, exit 1 (8,7 giây); APK debug **qua**, assembleDebug 29,9 giây.
   Format 18 file 0 thay đổi; whitespace check qua. AAPT xác nhận APK có CAMERA,
   không RECORD_AUDIO/WRITE_EXTERNAL_STORAGE. Log ở test-report.md.
5. **Cần người dùng làm:** kết nối Android qua USB để cập nhật APK giữ dữ liệu,
   thử quyền camera/ảnh, chụp và quay lại sau xuống nền, barcode rồi lưu cùng bữa.
6. **Giới hạn:** thêm camera chính thức 0.12.0+2 và 5 dependency chuyển tiếp từ
   cache, không nâng package có sẵn. enableAudio=false; loại các quyền video/audio
   và public storage plugin khai báo thừa. Native preview/capture/barcode chưa
   nghiệm thu trên điện thoại. Test dùng fake adapters; screenshot widget camera
   đen là fake session, không giả là ảnh thiết bị. Không đổi AI model/provider,
   backend/schema/Rules/App Check/billing; không push/deploy. KGP warning còn.
7. **Tiếp theo đề xuất:** nghiệm thu Android cho chính luồng hợp nhất này;
   không tự chuyển giai đoạn khác. Cách dùng/nguồn tham khảo ở unified-meal-entry.md.
# Web quản trị — 23/10/2026

1. **Giai đoạn:** mở rộng admin do người dùng yêu cầu, bản local hoàn tất;
   không tự chuyển sang deploy production.
2. **Đã hoàn thành:** web HTML/CSS/JavaScript + Firebase Web SDK, đăng nhập và
   role, CRUD catalog qua thêm/sửa/ẩn, khóa/mở quyền HealthMate qua Firestore,
   config chatbot/scanner/maintenance, nhật ký quản trị nguyên tử. Phân trang
   25, lỗi/empty/loading, phát hiện xung đột timestamp, form có lý do xác nhận.
   Admin không đọc nhật ký sức khỏe. Mobile có remote gate, đồng bộ directory
   tối thiểu và lọc catalog ẩn; cờ rollout mặc định false.
3. **File chính:** `admin-web/` (UI, Firebase adapter, validation, server,
   seed demo, README, tests/font license); `firebase.admin-emulators.json`;
   `firestore.rules`, `rules-tests/admin.rules.test.cjs`, package/test host;
   `lib/core/config/admin_runtime*.dart`, `admin_access_gate.dart`, app,
   AI/feature policy, nutrition/account-data repositories;
   `test/admin_runtime_test.dart`; README/database-design/test-report.
4. **Kiểm thử:** JavaScript syntax qua, 5/5 web unit; Rules **59/59** qua trên
   emulator (8 mới +51 hồi quy); Flutter runtime **5/5**, full **523/523** qua
   (78 giây); analyze **18 info cũ, không warning/error** (35,9 giây, exit 1);
   APK debug build qua (27,7 giây). Format các file Dart mới/sửa qua; diff
   whitespace qua. Thử UI trình duyệt có dữ liệu Firebase Emulator thật: tạo,
   sửa/ẩn món, khóa/mở tài khoản, tắt/bật lại scanner, audit và user không role.
5. **Cần cấu hình:** chưa chọn UID admin thật, chưa cấu hình public Web App/
   domain/App Check, chưa deploy Rules/hosting, chưa bật cờ rollout mobile.
   Các bước trong `admin-web/README.md`; không tự cấp role hoặc nâng billing.
6. **Giới hạn:** account lock không disable Auth/revoke token/chặn AI API ở
   server; directory chỉ gồm tài khoản đã đồng bộ. Bản bật cờ cần server xác
   minh, hạn chế truy cập offline. KGP warning và 18 analyze info cũ còn.
   Browser/CDN và emulator kiểm thử, chưa nghiệm thu production/điện thoại
   cho phần quản trị. Không commit/push/deploy, giữ mọi thay đổi trước lượt.
7. **Tiếp theo đề xuất:** cấu hình và nghiệm thu admin trên Firebase thật sau
   yêu cầu riêng; không thực hiện trong lượt này.
# Hoàn thiện auth mobile — 24/10/2026

1. **Giai đoạn:** mở rộng Giai đoạn 2 — Google, email verification và password
   recovery. Mã app/local QA hoàn tất; nghiệm thu Google/email production còn
   chờ cấu hình và thiết bị. Người dùng bỏ Facebook và tạm gác web admin.
2. **Đã làm:** Google native qua SDK + Firebase, xử lý cancel/config/provider
   collision, khóa bấm trùng; email verification gate trước dữ liệu/onboarding,
   gửi lại 60s, kiểm tra/resume reload user + token; forgot-password dialog có
   xác nhận, lỗi, cooldown, link Firebase tiếng Việt; mật khẩu mới tối thiểu 8,
   đăng nhập vẫn nhận mật khẩu cũ; Google-only ẩn đổi password và reauth bằng
   Google khi xóa. Rules yêu cầu verified claim cho owner health data.
3. **File chính:** auth repository/models/providers/screens, Google identity
   service, route verify-email, profile/bootstrap/reauth, AI gate; Rules và
   tests, `firebase.auth-emulators.json`; `google_sign_in` 7.2.0 + 5 dependency
   chuyển tiếp (không nâng package cũ), logo Google nguồn chính thức;
   `test/auth_completion_test.dart`, verified fixtures và helper C6/H7;
   `docs/authentication-flow.md`, README/schema/test report, snapshot auth.
4. **Kiểm thử:** full Flutter **534/534 qua** (82s); nhóm auth cuối sau chỉnh
   copy/logo **35/35 qua**, gồm 11 test mới và snapshot font thật; Rules
   **60/60 qua** (18s); Auth Emulator email E2E **1/1 qua** (1,3s); APK debug
   build qua (101,4s khi thêm plugin, cuối 10,8s). Analyze 18 info cũ, không
   warning/error; format và whitespace check qua. Chi tiết ở test-report.
5. **Cần cấu hình:** Google IDP thật chưa có (GET trả404), danh sách IDP rỗng,
   Email/Password bật. Cần bật Google, thêm SHA debug/release phù hợp, tải JSON
   có Web OAuth client. Hướng dẫn có SHA thực của máy. Kiểm tra email templates,
   triển khai Rules sau rà soát toàn bộ diff và nghiệm thu bằng email thật.
6. **Giới hạn:** không có ADB device nên chưa cài APK/chạy native C6/H7;
   chưa đăng nhập Google thật hoặc chứng minh email tới inbox production.
   Emulator chứng minh email action/link/token/password, không giao email thật.
   Không tự nâng billing/cấp role/deploy Rules/commit/push; giữ thay đổi cũ.
   Không tiếp tục tính năng web admin. Cờ rollout admin mặc định vẫn false.
7. **Tiếp theo:** cấu hình Google và nghiệm thu cùng luồng auth trên điện thoại;
   chưa thực hiện production/config khi thiếu yêu cầu và public OAuth config.

## Tiếp tục cấu hình Google — 24/10/2026 (chờ email hỗ trợ)

- Người dùng đã yêu cầu bật Google. Đã thêm SHA-1 debug vào đúng Android app
  qua Firebase CLI; đọc lại xác nhận SHA-1 và SHA-256 đã có, không xóa hash cũ.
- Firebase Console đã chuẩn bị tên HealthMate. Chưa lưu provider: chờ xác nhận
  email hỗ trợ sẽ hiển thị công khai cho người đăng nhập, theo quy tắc an toàn
  điều khiển trình duyệt. Chưa thay đổi email/người dùng hay bật Google.
- Tải thử SDK config vào build/: đúng project/package/app ID, OAuth client vẫn
  rỗng. Chưa thay android/app/google-services.json hoặc build lại APK. Không có
  thiết bị ADB; chưa kiểm thử Google thật. Không đổi Rules/billing, không deploy.
- Bước còn lại: xác nhận email, lưu Google provider, tải/cập nhật JSON có OAuth
  client, build APK và nghiệm thu trên điện thoại. Web admin vẫn tạm gác.

## Google production đã bật — 24/10/2026 (thay trạng thái chờ phía trên)

- Người dùng đã xác nhận email hỗ trợ. Lưu Google trên Firebase thành công,
  tên công khai HealthMate; Console Enabled và đọc API200 enabled=true có
  client ID. Email/Password giữ bật, Spark không đổi.
- File chính: `android/app/google-services.json` cập nhật từ CLI, Android client
  đúng SHA-1 debug và Web client_type3. Chỉ OAuth client thay đổi, cấu hình
  Firebase khác giữ nguyên; không đưa client secret vào repo/app. README,
  authentication-flow, handoff/test-report cập nhật trạng thái thực.
- Build APK debug qua11,1s, resource default_web_client_id khớp Web client từ
  JSON; diff whitespace qua. Không sửa Dart nên không chạy lại format/analyze/
  unit suite đã qua ở lượt auth. KGP warning cũ vẫn có.
- Không có ADB device: chưa cài APK hoặc thử Google account thật; chưa chứng
  minh thư xác minh/reset tới inbox. Rules mới chưa deploy, admin vẫn tạm gác.
- Tiếp theo đề xuất: cài APK mới và nghiệm thu auth trên điện thoại. Không tự
  chuyển giai đoạn, deploy Rules/hosting, đổi billing hoặc commit/push.

# Mở rộng chatbot — 25/10/2026

1. **Giai đoạn:** mở rộng Giai đoạn9 theo yêu cầu xây chatbot. Giữ Gemini
   Developer API miễn phí, không backend/package mới, không tiếp tục web admin.
2. **Hành vi:** nhập tiếng Việt có/không dấu; nhật ký một ngày/ngày cụ thể/
   hôm nay/hôm qua/hôm kia/tuần này/tuần trước/7ngày; tổng kcal/macro/fiber,
   nước/phút, cân nặng có ngày đo, lượng còn/vượt so target thật theo từng ngày.
   Câu nối tiếp giữ khoảng ngày, thiếu dữ liệu không thành0 hoặc mục tiêu giả.
   Câu hỏi mục tiêu nước/cân nặng/vận động được giải thích phạm vi, không trả
   nhầm ngân sách kcal. Không tự ghi/sửa/xóa nhật ký hoặc kê chế độ ăn.
3. **AI:**10chủ đề dinh dưỡng/thói quen. Câu tự nhập được map ở app sang enum;
   sau đồng ý chỉ prompt chủ đề cố định được gửi tới Gemini. Không gửi dữ liệu
   cá nhân/history. Model mặc định gemini-3.5-flash-lite, thinking minimal,
  2048output tokens; tài liệu model/điều khoản đã kiểm tra25/10. Chưa là LLM
   tự do có ngữ cảnh sức khỏe hoặc Meal Planner. Giữ giới hạn20lượt/phiên.
4. **File chính:** thêm domain/chat_request.dart, personal_chat_context.dart;
   sửa chat models/KnowledgePrompt/FirebaseKnowledgeService/controller/UI;
   thêm14test trong chatbot_personal_test.dart, cập nhật test navigation theo
   nhãn mới và vẫn kiểm tra composer/route. README/chatbot/schema/handoff/test
   report và4snapshot font thật trong docs/ux/chatbot cập nhật.
5. **Kiểm thử:** nhóm chat32/32qua; full cuối548/548qua (73s), vòng
   chốt có log build/chatbot-personal-accepted-tests.log. Format12file0thay đổi;
   analyze cuối18info cũ,0warning/error,48s exit1; APK cuối build25,7s,
   build/chatbot-personal-build-final.log, vẫn KGP warning cũ. Whitespace qua.
   Không đổi Rules/schema/index nên không chạy lại Rules emulator ở lượt này.
6. **Giới hạn/cần nghiệm thu:** không có ADB device. Chưa cài APK hoặc thử
   Gemini API live. Snapshot và tests dùng repositories fake, không chứng minh
   cloud end-to-end. Cần kiểm tra Android qua Thêm→Chat, dữ liệu thật, target,
   Gemini/quota/mạng/stop/history/đổi UID. Rules verified/schema mới và lỗi USDA
   từ audit chưa sửa/deploy trong lượt này, giữ mọi thay đổi cũ.
7. **Tiếp theo đề xuất:** nghiệm thu chatbot trên Android; chưa thực hiện gợi
   ý thực đơn, billing, deploy Rules/hosting/admin, commit hoặc push.

## 25/10/2026 — Giai đoạn 9, đánh giá API chatbot miễn phí

- Người dùng yêu cầu linh hoạt như MyFitnessPal, giữ miễn phí và làm rõ muốn
  gọi API cloud; không cần tải model vào điện thoại. Chỉ nghiên cứu, chưa tích hợp.
- Đã kiểm tra Git/code/dependencies, giữ nguyên các thay đổi chưa commit. Thêm
  docs/chatbot-free-evaluation.md, cập nhật quyết định trong chatbot-flexible-plan.md.
- Ưu tiên thử Workers AI/Qwen3-30B-A3B-FP8, dự phòng Groq Free; quota, giữ key,
  dữ liệu và proxy ngoài Firebase được ghi rõ. Chưa chốt thay đổi kiến trúc.
- Có bộ 20 tình huống tổng hợp dự kiến. Chưa gọi inference, tạo tài khoản,
  gửi dữ liệu cá nhân hay đo tiếng Việt/độ trễ. ADB không có thiết bị.
- Kiểm tra tài liệu và whitespace; không chạy lại Flutter format/analyze/test/
  build do chỉ sửa Markdown. Không coi kết quả test app trước là benchmark AI.
- Tiếp theo đề xuất: thử API trên dữ liệu tổng hợp trước khi quyết định tích hợp;
  không tự bật billing, deploy, sửa admin/scanner, commit hoặc push.

## 25/10/2026 — Giai đoạn 9, triển khai code chatbot API miễn phí

1. **Trạng thái:** người dùng yêu cầu làm phương án Cloudflare API sau đánh giá.
   Code app/Worker và QA local hoàn tất; **chưa rollout**, chờ tài khoản Cloudflare
   Free. Người dùng nói chưa có tài khoản và sẽ tạo; `wrangler whoami` chưa đăng nhập.
2. **Hành vi đã triển khai:** khi cấu hình URL thật, nhập câu hỏi tự do và tối đa
   3 lượt chat gần nhất cho Qwen lập kế hoạch; app đọc tối đa 3 nguồn hợp lệ, tính
   số liệu qua repositories rồi AI trả SSE. Có consent, tra cứu không gửi AI,
   stop/cancel transport, UID guards, retry lưu cùng ID và không lưu stream dở.
   Không cấu hình URL thì báo rõ chưa kết nối và giữ luồng hiện có.
3. **File chính:** chat-api/src/{auth,index,protocol}.mjs, wrangler.jsonc và README;
   Flutter assistant_request, ChatDataReader, ChatAssistant/CloudflareChatAssistant,
   assistant_providers; sửa controller/UI chat, test helper và chatbot_api_test.dart.
   Không đổi schema/Rules/index/Firebase billing, scanner/USDA hoặc admin.
4. **Kiểm thử thực tế:** Flutter full cuối **569/569 qua, 56s**;
   build/chat-api-full-tests-final.log. Nhóm chat trước thêm layout **51/51**, 6s;
   capture layout **2/2**, 2s, 4 PNG font thật 360px/100–200%, đã xem trực quan.
   Analyze cuối **18 info cũ, 0 warning/error**, 6,8s, exit1. Format 17 file không
   thay đổi; whitespace qua. APK debug cuối build **10,9s**, exit0, còn KGP warning
   cũ; build/chat-api-android-build-final.log. APK chưa đóng URL thật/chưa cài máy.
5. **Worker:** **18/18 test qua**, có JWT RSA ký/verify thật với key test; kiểm
   tra project/verified/expiry/App Check app/UID/schema/body/rate/stream. AI binding
   dùng fake, không coi là model benchmark. Node syntax check, npm audit **0**,
   Wrangler dry-run bundle **48,14 KiB** qua; logs chat-api-worker-tests/build.log.
   Pin jose 6.2.13, Wrangler 4.152.0; override undici 7.30.1 sửa dev dependency audit.
6. **Còn chờ:** chủ dự án hoàn tất Cloudflare Free, đăng nhập CLI, xác nhận account,
   triển khai Worker, build URL thật rồi nghiệm thu Qwen/JSON/SSE/JWKS/CPU/quota và
   tiếng Việt/latency trên Android. ADB không có thiết bị; chưa có API call live,
   chưa gửi dữ liệu thật cho provider. Không tuyên bố chất lượng ngang MyFitnessPal.
7. **Tiếp theo đề xuất:** kết nối và nghiệm thu API đã chuẩn bị sau khi tài khoản
   sẵn sàng, vẫn trong giai đoạn 9. Không chuyển giai đoạn khác hoặc tự nâng Paid,
   deploy Firebase/admin, commit hay push. Setup cụ thể: chat-api/README.md.
