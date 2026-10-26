# Báo cáo theo năm và khoảng ngày — 27/10/2026

## Phạm vi và thời hạn lưu

Thực hiện phần mở rộng báo cáo của Giai đoạn 8 theo yêu cầu người dùng. Các mốc
7/30/90 ngày trước đây là cửa sổ xem/tải báo cáo, không phải lệnh xóa nhật ký sau
thời gian đó. Mã ứng dụng không tự xóa `meal_logs`, `water_logs`, `activity_logs`
hoặc `body_metrics` theo các mốc này. Xóa nhật ký/tài khoản vẫn theo thao tác của
người dùng. Không đưa ra cam kết về lưu trữ vô hạn, quota hoặc chính sách ngoài app.

Không tạo dữ liệu tổng hợp theo năm trên server, không di chuyển/ghi lại nhật ký
cũ. Không thay schema Firestore, Rules, index, lịch sử mục tiêu hoặc backend.
Các thay đổi cá nhân hóa dinh dưỡng chưa commit của lượt trước được giữ nguyên.

## Cách dùng

Mở **Tiến độ**:

- **Tuần / 30 ngày / 90 ngày** vẫn dùng được như trước.
- **Theo năm**: chọn năm từ danh sách hoặc mũi tên trước/sau. Năm cũ tính đủ
  01/01–31/12, kể cả ngày 29/2; năm hiện tại tính đến hết hôm nay, không thêm
  các ngày tương lai vào mẫu số. Có thể mở lại năm cũ dù nằm ngoài 90 ngày gần đây.
- **Tùy chọn**: chọn ngày bắt đầu/kết thúc, hoặc nhập số ngày nguyên 1–366 và
  ngày kết thúc. Khoảng tính cả hai đầu. Bấm Áp dụng mới tải; Hủy giữ khoảng cũ.
  Mỗi lượt tối đa 366 ngày, không phải giới hạn tổng số năm dữ liệu được lưu.
- Báo cáo hiển thị kcal/ba chất/chất xơ theo dữ liệu đã biết, số ngày có ghi và
  có xác nhận, nước, vận động và cân nặng. Khoảng trên 90 ngày có mục **Tổng hợp
  theo tháng**; **Chi tiết từng ngày / xác nhận** phân trang 31 ngày.
- Ngày không ghi là thiếu dữ liệu, không phải 0 kcal đã ăn. Trung bình năng lượng
  chỉ lấy ngày có bữa được người dùng xác nhận đủ; không chia tổng cho 365/366 khi
  phần lớn ngày chưa ghi. Mục tiêu gốc đúng từng ngày được giữ theo phiên bản cũ;
  biểu đồ chưa cộng điều chỉnh bước, có nhãn giải thích.

Các màn wellness chuyên biệt bước chân/giấc ngủ vẫn giữ phạm vi hiện tại. Đợt này
mở rộng báo cáo dinh dưỡng/nhật ký trong Tiến độ, không thêm phân tích giấc ngủ năm.

## Lưu tệp riêng

Nút **Xuất nhật ký CSV** trên Tiến độ điền sẵn khoảng năm/tùy chọn đang xem. Có thể
chọn lại khoảng/số ngày hoặc chọn năm nay trong form xuất. Hỗ trợ Android và hộp
chọn nơi lưu, vẫn cần người dùng đồng ý xuất dữ liệu riêng tư trước khi thực hiện.

CSV mở rộng từ 1–90 thành **1–366 ngày**, giữ nguyên định dạng UTF-8, snapshot,
đơn vị, ô chưa biết, chống công thức trong ô và kiểm tra byte sau khi lưu. Bao gồm
bữa ăn từng món, nước, vận động, cân nặng; không bao gồm chat/hồ sơ/mục tiêu/nháp.
File tối đa 5 MB; tối đa 10.000 bản ghi mỗi nguồn sau ghép (xem giới hạn đọc bên dưới).
Nếu vượt giới hạn cần chia khoảng, không xuất âm thầm một phần rồi báo thành công.

## Tải dữ liệu và quyền riêng tư

- `ReportRange` xử lý ngày lịch, không dùng chênh lệch giờ địa phương để đếm ngày.
  Chia khoảng tối đa 366 ngày thành nhiều phần liên tiếp **không quá 90 ngày**.
- Giữ giới hạn repository cũ: đọc server, mỗi truy vấn có ngưỡng 2.000 bản ghi;
  không nâng giới hạn query chung cho chatbot, journal, wellness hoặc luồng khác.
- Từng nguồn tải tuần tự, loại trùng ID. Phiên bản mục tiêu dùng khóa ngày hiệu lực
  để không cộng lặp bản baseline xuất hiện ở nhiều phần. Ghép tối đa 10.000 bản ghi
  mỗi nguồn. Một phần lỗi thì nguồn đó báo lỗi, không trả tổng thiếu như tổng đủ.
  Nguồn độc lập tải thành công vẫn được hiển thị.
- UID được chụp trước mỗi phiên; provider hủy/đổi tài khoản thì bỏ kết quả chậm
  và không tiếp tục phần kế. Xuất file kiểm lại UID/session trước đọc tiếp, trước
  ghi và sau khi người dùng chọn nơi lưu. Vẫn giữ kiểm tra A→B→A.
- Báo cáo không tự ghi Firestore. Chỉ đọc khi mở/chọn khoảng hoặc bấm tải lại;
  nhiều năm không được tải cùng lúc. Khoảng dài làm tăng số lượt đọc theo dữ liệu,
  không hứa miễn phí vô hạn hoặc thời gian tải cố định.
- Một nguồn có nhiều truy vấn không phải snapshot nguyên tử của toàn năm. Dữ liệu
  có thể được chỉnh trong lúc tải; bấm Tải lại khi vừa sửa nhật ký.

## Kiểm tra và giới hạn nghiệm thu

Ca mới bao phủ năm nhuận, năm hiện tại, khoảng 1/123/366 ngày và quá giới hạn,
hai đầu bao gồm, ghép phần đúng ngày, không trùng target, lỗi phần sau và retry,
đổi UID khi chờ tải, giữ ngày chưa ghi, chi tiết tháng/ngày, CSV năm đủ và lỗi
không tạo tệp, prefill xuất theo báo cáo, calendar picker/cancel, màn 360×800/chữ150%.

Kết quả cuối và log ở đầu [test-report.md](test-report.md). Ảnh widget font thật
ở `build/year-report-ui/year.png`; dữ liệu fixture chỉ dùng kiểm thử. Chưa cài/
nghiệm thu luồng này trên điện thoại thật và không nhận test Emulator cũ là vừa
chạy lại. Không cần cấu hình mới ở Firebase; không deploy hoặc push trong đợt này.

APK debug thường (gồm cả cá nhân hóa dinh dưỡng của lượt trước):
`build/releases/healthmate-year-reports-debug.apk`, 236755282 byte,
SHA256 `06B582128D40D19D6EC99DC9943765774EB6123C7B8E0E07F1427D869CD4E592`.
Entry point `lib/main.dart`, dùng cấu hình AI/App Check debug cục bộ đã có;
không phải bản phát hành production hoặc integration-test APK.
