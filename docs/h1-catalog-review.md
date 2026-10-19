# H1 — catalog/khẩu phần và bản xem trước dữ liệu (19/10/2026)

## Hợp đồng và nguồn

Reader đọc metadata servingLabel/servingGrams/defaultServingGrams qua repository.
Một cặp hợp lệ có nhãn không rỗng, gram hữu hạn >0 và <=2000, cơ sở per_100g/g.
Thiếu hoặc hỏng metadata giữ nhập gram khi dinh dưỡng gốc hợp lệ, kèm giải thích;
unit/basis không hỗ trợ không được dùng để tính. Document cũ không cần migration.
Đổi đơn vị giữ lượng gram đang chọn, preview và snapshot tính trên lượng thật;
sửa định nghĩa portion hoặc xóa nguồn không sửa lịch sử.

47 công thức hiện có được đề xuất thêm **phần công thức tham khảo** bằng yield
thành phẩm đã khai báo. Đây là lượng giả định của công thức, không phải tô/đĩa
tiêu chuẩn của mọi quán. Không sửa số kcal/macros nguồn VDD 2007.

Ba sản phẩm gram mới, tách riêng dòng và hộp 100g:

| Sản phẩm | kcal / P / C / F trên 100g | Nguồn nhà sản xuất |
|---|---|---|
| TH true YOGURT có đường |94,9 / 3,1 / 13,2 / 3,3|[TH có đường](https://www.thmilk.vn/products/sua-chua-an-co-duong/)|
| TH true YOGURT vị tự nhiên |63,2 / 3,3 / 4,4 / 3,6|[TH vị tự nhiên](https://thmilk.vn/products/sua-chua-an-khong-duong/)|
| TH true YOGURT sầu riêng tự nhiên |100,4 / 3,1 / 14,8 / 3,2|[TH sầu riêng](https://thmilk.vn/products/sua-chua-an-sau-rieng-tu-nhien/)|

Đã kiểm tra trang ngày 19/10/2026; lưu source URL, basis, trạng thái ăn liền,
ngày/phiên bản. Nhà sản xuất công bố giá trị trung bình, có giới hạn nhãn; giữ
isEstimated và yêu cầu đối chiếu bao bì. Không dùng cho sữa uống 180ml, TOPKID,
Creamy hoặc nhãn hàng khác. Chưa thêm sản phẩm chỉ có ml; không gán ml=gram.
Nguồn Mộc Châu PDF không render được bằng tool trong lượt này, không nhập số từ
snippet chưa đối chiếu. Không ép số lượng để lấp các brand chưa có nguồn.

## Tìm kiếm và tải dữ liệu

Tái sử dụng listener catalog hiện có ở foodCatalogProvider autoDispose, một
query orderBy(name) cho toàn catalog của scope đang mở; tìm/paging hiển thị làm
trong bộ nhớ, không query backend theo mỗi phím. Không thêm dependency/search
backend. Đây là phân tích đường gọi, không phải benchmark hóa đơn Firestore.
Cold listener có thể đọc toàn catalog (production đang158 document); mở lại sau
dispose có thể tải lại, cache/đọc phát sinh còn tùy SDK/kết nối. Không hứa 0 read.

Xếp exact tên/alias, prefix nguyên cụm, khớp các từ rồi substring; giữ các kết quả
substring cũ. Ví dụ cơm gà lên trước cơm gạo lứt; không xóa kết quả nhiễu cũ chỉ
để đẹp benchmark. Chuẩn hóa tiếng Việt, dấu/NFD và khoảng trắng vẫn giữ.

`tool/benchmark_food_search.dart` cố định 19 truy vấn trước khi chấm: nhóm món
Việt, 3 dòng TH, sản phẩm chưa hỗ trợ và nhóm held-out; expected IDs rõ ràng.
Dataset branch151, **không phải** production158. 15 truy vấn có món mong đợi và
4 truy vấn chủ đích rỗng; 19/19 đúng kết quả đầu hoặc rỗng. JSON lưu mọi kết quả
trước/sau và nhiễu; query rỗng trả151 để browse. Timing100 vòng/1900 truy vấn
4.227ms tổng (~2,22ms/truy vấn), CPU máy này, không phải tốc độ mạng/máy thật.

## Review import/rollback — chưa áp dụng production

Dry-run chỉ đọc project healthmate-app-20261013: existing158, create3, skip148,
đề xuất metadata update47, conflict0. Source build có151 (148 cũ +3 mới);10 mục
USDA legacy production không nằm trong source build được giữ nguyên.
Manifest ở build/h1-catalog-manifest.json; benchmark build/h1-search-benchmark.json.

Tool mặc định dry-run. `--manifest <new-file>` ghi trước/patch/updateTime để review;
không ghi đè file. `--apply` hiện **chỉ tạo mục thiếu** với exists:false, không tự
áp dụng47 metadata updates. Chưa cung cấp thao tác apply-update tự động: cần giao
maintenance riêng, dùng precondition updateTime và updateMask đúng ba field,
không replace document/nutrition hay user data. Tên trùng ID khác hoặc core value
khác báo conflict. Khi apply lỗi không đoán rollback; đọc lại trước retry.

Nếu sau này cho phép apply: lưu snapshot các document tác động, dry-run lại,
kiểm tra đúng project và manifest mới; thêm3 riêng, update47 metadata riêng theo
precondition. Khôi phục metadata từ before (xóa field khi before là null), chỉ
khi updateTime còn đúng bản apply; không xóa tùy tiện document đã được người
khác cập nhật. Không cần Rules/index mới cho H1; client catalog vẫn read-only.

## Kiểm chứng

Unit/widget:379/379 toàn suite; focused51 và test H1 cuối9 đều đạt. Analyzer
cuối sạch9,6s. Node catalog9/9. SDK emulator15/15, Rules47/47, import thật151
create và retry0create/update/conflict. Test đọc qua Flutter repository và lưu
snapshot phần phân số, nhận đúng giá trị server.

Lượt import fixture đầu thất bại vì helper bỏ nextPageToken, làm thiếu mục cuối
vn2007-9007 khi emulator trả page nhỏ hơn request. Lượt đổi prefix chưa sửa gốc
cũng fail; diagnostic xác định đúng ID, sửa pagination rồi suite đạt. Không reset
DB để giấu lỗi. Analyzer của benchmark đầu có5lint import/braces, đã sửa sạch.
Android H1 đang chạy, kết quả sẽ ghi tiếp ở h-improvements/test-report; không coi
unit hoặc SDK web emulator là nghiệm thu Android/production UI.

Android H1 đã đạt 10 checkpoint trong154s trên emulator-5580/API30/backend demo; ảnh portion và manifest/benchmark ở docs/ux/h1. Chưa nghiệm thu máy thật hoặc UI production.
