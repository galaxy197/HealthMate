# HealthMate

Ứng dụng Flutter giúp người từ **18 tuổi** theo dõi thói quen lành mạnh.
Android là nền tảng chính;
web phục vụ xem và kiểm tra giao diện trong quá trình phát triển.

## Phạm vi hiện tại — Giai đoạn 10

- Material 3, màu sắc, typography, spacing và widget dùng chung.
- Giao diện tiếng Việt, chế độ sáng/tối/theo thiết bị.
- Thanh điều hướng hiển thị Tổng quan, Nhật ký và Cá nhân; route Quest/Chat
  vẫn được giữ. Mở mục tiêu/nhiệm vụ và trò chuyện từ trang Cá nhân.
- Điều hướng bằng `go_router`, giữ trạng thái từng tab; Riverpod quản lý router
  và lựa chọn theme. Lựa chọn theme được lưu trên thiết bị.
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
- Firestore Security Rules giới hạn dữ liệu theo UID, schema, kiểu dữ liệu,
  khoảng giá trị và ngày theo timestamp/UTC offset; rules mới đã test trên emulator nhưng
  chưa deploy production.
- Danh mục **158 mục**: 10 mục USDA cũ, 101 thực phẩm Việt theo Viện Dinh dưỡng
  2007 và 47 món chế biến theo công thức tham khảo. Dùng `100 g`, có macro,
  nguồn và nhãn ước tính; client chỉ đọc khi đã đăng nhập. Tìm được không dấu,
  có **Xem thêm món**. Chi tiết nguồn, giới hạn và cách nạp:
  [`docs/food-catalog.md`](docs/food-catalog.md).
- Nhật ký bữa ăn hỗ trợ tìm món, chọn khẩu phần, loại bữa/thời điểm, xem tổng
  kcal/protein/carb/fat, thêm/sửa/xóa và lưu snapshot dưới UID.
- AI Food Scanner trên Android cho phép chụp/chọn ảnh, dùng Firebase AI Logic với
  Gemini Developer API và model `gemini-3.8-flash` để gợi ý món. Người dùng luôn
  xác nhận món/khẩu phần trước khi lưu; AI không quyết định số dinh dưỡng.
- App Check dùng debug provider trong debug và Play Integrity trong release.
  Trạng thái enforcement hiện tại cần kiểm tra trong Console trước khi demo.
  Ảnh được mã hóa lại từ pixel để bỏ metadata gốc rồi chỉ gửi sau xác nhận;
  HealthMate không tải ảnh lên Storage hoặc lưu ảnh trong Firestore. Camera/picker
  có thể tạo file tạm trên thiết bị; nhà cung cấp AI xử lý ảnh theo điều khoản riêng.
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

Widget tests kiểm tra các tab hiện và route ẩn, Auth/quay lại, phục hồi đường dẫn không
tồn tại, đổi theme, màn hình nhỏ với cỡ chữ lớn và layout rộng. Bộ test Auth còn
kiểm tra validation, session routing, loading, lỗi mạng, đăng xuất và retry. Test
Profile bao phủ bootstrap sau đăng nhập, validation/BMI và CRUD Body Metrics.
Test Nutrition bao phủ công thức khẩu phần, parser Gemini và luồng thêm bữa.
Test Daily Logs bao phủ date key, validation, tổng hợp và luồng CRUD nước/vận động.
Scanner có test chọn ảnh/hủy/lỗi/timeout/consent/xác nhận; Chat có test nguồn dữ
liệu, streaming, retry, đổi UID và không gửi nhật ký tới AI. Integration test
Android gọi Firebase AI Logic thật chỉ được chạy khi có thiết bị và App Check;
không coi việc có file test là bằng chứng đã chạy.
Kết quả thực tế và giới hạn môi trường được ghi tại
[`docs/implementation-progress.md`](docs/implementation-progress.md).
Kết quả kiểm tra Giai đoạn 10 và giới hạn: [`docs/test-report.md`](docs/test-report.md).

Kiểm thử Auth + Firestore SDK thật và Rules trên emulator (không gọi production):

```powershell
# Sau khi đã có Node.js 22+, Firebase CLI, Java 21 và dependencies rules-tests:
.\tool\test_emulators.ps1
# Máy khác có thể truyền -FlutterSdk, -Chrome, -JavaHome.
```

Script dùng cố định `demo-healthmate-rules`, Auth 9099/Firestore 8080. Test SDK
ở `test/firebase_repository_integration.dart` được chạy riêng, không được phát
hiện trong `flutter test` mặc định vì không mang hậu tố `_test.dart`. Mặc định
trên Windows script bật adapter phục vụ CanvasKit từ cache cho lỗi slash của
Flutter web test runner hiện tại; không sửa SDK. Có thể dùng
`-WithoutChromeAdapter` khi SDK đã sửa lỗi. Chỉ trình duyệt test headless bị tác động.

Security Rules có bộ test Node riêng. Trên máy hiện tại cần Java 21 từ Android
Studio vì Java mặc định còn là Java 8:

```powershell
npm install --prefix rules-tests
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --only firestore --project demo-healthmate-rules "npm test --prefix rules-tests"
```

Chỉ sau khi chủ project review và chủ động yêu cầu triển khai Rules:

```powershell
firebase deploy --only firestore:rules --project healthmate-app-20261013
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
  shared/providers/              # Theme preference lưu trên thiết bị
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

Giai đoạn tùy chọn 11: thông báo và polish, chỉ khi người dùng yêu cầu sau khi
đã kiểm tra MVP trên Android thật. Chưa triển khai.

Tuân theo `AGENTS.md`: mỗi lượt chỉ thực hiện giai đoạn được yêu cầu.

## Thiết lập Firebase trên máy mới

1. Chạy `flutter pub get`, cài Firebase CLI và FlutterFire CLI theo
   [hướng dẫn Flutter chính thức](https://firebase.google.com/docs/flutter/setup).
   Đăng nhập tài khoản được cấp quyền vào project. Các file cấu hình client đã
   có trong repo; chỉ chạy `flutterfire configure --project=<project-id>` nếu
   chủ động đổi project/platform, không tự ghi đè cấu hình hiện tại.
2. Trong Authentication bật **Email/Password**. Dùng Firestore Native mode và
   review Rules hiện có; không bật test mode công khai để vượt lỗi permission.
   Rules Giai đoạn 7/9/10 còn ở source, chưa deploy trong lượt này. Cần yêu cầu
   triển khai riêng trước khi thử ghi Goals/Quest/Chat trên production.
3. Trước khi thử AI trên Android, kiểm tra Firebase AI Logic đã cấu hình
   **Gemini Developer API**, model còn được hỗ trợ và quota trong project.
   Không bật billing hoặc thêm API key Gemini riêng vào Flutter để vượt hạn mức.
   Free tier có hạn mức và điều khoản xử lý dữ liệu; không bảo đảm miễn phí vô hạn.
4. Đăng ký Android App Check debug token trong Console theo
   [hướng dẫn debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider).
   Lưu token tại `%LOCALAPPDATA%\HealthMate\app-check-debug-token.txt` trên máy
   phát triển để chạy `tool/run_android.ps1`; giữ ngoài Git, không chia sẻ log
   chứa token. Bản release dùng Play Integrity và SHA-256 ký phát hành, cần
   cấu hình/kiểm tra riêng. Không tắt enforcement production để sửa lỗi debug.

Không dùng Storage trong MVP hiện tại. Không có Cloud Functions hoặc backend
riêng. Lựa chọn miễn phí giữ dữ liệu nhật ký/hội thoại khỏi model: Chat chỉ gửi
ba câu hỏi kiến thức định sẵn. Scanner yêu cầu đồng ý **cho từng ảnh**; chỉ chọn
ảnh món ăn không có khuôn mặt, giấy tờ hay nội dung cá nhân. Re-encode ảnh bỏ
EXIF/GPS gốc, nhưng không loại được thông tin cá nhân xuất hiện trong pixel.
[Điều khoản Gemini](https://ai.google.dev/gemini-api/terms) áp dụng cho payload gửi đi.

## Kịch bản demo và kiểm tra trên Android thật

1. Dùng tài khoản kiểm thử của người từ 18 tuổi; thử đăng ký, hoàn tất thiết lập,
   đóng/mở lại app, đăng xuất/đăng nhập. Người dùng cũ thiếu thông tin được yêu
   cầu bổ sung; dữ liệu cũ được giữ nguyên. Ngày sinh là thông tin tự khai,
   không phải xác minh danh tính. Tài khoản không đủ điều kiện không được gọi AI.
2. Ghi một bữa thủ công, nước và vận động; đổi ngày sang ngày trống rồi quay lại.
   Sửa/xóa và đối chiếu tổng kcal/macro/ml/phút trên Tổng quan và Nhật ký.
   Mở Nhìn lại tuần, tải lại sau khi sửa dữ liệu; không dùng số liệu demo giả.
3. Tạo mục tiêu và hoàn thành/bỏ qua nhiệm vụ; mở lại để kiểm tra trạng thái
   được lưu. Chat thử câu hỏi số liệu theo ngày và tải lại lịch sử; chỉ thử
   chủ đề AI chung sau khi đọc disclosure và xác nhận App Check hoạt động.
4. Scanner thử hủy camera, từ chối quyền, ảnh hỏng/lớn, ảnh món không trong
   catalog, mất mạng và đóng khi đang phân tích. Phải đồng ý xử lý ảnh trước
   khi phân tích, xác nhận món/khẩu phần trước lưu. Hủy chờ không bảo đảm hủy
   xử lý phía AI hoặc hoàn quota; vẫn luôn có lối nhập thủ công.
5. Thử mất mạng khi thêm nước: app báo đang chờ máy chủ, khóa gửi lặp; kết nối
   lại rồi kiểm tra chỉ có một bản ghi. Báo cáo tuần/tra cứu Chat cần mạng để
   lấy dữ liệu mới, không coi cache cũ là số liệu vừa được server xác nhận.
6. Kiểm tra sáng/tối, chữ lớn, bàn phím và back gesture. Với tài khoản **dùng
   riêng để kiểm thử**, thử quên/đổi mật khẩu và xóa tài khoản. Xác thực lại
   trước thao tác nhạy cảm; xóa dữ liệu trước Auth, xử lý lỗi giữa chừng bằng
   thông báo/thử lại. Không thử xóa trên tài khoản có dữ liệu cần giữ.

Firebase native có cache cục bộ; đăng xuất không bảo đảm xóa byte cache khỏi
thiết bị. Chỉ xóa dữ liệu ứng dụng qua Android sau khi đã đồng bộ các ghi đang
chờ. Cấu hình Android loại dữ liệu app khỏi backup đám mây/chuyển thiết bị;
chưa kiểm thử chuyển máy trên OEM thực và không tuyên bố xóa dữ liệu an toàn.

Giai đoạn 10 đã build APK **debug**, chưa xác minh Gemini/App Check/camera trên
Android thật trong lượt này. Trước phát hành công khai cần chốt application ID,
icon, release keystore/App Signing, SHA-256 và Play Integrity, kiểm tra Rules
production theo quy trình được phê duyệt. Cấu hình ký release hiện vẫn là debug
template, vì vậy bản hiện tại phục vụ phát triển/demo, chưa sẵn sàng phát hành.

## Trò chuyện HealthMate (Giai đoạn 9)

Mở **Cá nhân → Trò chuyện cùng HealthMate**. Hỏi kcal/macro, nước, vận động
hoặc tóm tắt ngày. Chọn ngày bằng lịch; câu hỏi có “hôm nay”/“hôm qua” dùng
ngày tương ứng tại thời điểm gửi. Số liệu được lấy mới từ repository, tính tại
ứng dụng; không có bản ghi khác với không ăn/uống/vận động.

Theo lựa chọn giữ Gemini Developer API free tier của người dùng: AI chỉ nhận
**ba chủ đề kiến thức chung định sẵn**, mỗi yêu cầu độc lập. Không gửi nội dung
tự nhập, dữ liệu nhật ký, hồ sơ hoặc lịch sử hội thoại tới model. Đây là phạm vi
đã điều chỉnh sau khi kiểm tra [điều khoản dịch vụ miễn phí](https://ai.google.dev/gemini-api/terms#unpaid-services);
không bật chế độ AI phân tích dữ liệu sức khỏe cá nhân. Thông báo xử lý dữ liệu
xuất hiện trước khi gửi chủ đề AI lần đầu trong mỗi lần vào Chat.

Firebase AI Logic dùng `gemini-3.8-flash`, kiểm tra trong
[danh sách model chính thức](https://firebase.google.com/docs/ai-logic/models)
ngày 16/10/2026. Có thể đổi qua `--dart-define=HEALTHMATE_CHAT_MODEL=<model-được-hỗ-trợ>`;
cần kiểm tra lại model/quota khi đổi. Model cấu hình thinking thấp, tối đa 2048
output tokens và 6000 ký tự. Không thêm API key riêng hay package mới.

- AI chạy trên Android có App Check hiện có; web/desktop chỉ tra cứu nhật ký.
- Có streaming, dừng nhận, lỗi mạng/hạn mức, thử lại. Dừng không bảo đảm server
  hủy xử lý hoặc hoàn lại quota. Bản AI chưa hoàn chỉnh không được lưu.
- Lưu cặp tin nhắn nguyên tử theo UID, tối đa 20 lượt/phiên; lịch sử hiển thị 20
  phiên gần nhất. Thử lại sau lỗi lưu dùng cùng ID và đáp án, không gọi AI lại.
- Khi lỗi lưu, đáp án hoàn chỉnh hiển thị nhãn chưa lưu. Rời màn hình có thể mất
  bản chưa lưu; chỉ lịch sử đã được Firestore xác nhận tồn tại khi mở lại.
- Không có listener lịch sử thường trực; tải lại bằng menu lịch sử khi cần.
- Rules Chat trong source cần được review/deploy riêng trước khi lưu vào
  production. **Giai đoạn 9 không deploy Rules/indexes, không bật billing.**

Chi tiết schema, giới hạn, cách kiểm tra trên máy thật:
[`docs/chatbot.md`](docs/chatbot.md).

## Mục tiêu và nhiệm vụ hằng ngày (Giai đoạn 7)

Mở **Cá nhân → Mục tiêu và nhiệm vụ hằng ngày**. Tạo mục tiêu số bữa đã ghi,
lượng nước, phút vận động mỗi ngày hoặc cân nặng theo thời hạn. Mức do bạn tự
chọn; sửa được giá trị, thời hạn và trạng thái theo dõi. Mục tiêu định lượng
được lưu riêng với định hướng sức khỏe trong hồ sơ.

Mỗi ngày có một nhiệm vụ từ quy tắc có lý do hiển thị. Chỉ gợi ý nước/vận động
khi bạn đã chọn theo dõi nội dung đó. Hoàn thành/bỏ qua được lưu theo UID/ngày;
không có điểm phạt và không tự tạo dữ liệu nhật ký. Nhiệm vụ giữ nguyên trong
ngày kể cả khi bạn sửa mục tiêu. Tạo/cập nhật nhiệm vụ cần kết nối mạng.

Rules mới đã có trong source để kiểm thử. **Chưa deploy production**: cần
review và deploy `firestore.rules` trước khi tạo mục tiêu/nhiệm vụ trên Firebase
thật. Không cần tạo index mới, package mới hoặc dịch vụ trả phí.

## Tổng quan và Nhìn lại tuần (Giai đoạn 8)

Tổng quan hiển thị dinh dưỡng hôm nay, nước, phút vận động, số bữa, lần cân gần
nhất và tiến độ mục tiêu/nhiệm vụ đã lưu. Lỗi hoặc dữ liệu đang tải dùng dấu `—`;
ngày/múi giờ được hiển thị và đồng hồ cập nhật khi qua ngày hoặc app trở lại
foreground. Lối vào nhiệm vụ mở màn Goals/Quest hiện có.

Mở **Nhìn lại tuần** ở cuối Tổng quan để xem tuần từ Thứ Hai đến Chủ nhật, đổi
tuần trước và biểu đồ kcal/nước/phút vận động. Tổng macro, số ngày có ghi nhận,
trung bình kcal trên ngày có ghi bữa và thay đổi giữa các lần cân đều lấy từ
nhật ký thật. Biểu đồ cân nặng hiển thị tối đa 12 lần cân gần nhất trong tuần.
Ngày trống không có nghĩa là không ăn/uống/vận động; một lần cân chưa đủ để
mô tả thay đổi. Không chẩn đoán hoặc suy diễn nguyên nhân.

Báo cáo tuần là lượt đọc một lần từ server, có giờ tải và nút **Tải lại báo cáo**.
Cần mạng khi mở/làm mới; nếu một nguồn lỗi thì không hiển thị tổng thiếu. Sau
khi sửa nhật ký, mở lại hoặc tải lại báo cáo. Khi phần báo cáo đóng thì không
truy vấn tuần. Không thêm package, collection, index hoặc Rules mới.

## Tài liệu đã đối chiếu

- [Firestore range queries](https://firebase.google.com/docs/firestore/query-data/queries)
- [fl_chart BarChartData](https://pub.dev/documentation/fl_chart/latest/fl_chart/BarChartData-class.html)

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
