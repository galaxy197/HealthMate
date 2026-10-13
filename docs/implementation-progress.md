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
