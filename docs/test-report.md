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

## U1 — Nhật ký/Tiến độ và Firebase review (18/10/2026)

Chỉ U1 theo file PROMPT-Agent-Cai-Thien-HealthMate-UX-Firebase.md. REPO_ROOT là
checkout HealthMate2 hiện có, main/HEADfd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12,
working tree sạch lúc đầu. Không checkout/reset/clean/pull đè; U1 chưa commit/push,
U2/deploy, billing, migration/seed, App Check changes hoặc AI. Flutter3.44.1,
Dart3.12.1/Java21/Windows; TEMP/TMP D:\HealthMateMaintenanceQA\tmp.

### Kết quả thực chạy

| Lệnh | Kết quả U1 |
|---|---|
| Baseline flutter test --no-pub --reporter expanded |349/349pass36s; u1-baseline.log|
| dart format --output=none --set-exit-if-changed lib test integration_test test_driver |180file0đổi/exit0,0,63s; u1-format-check.log|
| flutter analyze --no-pub |No issues found43,8s; u1-analyze-final.log|
| flutter test --no-pub --reporter expanded |370/370pass64s,0skip; u1-tests-final.log|
| node --test tool/food_catalog.test.cjs |7/7pass273,9ms; u1-catalog.log|
| tool/test_emulators.ps1 |47/47Rules pass19,1s +14/14Firebase SDK pass24s; u1-emulators.log|
| tool/test_android_core.ps1 -DeviceId emulator-5560 -CrossDriveBuild |Exit0,10core checkpoints + viewport và Gần đây;164s; u1-android.log|
| flutter build apk --debug --no-pub --target lib/main.dart --target-platform android-arm64 |Pass39,6s trên copy D; u1-build-arm64.log|
| node --check tool/inspect_firestore_deployment.cjs |Exit0|
| tool/inspect_firestore_deployment.ps1 |GET cấu hình/backup thành công, không deploy; u1-firebase-inspection.log và u1-firebase-final.log|
| git diff --check |Kiểm tra cuối trong u1-diff-check.log|

Log trong build/ (ignored). Số test là kết quả lệnh lượt này, không cộng kết quả
2test độc lập được nhắc trong prompt hoặc dùng số C6 như kết quả U1.

21test mới u1_ux_test gồm2viewport sáng/tối (fixture đủ target3macro, không cuộn),
luồng recent ngày/loại bữa/gram/snapshot/1write;2loading/error có dữ liệu cũ bằng
FutureProvider refresh thật; target lỗi/retry giữ tổng; ngày trống/chưa đặt;
macro0/excess/UID sheet; weekly logs lỗi không thêm target query;12matrix
360×800/412×915×scale100/150/200%×sáng/tối, keyboard260dp không che nút Lưu.
Giữ assertion nghiệp vụ cũ: target lịch sử/late response, mean mẫu số, tuần ranh
giới, no extra queries/listeners, stale UID, F01/F02/F05/F06/R01, snapshot/copy,
idempotency/offline/retry, favorites/library/recipe và cleanup.

### UX và ảnh trước/sau

[Gallery kèm ảnh/JSON đã lưu trong repo](ux/u1/README.md), cùng390×844/100%, font
đóng gói thật, fake repositories/synthetic data: ngày18/10/2026,2bữa195kcal khác
ngày, target2000kcal/100gP/250gC/60gF,750ml/25phút, cân70→69,5kg. 8ảnh trước/sau,
sáng/tối, scroll offset0. Trước sửa: addBreakfast1319–1367, chart888–1128;
sau: addBreakfast497–545, chart362–602; viewport không bị bottom bar che đến748dp.
Test đo full rect và hitTestable của nút, chart/range/tổng; không ensureVisible
hoặc cuộn trước assertion viewport đầu. Chữ lớn được đọc/cuộn thay vì ép chiều
cao/font. Đã mở ảnh sáng/tối và ảnh native để xem bố cục/số/nhãn/biểu đồ.

Luồng Gần đây giữ5bấm,0search,1xác nhận khẩu phần đã có,0xác nhận mới; cuộn1→0.
Baseline flow được chạy lại trên copy UI/formfd2f72b (6blob đã so,0mismatch),
không checkout ngược source người dùng. Saved16/10/Bữa sáng/150g195kcal/1write;
khác quy tắc global+ hôm nay. Các phép đo không được suy thành benchmark người
dùng hoặc tốc độ mạng. Fixture/ảnh không phải số liệu sức khỏe production.

### Android SDK/repository thật qua backend demo

AVD riêng HealthMateMaintenanceQA/emulator-5560, Android11/API30/x86_64,
1080×2280/density440/UTC+07, named Firebase app QA, demo-healthmate-rules tại
10.0.2.2:9099/8080. Đã đọc runner và xác minh AVD/project; không dùng máy/phiên
người dùng, không clear/wipe hoặc fixture production. QA AVD đã tắt khi xong.

Kịch bản core cũ vẫn đủ10checkpoint: onboarding, target hôm qua1800/hôm nay2000,
thêm150g195kcal/sửa200g260kcal/copy giữ snapshot và ngày,350ml/25phút/69,5kg,
tuần thật520kcal từ2ngày trước bữa recipe, CRUD món/công thức/giữ MealLog50kcal,
offline target2100/retry chỉ2phiên bản/giữ hôm qua, tối chữ200%, logout/A→B và
permission denied khi B đọc A. AI flagsfalse/service không khởi tạo.

Thêm target đủ100gP/275gC/60gF cho native viewport: addBreakfast584–632dp trong
body đến685,1dp và hit-test được; chart top386dp, range và tổng hit-test được,
không cuộn trước đo. Sau core bước8, recent5bấm/khôngsearch/gram200/260kcal/
ngày hôm nay/Bữa sáng và3MealLog. Cuối tuần tổng830kcal vì đã thêm bữa recipe50
và recent260, không coi khác fixture520 ban đầu là lỗi tổng.5PNG từ driver ở
build/u1-android,2ảnh viewport copy vào gallery; không dùng last-screen teardown
trống làm bằng chứng UI. Đây là Android emulator, không điện thoại thật/cloudE2E.

### Các lượt chưa đạt và cách xử lý

Lượt full đầu337pass/14fail: title cũ, tổng cũ bị gộp, target/daily details đang
đóng và drag700 cố định làm trượt qua nút mới. Cập nhật finder về journal-screen,
kiểm tra kcal và từng macro, mở details rồi giữ các assert lịch sử/quyền/query,
ensureVisible đúng action trong test thao tác (không dùng trước viewport proof).
Luồng recent mới ban đầu thiếu thao tác xác nhận khẩu phần **đã có** nên nút Lưu
bị dialog chắn; thêm thao tác đó vào cả trước/sau, không đổi production flow.
Lượt focused ban đầu còn2fail (recent và label0macro cũ), sau sửa test pass.

Analyze đầu có unused totals và test gọi copyWithPrevious internal; bỏ biến thừa
và dùng FutureProvider refresh thật để kiểm tra stale data, không ignore lint.
Harness Android đầu thiếu import MealType; thêm import, chạy lại thành công.
Một lượt test sau thay helper thiếu import Completer, đã thêm lại dart:async;
final21UX tests rồi full370pass và analyze sạch. Không xóa test/hạ Rules/assert
để che lỗi; log first/related và D:\HealthMateMaintenanceQA\u1-android.log giữ
lỗi trước sửa, lượt pass native là u1-android-second.log (copy thành build/u1-android.log).

AVD SwiftShader có log Impeller/GLES shader active uniforms exceed GL_MAX_FRAGMENT_
UNIFORM_VECTORS; ảnh thật đã xem có đầy đủ card/chữ/biểu đồ và E2E không có test
exception. Không sửa engine hoặc bỏ bảo vệ app; chưa xác minh mọi GPU/máy thật.
KGP warning Firebase plugins còn. App Check placeholder chỉ ở named emulator app;
production App Check không bị đổi/tắt. Không có kết quả release build trong U1.

### Build, cấu hình và giới hạn

APK thường lib/main.dart debug ARM64 **D:\HealthMateMaintenanceQA\HealthMate-U1-debug-arm64.apk**,
150690083bytes, SHA256
cd9796fbc43159db9db001536752d20eb37cf9c596fa86a6c5bc8a708173b4a0.
APK này khác test target; APK C6 cũ được giữ. Copy source D khớp217file Dart/test/
asset/Android/Rules/config/script (build/u1-source-parity.json),0mismatch;
gradle.properties override Kotlin incremental khác ổ chỉ tạm trên QA copy,
finally đã khôi phục. Không nâng/cài package mới hoặc đổi pubspec/lock.

Ổ C có lúc còn100MB; giữ tmp/build native ở D và chuyển **artifact generated**
build/app cũ968MB sang D:\HealthMateMaintenanceQA\archived-project-build-app-20261018
sau xác minh absolute source/destination. Không xóa dữ liệu/cache ngoài công việc,
không thay source hoặc APK C6 đã bàn giao; C còn khoảng1GB sau chuyển.

Rules/index local không đổi từfd2f72b: SHA256LFtrimd33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877.
Đã review owner/schema/bounds/timestamps và chạy lại47Rules +14SDK, gồm guest/B
read/query/write bị chặn và cleanup A giữ B. Không thêm query/listener/schema/index.
Tool inspect chỉ GET Rules release/source, database metadata và indexes; auth CLI
ở RAM, output metadata/source/config rollback không có credential hoặc dữ liệu
sức khỏe. Tool yêu cầu output build mới, không overwrite backup cũ.

Production GET cuối **19:12:59UTC+07,18/10/2026**: healthmate-app-20261013,
database(default)/asia-southeast1/FIRESTORE_NATIVE, CLI15.22.4. Release update
2026-10-13T06:25:21.345792Z, rulesetb83d6f60-1e9a-49b3-a3e7-239ccf0d3ee0,
hash0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade,
matchesLocalfalse. Vẫn thiếu create/update targets/favorites/custom/recipes/goals/
quests/chat;2water/activity composite indexes READY, không cần index mới.
Backups build/u1-firebase-review và u1-firebase-final, diff252thêm/7bỏ so với
production; không phải diff Rules mới do U1. [Playbook](firebase-deployment-plan.md)
có commit/hash/đích, exact command chỉ Rules, GET xác minh/rollback và QA sau U2.

**Local U1 đạt / Rules production chưa deploy / E2E production chưa kiểm chứng.**
Chưa tài khoản QA production được giao, chưa máy thật/Play Integrity/release
signing. Draft chỉ RAM và báo cáo cần mạng/refresh như core cũ. Giữ AI tắt,
không tự tạo tài khoản cloud/thử xóa thật. Dừng U1; U2 chỉ sau yêu cầu rõ từ chủ
sản phẩm. Bảng/lệnh deploy trong playbook là phần chuẩn bị, chưa được thực thi.

## U2 — deploy Rules và kiểm thử production thật (18/10/2026)

Đây là kết quả sau yêu cầu hoàn tất toàn bộ file UX/Firebase, thay trạng thái U2
còn chờ trong phần lịch sử U1. Người dùng cho phép tạo đúng hai tài khoản QA có
dữ liệu tổng hợp và chỉ dọn dữ liệu QA. Base main/fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12;
giữ working tree U1, chưa stage/commit/push. Không thay app code trong U2.

### Kiểm tra mới thực sự đã chạy

| Lệnh/kiểm tra U2 | Kết quả |
|---|---|
| `.\tool\test_emulators.ps1` | 47/47 Rules + 14/14 Firebase SDK, exit 0; SDK 20 giây |
| `firebase deploy --only firestore:rules --project healthmate-app-20261013` | Exit 0, release chỉ Rules thành công |
| Inspect GET trước, sau deploy và cuối production QA | Đúng project/default DB; sau deploy/final hash khớp local; hai indexes READY |
| `.\tool\test_production_qa.ps1 -AllowProductionQa -CredentialsFile <PRIVATE_FILE> -VerifiedDeploymentDirectory <VERIFIED_METADATA>` | Flutter test Chrome/backend production: **1 scenario, 10 checkpoint, 27 giây, pass cả teardown** |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 180 file, 0 thay đổi, exit 0 |
| `flutter analyze --no-pub` (cuối) | No issues found, 6,7 giây, exit 0 |

Analyze đầu báo một unnecessary import dart:async ở harness mới (57,6 giây);
đã bỏ import thừa rồi chạy analyze sạch. Không sửa/hạ test để che lỗi. Flutter
370/370, catalog 7/7, Android API30 E2E và build APK là lần chạy **U1** đã ghi ở
trên, không phải chạy lại trong U2. Không có thay đổi sản phẩm sau lần U1 đó.

### Deploy và khả năng phục hồi

Trước deploy GET lúc 19:31:42 UTC+07: Rules release cũ 13/10/2026, hash
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade.
Backup đầy đủ source/metadata/firebase.rollback.json tại
`D:\HealthMateMaintenanceQA\u2-before-20261018-193138`; đã so bản copy trước deploy.
Rules/index source không đổi so với fd2f72b; không thêm diff vô nghĩa.

Release mới 2026-10-18T12:33:45.507953Z (19:33:45 UTC+07), ruleset
423ff6c8-79b7-4158-ba4f-2de9871a715d. Hash LF-trim deployed/local cùng
d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877;
matchesLocal=true trong hai GET sau deploy và cuối QA. Hai composite water/activity
vẫn READY. Không deploy indexes hoặc chạy rollback; không đổi App Check/billing.
[Metadata và log đã lưu](firebase/u2/README.md),
[lệnh rollback chỉ Rules](firebase-deployment-plan.md).

### SDK E2E production và dữ liệu QA

Chrome headless, Firebase Web SDK thật và repository/model ứng dụng thật; named
apps A/B/guest tách khỏi default session, Auth persistence NONE, Firestore cache
không lưu đĩa. Hai QA email cố định có prefix/run; retry cùng credential, không
tạo tài khoản bổ sung. Credentials lưu ngoài repo với ACL riêng, không in log.
Harness không có hậu tố _test.dart nên full suite thông thường không gọi cloud.
Runner và Dart cùng chặn thiếu opt-in, sai prefix/project/hash hoặc credential
trong repo. Chạy từ QA copy D để artifact test riêng, không phân phối test build.

- Onboarding tổng hợp 18+, lưu/tải lại profile và cân nặng ban đầu.
- Target ngày cũ/mới, cập nhật hôm nay giữ lịch sử, query range thật.
- Món riêng, công thức và favorite retry idempotent; bữa 20g từ recipe 80g có
  50kcal. Sửa/xóa hai nguồn vẫn giữ 50kcal, scale snapshot 40g thành 100kcal;
  copy sang hôm trước vẫn 50kcal đúng ngày.
- Nước 250ml, đi bộ 20phút; query server dateKey/orderBy dùng index production.
- Goal tạo hai lần cùng ID vẫn một bản; Quest hoàn thành không reset khi ensure.
- Logout/login cùng UID, dữ liệu target/meal đọc lại đúng từ server.
- Tắt network 3 giây không xác nhận lưu; bật lại, đợi thao tác cũ kết thúc rồi
  retry cùng operation ID, đúng một bữa 50kcal. Không coi timeout là hủy write.
- **50** yêu cầu guest/B đọc/query/ghi/xóa vào A nhận permission-denied: profile
  và 11 collection core, thêm update profile/delete meal. Không chỉ nhìn Rules.
- Dọn dữ liệu Firestore A, xác minh B vẫn còn profile rồi dọn B. Đọc server xác
  nhận profile không tồn tại và cả 11 collection rỗng; teardown kiểm tra lại hai
  tài khoản. **Giữ hai Auth QA**, không thử xóa Auth production.

Không đọc/sửa/xóa hồ sơ thật, seed food_catalog, migration hoặc gọi AI.
Production SDK log + tổng hợp không credential ở docs/firebase/u2. Raw log và
credential riêng ở D:\HealthMateMaintenanceQA\u2-production-qa-20261018194000.
APK thường lib/main.dart U1 giữ nguyên, không chứa QA dart-defines; không rebuild
Android trong U2 vì source app không đổi và Rules nằm trên backend.

**Local đạt / Rules đã deploy đúng / SDK production E2E đã kiểm chứng.**
Không suy thành Android UI production, điện thoại thật, Play Integrity, release
signing hoặc mọi thiết bị/mạng đã đạt. Các giới hạn KGP/GPU/draft RAM ở U1 vẫn
còn. Hoàn tất file U1/U2 và dừng, không thêm giai đoạn hoặc push ngoài yêu cầu.

Kiểm tra bàn giao lúc 19:45 UTC+07: `git diff --check` sạch, parser PowerShell
runner không lỗi, scan chính xác QA password trên 37 file text thay đổi/bằng
chứng không có kết quả khớp (không phải chứng nhận quét mọi loại secret).
Staged 0; HEAD và origin/main đã biết vẫn fd2f72b; diff Rules/index/dependencies 0.
APK U1 thường giữ SHA256 cd9796fbc43159db9db001536752d20eb37cf9c596fa86a6c5bc8a708173b4a0.

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

## 20/10/2026 — UI/UX theo ảnh tham chiếu MyFitnessPal

Trên nền ba0557d cùng bản sửa palette cục bộ; chưa commit/push/deploy.
Báo cáo chi tiết: [mfp-ui-redesign.md](mfp-ui-redesign.md).

| Kiểm tra | Kết quả thực tế | Chứng cứ |
| --- | --- | --- |
| Format file Dart thay đổi | 25 file, 0 cần format ở lần kiểm tra cuối | Dart formatter exit 0 |
| Flutter unit/widget đầy đủ | **468/468 qua**, 52s, exit 0 | build/mfp-flutter-complete.log |
| Analyze | **0 error, 0 warning, 21 info**, exit 1 | build/mfp-analyze-complete.log |
| APK Android debug | **Build thành công**, 16.4s, exit 0 | build/mfp-build-complete.log |
| Ảnh widget QA | 24 ảnh, sáng/tối, cỡ chữ 1.0/1.5 | docs/ux/mfp/README.md |

Các info còn lại: withOpacity ở widget cũ, print của unified search và http
chưa khai báo trong dependencies chính. KGP warning xuất hiện lúc build.
Không gọi các info này là analyze thành công hoàn toàn.

14 test mới kiểm tra tương phản 4,5:1, dữ liệu thật qua fake repository, ngày
trống, phản hồi ngày cũ đến trễ, trạng thái tải/lỗi mục tiêu, mục tiêu tự đặt,
copy bữa chỉ lưu sau xác nhận, tab dùng chung range, xuất CSV mở đúng dialog,
retry báo cáo và search đảo thứ tự ở cả form standalone và thư viện món.
Các test cũ giữ xác nhận số liệu/UID/quyền thao tác/nháp/operation ID; cập nhật
cách mở báo cáo chi tiết và vùng bấm sau khi đổi UI. Hai fixture standalone
được bọc ProviderScope theo ConsumerStatefulWidget hiện tại. Không xóa test.

Các kết quả 48 hoặc 65 case lỗi trong log phát triển là các lượt trước sửa,
không phải trạng thái cuối. Toàn bộ suite trên source cuối qua 468 case.
Không chạy lại Firestore emulator/security hoặc production QA; không sửa Rules,
indexes/schema hoặc package. Chưa kiểm chứng camera/API online trên máy thật.

### 2026-10-20 — Thanh dưới 5 ô, hiện lại Scanner/Chat

- dart format 8 file Dart thuộc lượt sửa: qua, kiểm tra lại 0 thay đổi.
- flutter test --no-pub --reporter expanded: **485/485 qua**, 60 giây, exit 0.
  Log build/navigation-full-test-final.log. Thêm 16 widget test về 5 ô ở rộng
  320/390, textScale 1/1,5/2 và sáng/tối; tab chuyển đúng route, + ở giữa, vùng
  bấm >=48; mở Scanner không gọi camera/AI, Mục tiêu/Chat mở từ + và Thêm;
  barcode có mặt trong form thật dùng sourcesBuilder kể cả khi AI tắt.
  Thêm test mặc định cờ hiển thị mà không khởi tạo Firebase/AI. Các test core-only
  vẫn kiểm tra hai cờ false chặn AI và đường dẫn trực tiếp như trước.
- flutter analyze --no-pub: **21 info, 0 warning, 0 error**, exit 1. Đây là các
  info withOpacity/print/http có sẵn; không gọi analyze sạch. Lượt phát triển đầu
  có thêm 1 info thiếu ngoặc trong test mới, đã sửa.
- flutter build apk --debug --no-pub: qua, assembleDebug 26,3 giây, exit 0.
  APK build/app/outputs/flutter-apk/app-debug.apk; cảnh báo KGP còn tồn tại.
- Một lượt full trước sửa test cuộn có 484 qua/1 lỗi do locator Sửa khẩu phần
  chưa được dựng vì ngoài viewport; đã bổ sung scrollUntilVisible, giữ nguyên
  assertion ngày/loại/khẩu phần/tổng và dữ liệu gốc. 36 test nhật ký riêng qua
  sau sửa, rồi toàn suite cuối qua 485. Log lỗi giữ ở build/navigation-full-test.log.
- Đã xem ảnh widget render today-dark-1.0.png: 5 ô hiện đúng. Ảnh trong docs/ux/mfp
  tiếp tục là fixture tổng hợp, không phải dữ liệu thật hay kiểm tra điện thoại.
- Không chạy camera/AI/Open Food Facts thật, không thay/deploy Rules/indexes, không
  kiểm thử lại security emulator; các kiểm tra AI eligibility/consent hiện có vẫn qua.

### 2026-10-20 — Rút gọn UI, mở chi tiết theo nhu cầu

- Format 20 file Dart của đợt này: qua, kiểm tra lại 0 thay đổi.
- flutter test --no-pub --reporter expanded: **490/490 qua**, 65 giây, exit 0.
  Log build/compact-full-final.log. 5 test mới xác nhận nội dung phụ không dựng
  hoặc đọc Goals trước khi mở; mở/đóng vẫn giữ các chức năng; nút thông tin mở
  đúng giải thích và đóng được ở cỡ chữ 1/1,5/2; Barcode/Save còn trong form thật.
  Các test mục tiêu/weekly được cập nhật mở mục tổng kết trước khi kiểm tra;
  giữ nguyên assertions dữ liệu/UID/lưu/tổng/cạnh tranh async.
- flutter analyze --no-pub: **21 info, 0 warning/error**, exit 1, 21,7 giây.
  Không gọi analyze sạch. Log build/compact-analyze.log.
- flutter build apk --debug --no-pub: qua, assembleDebug 49,1 giây, exit 0.
  Log build/compact-build.log. APK build/app/outputs/flutter-apk/app-debug.apk.
- Các lượt phát triển đầu có lỗi finder sau đổi nhãn hoặc do nội dung mặc định
  đóng; đã cập nhật tương tác mở/đóng đúng header, scoped finder trạng thái tải.
  Lượt full trước cuối 489 qua/1 lỗi copy cảnh báo macro thiếu; sửa thành câu ngắn
  vẫn phân biệt — với 0, cập nhật assertion, toàn suite cuối qua 490. Không skip.
- Đã xem ảnh Today dark 1.0 được render lại: bỏ dòng UTC cố định và đoạn giải thích
  macro, thấy phần Bữa ăn sớm hơn; 5 ô vẫn rõ. Bộ ảnh fixture sáng/tối và chữ lớn
  tiếp tục sinh từ widget test, không phải kiểm tra trên điện thoại thật.
- Không chạy lại security emulator hay API/camera thật; không đổi nghiệp vụ,
  Firebase Rules/indexes/schema, dependency hoặc triển khai production.

### 2026-10-23 — Kiểm tra trước khi đồng bộ GitHub

- Theo yêu cầu người dùng, gom đầy đủ các thay đổi UI, thanh điều hướng 5 ô,
  Scanner/Chat, rút gọn nội dung, test, ảnh fixture và tài liệu bàn giao để commit/push.
- git fetch origin: main và origin/main cùng ở ba0557d trước khi tạo commit mới,
  không có commit remote cần hợp nhất.
- dart format --output=none --set-exit-if-changed trên 40 file Dart thay đổi/mới:
  0 file cần sửa, exit 0.
- flutter test --no-pub --reporter expanded: **490/490 qua**, 64 giây, exit 0;
  log build/github-push-test.log.
- flutter analyze --no-pub: **21 info, 0 warning/error**, 87,3 giây, exit 1;
  log build/github-push-analyze.log. Không gọi analyze sạch.
- Kiểm tra diff whitespace: qua. Rà soát danh sách file và mẫu private key/token
  phổ biến: không thấy mẫu khớp trong các file sẽ đưa lên; không đưa build, log,
  credential hoặc file cục bộ bị ignore vào commit. Ảnh UI dùng fixture tổng hợp.
- Không sửa mã nguồn nghiệp vụ trong lượt đồng bộ, không chạy lại build APK;
  kết quả build gần nhất của chính thay đổi này là bản debug qua ngày 20/10.
  Không deploy Firebase; kết quả push và mã commit xác nhận sau khi GitHub nhận.
