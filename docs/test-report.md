# Giai đoạn 10 — Báo cáo kiểm thử và rà soát MVP

Ngày kiểm tra: **16/10/2026**. Phạm vi chỉ Giai đoạn 10; không triển khai Giai đoạn 11.
Người dùng đã duyệt MVP/demo **18+**, cập nhật onboarding và chặn gọi AI khi
chưa xác nhận đủ điều kiện. Giữ lựa chọn Gemini Developer API free tier:
tra cứu nhật ký tại ứng dụng, AI Chat chỉ nhận chủ đề chung định sẵn.

## Kết quả chạy thực tế cuối lượt

| Lệnh | Kết quả thực tế |
| --- | --- |
| `dart format lib test tool` | 136 file, 0 thay đổi ở lần chạy cuối |
| `flutter analyze --no-pub` | **No issues found**, 7,5 giây |
| `flutter test --no-pub` | **134/134 pass**, khoảng 14 giây, không skip |
| `tool/test_emulators.ps1` | **31/31 Rules + 4/4 Flutter SDK pass**, exit 0 |
| `flutter build apk --debug --no-pub` | **Thành công**, assembleDebug 16,2 giây |
| `flutter pub get --offline` | Thành công; dùng cache, không nâng phiên bản dependency |
| `git -c core.safecrlf=false diff --check` | Sạch; không có lỗi whitespace |
| `dart format --output=none --set-exit-if-changed lib test tool` | 136 file, 0 thay đổi, exit 0 |

APK: `build/app/outputs/flutter-apk/app-debug.apk` (artifact được Git ignore).
Build còn cảnh báo Firebase plugins `firebase_ai`, `firebase_app_check`,
`firebase_auth`, `firebase_core` dùng Kotlin Gradle Plugin; Flutter cảnh báo
khả năng không tương thích với bản Flutter tương lai. Cảnh báo không làm build
hiện tại thất bại; chưa tự nâng SDK/plugin để tránh đổi phạm vi.

Môi trường: Windows, Flutter 3.44.1/Dart 3.12.1 tại `D:\Flutter\flutter`,
Android SDK đã cài, Java 21 từ Android Studio, Node.js và Firebase CLI,
Chrome headless. `flutter devices` chỉ thấy Windows/Chrome/Edge, không có
Android kết nối trong lượt kiểm tra này.

Log phát triển ở `build/stage10-tests.log`, `build/stage10-emulators-final.log`,
`build/stage10-apk.log` chỉ nằm cục bộ, không đưa vào Git. Các dòng
`PERMISSION_DENIED` trong log Rules là kết quả mong đợi của test từ chối truy cập;
kết luận dựa trên test runner 31 pass/0 fail, không dựa trên việc log không có lỗi.

## Unit/widget tests

Bộ 134 test gồm các test đã có cho Auth, tài khoản, onboarding/profile/BMI,
công thức khẩu phần, nhật ký nhiều ngày/ranh giới ngày, Goals/Quest rules engine,
tổng hợp tuần, Dashboard, Chat và layout/navigation. Giai đoạn 10 bổ sung
**13 test** trong `test/security_regression_test.dart` (6) và
`test/food_scanner_test.dart` (7), đồng thời tái sử dụng fake repositories:

- Chính xác ngày sinh nhật 18 tuổi, giới hạn 120 tuổi; thiếu ngày sinh,
  thiếu onboarding, khác UID và tài khoản chưa đủ tuổi không được gọi AI.
- Hồ sơ cũ dưới 18 tuổi quay lại thiết lập, giữ nguyên dữ liệu và không làm
  crash date picker. Không tự thay đổi ngày sinh để cho phép gọi AI.
- `NaN`, Infinity và số overflow bị chặn ở form profile/dinh dưỡng/BMI;
  đầu ra JSON sai kiểu/quá dài/danh sách quá giới hạn bị từ chối.
- Scanner không có catalog vẫn có đường nhập thủ công; hủy picker, lỗi quyền,
  consent từng ảnh, matching và xác nhận bữa đều có test. Không tự lưu meal.
- Lỗi ngoài dự kiến, timeout, đóng khi tải, đăng xuất và kết quả về muộn không
  được gắn vào session mới. Hủy chờ chỉ bỏ kết quả, không cam kết hủy server.
- Re-encode PNG từ pixel giữ pixel thử nghiệm, bỏ metadata gốc của fixture;
  byte rỗng/quá lớn/ảnh hỏng bị chặn. Test không thay thế thử camera OEM thật.
- Ghi nước đang chờ máy chủ hiển thị trạng thái chờ và vô hiệu gửi nhanh lặp.

Widget tests dùng fake repositories/services; không chứng minh model AI thật,
camera thật hoặc App Check production hoạt động. Các bài test cũ về công thức,
parsing, engine và tổng hợp báo cáo đã chạy lại toàn bộ, không chỉ test mới.

## Rules và tích hợp Firebase SDK thật

Chạy lại trên **demo project cố định** `demo-healthmate-rules`, localhost Auth
9099/Firestore 8080 với `firebase.emulators.json`. Không dùng config Firebase
production, không import `firebase_options.dart`, không có fallback production.
Emulators tự dừng khi script kết thúc; không deploy Rules/indexes.

31 test Node trong `rules-tests/firestore.rules.test.cjs` kiểm tra quyền owner,
guest, hai UID, catalog chỉ đọc, schema/giới hạn, bất biến timestamp, meal totals,
Goals/Quest transitions/idempotence, Chat pair transaction/sequence và cleanup.
Hai test mới bao phủ dateKey/timestamp/offset và đường dẫn ngoài schema:

- Ngày trong `dateKey` phải trùng calendar day của timestamp sau khi cộng
  `timezoneOffsetMinutes`: có ca sát nửa đêm, bù giờ âm/dương, ngày nhuận,
  ngày không tồn tại và offset không hợp lệ cho meal/water/activity.
- Guest/UID khác và collection-group rộng bị từ chối; không ghi được root
  tùy ý, collection chưa định nghĩa hay field quản trị vào profile.
- Owner read/delete wildcard vẫn được giữ để dọn dữ liệu của chính tài khoản;
  wildcard này không cho create/update collection tùy ý. Các match cho phép
  có hiệu lực OR; không coi một nhánh `false` là phủ định nhánh khác.

`test/firebase_repository_integration.dart` có **4 test** dùng Flutter Firebase
Auth/Firestore SDK và các repository production thật, không dùng fake backend:

1. Đăng ký, tạo profile, hoàn tất onboarding hai lần vẫn giữ completion marker
   và một metric ban đầu; ghi/tải meal, water, activity, goal, quest và chat.
   Tạo quest/save turn lại không nhân đôi hay ghi đè trạng thái hoàn tất.
2. Đăng nhập bằng tài khoản thứ hai: không đọc hoặc ghi được dữ liệu UID thứ nhất.
3. Tắt mạng SDK, quan sát snapshot cache `hasPendingWrites`, Future ghi chưa
   hoàn tất; bật mạng lại xác nhận chỉ có một bản ghi nước mới (tổng 583 ml).
4. Xác thực lại và đổi mật khẩu; xóa tất cả collection được ứng dụng hỗ trợ,
   gồm messages lồng trong chat, kiểm tra dữ liệu không còn trong khi Auth
   vẫn tồn tại, rồi mới xóa Auth.

Mô phỏng offline này dùng SDK web trong Chrome; chưa kiểm tra cache/persistence
Android sau kill/restart, và không khẳng định mọi luồng offline đều đã được thử.
Xóa tài khoản vẫn cần kết nối mạng, không có transaction nguyên tử liên dịch vụ
Firestore/Auth. Test lỗi giữa chừng ở tầng controller tiếp tục nằm trong bộ
widget/unit có sẵn; không cố tạo lỗi production.

### Chạy lại trên máy khác và lỗi test runner đã xử lý

```powershell
flutter pub get
npm ci --prefix rules-tests
.\tool\test_emulators.ps1 -FlutterSdk 'D:\Flutter\flutter' `
  -Chrome 'C:\Program Files\Google\Chrome\Application\chrome.exe' `
  -JavaHome 'C:\Program Files\Android\Android Studio\jbr'
```

Trong lượt này không chạy `npm install/ci`; dependencies Node đã có. Bốn package
web vốn là transitive dependencies đã được khai báo thêm dưới **dev_dependencies**
để đăng ký plugin thật trong web test: `firebase_core_web`, `firebase_auth_web`,
`cloud_firestore_web`, `flutter_web_plugins`. `flutter pub get --offline` chỉ
đổi phân loại lockfile thành direct dev, giữ nguyên phiên bản/runtime dependencies.

SDK Windows hiện tại có lỗi slash trong route CanvasKit khi chạy Flutter web
test: JS/wasm 404 trước khi test khởi động, và đường dẫn test lồng thư mục cũng
gây lỗi selector. Giữ test SDK ở gốc `test/` và adapter headless riêng trong
`tool/chrome_test_adapter.*` phục vụ **file cache SDK nguyên bản** cho đúng URL
CanvasKit của test localhost. Không sửa SDK, nội dung test hay mã production
để bỏ qua lỗi. Các lần chạy trước adapter từng thất bại ở bootstrap; kết quả
31+4 cuối bảng là lần chạy script portable thành công sau khi khắc phục.
Khi SDK sửa lỗi, dùng `-WithoutChromeAdapter` để chạy Chrome trực tiếp.

Test SDK không mang hậu tố `_test.dart` nên không tự chạy trong suite mặc định.
Cần cờ `--dart-define=HEALTHMATE_EMULATOR_TESTS=true`; chạy sai cách sẽ fail
ngay thay vì im lặng skip hoặc kết nối production. Script giữ/restores biến môi
trường của terminal và chỉ khởi chạy Chrome profile test headless riêng.

## Thay đổi bảo mật/quyền riêng tư

- MVP/demo 18+ theo quyết định người dùng và
  [điều khoản tuổi Gemini](https://ai.google.dev/gemini-api/terms#age-requirements).
  Cổng AI dùng cùng UID/profile hợp lệ, không khởi tạo model khi bị chặn.
  **Ngày sinh tự khai, kiểm tra client không phải chứng thực tuổi phía server.**
- Giữ Chat free tier chỉ gửi ba chủ đề chung; không gửi text tự nhập, hồ sơ,
  nhật ký hoặc lịch sử. Scanner yêu cầu consent từng ảnh, công khai điều khoản
  xử lý miễn phí; không chấp nhận thông tin cá nhân trong ảnh. Decode/scale và
  encode PNG loại EXIF/GPS gốc, không làm ẩn nội dung cá nhân trong pixel.
- Không có Firebase Storage SDK, upload code hay collection lưu ảnh gốc.
  Storage Rules **không áp dụng** cho ứng dụng hiện tại. OS picker có thể tạo
  file tạm; không hứa mọi byte ảnh biến mất ngay sau khi đóng dialog.
- Android đặt `allowBackup=false`, `fullBackupContent=false` và XML loại dữ
  liệu khỏi cloud backup/device transfer. APK debug đã compile tài nguyên này;
  chưa kiểm thử chuyển máy OEM, không tuyên bố xóa an toàn cache đang tồn tại.
- Native Firestore cache có thể tồn tại sau đăng xuất. UI giải thích rõ; không
  tự clear cache làm mất ghi đang chờ. Khi offline không tự timeout/retry các
  ghi journal đang pending để tránh tạo bản trùng.
- Quét mẫu secret trong source nonignored và kiểm tra log/error paths: không
  phát hiện private/service-account/Gemini secret riêng; chỉ gặp public Firebase
  client config hiện có. Không in giá trị token. Đây là kiểm tra mẫu, không phải
  audit toàn bộ lịch sử Git, ignored files hoặc cam kết không có mọi loại secret.

## Giới hạn và việc cần làm trước demo/phát hành

- **Chưa chạy Android thật**, live AI/App Check/Play Integrity, quota/model,
  camera/permissions thực hoặc bài `integration_test/firebase_ai_smoke_test.dart`
  trong lượt này. Chưa kiểm tra release signing hay phát hành Play Store.
- Source Rules Giai đoạn 7/9/10 cần chủ project review và yêu cầu deploy riêng.
  Không có thay đổi Rules/index production trong nhiệm vụ này; chưa coi những
  thao tác mới đã được xác minh trên backend production.
- Android còn ID `com.example.healthmate`, icon template, release signing dùng
  debug template. Cần quyết định thương hiệu và signing/Play Integrity trước
  public release. Không tạo keystore/billing hay thay đổi project tự động.
- Rules bảo vệ UID/schema/range và các bất biến được test; không chứng thực
  độ chính xác dinh dưỡng, nguồn catalog, tuổi tự khai hoặc tính trung thực
  nhật ký do owner nhập. AI vẫn có thể sai và free tier có thể hết quota.
- Xóa account phía client biết các collection được app hỗ trợ. Khi thêm
  collection/subcollection mới phải cập nhật cleanup và test; không thể tự liệt
  kê mọi subcollection tùy ý như Admin SDK. Client không được tạo path ngoài schema.
- Test emulator không thay thế audit bảo mật độc lập. Kiểm tra bằng mắt/thực
  tế theo kịch bản Android trong README: chữ lớn/sáng tối, đổi tài khoản,
  mất mạng, pending write, Scanner, Chat, quên mật khẩu, xóa account thử nghiệm.

Không commit, stage, push, deploy Firebase, chạy migration, bật billing hoặc
tự tiến sang Giai đoạn 11. HEAD giữ nguyên
`310c8971ee2189ab4f01f2002edd4f93ff1e5535`; bảo toàn thay đổi chưa commit của
các đợt trước. Danh sách thay đổi Giai đoạn 10: [implementation-progress.md](implementation-progress.md).

## Tài liệu chính thức đã đối chiếu

- [Gemini API Terms](https://ai.google.dev/gemini-api/terms)
- [Firestore Rules conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Rules structure/overlapping matches](https://firebase.google.com/docs/firestore/security/rules-structure)
- [Firestore offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [App Check debug](https://firebase.google.com/docs/app-check/flutter/debug-provider)
- [Android backup/device transfer](https://developer.android.com/identity/data/autobackup)

## Bảo trì MVP — 17/10/2026 (F01–F06, R01)

Đây là kết quả mới của đợt bảo trì, không thay thế lịch sử ở trên.
Chi tiết nguyên nhân, file, bằng chứng đỏ→xanh và giới hạn runtime:
[maintenance-2026-10-17.md](maintenance-2026-10-17.md).

- HEAD ban đầu/cuối: `3e8e9cc756c0a8caf1a882f6829088216736e56b`, checkout sạch lúc bắt đầu.
- Format `lib test integration_test`: 145 file, 0 thay đổi; analyze: No issues found (19,0s).
- Flutter: **176/176 pass**; catalog Node: **7/7 pass**.
- Firebase Rules **31/31** và SDK integration **6/6 pass**, project cố định
  `demo-healthmate-rules`, Auth/Firestore emulator, SDK qua Chrome.
- Android x64 debug build thành công (52,1s); có cảnh báo KGP từ plugin Firebase.
- Đã sửa/xác minh F01 giữ bản nháp + pending/session, F02 snapshot lịch sử,
  F05/F06 responsive/không cắt nhãn, R01 retry tạo mục tiêu theo ID ổn định.
- F03 đã sửa chẩn đoán/retry local; đọc Rules production xác nhận thiếu match ghi
  Goals/Quest/Chat. **Chưa deploy, chưa xác minh luồng Quest production đã hết lỗi.**
- F04 Android QA: một lượt Chat cloud18,151s/14chunks và Scanner service15,709s
  thành công; ba lượt khác timeout45s mỗi thao tác. **AI chưa ổn định, chưa sửa dứt điểm.**
  Không đổi model/provider/timeout, billing hoặc App Check enforcement.
- Layout: 24 tổ hợp360/390/412/900dp × scale1/1,5/2 × sáng/tối, có xem ảnh render.
  Chưa kiểm tra điện thoại thật hoặc toàn bộ scanner end-to-end.
- QA AVD mới trên D:, không dữ liệu người dùng; không uninstall/pm clear/wipe,
  tạo tài khoản production hoặc dùng dữ liệu sức khỏe thật để test.
- Không stage/commit/push/PR/deploy/migration. Chỉ thêm `http` đã có bắc cầu vào
  dev dependency cho probe, khôi phục offline, không nâng phiên bản.
