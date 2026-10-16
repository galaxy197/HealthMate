# Tiến độ HealthMate

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
