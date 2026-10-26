# Đề xuất giao diện và điều hướng — 26/10/2026

Trạng thái: đề xuất theo yêu cầu người dùng, chưa thay đổi giao diện ứng dụng.
Ảnh tham khảo dùng để định hướng bố cục, màu sắc và khoảng cách; không dùng số
liệu hoặc món minh họa trong ảnh làm dữ liệu thật của HealthMate.

## Hồ sơ ở góc trái trên

Trên các trang chính, đặt avatar/chữ cái tên và lời chào ở góc trái trên.
Bấm vào mở Hồ sơ, mục tiêu cá nhân, tài khoản, cài đặt và nhắc nhở. Có thể dùng
chữ cái từ tên hiện có trước, chưa cần thêm dịch vụ lưu ảnh đại diện.
Trang chi tiết vẫn có nút quay lại. Tiêu đề các trang chính phải dễ nhận biết.

## Năm mục dưới cùng, theo thứ tự trái sang phải

| Mục | Nội dung chính |
| --- | --- |
| Hôm nay | Kcal đã ăn/còn lại theo mục tiêu, đạm–carb–béo, nước, bước chân, giấc ngủ và nhiệm vụ tiếp theo. |
| Dinh dưỡng | Nhật ký bữa ăn, nhập tay/chụp ảnh/mã vạch, món đã lưu, bữa mẫu, thực đơn và dưỡng chất. |
| Tập luyện | Nhật ký vận động hiện có; sau đó bổ sung thư viện bài, buổi tập, lịch và lịch sử tập. |
| Tiến độ | Cân nặng/mục tiêu, biểu đồ 7/30/90 ngày, xu hướng ăn uống, bước chân và giấc ngủ. |
| Trợ lý | Chat AI và lịch sử trò chuyện, giải thích dữ liệu đã ghi nhận. |

Hiện thanh dưới có bốn điểm đến và một nút “+”; đề xuất đổi thành năm điểm đến
thật. Nút “+” mở ghi nhận nhanh đặt riêng trên màn hình, ưu tiên chụp/ghi bữa ăn.
Nhiệm vụ hằng ngày nằm trong Hôm nay; cấu hình và hồ sơ mở qua avatar.
Giữ trạng thái trang, ngày đã chọn, nháp bữa ăn và lịch sử chat khi đổi mục.

## Phong cách từ ảnh tham khảo

- Nền trắng/xanh mint nhạt, xanh teal làm màu hành động chính; hỗ trợ theme tối.
- Một thẻ kcal nổi bật, ba chỉ số dưỡng chất gọn; đặt chi tiết dưới vùng mở rộng.
- Thẻ bữa ăn rõ tên, giờ, kcal và nút thêm; giảm các đoạn giải thích dài ở trang chính.
- Bo góc và khoảng cách nhất quán; chữ dễ đọc, không chỉ phân biệt trạng thái bằng màu.
- Luôn giữ nhãn ước tính và xác nhận khẩu phần; khi chưa có dữ liệu, hiển thị cách bắt đầu.
- Tránh các nút hoặc tab hứa tính năng chưa hoạt động trong bản phát hành.

## Phần bài tập còn thiếu

Ứng dụng hiện có nhật ký vận động theo loại/thời lượng. Mã nguồn có danh mục
MET tham khảo, nhưng chưa có luồng hướng dẫn và thực hiện từng buổi tập.

Phạm vi đề xuất cho một đợt riêng:

1. Thư viện bài tập: lọc nhóm cơ, trình độ, dụng cụ; hướng dẫn tư thế có nguồn.
2. Buổi tập: chọn bài, số hiệp/lần/phút và đồng hồ nghỉ; có thể sửa hoặc bỏ bài.
3. Lịch và lịch sử: đặt lịch tuần, lưu buổi hoàn thành và xem tiến độ.

Dùng dữ liệu hướng dẫn được phép sử dụng, không tự thêm video hoặc nội dung
không rõ bản quyền. Calo vận động chỉ là tham khảo; không tự cộng hai lần với
bước chân hoặc phần vận động đã có trong mục tiêu. Chưa triển khai phần này
trong đợt đưa mã nguồn lên GitHub.

Thứ tự đề xuất: thống nhất điều hướng/header → làm gọn Hôm nay và Dinh dưỡng →
triển khai Tập luyện trong một đợt được người dùng yêu cầu riêng.

Tham khảo hệ thống thành phần: [Material Design 3](https://m3.material.io/).
