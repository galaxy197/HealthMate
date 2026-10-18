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

## C1 — Chuyển sang phạm vi core (17/10/2026)

Báo cáo/phạm vi, mapping code, schema dự kiến và kế hoạch C2–C6:
[core-scope.md](core-scope.md). Kết quả dưới đây được chạy mới trong C1.
HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`, working tree sạch trước sửa.

| Lệnh/môi trường | Kết quả thực tế |
|---|---|
| Baseline `flutter test --no-pub` | 176/176 pass,13s. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 147file,0thay đổi. |
| `flutter analyze --no-pub` | No issues found,10,7s. |
| `flutter test --no-pub` | 201/201 pass,18s; 25test C1 mới, không skip/hạ assertion cũ. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | Rules31/31 + SDK6/6 pass trên Auth/Firestore demo-healthmate-rules, SDK qua Chrome. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,11,8s; cảnh báo plugin Firebase dùng KGP, không có token/cờ bật AI. |

Test C1 bao phủ flags mặc địnhfalse, không khởi tạo Chat/controller/service/picker
khi startup/tab/menu/route bị tắt; controller gọi trực tiếp không đọc/ghi lịch sử
hoặc gọi AI; scan action bị chặn; manual form vẫn mở; giữ Quest/Profile indexes;
Auth/onboarding, cold deep link, return link, Back và hai flags độc lập.
18tổ hợp360/390/412dp × scale1/1,5/2 × sáng/tối; dùng font thật và đã xem3ảnh render
menu+ trong build/c1-layout. Không gọi AI thật; test AI cũ bật flags riêng và dùng fake.

Đã GET read-only Rules production lúc11:59 UTC+07 ngày17/10/2026: release updateTime
2026-10-13T06:25:21.345792Z, vẫn khác local và thiếu match ghi goals/daily_quests/
chat_sessions. Không sửa Rules/indexes trong C1 vì source local đã có và đạt tests.
Chưa deploy hoặc chạy nghiệp vụ bằng tài khoản production, chưa xác minh indexes thật.

Không có Android kết nối (chỉ Windows/Chrome/Edge). Chỉ build x64; chưa cài/chạy E2E
Android/điện thoại vật lý, không uninstall/clear/wipe hoặc đụng session người dùng.
Không đổi schema, seed/migration, model/provider, App Check, billing hoặc dependency.
Local C1 đạt; production chưa nghiệm thu, đặc biệt mục tiêu/Quest còn chờ Rules được
review/deploy riêng. Không stage/commit/push/deploy; không làm C2–C6.

## C2 — Mục tiêu dinh dưỡng theo ngày hiệu lực (17/10/2026)

Chi tiết hành vi, schema, file, lỗi trung gian và giới hạn:
[core-scope.md — C2](core-scope.md#c2--mục-tiêu-kcalmacros-theo-ngày-hiệu-lực-17102026).
HEAD86238197a9f8e24a2222da2da9e74164c35844ea, bảo toàn C1 chưa commit.

- Baseline mới201/201 Flutter (16s). Cuối **234/234Flutter pass** (24s), không skip;
  **35/35Rules**, **7/7SDK integration** (demo-healthmate-rules, SDK qua Chrome),
  **7/7catalog Node** pass. Không dùng production cho test ghi/xóa.
- Format lib/test/integration_test155 file/0 thay đổi; analyze sạch11,6s;
  debugAPKandroid-x64 build18,0s. Cảnh báo KGP còn, chưa phải bản ARM/release.
-33 bài C2 gồm lịch sử hiệu lực/ngày trống/tương lai/cuối năm, macro/all-null/0/NaN/
  bounds, còn/vượt/zero denominator, mismatch confirmation, lỗi lưu/giữ draft/retry,
  pending 20 s/nhấn lặp, đổiUID và async muộn, đổi ngày khi tải, qua nửa đêm;
  UI18 tổ hợp360/390/412 × scale1/1,5/2 × sáng/tối + insets keyboard 260 dp.
- Đã xem3 ảnh font thật. Sửa đệm keyboard trùng sau khi xem ảnh, chạy lại toàn bộ
  kiểm tra. Chưa E2E Android/điện thoại/bàn phím thật, không cài/xóa app người dùng.
- SDK thực tế phát hiện transaction có thể ghi khi disableNetwork đã chặn server
  reads. Đã thêm server read-back trước success; lỗi ack giữ draft, retry cùng ID.
  Test mới xác minh bản ghi đã có sau reconnect và không nhân đôi khi retry;
  không giả định lỗi đồng nghĩa rollback.6SDK tests cũ giữ nguyên ý nghĩa/assertion.
- Cleanup đã kiểm tra xóa nutrition_targets. Rules mới kiểm tra owner/guest/B,
  document/collection/query, schema/bounds/date/timestamps, unknown fields và số xấu.
- GET Rules production read-only12:23 UTC+07,17/10/2026: vẫn updateTime
  2026-10-13T06:25:21.345792Z, chưa có quyền ghi nutrition_targets/Goals/Quest/Chat.
  **C2local đạt; production chưa nghiệm thu và chưa lưu được mục tiêu mới.**
- Không deploy Rules/index, commit/push, billing, migration, dependency upgrade
  hoặc gọiAI thật. ChỉC2; chưaC3. Logignored: build/c2-*.log và build/c2-layout.

## Core C3 — kiểm chứng mới ngày 17/10/2026

Checkout main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`; bảo toàn C1/C2
chưa commit. Baseline thực tế 234/234 Flutter pass, 17s. Môi trường Windows,
Flutter 3.44.1/Dart 3.12.1, Java 21 và Chrome.

| Lệnh đã chạy | Kết quả cuối |
|---|---|
| `dart format lib test integration_test`, rồi `dart format --output=none --set-exit-if-changed lib test integration_test` | 162 file; 0 thay đổi ở kiểm tra cuối. |
| `flutter analyze --no-pub` | No issues found, 8,2s. |
| `flutter test --no-pub` | 270/270 pass, 22s, không skip. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass, 0 fail/skip. |
| `tool/test_emulators.ps1` | 39/39 Rules + 9/9 SDK pass, SDK 19s; project demo-healthmate-rules, Auth 9099/Firestore 8080. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công, 11,8s; TEMP/TMP tại D:, không bật AI. |
| `git -c core.safecrlf=false diff --check` | Sạch. |
| `flutter devices` | Chỉ Windows/Chrome/Edge, không Android. |

36 test C3 trong core_journal_test.dart bao phủ ID favorite, copy qua nửa đêm/
tháng-năm/offset và chặn tương lai; nhóm bữa độc lập, tổng sau sửa/xóa, thêm đúng
ngày/loại; catalog lỗi không che logs. Recent có live/loading/error/retry/cache
và dùng lại snapshot khi catalog mất. Favorite có idempotency, pending, lỗi ghi,
retry, mất nguồn, tải hơn 40, đổi UID A→B và completion muộn. Copy có hủy không ghi,
retry cùng ID sau unknown ack, ID mới cho ý định mới, sửa ngày/giờ/loại/gram.
Catalog thiếu chất bị chặn cả khi là món gợi ý, không bị thay bằng món 0 kcal.
Giới hạn 5/6 món có test; giữ gram và snapshot dinh dưỡng.

UI có 18 tổ hợp 360/390/412dp × textScale 1/1,5/2 × sáng/tối, keyboard insets
260dp, favorite/mất nguồn và nút Save. Đã xem 3 ảnh dùng font thật trong ignored
build/c3-layout. Đây là render/widget test với insets mô phỏng, chưa phải Android
E2E hoặc bàn phím thật.

4 Rules test C3 mới kiểm tra owner CRUD/createdAt, guest/B bị chặn read/query/
write/delete; field/type/sourceKind/sourceId/docId/schema xấu, catalog không tồn
tại và nguồn mất vẫn bỏ favorite được. Client không được ghi catalog.
2 SDK test C3 mới dùng repository Firebase thật: favorite create/read/retry giữ
createdAt/remove, chặn đọc chéo; copy lưu/đọc lại và giữ 195 kcal dù catalog đổi,
đổi 100g thành 130 kcal, nguồn không đổi, dateKey/offset mới, một ID khi retry,
payload khác bị chặn, ý định copy mới dùng ID khác. Test offline kiểm tra ack lỗi
không đồng nghĩa rollback, reconnect/retry không trùng, favorite delete chờ mạng.
Cleanup xóa mọi collection A gồm favorite_foods trước Auth; favorite B vẫn còn.

Các hồi quy F01/F02/F05/F06/R01 và C1/C2 được chạy lại. Các lần đầu có lỗi test
cuộn tới vị trí cũ, assertion đếm catalog đã bỏ khỏi UI và finder Tooltip trả
RawTooltip. Đã sửa thao tác test theo key/vùng hiển thị, giữ assertion 195/130 kcal,
150/100g, số document và ý nghĩa hồi quy. Kết quả cuối ở bảng, không che fail.

GET Rules production read-only lúc 12:45:30 UTC+07 ngày 17/10/2026: release vẫn
2026-10-13T06:25:21.345792Z, normalized SHA256
`0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`, thiếu match
favorite_foods/nutrition_targets/goals/daily_quests/chat_sessions.
**Local C3 đạt trong phạm vi test/build; production chưa đạt.** Không deploy
Rules/index, seed/migrate/delete production, commit/push, bật billing hoặc gọi AI.
Hướng dẫn deploy với project cụ thể trong core-scope chỉ là tài liệu, chưa chạy.

Giới hạn: chưa Android E2E, APK debug x64 chưa phải ARM/release; cảnh báo KGP của
plugin Firebase còn; draft chỉ giữ RAM và mất khi tắt app. Không cài/uninstall/
clear app hoặc đụng session thật. Sau khi Rules được triển khai có chủ đích, cần
xem trên Android với tài khoản QA: hai log cùng bữa → thêm qua favorite/recent →
copy/sửa ngày giờ gram → hủy/retry → kiểm tra tổng; chữ lớn/sáng tối/keyboard và
switch UID. Không dùng tài khoản sức khỏe thật thử cleanup.

Log ignored: build/c3-{baseline,tests,analyze,format,emulators,catalog,build}.log,
build/c3-production-rules.json; ảnh build/c3-layout. Chi tiết file/luồng C3 và kế
hoạch tiếp theo: docs/core-scope.md. Chỉ C3; chưa thực hiện C4.

## Core C4 — kiểm chứng mới ngày 17/10/2026

Checkout main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`; bảo toàn thay đổi
C1–C3 chưa commit. Baseline270/270 Flutter pass19s. Windows, Flutter3.44.1/
Dart3.12.1/Java21, SDK thực qua Chrome; dữ liệu tổng hợp trên demo Emulator.

| Lệnh thực tế | Kết quả cuối C4 |
|---|---|
| `dart format lib test integration_test`, sau đó `dart format --output=none --set-exit-if-changed lib test integration_test` | 172file, không còn thay đổi ở kiểm tra cuối. |
| `flutter analyze --no-pub` | No issues found,7,4s. |
| `flutter test --no-pub` | 308/308 pass,39s,không skip;38test C4 mới. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | 47/47Rules +11/11SDK pass,SDK19s; project demo-healthmate-rules, Auth9099/Firestore8080. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công45,5s; TEMP/TMP trên D:, không bậtAI. |
| `git -c core.safecrlf=false diff --check` | Sạch. |
| `flutter devices` | Windows/Chrome/Edge, không Android. |

38test C4 bao phủ serialization, alias/list bất biến, scale4chất, yield khác tổng
nguyên liệu, phần thập phân, bound0/âm/NaN/Infinity, thiếu macro/cặp khẩu phần,
6/vượt6dòng và lỗi dòng giữa/cuối/nested recipe. Widget test CRUD món riêng,
recipe chọn catalog và món cá nhân, thêm0,5phần đúng ngày thành snapshot, không
ngầm lưu thư viện, nguồn thư viện đã lưu nhưng bữa lỗi/retry, ack không rõ/pending
20s/double tap/cùng ID, logout và completionA đến sau khi chuyểnB, pagination41,
favorite đọc trực tiếp nguồn ngoài trang đầu và3namespace độc lập, lỗi đọc/cache/
missing/retry, route thư viện qua Auth. Kiểm tra macro0 phải nhập chủ động, không
coi trường trống là0; kiểm tra dinh dưỡng sau quy đổi không vượt MealItem bounds.

18tổ hợp360/390/412dp × textScale1/1,5/2 × sáng/tối: cả form món và recipe6dòng,
chỉnh dòng cuối, nhập một lần có checkbox thư viện, keyboardinsets260dp, Save vẫn
trong vùng bấm. Font Be Vietnam Pro/MaterialIcons nạp thật; đã xem4ảnh tại ignored
build/c4-layout. Đây là render/widget test, không E2E/keyboard Android thật.

8Rules mới kiểm tra CRUD/query owner, guest/B không đọc/ghi/xóa/query A; field lạ,
kiểu sai/missing/NaN/Infinity, cặp khẩu phần và alias mọi vị trí, createdAt bất
biến, recipe đủ6/vượt6/lỗi dòng0/2/5/nested, favorite cần nguồn đúngUID và vẫn bỏ
được khi nguồn xóa. Rule6dòng ban đầu vượt1.000expression; tối ưu binding số,
allowlist dùng chung và regex type/length; vẫn kiểm tra mọi dòng, không giảm test.
47Rules gồm các hồi quy catalog/MealLog/Profile/Goals/Quest/Chat cũ.

2SDK mới dùng FirebaseFoodLibraryRepository thật: create/read/update/delete,
watch server page, createdAt/retry/cùngID; six-row recipe, yield và phần thập phân;
MealLog và ingredient snapshots không đổi khi sửa/xóa nguồn; từ chối sửa nguồn
đã xóa; chặn B thao tác A; lỗi Source.server khi offline không biến thành missing,
write ack không rõ/reconnect/retry không trùng hoặc ghi đè payload khác, delete
pending tới reconnect. Cleanup thử A gồm custom_foods/recipes trước Auth và kiểm
tra custom food/recipe/favorite B còn nguyên. Emulator localhost/demo guard giữ
nguyên; không chạy seed hoặc cleanup trên production.

Các hồi quy F01/F02/F05/F06/R01/C1/C2/C3 giữ ý nghĩa. Điều chỉnh ensureVisible/
pump cho vị trí mới khi form có5nguồn, giữ assertion dinh dưỡng/số bản ghi cũ;
test nhập một lần điền0macro chủ động thay vì dựa vào field mặc định. Test CRUD
phát hiện confirm xóa dùng context của nested Navigator, đã sửa dialogContext
và chạy lại thành công. Một lượt compile bị ngắt; một lượt full test lỗi thật
errno112 khi copy compiler file trên C. Không hạ assertion/skip để che lỗi; chuyển
TEMP/TMP sang D và chạy đủ308test. Lệnh môi trường dùng ở lượt cuối:

```powershell
$env:TEMP = 'D:\HealthMateMaintenanceQA\tmp'
$env:TMP = $env:TEMP
```

GET Rules production read-only lúc16:11:23UTC+07 ngày17/10/2026: project
healthmate-app-20261013, releaseupdateTime2026-10-13T06:25:21.345792Z, normalized
SHA256 `0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Chưa match custom_foods/recipes/favorite_foods/nutrition_targets/goals/
daily_quests/chat_sessions. **Local C4 đạt trong phạm vi trên; production chưa đạt.**
Chưa deploy Rules/index, push/commit, billing, migration hoặc gọiAI. Không thay
package/config/schema MealLog; các field nguồn mới nằm trong namespace foodId.

Giới hạn: chưa E2E Android hoặc cài APK, APKdebugx64 chưa ARM/release; warningKGP
của plugin Firebase đã có vẫn còn. C ít chỗ trống, QA Flutter dùng thư mục tạm D.
Không clear/uninstall app, thay session hoặc xóa dữ liệu người dùng. Draft chỉ
RAM, mất khi đóng app. Sau deploy được yêu cầu riêng, cần QA Android với tài khoản
thử: CRUD nguồn → recipe yield/0,5phần → bữa → sửa/xóa nguồn → kiểm tra lịch sử →
favorite nguồn mất → offline/retry/đổiUID; xem chữ lớn/sáng tối/keyboard/nútSave/
confirmdelete. Không dùng tài khoản sức khỏe thật để thử cleanup.

Log ignored build/c4-{baseline,tests,analyze,format,emulators,catalog,build}.log;
build/c4-tests-environment.log giữ lỗi dung lượng; build/c4-production-rules.json
chỉ có metadata/hash/boolean. Ảnh build/c4-layout. Danh sách file/luồng/schema và
hướng dẫn deploy chưa chạy trong docs/core-scope.md phầnC4. Chỉ C4; chưa C5.


## Core C5 — Tiến độ, cân nặng và tổng hợp tuần (17/10/2026)

Chỉ C5 theo file Sửa; main/HEAD86238197 không đổi, working tree C1–C4 được giữ.
Không stage/commit/push/deploy/migration/billing hoặc gọi AI. Flutter3.44.1,
Dart3.12.1/Windows/Java21; TEMP/TMP D:\HealthMateMaintenanceQA\tmp. Kết quả mới:

| Lệnh | Thực tế cuối C5 |
|---|---|
| Baseline flutter test --no-pub | 308/308pass,33s |
| dart format lib test integration_test + kiểm tra --output=none --set-exit-if-changed | 174file,0đổi ở check |
| flutter analyze --no-pub | No issues found,7,1s |
| flutter test --no-pub | 337/337pass,41s,0skip |
| node --test tool/food_catalog.test.cjs | 7/7pass,0fail/skip |
| tool/test_emulators.ps1 | 47/47Rules +13/13Flutter SDK pass; SDK21s; demo-healthmate-rules |
| flutter build apk --debug --no-pub --target-platform android-x64 | Thành công,21,6s; build/app/outputs/flutter-apk/app-debug.apk |
| git -c core.safecrlf=false diff --check | Sạch |

29test C5 mới trong progress_test: tuần qua tháng/năm và Thứ Hai, ghi0 vẫn có ngày
trong mẫu số, missing không thành0, future không cộng, tổngmacro/nước/phút, cân
sort/real timestamp gaps, ít điểm, loading/error/retry/timeout, đổi tuần liên tục
và giữ tuần qua tab, đổi UID/pending, quick weight giữ draft/chặn nhấn lặp/logout,
Auth/deep link/push/back.18layout360/390/412 × scale1/1,5/2 × sáng/tối với font
Be Vietnam Pro thật, cả weekly chart và weight chart. Ảnh ignored build/c5-layout;
đã xem sáng100%/tối200%, sửa padding nhãn y và gợi ý vuốt chart chữ lớn.
Core_scope18matrix cũng đi qua Progress và xác minh AI vẫn không được khởi tạo.

Hai SDK C5 dùng Firebase repositories thật: lưu/đọc lại bữa/nước/vận động/cân nặng
một tuần qua năm mới, khớp600kcal/40gP/80gC/12gF/250ml/20phút,2ngày ghi và300kcal
trung bình, cân70→69,5 đúng ngày, không lấy lần cân ngoài tuần, B không đọc A.
Fixture chỉ emulator, không số liệu mẫu trong app. Target range kiểm tra base từ
trước tuần, đổi trong tuần, loại biên end, giữ mục tiêu cũ khi sửa bản mới, khoảng
sai, trước bản đầu, đọc server offline và B bị từ chối, dữ liệu hỏng không thành0.
47Rules kiểm tra owner/guest/B/allowlist/giới hạn; cleanup A trước Auth giữ dữ liệu B
được chạy lại. Không sửa Rules/index/schema/dependency C5 hoặc chạy migration.

Lượt full đầu334pass/1fail: Profile scrollUntilVisible tìm nhiều Scrollable sau
khi chart cuộn ngang. Đổi ensureVisible đúng nút sửa/xóa, giữ mọi assert CRUD rồi
chạy lại đủ337pass. SDK bổ sung ban đầu compile fail do tham số fixture sai;
sửa nutrition/source, chạy lại13/13pass. Info lint ban đầu đã sửa. Không skip hoặc
hạ assertion/Rules để che lỗi. Log lỗi vẫn nằm ở build/c5-tests.log và
build/c5-emulators-compile.log; các log kết quả cuối dùng hậu tố -final (riêng
catalog/format-check không hậu tố này). Không dùng số lượt cũ làm kết quả hiện tại.

GET Rules production chỉ đọc16:33:55UTC+07,17/10/2026: healthmate-app-20261013,
release2026-10-13T06:25:21.345792Z, normalized SHA256
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade. Thiếu match
nutrition_targets/favorite_foods/custom_foods/recipes/goals/daily_quests/chat_sessions.
Metadata/hash/boolean trong ignored build/c5-production-rules.json; không chứa token
hoặc dữ liệu sức khỏe. Chưa deploy. **Local C5 đạt; production chưa nghiệm thu.**

Không Android trong flutter devices (chỉ Windows/Chrome/Edge); chưa E2E máy thật,
chưa cài/clear/uninstall/đổi session app. APK debugx64, chưa ARM/release. KGP warning
Firebase plugins cũ còn; C ít dung lượng nên Flutter QA dùng TEMP/TMP D.
Cần review và yêu cầu deploy riêng rồi QA Android: tổng tuần vs Journal, mục tiêu
lịch sử, sparse weight/ngày đo, quick+/save/retry/offline/UID,4tab ở chữ100/150/200%,
sáng/tối, vuốt chart, keyboard/safe area. Báo cáo tuần cần mạng, có refresh sau sửa
nhật ký; draft chỉ RAM. Dừng C5, chỉ đề xuất C6, chưa thực hiện nghiệm thu C6.

## Core C6 — Nghiệm thu Android và bàn giao (17/10/2026)

Chỉ C6/file Sửa. Main HEAD86238197a9f8e24a2222da2da9e74164c35844ea;
working tree C1–C5 có sẵn được giữ. Không stage/commit/push/deploy/migration/
billing, không bật hoặc gọi AI. Flutter3.44.1/Dart3.12.1/Java21 trên Windows.
TEMP/TMP D:\HealthMateMaintenanceQA\tmp; native project copy trên D do ổ C còn
khoảng157MB. Không sửa lock/dependency; pub get --offline chỉ tái tạo tooling copy.

### Lệnh và kết quả thực tế

| Lệnh/phạm vi | Kết quả C6 |
|---|---|
| Baseline flutter test --no-pub | 337/337pass34s |
| dart format lib test integration_test test_driver | 178file,0đổi ở lượt cuối |
| dart format --output=none --set-exit-if-changed lib test integration_test test_driver | Exit0,178file/0đổi,0,8s; build/c6-format-check.log |
| flutter analyze --no-pub | No issues found10,8s |
| flutter test --no-pub --reporter expanded | 349/349pass37s,0skip |
| node --test tool/food_catalog.test.cjs | 7/7pass,142,9ms,0skip |
| tool/test_emulators.ps1 | 47/47Rules pass15,7s +14/14Flutter Firebase SDK pass22s; demo-healthmate-rules |
| tool/test_android_core.ps1 -DeviceId emulator-5560 -CrossDriveBuild | Exit0,10/10checkpoints,137s; Flutter driver báo All tests passed |
| flutter build apk --debug --no-pub --target lib/main.dart --target-platform android-arm64 | Pass24,8s trên copy D; APK150691276bytes |
| gradlew :app:processReleaseMainManifest --offline (bổ sung) | Fail7s: chưa cache io.flutter armeabi_v7a_release/arm64_v8a_release/x86_64_release; không có kết quả release merged manifest |
| git -c core.safecrlf=false diff --check | Exit0,sạch; build/c6-diff-check.log; không stage |

12test mới (core_acceptance_regression_test) kiểm tra: success/error UID A trễ
không thay trạng thái B; đổi UID sau reauth không đổi mật khẩu B; cleanup A về
trễ không xóa Auth B;2form hồ sơ/cân giữ draft khi lỗi/retry; lần cân sau onboarding
hôm nay là mới nhất; sửa cân giữ nguyên giờ/microseconds;2form pending bỏ khi logout;
active stream error giữ lỗi, Future cancel lỗi không thoát sang phiên mới.
SDK mới kiểm tra expectedUid sai từ chối cả reauth/updatePassword/delete và tài
khoản vẫn đăng nhập/hoạt động bình thường sau đó. Các test F01/F02/F05/F06/R01,
ngày trống/nửa đêm/timezone/tuần qua năm mới, schema/ownership/cleanup của C1–C5
được chạy lại, không bỏ hoặc hạ assertion. Rules C6 không sửa so với C5.

### E2E Android native với dữ liệu thử tách biệt

AVD riêng HealthMateMaintenanceQA/emulator-5560, Android11/API30/x86_64,
1080x2280/density440 (~393dp), timezone Asia/Bangkok/UTC+07. AVD chạy headless
trên D, không dùng máy/AVD có phiên thật. Native Firebase SDK + repositories thật
và UI/router thật; không fake health repository. Named app healthmate-core-c6-qa,
project demo-healthmate-rules, Auth9099/Firestore8080 tại10.0.2.2; persistence false.
Tài khoản alice/bob-email QA được tạo mới trong emulator; catalog một fixture
tổng hợp có nhãn QA. Không gửi dữ liệu thử vào Firebase production.

1. Đăng ký/onboard A, đọc hồ sơ isOnboardingComplete từ repository thật.
2. Fixture mục tiêu hôm qua1800; UI hôm nay2000; đọc lại lịch sử vẫn1800.
3. Chọn catalog fixture, nhập150g →195kcal và lưu qua form/SDK.
4. Sửa200g →260kcal; copy sang hôm qua có ID khác, gram/snapshot đúng; Journal
   hôm qua hiển thị260/1800 thay vì dùng mục tiêu hôm nay.
5. Thêm350ml nước/25phút vận động/69,5kg, cân mới nhất đúng; tuần có2ngày ghi,
   520kcal,12gđạm/112gtinh bột/1,2gbéo,350ml/25phút, khớp dữ liệu thật.
6. UI tạo món200kcal/100g; recipe nguyên liệu100g/yield80g/2phần →250kcal/100g.
7. Ghi0,5phần=20g/50kcal; sửa món thành300kcal/100g, đổi yield160g rồi xóa món/
   công thức; MealLog50kcal và bữa260kcal còn nguyên.
8. DisableNetwork, lưu target2100: form giữ draft/lỗi; enableNetwork/retry chờ
   ack, document đúng2100; hôm qua1800, chỉ2phiên bản theo ngày, không trùng.
9. Chọn theme tối và native textScale200%, điều hướng Tiến độ, không exception.
10. Logout A, đăng ký/onboard B; B thấy tuần chưa ghi nhật ký và không lẫn món A;
    SDK từ B đọc targets A bị từ chối, own-target B null. AI flagsfalse và các
    controller/service Chat/Knowledge/Scanner chưa được khởi tạo.

Log **build/c6-android.log**,4PNG hợp lệ **build/c6-android/c6-01-journal-history.png,
c6-02-progress.png,c6-03-dark-large-text.png,c6-04-account-isolation.png**, được
driver ghi trong lượt pass17:26:26UTC+07. Đã mở xem bằng mắt Nhật ký ngày cũ,
Tiến độ có dữ liệu, tối/chữ200% và B trống. PNG tối chữ lớn đang ở đầu báo cáo;
không dùng ảnh đó làm bằng chứng đã xem mọi điểm biểu đồ. Native keyboard/scroll
được thao tác trong luồng, không warnIfMissed=false. Các matrix widget sáng/tối/
360–412dp/font100/150/200% và chart/công thức dài vẫn trong full349tests.
AVD và backend QA đã tắt sau khi xong; không xóa/clear/wipe app có phiên thật.

### Lỗi đã tìm thấy và các lượt chưa đạt

Baseline/new regression ban đầu tái hiện lỗi session/form. Sau sửa,20test liên
quan pass; sau thêm timestamp/cancel tests,51test nhóm liên quan pass11s rồi full
349pass. Log before/after được giữ trong build/c6-regression-*.log; không đổi
assertion để làm code lỗi thành pass.

Native build đầu lỗi Kotlin incremental different roots giữa cache C và source D.
Chỉ env override chưa đủ; runner nay tạm thêm kotlin.incremental=false vào copy
gradle.properties rồi khôi phục nguyên bytes trong finally. Các lượt flutter test
đầu thử uninstall package QA chưa tồn tại và báo DELETE_FAILED_INTERNAL_ERROR;
không có session thật bị gỡ. Runner cuối dùng flutter drive --keep-app-running.
Các lỗi harness tiếp theo: IME resize làm tap chưa vào nút, DatePicker OK khác
confirmText Chọn, convertFlutterSurfaceToImage chỉ được gọi một lần. Đã sửa helper
đúng API, không bỏ assert nghiệp vụ. Logout từ Profile giữ return destination
Profile; test nay xác nhận đã vào app shell rồi bấm Home, không giả định router
phải tự đổi về Dashboard.

Native cũng phát hiện2lỗi sản phẩm: cân mới cắt giờ về00:00 không thành latest;
Firestore async* cancel báo domain error khi logout sau consumer đã dispose.
Đã sửa timestamp và biên hủy subscription kèm test; active errors vẫn tới UI.
Cleartext emulator bị Android từ chối: debug-only config mở10.0.2.2/127.0.0.1/
localhost, base cleartextfalse; không bật cleartext toàn app hoặc đổi release.
Lượt native cuối đủ10checkpoint, không còn lỗi unhandled khi đổi UID.
Các log thất bại nằm D:\HealthMateMaintenanceQA\c6-android-{first,second,third,
drive1,drive2,drive3,drive4,drive5}.log; lượt pass drive6.log. Không lấy ảnh48byte
từ thử nghiệm cache-pull lỗi làm bằng chứng;4PNG cuối đã được driver ghi đè hợp lệ.

### Build, snapshot và quyền riêng tư

APK thường: **D:\HealthMateMaintenanceQA\HealthMate-core-debug-arm64.apk**,
150691276bytes, SHA2560a3a8ad877016891f532aeb68b6be95f7603985bb39267d56a99bf8c401ecd6e.
ZIP kiểm tra có lib/arm64-v8a/libflutter.so. Target lib/main.dart, AI mặc địnhfalse;
APK E2E không được dùng thay APK sản phẩm. Chưa cài máy thật hoặc ký release.
build/c6-snapshot-parity.json so SHA256213file nguồn/test/assets/Android/config/
Rules/scripts với copy D:0mismatch; gradle.properties đã phục hồi. Reports/README
được cập nhật sau kiểm tra, không tham gia code hash. Log build/c6-build-arm64.log.
Kiểm tra release offline bổ sung bị thiếu cache như bảng trên; log c6-release-
manifest.log, không coi lỗi môi trường này là release đã build thành công.

Scan155file lib/tool/integration_test/test_driver/android/app/src với pattern
private-key/service-account/OAuth/GitHub token:0findings; build/c6-secret-scan.json
chỉ lưu metadata. Scan có phạm vi hữu hạn; Firebase client config public không
được coi là credential Admin. Không in token CLI hoặc dùng tài khoản sức khỏe thật.

### Production, blocker và bước sau

GET Rules/index metadata chỉ đọc lúc17:04:32UTC+07,17/10/2026. Project
healthmate-app-20261013, releaseUpdatedAt2026-10-13T06:25:21.345792Z, SHA256normalized
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade, khác source.
Thiếu nutrition_targets/favorite_foods/custom_foods/recipes/goals/daily_quests/
chat_sessions; water/dateKey+consumedAt và activity/dateKey+performedAt indexes
READY. Metadata/hash/boolean ở build/c6-production-rules.json; không token/data.
Không deploy Rules/indexes, không migration hoặc CRUD production trong C6.

**C6 local đạt. Production chưa nghiệm thu**; các phần mới có thể bị permission
denied nếu chạy backend đang triển khai. Cần review và yêu cầu deploy riêng trước
QA tài khoản thử trên điện thoại thật. Chưa kiểm chứng App Check/Play Integrity
thực, release signing, process death/draft qua đóng app. KGP warning các Firebase
plugins còn, không tự upgrade. Xem máy thật: số ngày/mục tiêu cũ, sparse chart/vuốt,
keyboard/back/safe-area,4tab, tiếng Việt, sáng/tối/font100/150/200%, offline/retry/
đổiUID. Cleanup chỉ thử tài khoản tổng hợp trên emulator. Báo cáo tuần cần mạng/
refresh sau sửa nhật ký; draft chỉ RAM. Dừng C6, chưa tự làm phần khác.
