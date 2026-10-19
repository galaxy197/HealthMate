# H6 — Chất xơ có nguồn

H6 bổ sung chất xơ (g), không tự suy ra từ kcal/macros và không mở thêm natri,
đường hoặc chất béo bão hòa khi chưa có nguồn phù hợp. Chưa triển khai production.

## Dữ liệu và cách đọc

- `NutritionTotals.fiberG` là tổng phần biết được; `fiberKnown` cho biết tổng
  có đầy đủ nguồn hay chưa. Không có số liệu khác với 0 g đã được xác nhận.
- Catalog/món riêng dùng `fiberGPer100g` tùy chọn. Trường thiếu/hỏng trong catalog
  giữ khả năng sử dụng kcal/macros hợp lệ và hiển thị chất xơ chưa biết.
- Món riêng và Quick Add có ô chất xơ tùy chọn; xóa ô không lưu 0 thay thế.
  Quick Add tính đúng cơ sở 100 g, 100 ml, khẩu phần hoặc tổng đã ăn.
- Công thức cộng các nguyên liệu có nguồn rồi chia theo khối lượng thành phẩm.
  Một nguyên liệu thiếu số liệu làm tổng mất trạng thái đầy đủ; UI dùng
  `≥… g (chưa đủ)` hoặc `Chưa đủ dữ liệu`. Danh sách nguyên liệu giữ từng nguồn.
- Nhật ký, thư viện, preview, phần chi tiết dinh dưỡng và báo cáo dùng cùng trạng
  thái này. Chi tiết ngày nêu số snapshot có đủ dữ liệu chất xơ. Ngày trống không
  được biến thành bằng chứng đã ăn 0 g. Không thêm mục tiêu chất xơ tự động.

## Hợp đồng lưu và tương thích

Snapshot có `fiberG` khi biết số liệu (giữ cả 0 thật). Nếu chỉ là tổng biết được,
snapshot thêm `fiberIncomplete: true`; thiếu cả hai trường nghĩa là chưa biết.
Reader còn nhận dạng `knownFiberG` từ bản thử cục bộ; đây không phải migration.
Các giá trị được nhân theo lượng và đóng băng trong lịch sử, không đọc lại nguồn
để thay đổi bữa cũ.

Các phiên bản mới: meal log **4**, món riêng **2**, recipe **2**, bữa mẫu **3**.
Nhật ký 2/3 và thư viện/bữa mẫu cũ tiếp tục đọc được. Sửa/copy giữ phiên bản tối
thiểu; transaction cập nhật thư viện/bữa mẫu giữ phiên bản đã lưu. Rules chặn
hạ phiên bản của bản ghi mới để client cũ không ghi đè làm mất chất xơ.

Bữa mẫu 3 có cách mã hóa gọn để kiểm tra đủ 5 món trong giới hạn Rules:

- `items` dùng `quantity` + `quantityUnit` cho cả g/ml/serving/entry; không ghi
  gram giả. Macro chưa biết được bỏ khỏi snapshot này; reader phục hồi thành
  null và giữ cờ thiếu, không phục hồi thành 0 đã biết.
- `fiberValues` có đúng số phần tử như items: số là giá trị g, null là chưa biết.
- `fiberPartialMask` chỉ xuất hiện khi có tổng chất xơ chưa đầy đủ; bit thứ i
  đánh dấu phần tử i. Đây là metadata mức độ ghi nhận, không phải chất mới.
- Cả giá trị, độ dài, đơn vị, mask, giới hạn từng món/tổng và UID đều được Rules
  kiểm tra. Vẫn tối đa 5 món/bữa mẫu và 6 nguyên liệu/công thức.

Không có collection/index mới, migration hoặc tác vụ ghi lại lịch sử.

## Bốn nguồn USDA đã rà soát

`data/food_catalog/legacy_usda.json` dùng lại bốn ID có sẵn, giữ nguyên kcal và
ba macro đã đối chiếu. Chất xơ lấy nutrient **1079**, đơn vị g/100 g, dữ liệu
SR Legacy; ghi ngày rà soát 2026-10-19 và vẫn gắn nhãn tham khảo/ước tính.

| ID | FDC | Chất xơ g/100 g |
|---|---:|---:|
| rice-cooked | [168878](https://fdc.nal.usda.gov/food-details/168878/nutrients) | 0,4 |
| banana-raw | [173944](https://fdc.nal.usda.gov/food-details/173944/nutrients) | 2,6 |
| apple-raw-skin | [171688](https://fdc.nal.usda.gov/food-details/171688/nutrients) | 2,4 |
| egg-boiled | [173424](https://fdc.nal.usda.gov/food-details/173424/nutrients) | 0 thật |

Không gán các giá trị này cho món chế biến khác hoặc suy đoán cho sản phẩm TH
không công bố chất xơ. Branch có 155 mục có nguồn, không đồng nghĩa production
đã có đủ metadata. GET/dry-run production: 158 mục đang có; đề xuất 3 mục mới,
51 cập nhật metadata (47 khẩu phần + 4 nguồn chất xơ), 0 conflict, 152 skip theo
ID/tên. Manifest chỉ để review; `--apply` của importer vẫn chỉ tạo mới, không tự
áp dụng các cập nhật metadata hoặc ghi users/*.

## Kiểm thử và lỗi phát hiện trong quá trình làm

Xem nhật ký kết quả cuối trong `test-report.md`. Có unit/widget cho 0/thiếu/giá trị
hỏng, nguồn USDA, khẩu phần phân số, recipe yield, lower bound, schema, snapshot,
template round-trip và Quick Add ở 360/390/412, chữ 1/1,5/2, sáng/tối.

Rules ban đầu nhiều lần vượt 1.000 biểu thức ở 5/6 dòng. Một phương án metadata
dùng array lồng bị SDK từ chối; một lần sửa regex bằng replacement string gây lỗi
cú pháp. Đã sửa codec/Rules và giữ nguyên các assertion, số dòng tối đa, kiểm tra
truy cập chéo và giới hạn tổng. Những lượt lỗi có log trong build/h6-*.log; không
dùng chúng để tuyên bố đạt. Tài liệu [Rules List](https://firebase.google.com/docs/reference/rules/rules.List)
được đối chiếu khi tối ưu allowlist.

## Rollout và rollback chưa thực hiện

Phải review toàn bộ Rules/schema H2–H6 và đưa client đọc được các phiên bản mới
lên trước khi bật ghi các kiểu mới trên production. Không rollback mù về Rules
cũ sau khi đã có dữ liệu mới; cần giữ khả năng đọc/sửa các phiên bản đó hoặc tạm
dừng riêng tính năng ghi. Không xóa dữ liệu người dùng để rollback.

Catalog cần bước phê duyệt riêng dựa trên manifest mới và precondition updateTime;
rollback metadata chỉ phục hồi các field đã được duyệt, không thay macro hay bữa
đã ghi. Production Rules, indexes, catalog và tài khoản thật chưa bị thay đổi.


Kết quả chốt: format59/0, analyze sạch62.1s; Flutter423/423(67s), unitH6 mới nhất5/5; Rules51/51, SDK19/19(43s); Android10checkpoint+H1–H6 đạt239s. Ảnh docs/ux/h6/fiber-volume.png; catalog-manifest-review.json chỉ để review. Lượt native đầu có assert fixture sai, đã sửa kỳ vọng0,5g đầy đủ và đọc lại lịch sử thật sau xóa nguồn.
