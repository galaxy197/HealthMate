# HealthMate

Ứng dụng Flutter giúp theo dõi thói quen lành mạnh. Android là nền tảng chính;
web phục vụ xem và kiểm tra giao diện trong quá trình phát triển.

## Phạm vi hiện tại — Giai đoạn 6

- Material 3, màu sắc, typography, spacing và widget dùng chung.
- Giao diện tiếng Việt, chế độ sáng/tối/theo thiết bị.
- 5 tab: Tổng quan, Nhật ký, Quest, AI / Chat, Cá nhân; trang Tài khoản riêng.
- Điều hướng bằng `go_router`, giữ trạng thái từng tab; Riverpod quản lý router
  và lựa chọn theme. Lựa chọn theme chỉ giữ trong phiên, chưa lưu trên thiết bị.
- Thanh điều hướng dưới trên điện thoại, thanh bên khi rộng từ 840 logical pixels.
- Firebase được khởi tạo trước `runApp` bằng cấu hình Android/web do FlutterFire
  sinh cho project `healthmate-app-20261013`.
- Đăng ký, đăng nhập và đăng xuất bằng email/mật khẩu thật; session được theo dõi
  để bảo vệ route riêng tư và đưa người dùng về đúng trang họ định mở.
- Form có validation, trạng thái đang xử lý, chống gửi lặp, ẩn/hiện mật khẩu và
  thông báo tiếng Việt cho lỗi thông tin đăng nhập, email, mạng hoặc giới hạn thử.
- Hồ sơ được tạo an toàn theo session tại `users/{uid}`; người dùng sửa tên hiển
  thị và chiều cao, còn email được đồng bộ từ tài khoản Auth.
- Lịch sử cân nặng có thêm/sửa/xóa thật tại
  `users/{uid}/body_metrics/{metricId}`, sắp xếp theo ngày đo và có trạng thái
  không dữ liệu.
- BMI chỉ xuất hiện khi chiều cao và cân nặng hợp lệ, được ghi rõ là chỉ số tham
  khảo và không phải chẩn đoán.
- Firestore Security Rules giới hạn dữ liệu theo UID, schema, kiểu dữ liệu và
  khoảng giá trị; rules đã được test truy cập chéo trên emulator và deploy.
- Danh mục 10 món tham khảo có cơ sở `100 g`, macro, nhãn nguồn USDA FoodData
  Central và cờ ước tính; client chỉ được đọc danh mục khi đã đăng nhập.
- Nhật ký bữa ăn hỗ trợ tìm món, chọn khẩu phần, loại bữa/thời điểm, xem tổng
  kcal/protein/carb/fat, thêm/sửa/xóa và lưu snapshot dưới UID.
- AI Food Scanner trên Android cho phép chụp/chọn ảnh, dùng Firebase AI Logic với
  Gemini Developer API và model `gemini-3.8-flash` để gợi ý món. Người dùng luôn
  xác nhận món/khẩu phần trước khi lưu; AI không quyết định số dinh dưỡng.
- App Check dùng debug provider trong debug, Play Integrity trong release và đã
  bật enforcement cho Firebase AI Logic. Ảnh chỉ nằm trong bộ nhớ khi phân tích.
- Nhật ký nước uống hỗ trợ chọn ngày, nhập lượng ml và thời điểm, xem tổng theo
  ngày, sửa/xóa dữ liệu thật dưới UID.
- Nhật ký vận động hỗ trợ loại hoạt động, số phút, thời điểm và ghi chú tùy chọn;
  tổng thời lượng theo ngày cập nhật sau mọi thao tác.
- Ngày nhật ký dùng `dateKey` theo lịch địa phương và lưu độ lệch múi giờ tại
  thời điểm ghi. Ứng dụng không nhận là tự đo bước chân hay tính calories tiêu hao.

HealthMate hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.

## Yêu cầu môi trường

Môi trường đã dùng: Flutter 3.44.1 stable, Dart 3.12.1. `pubspec.yaml` yêu cầu
Dart `^3.12.1`; các phiên bản dependency được ghi trong `pubspec.lock`.
Cần Flutter SDK, Android SDK, kết nối mạng và thiết bị Android hoặc emulator để
chạy Android. Firebase project đã được cấu hình; Email/Password provider đang bật.

Trên máy hiện tại Flutter nằm tại `D:\Flutter\flutter`, chưa có trên PATH.
Trong PowerShell có thể thêm PATH cho **phiên terminal hiện tại**:

```powershell
$env:Path = 'D:\Flutter\flutter\bin;' + $env:Path
flutter --version
flutter doctor -v
```

Trên máy khác, dùng đường dẫn Flutter SDK thực tế của bạn. Nếu muốn dùng lâu dài,
thêm thư mục `flutter\bin` vào PATH qua Windows Environment Variables.

## Chạy ứng dụng

Mở terminal tại thư mục chứa `pubspec.yaml`:

```powershell
flutter pub get
flutter devices
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <android-device-id>
```

Trên máy phát triển đã cấu hình HealthMate, chạy Android qua script sau để nạp
App Check debug token từ file cục bộ ngoài repository:

```powershell
.\tool\run_android.ps1 -DeviceId <android-device-id>
```

Build release không dùng debug token; code chuyển sang Play Integrity. Khi tạo
release keystore hoặc bật Play App Signing, phải đăng ký SHA-256 release tương
ứng trong Firebase trước khi phát hành.

Nếu `flutter doctor` báo giấy phép Android chưa được chấp nhận, người dùng cần
tự đọc và chấp nhận giấy phép thích hợp bằng `flutter doctor --android-licenses`.

Để xem UI trong Chrome mà không cần emulator:

```powershell
flutter run -d chrome
```

## Kiểm tra và build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test integration_test/firebase_ai_smoke_test.dart -d <android-device-id> --dart-define=HEALTHMATE_APP_CHECK_DEBUG_TOKEN=<registered-debug-token>
flutter build web
flutter build apk --debug
```

Widget tests kiểm tra điều hướng 5 tab, Auth/quay lại, phục hồi đường dẫn không
tồn tại, đổi theme, màn hình nhỏ với cỡ chữ lớn và layout rộng. Bộ test Auth còn
kiểm tra validation, session routing, loading, lỗi mạng, đăng xuất và retry. Test
Profile bao phủ bootstrap sau đăng nhập, validation/BMI và CRUD Body Metrics.
Test Nutrition bao phủ công thức khẩu phần, parser Gemini và luồng thêm bữa.
Test Daily Logs bao phủ date key, validation, tổng hợp và luồng CRUD nước/vận động;
integration test Android gọi Firebase AI Logic thật với App Check enforcement.
Kết quả thực tế và giới hạn môi trường được ghi tại
[`docs/implementation-progress.md`](docs/implementation-progress.md).

Security Rules có bộ test Node riêng. Trên máy hiện tại cần Java 21 từ Android
Studio vì Java mặc định còn là Java 8:

```powershell
npm install --prefix rules-tests
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --only firestore --project demo-healthmate-rules "npm test --prefix rules-tests"
```

Deploy rules/indexes vào project đã chọn:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project healthmate-app-20261013
```

## Cấu trúc

```text
lib/
  main.dart                      # Khởi tạo Firebase trước ProviderScope/runApp
  app.dart                       # MaterialApp.router, locale và theme
  firebase_options.dart          # Client config do FlutterFire sinh
  core/
    config/                      # Firebase bootstrap
    router/                      # Đường dẫn, router và vòng đời
    theme/                       # Theme sáng/tối và spacing
    widgets/                     # Shell thích ứng, trang khung, trạng thái chờ
  features/
    auth/                        # Model, repository, provider và UI Auth
    dashboard/presentation/
    journal/presentation/        # Điểm vào nhật ký tổng hợp
    nutrition/                   # Catalog, meal log, repository, provider và UI
    food_scanner/                # Firebase AI service và luồng xác nhận ảnh
    water/                       # Nhật ký nước theo UID/ngày
    activity/                    # Nhật ký vận động theo UID/ngày
    daily_quest/presentation/
    chatbot/presentation/
    profile/                     # Model, repository, provider và UI profile/metrics
  shared/providers/              # Theme preference trong bộ nhớ
test/                            # Widget/unit tests và fake repositories
integration_test/                # Smoke test Firebase AI Logic trên Android
tool/run_android.ps1             # Chạy debug với token App Check ở ngoài repo
rules-tests/                     # Security Rules tests trên Firestore Emulator
firestore.rules
firestore.indexes.json
android/
web/
```

`journal` là điểm vào tổng hợp; nutrition, food scanner, water và activity được
tách theo feature.

## Firebase và bảo mật cấu hình

Android application ID hiện là `com.example.healthmate`; cần chốt namespace
thương hiệu trước khi phát hành. `firebase_options.dart` và
`android/app/google-services.json` chỉ chứa client configuration mà Firebase SDK
cần để kết nối. Không đưa service-account JSON, Admin SDK credential hoặc secret
server vào repository. Build release vẫn dùng debug signing theo template Flutter;
icon ứng dụng và favicon vẫn là icon template.

Cloud Firestore mặc định dùng Native mode tại `asia-southeast1` (Singapore).
Schema và quyền truy cập được mô tả tại
[`docs/database-design.md`](docs/database-design.md). Tài khoản chỉ có thể đọc và
ghi document nằm dưới UID của chính nó; validation được thực hiện cả ở Flutter
và Security Rules.

## Các bước tiếp theo

Giai đoạn 7: Goals và Daily Health Quest, chỉ khi người dùng yêu cầu.

Tuân theo `AGENTS.md`: mỗi lượt chỉ thực hiện giai đoạn được yêu cầu.

## Tài liệu đã đối chiếu

- [Flutter internationalization](https://docs.flutter.dev/ui/internationalization)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- [go_router](https://pub.dev/packages/go_router)
- [Cupertino icon font](https://pub.dev/packages/cupertino_icons)
- [Add Firebase to Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication for Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore for Flutter](https://firebase.google.com/docs/firestore/quickstart)
- [Firestore Security Rules fields](https://firebase.google.com/docs/firestore/security/rules-fields)
- [Test Firestore Security Rules](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Firebase AI Logic for Flutter](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter)
- [Firebase AI Logic supported models](https://firebase.google.com/docs/ai-logic/models?api=dev)
- [Firebase App Check for Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [USDA FoodData Central](https://fdc.nal.usda.gov/)
