# Danh mục thực phẩm và lựa chọn ăn — 27/10/2026

> Báo cáo lần mở rộng trước. Danh mục mới nhất hiện có **11.169 mục**;
> xem [cập nhật Foundation/FNDDS](current-food-data-2026-10-27.md).

## Kết quả rà soát

Trước lượt này, asset của HealthMate có **162 mục**, trong đó **58 mục có khẩu
phần quy đổi**. Sau mở rộng, app có **7.606 mục**, gồm thực phẩm, món và các
biến thể chế biến; **7.169 mục có khẩu phần quy đổi theo nguồn**. Đây là số mục
trong bản đóng gói, không phải số món độc nhất, số sản phẩm Việt Nam hay số
document trên Firebase production.

| Danh mục | Quy mô được công bố/kiểm đếm |
| --- | --- |
| HealthMate trước | 162 mục trong asset |
| HealthMate sau | 7.606 mục trong asset |
| MyFitnessPal | Khoảng 22 triệu mục, theo trang trợ giúp Today |
| Calz | Hơn 10.000 thực phẩm/đồ uống, theo mô tả App Store |

HealthMate **vẫn nhỏ hơn** số liệu các ứng dụng kia công bố. Các bên có cách
đếm, độ phủ nhãn hàng, nhà hàng, ngôn ngữ và mức kiểm duyệt khác nhau; không
suy ra chất lượng tương đương chỉ từ số mục.

Nguồn so sánh, xem ngày 27/10/2026:

- [MyFitnessPal — Your Today tab](https://support.myfitnesspal.com/hc/en-us/articles/39985611667341-Your-Today-tab).
- [Calz trên App Store](https://apps.apple.com/us/app/calz-calorie-counter-ai/id6738832996).

## Dữ liệu đã bổ sung

Giữ 162 mục hiện có và thêm **7.444 mục USDA SR Legacy**. Bỏ 4 bản ghi có FDC ID
đã được đại diện trong bộ cũ. Chọn nhóm thực phẩm thông thường; không nhập nhóm
thức ăn trẻ nhỏ và sản phẩm dinh dưỡng lâm sàng. Mỗi mục mới có FDC ID, mô tả
gốc, kcal/đạm/carb/béo trên 100 g, nguồn và cờ giá trị tham khảo/ước tính. Thiếu
dưỡng chất phụ vẫn là chưa biết, không tự điền bằng 0.

Nguồn là **bản phát hành cuối tháng 4/2018, mang tính lịch sử**. Đây không phải
cơ sở nhãn hàng cập nhật đến 2026 và không phải phép đo chính bữa ăn của người
dùng. 7.444 mục có tên hiển thị Việt hóa/rút gọn; **6.969 mục dịch được tên
thực phẩm chính** bằng từ điển offline. 475 mục còn lại dùng nhóm tiếng Việt
kèm thương hiệu/tên gốc hiếm; không gọi đó là bản dịch đầy đủ. Trạng thái
sống/chín, cách nấu, muối/đường phổ biến được dịch. Tên rút gọn có FDC ID để
phân biệt biến thể; tên gốc đầy đủ nằm trong `originalName`, xem bằng mục
**Tên gốc và nguồn USDA** khi chọn gram và tìm được bằng tiếng Anh. Các chi
tiết loại/cấp thịt không có bản dịch vẫn đối chiếu tên gốc. Không đổi số dinh
dưỡng, khẩu phần nguồn hoặc snapshot lịch sử. Món Việt được ưu tiên khi duyệt.

Khẩu phần lấy từ `food_portion.csv`: gram cho một đơn vị = `gram_weight / amount`.
Không tự giả định một cốc, miếng hoặc phần luôn cùng trọng lượng. Một số mô tả
khẩu phần USDA còn tiếng Anh. Người dùng vẫn kiểm tra và thay đổi số gram.

- [USDA tải dữ liệu](https://fdc.nal.usda.gov/download-datasets/).
- [USDA tài liệu dữ liệu và public domain](https://fdc.nal.usda.gov/data-documentation/).
- [Archive chính thức](https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip).
- SHA256 archive: `b80817294b8850530aaedf2e515c02593b1824f763a0ff356e5c2081643e6fd0`.

Tái tạo từ archive đã tải vào `build/catalog-expansion/`:

```powershell
python tool/import_usda_bundle.py build/catalog-expansion/usda-sr-legacy-2018.zip
python tool/test_usda_bundle.py
```

Importer chỉ dùng thư viện chuẩn Python, kiểm SHA và validation; không gọi API,
không cần API key và không ghi Firestore. Manifest kiểm đếm nằm ở
`data/food_catalog/usda-import-manifest.json`. Asset bổ sung khoảng 8,66 MB chưa
nén; giải mã trong isolate Flutter. Chỉ mục tìm kiếm chuẩn hóa được giữ theo
vòng đời đối tượng để tránh xử lý lại hàng nghìn tên mỗi lần gõ.

## Chế độ ăn theo người

Trước lượt này, app đã có mục tiêu tăng/giảm/giữ cân, tính chỉ tiêu kcal và bộ
câu hỏi lưu lựa chọn ăn chay; lựa chọn chay chưa được dùng để lọc món hoặc gợi ý
thực đơn. Sau lượt này:

| Lựa chọn | Hành vi |
| --- | --- |
| Tăng/giảm/giữ cân | Giữ cơ chế mục tiêu kcal/đạm/carb/béo hiện có; người dùng xác nhận và chỉnh khẩu phần. Không gắn mọi món thành món tăng/giảm cân. |
| Ăn đa dạng | Danh mục hiện tất cả nhóm. |
| Chay có trứng/sữa | Hiện nhóm thực vật và nhóm chay có trứng/sữa đã phân loại. |
| Thuần chay | Chỉ hiện nhóm thực vật đã phân loại. |
| Chưa rõ thành phần | Bị ẩn trong hai bộ lọc chay. |

Đổi lựa chọn tại **Cá nhân hóa · 20 câu hỏi**, câu 13. Luồng thêm món trong Nhật
ký lấy lựa chọn này làm bộ lọc ban đầu; người dùng vẫn có thể đổi bộ lọc cho lần
ghi hiện tại. Đổi bộ lọc trong form không tự sửa hồ sơ. Bộ lọc áp dụng lại cho
kết quả tìm kiếm bất đồng bộ; kết quả cũ không được ghi đè lựa chọn mới.

Rà soát tiếp sau phản hồi của người dùng phát hiện form chính dùng
`MealFoodSources` qua `sourcesBuilder`, nên bản đầu chỉ truyền preference mà chưa
lọc danh sách thật trong nhánh đó. Đã sửa để truyền lựa chọn hiện tại vào thành
phần nguồn món, lọc cả duyệt/tìm/kết quả ngoài và hủy hiệu lực response cũ khi
đổi lựa chọn. Bộ lọc xuất hiện trên màn Nhập tay và Yêu thích; món yêu thích
thuộc catalog nhưng ngoài bộ lọc vẫn bỏ lưu được, nút thêm bị khóa kèm lý do.
Người dùng có thể chọn Tất cả chế độ để chủ động ghi món đó.

Sửa kế hoạch và xác nhận kế hoạch đã ăn cũng nhận lựa chọn từ hồ sơ. Đổi bộ lọc
chỉ đổi danh sách khám phá, không tự bỏ món đã có trong kế hoạch. Nếu tìm thêm
bên ngoài bị lỗi, các kết quả local vẫn dùng được và có nút thử lại; không đưa
exception kỹ thuật/raw provider vào giao diện. Danh mục cập nhật trong khi đang
tìm sẽ làm mới kết quả theo truy vấn hiện tại.

Gợi ý thực đơn 7 ngày dùng lựa chọn hồ sơ để lọc công thức Việt có khẩu phần,
kèm trái cây ăn liền có khẩu phần USDA. Gram được điều chỉnh trong 0,5–2 lần
khẩu phần nguồn, tối đa 1.000 g/món, nhằm khớp kcal mục tiêu đã xác nhận có hiệu
lực vào từng ngày. Bữa có kế hoạch được giữ, kể cả bữa phụ, và kcal của chúng
được trừ trước khi chia phần còn lại cho các bữa trống. Mặc định sáng/trưa/tối/
phụ chia 25/35/30/10%; đây là quy tắc gợi ý, không phải chỉ định dinh dưỡng.
Không thêm khi bữa đã có chiếm đủ kcal. Không có mục tiêu thì dùng khẩu phần
nguồn và ghi rõ; lệch trên ±5% được báo ngay trong xem trước. Không ép khẩu phần
quá lớn để đạt con số, không tự ghi nhật ký, chưa tối ưu riêng macro/vi chất.

Phân loại được suy ra từ mô tả/nhóm thực phẩm của USDA và thành phần công thức
Việt đã rà soát; **không phải chứng nhận thuần chay** hoặc kiểm tra thành phần
đầy đủ của mọi nhãn hàng. Món chế biến mơ hồ như refried beans truyền thống,
burger thực vật, phô mai không rõ men đông được giữ là chưa rõ. Toàn bộ asset:
1.709 mục thực vật, 160 chay có trứng/sữa, 3.078 không chay, 2.659 chưa rõ.

Không tự sửa/xóa nhật ký hoặc snapshot đã lưu khi đổi chế độ ăn. Món cá nhân,
yêu thích từ món riêng, bữa đã lưu và các lối thêm từ lịch sử chưa có phân loại đầy đủ;
không tuyên bố mọi lối nhập đều bị ràng buộc chế độ ăn.

## Thực phẩm cần tránh

Khai báo tại Cá nhân hóa, ô thực phẩm cần tránh; dùng `;`, dấu phẩy hoặc xuống
dòng để tách tên. Bộ lọc tự bật theo hồ sơ và không bị tắt khi chọn Tất cả chế
độ ăn. Các nhóm từ đồng nghĩa Việt/Anh: sữa, trứng, đậu phộng, đậu nành, lúa mì,
gluten, hạt cây, giáp xác, cá, hải sản, mè; từ khác dùng khớp cụm từ sau chuẩn hóa.
Một tên cụ thể trong nhóm như tôm/hạnh nhân sẽ sàng lọc cả nhóm tương ứng,
được thể hiện bằng tên nhóm trong giao diện. Không có cơ sở cho mọi từ đồng nghĩa.

Tên Việt, mô tả gốc và nguyên liệu công thức tham khảo được đối chiếu; không
có từ khóa trùng nhưng thiếu thành phần vẫn là **chưa rõ** và bị ẩn khỏi tìm/
duyệt/gợi ý. Bản ghi USDA chế biến và sản phẩm thiếu danh sách thành phần không
được coi là đầy đủ; dầu thực vật không rõ loại và thịt chế biến tương tự. Khi
hồ sơ lỗi/đang tải, không mở form với bộ lọc rỗng. Công thức tham khảo không
đại diện mọi quán/nhãn hàng, cần kiểm tra lại nguyên liệu thực tế và nhiễm chéo.

Món từ lịch sử, món riêng, quét ảnh và bữa đã lưu không tự bị xóa. Trước khi
lưu nhật ký có món trùng/chưa rõ, form yêu cầu xác nhận **Vẫn ghi nhật ký** để
ghi lại bữa đã ăn. Ghi nhật ký không xác nhận món an toàn. Kế hoạch mới/sửa
không lưu được khi còn snapshot cần tránh/chưa rõ; phải bỏ hoặc thay món đó.

## Phân phối và quản trị

7.444 mục mới nằm trong APK/offline asset, không tự tạo hàng nghìn document
`food_catalog`. Web admin hiện quản lý catalog trên Firestore nên **không hiện
toàn bộ asset bổ sung**. Các bản ghi server tiếp tục ghi đè theo ID; trạng thái
ẩn trên server được tôn trọng. Phân loại local chỉ được kế thừa khi ID, tên,
nhãn nguồn và bốn chỉ số dinh dưỡng chính vẫn khớp; thay đổi làm mất căn cứ thì
chuyển về chưa rõ nếu server không có phân loại hợp lệ.

Không thay collection, Rules, index, meal snapshot hoặc dịch vụ cloud. Nhật ký
vẫn tính từ món/gram đã xác nhận. Không thêm dependency hay nguồn trả phí.

Nếu asset bổ sung bị thiếu/hỏng, bộ tải giữ danh mục gốc 162 mục thay vì làm
mất toàn bộ catalog local. Khi thiếu metadata, phân loại là chưa rõ. Trường hợp
này chỉ phục hồi dữ liệu, không được coi là đã tải đủ 7.606 mục.

## Kiểm chứng và nghiệm thu

APK mới nhất: `build/releases/healthmate-personalized-food-debug.apk`.
Full678/678, analyze sạch; nhóm cá nhân hóa9/9, nhóm catalog13/13, importer7/7.
Kết quả build/asset/hash ghi trong test-report. Đây là bản debug để nghiệm thu,
chưa cài lên Android thật.

Kết quả cuối và APK được ghi trong `docs/test-report.md` và
`docs/implementation-progress.md`. Tests có nguồn và khẩu phần, chống phân loại
chay sai ở món mơ hồ, server override, hồ sơ → form Nhật ký, hồ sơ → xem trước
thực đơn, bộ lọc và cỡ chữ 100%/150%. Không có thiết bị ADB; cần cài APK mới để
nghiệm thu tốc độ tải/tìm trên Android thật, tìm vài món thường ăn, đổi bộ lọc,
ghi/chỉnh gram và đối chiếu tổng nhật ký.
