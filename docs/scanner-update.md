# Quét ảnh, khẩu phần mã vạch và lưu món riêng — 23/10/2026

Phạm vi: bảo trì/mở rộng Giai đoạn 5 theo yêu cầu trực tiếp của người dùng.
Giữ Firebase AI Logic/Gemini, image_picker, mobile_scanner/ML Kit và Open Food
Facts; không thêm dịch vụ trả phí, package, collection hoặc thay đổi Rules.

## Quét ảnh

Vào **+ → Quét món**, chụp/chọn ảnh món ăn, đọc thông báo và đồng ý gửi ảnh,
bấm **Phân tích**. Kết quả gồm tên có thể sửa, mô tả, thành phần có thể nhận
diện và bảng kcal/đạm/carbohydrate/chất béo/chất xơ trên 100 g và theo khẩu phần.
Khối lượng do AI gợi ý chỉ là tham khảo; người dùng kiểm tra/nhập lại gram.

- Món catalog trùng đầy đủ tên/tên tương đương được chọn là nguồn dinh dưỡng ưu tiên. AI có thể đưa ra số liệu
  tham khảo khi chưa có món phù hợp, theo yêu cầu mới; luôn ghi rõ **Ước tính**.
- Giá trị chưa biết là `null` trong JSON, hiển thị **Chưa có dữ liệu**, không
  biến thành số 0. Parser chặn sai kiểu, số âm/quá giới hạn, JSON quá lớn.
- Không suy đoán vitamin, khoáng chất, dị ứng, độ an toàn hay chẩn đoán từ ảnh.
  Không thể bảo đảm mọi thông tin thực tế của món ăn đều suy ra được từ ảnh.
- Ảnh không xác định được món không có nút lưu món AI; còn đường nhập thủ công.
- Tuổi 18+, onboarding, UID, consent, App Check, giới hạn ảnh, timeout và cơ chế
  bỏ phản hồi đến trễ vẫn được giữ. Không lưu ảnh gốc lên Cloud Storage/Firestore.

## Món mới chưa có trong danh mục

Bấm **Kiểm tra và lưu vào Món của tôi**. Form điền sẵn thông tin có được;
kiểm tra/sửa tên, kcal/macros trên 100 g, chất xơ tùy chọn và gram rồi bấm **Lưu**.
Các trường kcal/macros còn thiếu phải được người dùng nhập trước khi lưu, thay
vì âm thầm điền 0. Món được lưu riêng tại `users/{uid}/custom_foods/{id}`, có nguồn
và `isEstimated: true`; không ghi vào catalog dùng chung. Lưu lỗi giữ form và
retry cùng ID; đổi tài khoản đóng form và bỏ phản hồi cũ.

Lưu thư viện không tạo meal log. Sau đó **Xác nhận món đã chọn** mở bản nháp bữa
ăn với đúng gram vừa chọn. Chỉ nút Lưu bữa ăn mới ghi nhật ký và snapshot.
Tên, dinh dưỡng, khẩu phần và nguồn được giữ trong thư viện theo schema có sẵn;
mô tả/thành phần nhận diện là thông tin ở kết quả quét, chưa thêm field lưu mới.

## Mã vạch

Vào form thêm bữa → **Quét mã vạch**, quét sản phẩm, nhập khẩu phần và xác nhận.
Kết quả trả về cả sản phẩm và gram người dùng đã chỉnh. Snapshot được tính đúng
một lần theo công thức `dinh dưỡng /100 g × gram /100`, bao gồm chất xơ nếu có.
Ví dụ 500 kcal/100 g, chọn 30 g → 150 kcal; sửa lại 60 g → 300 kcal.
Số thập phân dùng dấu chấm hoặc phẩy; giá trị rỗng/âm/không hữu hạn/trên 2000 g
không thể xác nhận và không dùng lại giá trị hợp lệ trước đó.

API không tìm thấy sản phẩm được tách khỏi lỗi mạng, quota, lỗi máy chủ hoặc
JSON hỏng. Macro/chất xơ thiếu được giữ là chưa biết xuyên suốt UI và snapshot.
Khẩu phần Open Food Facts ghi rõ ml không bị lấy làm gram mặc định; luồng mã
vạch này vẫn yêu cầu người dùng xác nhận khối lượng gram, chưa suy ra mật độ.

## Backend và nghiệm thu

Không thay đổi hoặc triển khai Rules/index/schema. README đang ghi nhận Rules
H0–H7 (schema mở rộng/chất xơ) chưa deploy production; cần kiểm tra phiên bản
Rules thực tế và triển khai trong một yêu cầu được cho phép riêng trước nghiệm
thu bản production có những field này. Lỗi quyền ghi vẫn phải được hiển thị,
không bỏ chất xơ/đổi số liệu để lách Rules.

Các unit/widget test dùng dữ liệu tổng hợp và fake repositories/services,
không chứng minh camera, chất lượng nhận diện hoặc cloud AI thật đã hoạt động.
Không có thiết bị/emulator kết nối ở lần kiểm tra ADB ban đầu; lượt kiểm tra
tiếp theo trên điện thoại thật được ghi dưới đây.
Không thay App Check, billing, production data, commit/push/deploy.

Tài liệu chính thức đã kiểm tra khi chọn JSON schema/model:

- [Firebase structured output](https://firebase.google.com/docs/ai-logic/generate-structured-output)
- [Firebase supported models](https://firebase.google.com/docs/ai-logic/models)
- [Open Food Facts API](https://openfoodfacts.github.io/openfoodfacts-server/api/)

Kết quả lệnh thực tế được ghi trong `test-report.md` và `implementation-progress.md`.

## 23/10/2026 — Sửa thời gian phản hồi và xác minh trên điện thoại

Ảnh người dùng gửi có thông báo quá thời gian 45 giây. Lượt thử lại trên bản
cũ ghi lỗi SDK sau 8,868 giây nhưng mã lỗi chung chưa xác định được nguyên nhân
cụ thể. Không kết luận mọi lỗi trước đó đều do timeout hoặc App Check.

- Chuyển riêng scanner mặc định từ `gemini-3.8-flash` sang
  `gemini-3.5-flash-lite`, thinking minimal. Có thể cấu hình qua
  `HEALTHMATE_FOOD_SCANNER_MODEL`; giữ tương thích override `HEALTHMATE_AI_MODEL`.
  Chatbot giữ cấu hình cũ. Schema kết quả dinh dưỡng vẫn đầy đủ như trên.
- Giới hạn cạnh ảnh 1024 px; kiểm tra App Check trước request (tối đa 8 giây).
  Giới hạn toàn thao tác service 40 giây và đóng HTTP client khi kết thúc.
  Không bảo đảm việc đóng client sẽ hủy xử lý hoặc quota phía máy chủ.
- Phân biệt thông báo quota, App Check, model, mạng/dịch vụ và kết quả không hợp
  lệ. Diagnostic chỉ ghi giai đoạn, thời gian và mã trạng thái, không ghi ảnh,
  nội dung request, API key hay token.
- Chuyển `http` từ dev dependency sang runtime dependency; giữ nguyên phiên bản,
  không thêm dịch vụ hoặc thay đổi billing/Rules/cấu hình bảo vệ App Check.

Probe qua Firebase AI Logic với App Check hợp lệ: model cũ không phản hồi trong
30 giây ở hai request nhỏ; model mới trả HTTP 200. Ảnh người dùng cung cấp và
schema thật trả JSON hợp lệ sau 16,898 giây, nhận diện cơm tấm sườn/trứng và
các trường dinh dưỡng tham khảo. Đây là phép thử chẩn đoán, không phải benchmark
đủ mẫu hoặc kiểm định độ chính xác dinh dưỡng.

Đã build và cập nhật APK bằng `adb install -r -t` lên điện thoại đang kết nối,
không gỡ ứng dụng hoặc xóa dữ liệu. Lượt người dùng thử trên bản mới ghi App
Check thành công sau 44 ms, HTTP 200 sau 6743 ms, parse thành công sau 6767 ms.
Người dùng xác nhận **“Đã ra kết quả món ăn”**. Một lượt thành công không cam kết
mọi ảnh đều xử lý dưới 7 giây. Thao tác chụp camera và lưu món lên production
chưa được nghiệm thu lại trong lượt này.

Tài liệu đã đối chiếu khi chọn cấu hình tốc độ:

- [Firebase thinking](https://firebase.google.com/docs/ai-logic/thinking)
- [Gemini 3.5 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite)

## 23/10/2026 — Đối chiếu hai món theo ảnh người dùng (chỉ kiểm tra)

Người dùng gửi kết quả hai món từ HealthMate và hai ứng dụng khác. Đã đọc code,
đối chiếu seed và chạy lại widget thật với dữ liệu đầu vào dựng từ ảnh, không
sửa mã nguồn ứng dụng và không gửi thêm ảnh tới AI trong lượt đối chiếu này.

- Cơm tấm: `_matches` chấp nhận substring hai chiều trên tên/tên phụ/searchTerms;
  tên phụ “cơm” của Cơm trắng chín khớp tên cả đĩa. `_analyze` tự chọn phần tử
  đầu tiên theo thứ tự catalog. `_nutritionDetails` ưu tiên toàn bộ dinh dưỡng
  món catalog đã chọn, dùng khối lượng AI 450 g của cả đĩa. Widget tái hiện đúng
  585 kcal, đạm 12,11 g, carb 126,77 g, béo 1,26 g, và chuyển Cơm trắng chín/450 g
  sang form bữa ăn. Đây là lỗi ghép món/khẩu phần thực sự, không phải lỗi phép
  nhân hoặc chỉ là chênh lệch giữa mô hình. Luồng lưu món riêng cũng lấy số liệu
  từ `_selected`, nên có thể sao chép dữ liệu sai ngữ nghĩa nếu chưa chỉnh lại.
- Bít tết/khoai chiên: với AI 220 kcal, 18 g đạm, 15 g carb, 10 g béo, 1,5 g xơ
  trên 100 g và khẩu phần 350 g, widget trả đúng 770 kcal, 63/52,5/35/5,25 g.
  Chưa thấy lỗi quy đổi/hiển thị ở mẫu này. Ảnh app khác là 1056 kcal với 13 oz
  và tách thịt/khoai/dầu; đầu vào khối lượng và mật độ dinh dưỡng không giống nhau.
  Không có cân thực phẩm/công thức thực tế nên chưa thể xác định con số đúng.

Chẩn đoán chạy trong file tạm bị ignore `build/scanner_comparison_probe_test.dart`:
`flutter --no-version-check test --no-pub build/scanner_comparison_probe_test.dart
--plain-name "comparison probe" --reporter expanded`: **2/2 qua**, phần thực thi
2 giây; log `build/scanner-comparison-probe.log`. Các assertion xác nhận hành vi
hiện tại, bao gồm lỗi ghép cơm trắng; không được hiểu là đã sửa lỗi hoặc xác minh
độ chính xác AI. Không chạy lại full suite/build vì chưa sửa code sản phẩm.

Hướng sửa trong cùng feature khi được yêu cầu: không tự chọn khớp yếu/khớp một
nguyên liệu cho cả món nhiều thành phần; hiển thị rõ món và cơ sở khẩu phần của
nguồn đang dùng. Muốn tính từng thành phần cần có khối lượng riêng, không áp dụng
450 g toàn đĩa cho một nguyên liệu. Không sửa con số để khớp một app tham chiếu.

## 23/10/2026 — Bản sửa chọn nguồn cho cả món

- Tách `FoodScanCatalogMatcher`: chỉ khớp đầy đủ tên hiện tại hoặc tên tương
  đương của món sau chuẩn hóa dấu/cách viết tiếng Việt. Không dùng substring,
  tên thành phần hay `searchTerms` để chọn dữ liệu dinh dưỡng cho toàn đĩa.
- Chỉ tự chọn khi có một món khớp duy nhất; nhiều món trùng tên để người dùng
  chọn. Đổi tên xóa lựa chọn cũ; từ tìm của kết quả trước không ghép lại món cũ.
  Tìm rộng thủ công vẫn có trong form bữa ăn. Cách khớp này có thể bỏ sót món
  tương đương nhưng khác tên; chấp nhận giữ ước tính/nhập tay thay vì ghép sai.
- Nêu rõ nguồn, tên món danh mục hoặc phạm vi toàn món trong ảnh. Người dùng có
  thể bỏ nguồn danh mục và dùng lại ước tính AI. Nếu món catalog chưa có dữ liệu,
  không gắn nhãn nguồn catalog lên số AI. Lưu món riêng dùng cùng nguồn đang xem.
- Prompt nhắc ước tính tổng thể đĩa gồm thịt/cơm/trứng/rau hoặc thịt/khoai,
  cân nhắc dầu có cơ sở suy luận và tránh cộng dầu hai lần. Giữ model, schema,
  giới hạn ảnh, timeout, bước xác nhận và cơ chế bảo vệ hiện có; không thêm API.
- Không tách số lượng từng thành phần trong kết quả hiện tại và không khẳng
  định đã cải thiện độ chính xác dinh dưỡng bằng đo thực phẩm. Không sửa số để
  khớp Calz/Foodvisor; mục tiêu bản sửa là dùng đúng món/nguồn/khẩu phần.

Kiểm thử hồi quy dùng response cố định, không giả vờ là lượt AI cloud mới:
đĩa cơm 450 g và AI 185 kcal/100 g phải giữ 832,5 kcal xuyên suốt UI → món riêng
→ nhật ký, không bị đổi thành 585 kcal của cơm trắng. Mẫu bít tết 350 g giữ
770 kcal và các macro theo response. Các con số này là fixture kiểm thử luồng,
không phải kết luận dinh dưỡng chính xác cho ảnh người dùng.

Kết quả kiểm tra bản sửa: nhóm scanner 25/25, toàn suite 512/512 qua; analyze
18 info cũ, 0 warning/error; APK debug build qua (28,4 giây). Format 5 file 0
thay đổi và whitespace check qua. ADB không có thiết bị, chưa cập nhật APK hoặc
nghiệm thu lại ảnh thật trong lượt này. Không push/deploy. Chi tiết lệnh/log và
các giới hạn xác minh ở test-report.md, implementation-progress.md.

## Giao diện tiếp theo: nhập tay/quét món dùng cùng bữa ăn

Luồng mới dùng một màn hình với Nhập tay/Ảnh/Yêu thích, camera preview và lối
vào barcode. Xác nhận scanner thêm vào nháp đang mở rồi chuyển về Nhập tay;
không mở bữa ăn thứ hai. Xem [unified-meal-entry.md](unified-meal-entry.md).
