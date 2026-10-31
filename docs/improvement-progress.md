# HealthMate — tiến độ kế hoạch cải thiện

Ngày cập nhật: 31/10/2026. Kế hoạch đầu vào: `HealthMate-improvement-plan.md`
do chủ dự án cung cấp. Giữ các chỉnh sửa Gói 1–7; lượt hiện tại thực hiện
**Gói 8, 9, 10** theo yêu cầu trực tiếp làm ba gói cuối của chủ dự án.

## Baseline và phạm vi bằng chứng

- Branch bắt đầu: `main`; HEAD `0e897eca3cbdb7907012197830b9d365763e4faf`,
  đúng baseline của tài liệu. Working tree sạch trước khi bắt đầu.
- Đã đọc AGENTS.md; không có AGENTS.md lồng nhau được Git/file search tìm thấy.
  Giữ Flutter/Riverpod/Firestore, dependencies và cấu hình Android hiện có.
- Flutter 3.44.1, Dart 3.12.1, Node 24.18.0. Flutter chạy ở bản sao QA
  `D:/HealthMateMaintenanceQA/c6-workspace`; Gói 1 kiểm hash 441 file,
  Gói 3 kiểm hash 449 file source/config/assets. Không có build flag
  AI/production khi chạy test.
- Firestore Emulator local `127.0.0.1:8080`, chỉ các project `demo-*` của
  suite. Không ghi dữ liệu thật, không gọi model AI hoặc deploy production.
- Chỉ thực hiện ba gói cuối được yêu cầu trong lượt này. Gói 4 vẫn có
  fallback client, chưa có server job bền vững cho production; Gói 5 còn
  blocker hạ tầng AI. Các mục bên dưới Gói 1–7 là lịch sử kiểm chứng.

## Trạng thái các gói

| Gói | Trạng thái |
| --- | --- |
| 0 | Đã kiểm baseline cho phạm vi Gói 1–10; giữ các chỉnh sửa chưa commit |
| 1 | Đã xác minh local; chờ phát hành client và triển khai Rules |
| 2 | Đã xác minh local; chờ phát hành client |
| 3 | Đã xác minh local; chờ phát hành client và triển khai Rules phối hợp |
| 4 | Đã xác minh client fallback + Rules candidate local; server job/retention vẫn chặn production |
| 5 | Gateway + client/Rules candidate đã xác minh local; identity/IAM, chặn direct AI và retention vẫn chặn production AI |
| 6 | Query/history + migration tool đã xác minh local; chờ rollout client/Rules/indexes và migration được duyệt |
| 7 | Phân trang/export admin đã xác minh local; chưa publish web |
| 8 | Đã xác minh candidate local, chưa deploy |
| 9 | Đã tách form, rút README và thêm CI; xác minh local, kết quả CI hosted theo từng commit trên GitHub |
| 10 | Preflight/config/load probe local đã kiểm; signed release/native vẫn bị chặn bởi khóa ký/thiết bị và R1/Gói 5 |

## Gói 1 — hành vi trước và sau

- Trước: OFF 500 g protein/100 g tạo được snapshot; constructor trực tiếp
  cũng vượt qua. Sau: chọn cơ sở 100 g phải qua validator chung, kể cả khi
  khẩu phần rất nhỏ; không tạo snapshot có thể lưu nếu vượt giới hạn.
- `NutritionValidation.validPer100g`: kcal 0–1.000, từng protein/carb/fat/fiber
  0–100 g, hữu hạn. Ngưỡng năng lượng là trần kiểm tra dữ liệu có dung sai
  so với chất béo nguyên chất khoảng 900 kcal/100 g, không phải khuyến nghị
  ăn uống. Không cộng fiber vào carb hoặc buộc 4P+4C+9F bằng kcal.
- Barcode và USDA dùng chung validator cho cơ sở 100 g. Tại thời điểm hoàn
  thành Gói 1, tìm USDA chưa thay đổi. Tổng khẩu phần có thể hơn 100 g
  macro nếu khối lượng tương ứng hợp lệ; giữ các trần lưu hiện có.
- Số âm/NaN/vô cực/chữ không hợp lệ bị báo lỗi dữ liệu, không bị clamp hoặc
  chuyển thành 0. Macro/fiber thiếu vẫn có cờ unknown; số 0 thật vẫn known.
  Khoáng chất OFF chuyển g sang mg một lần; extras sai không bị bỏ âm thầm.
- Metadata, khẩu phần, hàng dưỡng chất và nút xác nhận thích ứng với chữ
  lớn. Nền sheet dùng màu surface của theme và chừa chỗ cho bàn phím/safe area.
  Món hợp lệ vẫn sửa lượng và thêm vào bữa được.

### Hợp đồng Open Food Facts và đơn vị

Đã đọc schema chính thức ngày 30/10/2026:

- [product_nutrition.yaml](https://github.com/openfoodfacts/openfoodfacts-server/blob/bd90d81d0353bf2af1474a9079b6fc2a51ac63d7/docs/api/ref/schemas/product_nutrition.yaml):
  `<nutrient>_100g` là giá trị chuẩn hóa **100 g hoặc 100 ml với chất lỏng**;
  các dưỡng chất khối lượng dùng g; energy/energy-kj dùng kJ, energy-kcal dùng kcal.
- [product_nutrition_properties.yaml](https://github.com/openfoodfacts/openfoodfacts-server/blob/bd90d81d0353bf2af1474a9079b6fc2a51ac63d7/docs/api/ref/schemas/product_nutrition_properties.yaml)
  và `lib/ProductOpener/Nutrition.pm` mô tả cơ sở `100g`, `100ml`, `serving`.
  V2 legacy không cung cấp một dấu hiệu đơn vị đáng tin cậy chỉ từ tên `_100g`;
  đơn vị bao bì hoặc khẩu phần không chứng minh cơ sở của bảng dinh dưỡng.

Do đó barcode từ OFF có `basis:unconfirmed`. Khách chọn **100 g / 100 ml theo
nhãn** trước khi thêm. Nếu không xác định được, chưa cho lưu tự động; có thể
quay về nhập theo nhãn. `serving_quantity` chỉ dùng làm gợi ý khi có đơn vị
g/ml rõ ràng và khớp lựa chọn. Không lấy `nutrition_data_per=100g` hay đơn vị
bao bì để đoán mật độ. Lựa chọn theo ml lưu `quantityUnit:ml`, `quantity`,
`grams:null` theo schema đã có. Không quy đổi 1 ml thành 1 g.

Giới hạn: đây là xác nhận cơ sở trên nhãn bởi người dùng, chưa tự xác minh
nhãn/mật độ. Trần 100 g không áp vào 100 ml hoặc quick-add theo lần ghi.

### Rules, tương thích và triển khai

- Candidate Rules chặn macro/fiber vượt khối lượng gram, kcal vượt 10 lần
  khối lượng gram; vẫn giữ trần tuyệt đối của từng item. Áp dụng meal schema
  2–5, kế hoạch dùng enriched item, recipe và template schema 1–4; custom
  food trên 100 g cũng có trần 100 g macro / 1.000 kcal.
- Fiber của compact template được kiểm cùng item và cùng đơn vị. Các
  boolean cố định được gom bằng `hasOnly([true])` để giữ giới hạn biểu thức
  của Rules với 5 món/6 nguyên liệu, không giảm số món hoặc bỏ kiểm tra UID.
- Không đổi schema/index, không migration hoặc sửa snapshot cũ. Đọc/xóa dữ
  liệu cũ vẫn theo quyền hiện có; ghi lại một bản cũ sai giới hạn sẽ bị từ
  chối đến khi người dùng chủ động sửa. Đây là thay đổi cần công bố khi rollout.
- Rules vẫn chỉ là candidate local. Trước triển khai: review diff, backup
  ruleset đang dùng, kiểm dữ liệu cũ bằng dry-run được cho phép, phát hành
  client tương ứng và xin quyết định production. Rollback Rules cần giữ
  bản trước; rollback mở lại giới hạn cũ, không khôi phục dữ liệu đã sửa.
- Không có APK mới, commit mới, GitHub push hoặc deploy trong Gói 1 này.

### Bằng chứng

- Test trước sửa: 5 test barcode cũ qua, **11 regression mới thất bại**
  (2 validation + 9 màn/cỡ chữ). Log `build/improvement-package1/flutter-red.log`.
  Assertion OFF sau xác minh hợp đồng được đặt tại bước xác nhận 100 g,
  vì parser không được tự giả định cơ sở của `_100g`; vẫn buộc từ chối trước
  khi tạo snapshot, không bỏ kiểm tra fixture 500 g đạm.
- Rules trước sửa: **1/4 qua, 3/4 thất bại** vì dữ liệu sai vẫn ghi được.
  Log `build/improvement-package1/rules-red.log`.
- Barcode regression: **24/24 qua**, gồm 320/360/412 px × text scale
  1/1,5/2 với AppTheme và font BeVietnamPro; chọn g/ml và lưu từ sheet ở
  320 px chữ 2. Kiểm lưu lượng, partial/zero, mineral conversion, direct
  constructor, phần ăn lớn và snapshot round-trip.
- Firestore suite cuối hiện tại: **95/95 qua**, exit 0; bữa 5 món, công thức
  6 nguyên liệu, unknown/zero, ml/serving/entry, hai UID và đọc snapshot cũ.
  Các vòng đầu phát hiện expression budget; đã tối ưu và giữ nguyên các
  assertion hợp lệ cũ. Log `build/improvement-package1/rules-all.log`.
- `flutter test --no-pub --reporter expanded`: **726/726 qua**, exit 0,
  khoảng **126s**. `flutter analyze --no-pub`: **No issues found**, exit 0,
  **104,2s**. Format 7 file Dart trong phạm vi; `git diff --check` qua.
  Log `flutter-all.log`, `analyze.log` trong `build/improvement-package1/`.
- Không chạy lại luồng Android/native, không build APK hoặc nghiệm thu
  production. Không cần chạy lại admin/chat suite vì không thay code tương ứng.
  Không suy số test thành bằng chứng đúng nhãn hoặc chính xác y khoa.
- Commit kết thúc vẫn là baseline cộng working tree Gói 1 chưa commit.
  Manifest hash source/Rules và thông tin môi trường:
  `build/improvement-package1/verification.json`.

Các file chính: `barcode_product_service.dart`, `barcode_product_models.dart`,
`barcode_product_detail_sheet.dart`, `nutrition_validation.dart`,
`usda_api_service.dart`, `firestore.rules`, `test/barcode_scanner_test.dart`,
`test/unified_meal_entry_test.dart`, `rules-tests/barcode-nutrition.rules.test.cjs`.

## Gói 2 — tìm USDA có giới hạn

- HEAD vẫn `main@0e897eca3cbdb7907012197830b9d365763e4faf`. Bắt đầu với
  working tree Gói 1 chưa commit và bảo toàn các chỉnh sửa đó. Đã đọc lại
  yêu cầu Gói 2, kiểm tra hai nơi dùng tìm kiếm: `MealFormDialog` và
  `MealFoodSources` (đường thêm món thông thường từ nhật ký).
- Tìm kiếm trả kết quả local ngay, sau đó cache và trạng thái bổ sung online.
  Khi đã đủ 10 món hoặc đủ limit thì không gọi online, giữ chiến lược hiện có.
  Mỗi thao tác gọi tối đa một `/foods/search`, giới hạn 50 kết quả tổng cộng;
  không tải detail của kết quả chưa chọn. Metadata không giả 0 kcal, không
  tạo snapshot/yêu thích trước khi tải dữ liệu dinh dưỡng.
- Chọn một kết quả mới gọi `/food/{fdcId}` cần thiết; kiểm cache trước và chỉ
  cache món được chọn. Detail được kiểm tên/ID/dinh dưỡng và bộ lọc trước
  khi chuyển tới nhập khẩu phần. Không tự lưu nhật ký. Lỗi đọc/ghi cache
  có cờ cảnh báo, không làm mất detail đã tải hợp lệ.
- `FoodSearchRequest.defaultTimeout`: **8 giây cho mỗi thao tác tìm hoặc
  tải chi tiết**, dùng chung xuyên các bước cache/HTTP/body/parsing. Debounce
  gõ chữ 300 ms diễn ra trước thao tác này. Không đặt lại 8 giây cho từng
  request. Nếu chỉ ghi cache bị chậm, detail đã tải vẫn dùng được cùng cảnh báo.
- Đổi query/bộ lọc/nguồn món/UID, ẩn tab hoặc dispose hủy operation và tín
  hiệu `AbortableRequest`. Trước bước bất đồng bộ kế tiếp đều kiểm hủy;
  UI kiểm generation/query/UID để chặn dữ liệu đến muộn. Retry hủy tác vụ
  trước, nút chọn detail có khóa chống bấm lặp.
- Phân biệt rỗng hợp lệ, lỗi 429/quota, mạng, provider, JSON/schema sai,
  timeout và partial. Kết quả local/cache vẫn chọn được khi online đang tải
  hoặc lỗi; thông báo không chứa URL, query hay exception thô.
- Không thêm package, proxy/backend hoặc API secret. Firebase/Rules/schema
  và snapshot lịch sử không đổi trong Gói 2.

### API chính thức và giới hạn demo

Đã đọc [USDA API Guide](https://fdc.nal.usda.gov/api-guide/) qua HTTPS, lưu
bản đọc tại `build/improvement-package2/usda-api-guide.html`:
`/foods/search` trả danh sách tìm kiếm, `/food/{fdcId}` trả detail một món.
Không dùng batch endpoint trong gói này.

Tài liệu tại thời điểm đọc ghi `DEMO_KEY` **30 request/IP/giờ, 50
request/IP/ngày**. Đây là giới hạn dịch vụ, không phải số lượt mỗi người
được HealthMate bảo đảm; các thiết bị cùng IP có thể dùng chung hạn mức.
App giữ public demo key và xử lý 429. Muốn khai thác quy mô thật cần đợt
riêng thiết kế giữ key/rate limit ở dịch vụ tin cậy; chưa triển khai ở đây.

### Bằng chứng local và giới hạn

- Regression trước sửa thất bại: fixture 50 hàng phát **1 search + 50
  detail = 51 request**. Sau sửa: **1 search, 0 detail khi chưa chọn**;
  chọn món ID 8 thêm đúng 1 detail; chọn lại qua cache không thêm request.
  Đây là số request của fixture, không phải benchmark mạng thật.
- Focused: `flutter test --no-pub test/food_search_request_test.dart
  test/usda_api_service_test.dart test/mfp_search_test.dart
  test/catalog_expansion_test.dart test/food_search_lifecycle_test.dart
  --reporter expanded`: **49/49 qua**, exit 0, khoảng 12 giây.
- `flutter analyze --no-pub`: **No issues found**, exit 0, 6,6 giây.
  Format các file Dart thay đổi và `git diff --check` qua.
- `flutter test --no-pub --reporter expanded`: **753/753 qua**, exit 0,
  khoảng **116 giây**; tăng 27 test so với mốc Gói 1 (18 service, 9 widget).
  Kiểm thử chỉ fixture/fake clock/client;
  không truy cập API USDA thật hoặc gọi AI. QA sync kiểm hash **445** file
  source/config/assets tại `D:/HealthMateMaintenanceQA/c6-workspace`.
- Cache SQLite đã bắt đầu không có primitive hủy/rollback; thao tác public
  cache đó có thể hoàn tất sau hủy. Luồng tiếp theo/kết quả cũ bị chặn.
  Abort HTTP phụ thuộc transport và không thu hồi request máy chủ đã nhận.
- Chưa kiểm thiết bị Android/native, mạng USDA thật hoặc production. Không
  build APK, push GitHub hoặc deploy. Không chạy lại Rules/admin/chat suite
  vì không sửa các phần đó trong Gói 2.
- Món USDA online lưu yêu thích vẫn phụ thuộc cơ chế resolve danh mục
  Firestore sẵn có; chức năng mở lại yêu thích online ngoài danh mục chưa
  được mở rộng trong gói này.
- Các vòng đầu chỉ ra lint, helper test chờ animation vô hạn khi fake đang
  pending, và finder tooltip mới của Flutter trả `RawTooltip`. Đã sửa đúng
  API/finder/cách chờ hữu hạn, giữ kiểm tra hành vi chọn món và bộ lọc.
  Không bỏ assertion hoặc tắt trạng thái loading để làm test qua.
- Log `build/improvement-package2/{flutter-red,flutter-focused,flutter-all,
  analyze}.log`; manifest source/hash/môi trường tại `verification.json`.

File chính: `food_search_request.dart`, `food_search_cache.dart`,
`unified_food_search_service.dart`, `usda_api_service.dart`,
`food_local_database.dart`, `nutrition_providers.dart`, `meal_form_dialog.dart`,
`meal_food_sources.dart`; test mới `food_search_request_test.dart`,
`food_search_lifecycle_test.dart` và các test double/search hiện có.

Gói tiếp theo đề xuất: **Gói 3 — toàn vẹn kế hoạch–nhật ký**; chưa thực hiện.

## Gói 3 — toàn vẹn kế hoạch–nhật ký

### Hành vi đã sửa

- Một transaction ghi nhật ký theo ID ổn định `plan-${plan.id}` và cập nhật
  liên kết kế hoạch. Không còn bước ghi meal rồi mới đánh dấu plan ở UI.
- Xóa meal cùng gỡ pointer trong transaction; plan cho xác nhận lại sau khi
  xóa. Chỉ đọc cặp document theo ID, không quét toàn bộ kế hoạch.
- Gửi lại cùng payload không tạo trùng hay đổi timestamp/snapshot đã lưu.
  Payload khác được báo xem/sửa trong Nhật ký. Hai SDK app xác nhận đồng
  thời chỉ có một bữa; khác khẩu phần thì một bên thắng, bên kia nhận lỗi.
- Form tải kế hoạch mới từ server sau khi đối soát. Kiểm tra phiên bản
  bằng timestamps/items chặn xác nhận đã cũ khi plan đổi/xóa/tạo lại hoặc
  khi meal bị xóa. Không tái tạo bữa đã bị người dùng chủ động xóa từ retry cũ.
- Plan có `loggedMealId` vẫn có nút “Đã ghi · Kiểm tra”. Thiếu meal thì
  gỡ marker và mở form xác nhận; có meal nhưng thiếu marker thì liên kết
  lại. Không sửa snapshot meal trong cả hai trường hợp; không migrate hàng loạt.
- Xóa plan giữ lịch sử ăn uống. Sửa plan đã có meal hoặc tạo lại plan chồng
  ID meal lịch sử bị chặn; người dùng sửa/xóa lịch sử chủ động ở Nhật ký.
- Rules kiểm trạng thái sau giao dịch và chặn các thao tác rời làm lệch
  cặp. Quyền delete tổng quát trước đây được loại khỏi `meal_logs` để không
  bỏ qua guard. Tối ưu cấu trúc biểu thức, giữ validator và giới hạn 5 món
  đủ 8 dưỡng chất mở rộng/fiber trong ngân sách đánh giá Rules.
- Cleanup hiện có xóa plan trước meal để tương thích guard; ca SDK xác
  minh cặp đang liên kết dọn được. Chưa làm tombstone/job/chính sách lưu giữ
  hoặc giải quyết race xóa tài khoản của Gói 4.

### Kiểm thử thực tế

| Lớp kiểm tra | Kết quả cuối |
| --- | --- |
| SDK tái hiện trước sửa | 0 qua / 3 thất bại đúng ba lỗi pointer treo, không tự gỡ và không sửa được plan |
| SDK Gói 3 trên Auth/Firestore Emulator | 13/13 qua, khoảng 4 giây chạy test sau compile |
| Widget Gói 3 | 4/4 qua, khoảng 2 giây |
| Rules focused plan–meal + wellness | 17/17 qua |
| Toàn bộ Rules | 100/100 qua, khoảng 16 giây |
| SDK hồi quy repository sẵn có | 23/23 qua, khoảng 29 giây |
| Toàn bộ Flutter mặc định | 757/757 qua, khoảng 93 giây; gồm 4 widget mới |
| `flutter analyze --no-pub` | No issues found, lần cuối 7,2 giây |
| Format các Dart đang thay đổi | 29 file, 0 thay đổi |
| `git -c core.safecrlf=false diff --check` | Qua |

Emulator chỉ chạy local Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8080`;
SDK dùng `demo-healthmate-rules`, Rules dùng các project `demo-*`. Kiểm tra
hai client dùng hai Firebase app độc lập cùng UID. Mất ACK được **mô phỏng
bằng bỏ giá trị trả về sau commit**, chưa cắt ACK ở lớp mạng. Không phải
nghiệm thu hai điện thoại Android thật.

Các vòng đầu lộ lỗi budget 1.000 biểu thức khi ghi 5 món; đã chỉnh cấu trúc
Rules, giữ assertion 5 món/đủ dưỡng chất. Dart exception trong callback
transaction web ban đầu thành NativeError; đổi callback trả enum và báo
FormatException sau transaction. Widget harness ban đầu chờ animation vô
hạn của parent busy khi form đang mở; dùng pump hữu hạn, không tắt loading.
Không giảm assertion để làm xanh.

SDK rộng chạy lại ban đầu thiếu seed H1; lần tiếp theo bị fixture catalog
của lần chạy trước còn giá trị đã sửa, khiến C3 nhận kcal gấp đôi. Đã reset
**chỉ database demo local**, nạp lại 162 món bằng helper emulator có guard,
retry seed 0 create/update/conflict, rồi toàn suite 23/23 qua. Không sửa
source sản phẩm hoặc kỳ vọng kcal để né hai lỗi setup này. Một lần chạy
helper thiếu biến host bị guard từ chối trước request; đã đặt host đúng.

Format toàn `lib test` bằng `--output=none` báo 5 file có sẵn ngoài phạm vi
(`app_spacing.dart`, `main.dart`, `core_acceptance_regression_test.dart`,
`food_library_test.dart`, `h2_templates_test.dart`); không ghi thay đổi chúng.
Kiểm format 29 Dart đang thay đổi qua. Không tuyên bố toàn repo đã format sạch.

Log tại `build/improvement-package3/`: `sdk-red.log`, `sdk-focused.log`,
`sdk-all.log`, `ui.log`, `rules-focused.log`, `rules-all.log`, `flutter-all.log`,
`analyze.log`, `catalog-fixture.log`. `verification.json` ghi source hash,
môi trường, kết quả và giới hạn bằng chứng. SDK test opt-in không có hậu tố
`_test.dart`; cần gọi file cụ thể với `HEALTHMATE_EMULATOR_TESTS=true`.

File chính: `meal_document.dart`, `firebase_nutrition_repository.dart`,
`wellness_repository.dart`, `wellness_models.dart`, `wellness_screen.dart`,
`firebase_account_data_repository.dart`, `firestore.rules`; test mới
`plan_meal_repository_integration.dart`, `plan_meal_ui_test.dart`,
`plan-meal.rules.test.cjs`, cùng hai suite integration/wellness Rules hiện có.

### Phát hành và giới hạn

Chưa phát hành APK, deploy Firebase, push GitHub hay chạy lại native Android
theo lựa chọn chủ dự án. Không thêm dependency, dịch vụ trả phí, key/secret,
schema/index hoặc migration lịch sử. Chưa xác minh production/mạng di động thật.

Client mới và Rules candidate phải được phát hành phối hợp: client cũ ghi
hai bước sẽ bị Rules mới từ chối; transaction mới nếu Rules cũ từ chối gỡ
pointer sẽ không xóa riêng meal. Chủ dự án cần kế hoạch nâng phiên bản trước
khi triển khai candidate; kết quả local không đồng nghĩa bản đang cài đã đổi.

Gói tiếp theo đề xuất: **Gói 4 — vòng đời xóa tài khoản và chính sách lưu giữ**;
chưa thực hiện.

## Gói 4 — vòng đời xóa tài khoản và chính sách lưu giữ

### Hành vi đã sửa trong candidate

- Yêu cầu xóa tạo `account_deletions/{uid}` độc lập với hồ sơ, sau xác thực
  lại. Rules kiểm `auth_time` của token khi tạo lần đầu, không tin cờ từ
  client. Marker không được owner xóa/reset; trạng thái/checkpoint chỉ tiến.
- Máy chủ xác nhận marker trước khi dọn. Mọi create/update sản phẩm bị
  chặn, kể cả bootstrap hồ sơ, chat, Premium/AI usage, support, directory và
  admin ghi vào account đang xóa. Quyền đọc/xóa cleanup cùng UID được tách
  khỏi quyền sản phẩm; suspended owner vẫn yêu cầu và tiếp tục xóa được.
- Cleanup lặp batch 100, xóa plan trước meal; messages trước chat/ticket.
  Dọn toàn bộ inventory đã biết, gồm Premium demo/phiếu mua mô phỏng, mọi
  ngày usage kể cả không có parent, directory bất kể build flag và controls.
  Audit bất biến được giữ. Mỗi retry liệt kê lại từ server, không bỏ qua
  dữ liệu vì checkpoint; kiểm rỗng trước bước Auth.
- Dừng và chặn ghi native theo UID trước cleanup; dọn nháp, wellness,
  reminders/steps. Marker native tồn tại qua process restart, tuần tự với
  thao tác ghi và không chặn account khác. Lỗi một bộ dọn vẫn cho bộ còn
  lại chạy, nhưng không chuyển sang server cleanup/Auth khi chưa dọn xong.
- Gate kiểm trạng thái xóa độc lập với cờ admin. Mở lại hoặc thiết bị thứ
  hai nhận marker sẽ đóng sản phẩm, dọn local và cho tiếp tục cùng yêu cầu.
  Kiểm tra đang chờ/lỗi không mở lại quyền. Bootstrap, đồng bộ directory,
  native activation và thao tác xuất CSV đang chờ đều có guard.
- Auth delete lỗi được báo là chưa hoàn tất và có thể thử lại. Sau Auth
  delete thành công, client vẫn giữ marker `auth_pending`, không tự ghi
  `completed`. UI công khai UID/metadata và audit giữ lại; chi tiết dài có
  thể mở rộng, không tuyên bố xóa vật lý mọi bản sao.

Inventory, lý do lưu giữ, schema, đường thực thi và hợp đồng server tương
lai nằm trong [account-deletion-adr.md](account-deletion-adr.md). Thêm schema
candidate vào `database-design.md`; README ghi rõ trạng thái rollout.

### Bằng chứng kiểm thử

| Lớp | Kết quả |
| --- | --- |
| SDK deletion mới, Auth/Firestore emulator + Chrome | 8/8 qua, 12 giây chạy test |
| Rules deletion riêng | 9/9 qua |
| Toàn bộ Rules | 109/109 qua, 17,75 giây |
| Rules hồi quy plan–meal đủ 5 món | 5/5 qua |
| Flutter focused auth/gate/security/private/admin | 75/75 qua |
| Flutter export đang chờ và nhận marker | 4/4 qua |
| Wellness hồi quy sau sửa harness | 11/11 qua |
| SDK repository rộng sẵn có | 23/23 qua, 29 giây |
| Flutter mặc định cuối | 772/772 qua, 89 giây |
| `flutter analyze --no-pub` cuối | No issues found, 8,6 giây |
| Format 54 Dart đang thay đổi, chế độ chỉ kiểm | 0 thay đổi |
| `git -c core.safecrlf=false diff --check` | Qua |
| Host contract dùng source marker Kotlin thực | 5/5 qua |
| `:app:compileDebugKotlin --offline` (tắt incremental) | BUILD SUCCESSFUL, 41 giây, 142 tasks |

SDK mới xác minh hơn 100 health records qua nhiều batch, nested chat/support,
Premium/usage/directory/controls và audit giữ lại; hai context cùng UID bị
chặn ghi trước cleanup; write đã xếp hàng offline bị từ chối khi reconnect;
bootstrap không tái tạo parent. Kiểm suspended, owner isolation, resume bằng
repository mới sau checkpoint dở, từ chối finalize sớm, Auth chưa xóa và
retry `auth_pending`; ca cuối xóa Auth emulator thật. Không reset production.

Ca offline có snapshot chứng minh pending write trước marker. Harness dùng
hai Firebase app mới cho mỗi test, reconnect/terminate trong teardown; việc
tái dùng app giữa nhiều UID từng gây chờ, không kết luận lỗi SDK từ hiện
tượng đó. Project SDK phải trùng emulator `demo-healthmate-rules` để helper
email action lấy đúng OOB code. Chỉ dùng Auth/Firestore loopback 9099/8080.

Full Flutter lượt đầu có 771 qua/1 lỗi: unit test wellness thiếu fake của
dependency mới nên gọi Firebase chưa khởi tạo. Đã bổ sung fake repository,
giữ provider và assertions. Standalone Riverpod harness cần subscription
đang hoạt động để stream không bị pause; không bỏ guard sản phẩm. Rules
lượt đầu lộ budget 1.000 biểu thức ở payload 5 món; đã tối ưu biểu thức,
giữ validator và assertion đủ dưỡng chất. Kotlin incremental gặp đường dẫn
khác ổ C/D; compile nonincremental thành công, không build APK.

Log/hash được lưu tại `build/improvement-package4/verification.json` và log
cùng thư mục. Sync QA kiểm hash 458 source/config/assets; file native dùng
cho compile được đối chiếu với source. Host test dùng adapter filesystem,
không chứng nhận Android Keystore, sensor/alarm hoặc E2E native.

### Phần chưa hoàn tất trước production

Đây là **client fallback + Rules candidate đã kiểm local**, chưa phải server
job bền vững. Khi app chết, cleanup không tiếp tục chạy trên server; người
dùng phải mở app, có mạng và tiếp tục. Client chưa liệt kê được collection
ngoài inventory hoặc messages legacy mồ côi đã mất parent; checkpoint 4/5
không chứng minh toàn bộ dữ liệu server đã hết. Cần job đặc quyền, inventory
đệ quy, thu hồi role admin và xác minh Auth server trước khi chứng nhận xong.

Marker UID/metadata được giữ không có purge tự động; audit/provenance và
admin message trong ticket của người khác còn cần chính sách retention có
lý do, thời hạn và đường thực thi server. Không bịa thời hạn pháp lý. Cache
thiết bị offline, file đã export, ảnh thư viện và dữ liệu provider đã xử lý
không thể được client thu hồi từ xa ngay.

Chưa deploy Rules/client, build APK, push GitHub, chạy lại nghiệm thu Android,
xóa tài khoản thật hoặc thay billing/hạ tầng. Không thêm dependency/secret.
Khi rollout phải phối hợp client mới và Rules, đánh giá client cũ chưa có
marker/retry và có cách hỗ trợ yêu cầu dở. Không chạy lại script QA production
cũ với UID cần tái sử dụng: tombstone sẽ khóa UID đó lâu dài.

Gói kế tiếp đề xuất: **Gói 5 — AI policy/quota tại dịch vụ tin cậy**; chưa làm.

## Gói 5–7 — candidate ngày 31/10/2026

Chủ dự án yêu cầu ba gói tiếp theo trong cùng lượt, sau Gói 4, và tắt laptop
khi hoàn tất. Phạm vi là các gói trong improvement plan; không phải Giai đoạn
5–7 của lộ trình MVP. Giữ toàn bộ chỉnh sửa chưa commit Gói 1–4. Branch `main`,
HEAD bắt đầu/kết thúc vẫn `0e897eca3cbdb7907012197830b9d365763e4faf`.
Không commit/push, deploy, migration production, nâng billing hoặc cấp IAM.

### Gói 5 — AI policy và quota

- Trước: client có thể tự ghi counter/demo entitlement rồi gọi Firebase AI
  trực tiếp; quota/UI không phải ranh giới dịch vụ. Sau: chat gateway kiểm
  chữ ký Auth/App Check, privileged Auth lookup (disabled/deleted/validSince),
  account status, deletion, eligibility, runtime flag và entitlement trước model.
- Firestore REST transaction reserve 5/50 lượt chat mỗi ngày UTC+7, tối đa
  hai lease đang chạy/UID; request ID ổn định cho plan/answer/retry. Các trạng
  thái reserved/sent/completed/failed/unknown xử lý mất ACK và lỗi provider
  bảo thủ: không tự phát lại phase hoặc hoàn lượt khi chưa biết đã dispatch.
- Giới hạn body, token, thời gian model/stream và output; rate limiter theo
  location bổ sung bảo vệ, không được gọi là global counter chính xác.
- Counter/reservation chỉ server ghi. Rules chặn client tạo/cập nhật hai cây
  `ai_gateway_usage`/`ai_gateway_reservations`; owner chỉ đọc metadata và
  cleanup sau tombstone. Cleanup duyệt cả nested days/requests khi thiếu parent.
- Flutter gửi cùng request ID, đọc lượt được server xác nhận, không tự consume
  quota. Scanner/knowledge không còn gọi Firebase AI trực tiếp; scanner ảnh
  báo chưa có gateway, vẫn dùng barcode/nhập tay. Không âm thầm đổi provider.
- File chính: `chat-api/src/{index,auth,ai-policy,trusted-firestore}.mjs`,
  `wrangler.jsonc`, cloudflare assistant, premium provider/repository/UI,
  scanner/knowledge service, account cleanup và `firestore.rules`.
- ADR và rollout: [ai-policy-quota-adr.md](ai-policy-quota-adr.md).

**Trạng thái:** đã xác minh candidate local, chưa đạt production AI. Worker
mặc định `AI_GATEWAY_ENABLED=false`; chưa provision credential/IAM, xác minh
OAuth/revoke/model thật, chặn đường Firebase AI của APK cũ/client sửa đổi,
gateway ảnh hoặc retention job. Không nhúng secret vào Flutter, không bật billing.
Firestore/Auth/Workers/AI đều có hạn mức và chi phí riêng; không hứa miễn phí
vô hạn. Không bật lại đường trực tiếp chỉ để scanner có vẻ đang hoạt động.

### Gói 6 — truy vấn và lịch sử cân

- Marker server `users/{uid}/data_migrations/meal_date_key_v1` chứng nhận
  partition. Thiếu marker/lỗi/timeout dùng compatibility hiện có (vẫn đọc
  trùng); partitioned dùng hai nhánh rời current/legacy; complete chỉ dateKey.
  Client không tự viết/reset marker hoặc đưa món current về legacy.
- Serializer ghi `queryPartition=current`. Tool mặc định dry-run; apply chỉ
  tới project demo cố định/localhost. Lock migrating, batch100, re-enumerate
  khi resume và full verification trước chứng nhận; chỉ sửa routing/date,
  không sửa snapshot dinh dưỡng. Thêm hai composite indexes candidate.
- Baseline và latest mỗi query limit1; lịch sử 25 mục +1 lookahead, cursor
  timestamp/ID giữ tie. UI Cũ hơn/Mới hơn, biểu đồ ghi rõ phạm vi trang.
  Báo cáo dùng range riêng, không cộng thiếu từ các trang.
- Rules giữ đủ validation từng món. Nhánh đúng 5 món gọi cả 5 validator trực
  tiếp để giảm điều kiện lặp, không bỏ món; kiểm cả fiberIncomplete=true,
  vector8 dưỡng chất, khẩu phần khác plan, kiểu sai/rỗng và field lạ.
- Hồi quy SDK phát hiện contender transaction đôi khi nhận permission-denied
  trước ABORTED. Repository chỉ retry một lần sau khi đọc server xác nhận
  cặp meal–plan đã tồn tại/liên kết đúng; transaction mới kiểm payload và UID,
  cùng payload idempotent, khác payload conflict, không ghi đè winner.
- File chính: nutrition repository/meal_document/meal_query_mode, wellness
  repository, profile repository/model/providers/UI, onboarding/Quest,
  migration tool/tests, Rules/indexes và query SDK tests.
- Thiết kế/rollback: [package6-query-migration.md](package6-query-migration.md).

**Trạng thái:** đã xác minh local, chưa migration production. Cần quyết định
múi giờ legacy, backup/dry-run, coordinator server và rollout client/Rules/index
trước certify UID. Compatibility chỉ được bỏ theo bằng chứng từng tài khoản.
Đếm SDK fixture là document tải, không phải đo hóa đơn production.

### Gói 7 — admin có giới hạn truy cập dữ liệu

- Catalog/directory/audit/support/revenue tải cursor 25 mục/trang; directory
  chỉ enrich role/control của trang đó. Không tải 10.037 tài khoản trước trang1.
- Tìm/lọc công khai phạm vi trang. Export theo khoảng mã/ngày riêng, batch200,
  tối đa5.000, vượt thì báo lỗi và không tạo file thiếu. Báo cáo doanh thu tải
  theo kỳ riêng, không cộng từ trang đang xem; doanh thu vẫn là mô phỏng.
- Cursor revenue giữ nanoseconds; hủy/logout/revoke bỏ kết quả/file tới muộn.
  Trang realtime không phải snapshot nguyên tử toàn database.
- File chính: `admin-web/dist/{server-paging,firebase,app,support-page,
  revenue-page,revenue-model}.mjs` và Node/DOM/SDK tests.
- Bằng chứng và giới hạn: [package7-admin-pagination.md](package7-admin-pagination.md).

**Trạng thái:** candidate đã xác minh local, chưa publish. Global full-text
search chưa có; không trình bày page-local search như tìm toàn database.
Production index và tải đồng thời vẫn cần nghiệm thu riêng.

### Kiểm tra bàn giao

Node chat48/48 + REST emulator3/3; admin42/42 + SDK7/7; migration6/6;
Rules119/119; Flutter780/780; analyzer sạch. Kết quả SDK repository cuối,
lệnh/exit code, fixture và lỗi trung gian được chốt ở
[test-report.md](test-report.md). Manifest/log/hash:
`build/improvement-packages5-7/verification.json`.

Không build APK hoặc chạy lại nghiệm thu Android theo lựa chọn chủ dự án.
Không gọi AI thật, xóa tài khoản thật hoặc thực hiện Gói 8–10. Gói kế tiếp
đề xuất: **Gói 8 — chống spam support và phân trang lịch sử ticket**.

## Gói 8–10 — candidate ngày 31/10/2026

Chủ dự án yêu cầu làm ba gói cuối và xác nhận giữ `com.example.healthmate`,
`1.0.0+1` cho demo. Không đổi package/version, dependencies, billing hoặc
identity server. Giữ toàn bộ Gói 1–7 chưa commit; branch/HEAD không đổi.
Không push/deploy, migration production, gọi AI thật, xóa account thật hoặc
nghiệm thu lại Android. Phần Android do chủ dự án tự test theo yêu cầu trước.

### Gói 8 — hạn mức và lịch sử support

Trước: chỉ có hạn chế UI/lịch sử đầu, không có counter tạo mới authority.
Sau: `support_usage/{uid}` cùng transaction với ticket, Rules liên kết hai
chiều `getAfter`, tối đa 3 ticket mới/ngày UTC+7, cách nhau 60 giây. Không
reset counter bằng client; chỉ cleanup sau tombstone. Retry cùng ID/payload
không tăng count, payload khác bị từ chối. Reply/reopen/status/audit giữ
hợp đồng cũ, không tiêu quota tạo mới. Ticket lịch sử không tính hồi tố.

Lịch sử 25+1 với seconds/nanos/ID, có Cũ hơn/Mới hơn và reset theo UID.
Counter đã thêm vào cleanup inventory và server-empty verification. SDK
thật xác minh 70 ticket qua 25/25/20, anchor bị xóa và tranh lượt cuối.
File chính: support repository/models/providers/screen, `firestore.rules`,
cleanup repository, support/deletion fixtures và Rules/SDK/unit tests.
[Chính sách, tương thích, rollout/rollback](package8-support-policy.md).
Chưa deploy; client cũ tạo ticket thiếu counter sẽ bị Rules mới từ chối.

### Gói 9 — biểu mẫu, tài liệu và CI

Tách `MealFormController` cho draft/validation/ACK và `MealSearchController`
cho debounce/cancel/generation/detail/paging; giao diện nguồn nhập ở
`meal_entry_sources.dart`. Giữ operation ID ở repository/caller, không tự
retry write còn pending hoặc thay dinh dưỡng snapshot. UID được chốt sau
Auth resolve đầu tiên; không coi initial loading là đổi account. Các hàng
catalog vẫn là direct ListView children để giữ lazy scrolling/reveal.

Test controller độc lập và widget regression bảo vệ nháp/retry/UID/5 món,
đồng thời giữ xác nhận món cần tránh. Harness thiếu Auth fixture đã bổ
sung fake rõ ràng; auth lỗi vẫn chặn persistence, không mở guard để test qua.
[Thiết kế và phạm vi](package9-meal-form-refactor.md).

README nay chỉ giữ trạng thái/setup/lệnh; lịch sử được lưu `CHANGELOG.md`.
Thêm [bảng truy vết](candidate-verification.md) và CI source/Emulator không
secret/deploy. CI tách mỗi SDK suite thành process, reset/seed đúng project
demo trước suite vì một số suite cũ tự clear database. Workflow đã parse
YAML và helper có regression test; chưa chạy GitHub Actions hosted.
QA sync bỏ qua generated build paths, không copy/xóa credential hay dữ liệu
ignored; mọi file source QA được đối chiếu hash. Không thêm package.

### Gói 10 — chuẩn bị release và nghiệm thu còn chờ

Thêm `config/release-candidate.json`, `release_preflight.cjs`/tests và
`build_release.ps1`; Gradle resolved task graph chặn thiếu signing, debug/
emulator defines và config không được duyệt. Release candidate tắt chatbot/
Premium demo, giữ barcode entry; không mở lại direct AI. Preflight thực
exit 1 vì thiếu signing, giữ `releaseAccepted=false`, APK/hash chưa có.
Test Gradle chỉ là source contract, helper chỉ parse syntax, không thực build.

Load probe emulator thực: 10 workers, 100/100 cursor queries, 1.000 document
responses, 0 lỗi; p50 17,604 ms, p95 58,452 ms, max 66,382 ms. Dọn đúng 100
fixture paths của probe. Admin REST bypass Rules; đây không phải billing
reads, quota/Auth/App Check/nghiệm thu native hoặc capacity người dùng thật.

**Gói 10 chưa hoàn tất nghiệm thu phát hành:** thiếu khóa ký/certificate,
thiết bị và các bằng chứng native; R1 server deletion/retention job và Gói 5
IAM/direct-route/gateway ảnh vẫn chặn production tương ứng. Không thay bằng
APK debug hoặc gọi widget tests là nghiệm thu thiết bị. Ma trận còn chờ,
chi phí cần kiểm thực, backup/dry-run và rollout/rollback chưa thực thi:
[release-readiness.md](release-readiness.md).

Kết quả/exit code cuối, lỗi trung gian và hashes được chốt riêng tại
[test-report.md](test-report.md), `build/improvement-packages8-10/verification.json`.
Gói tiếp theo không tự triển khai: hoàn tất các blocker hạ tầng và chủ dự án
nghiệm thu signed release trên điện thoại trước quyết định phát hành.
