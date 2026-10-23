# Rút gọn thông tin giao diện — 2026-10-20

Phạm vi: các màn chính đang có; không đổi nghiệp vụ, nguồn dữ liệu hoặc thanh 5 ô.

| Khu vực | Cách hiển thị mới |
| --- | --- |
| Hôm nay | Giữ ngày, kcal, ba chất, bữa ăn và ghi nhanh. Múi giờ nằm trong tooltip của ngày. |
| Mục tiêu/báo cáo | Gom vào “Mục tiêu và tổng kết”, mặc định đóng. Chỉ dựng nội dung khi mở. Tiến độ vẫn truy cập trực tiếp từ thanh dưới. |
| Dinh dưỡng | Bỏ đoạn giải thích cố định. Nút ⓘ mở cách đọc gram/tỷ lệ và dữ liệu thiếu. |
| Thẻ bữa | Bỏ câu “Chưa ghi bữa này” lặp lại 4 lần. Tên món dài được giới hạn dòng; Xem chi tiết mở nhật ký đầy đủ. Ghi lại bữa trước vẫn mở xác nhận. |
| Số liệu phụ | Bỏ nhãn lặp ngày/số bữa, thu gọn chiều cao tối thiểu. Cân nặng vẫn có ngày đo. |
| Nhật ký nước/vận động | Giữ tổng và thao tác; giải thích nguồn số liệu nằm sau ⓘ. Nước hiển thị ml, không lặp cùng số theo lít. |
| Thêm bữa | Đếm món ngắn “n/5 món đã chọn”, hướng dẫn khẩu phần/giới hạn nằm sau ⓘ. Barcode vẫn hiện ở form dùng MealFoodSources. |
| Cá nhân | Rút gọn giới thiệu, bỏ email bị lặp trong Hồ sơ; email vẫn có ở Tài khoản. |

Không thu gọn thông báo lỗi cần xử lý, cảnh báo đang lưu, nhãn ước tính, nút thử lại,
xác nhận lưu/xóa hay consent trước khi gửi AI. Giá trị chưa biết vẫn là —, không đổi
thành 0. Không thay đổi dữ liệu/mục tiêu đã lưu, truy vấn theo ngày hoặc quyền UID.

## File chính

- lib/core/widgets/details_disclosure.dart: nội dung phụ chỉ dựng sau khi mở.
- lib/core/widgets/information_button.dart: mở/đóng giải thích, có tooltip.
- lib/features/dashboard/presentation/dashboard_screen.dart và widgets/mfp_*.
- lib/features/journal/presentation/daily_log_section_card.dart,
  journal_nutrition_overview.dart, journal_screen.dart.
- lib/features/nutrition/presentation/meal_form_dialog.dart, meal_log_section.dart.
- lib/features/water/presentation/water_log_section.dart.
- lib/features/profile/presentation/profile_screen.dart.
- test/compact_ui_test.dart và các test nhật ký/mục tiêu/báo cáo được cập nhật cách
  mở phần chi tiết hoặc nhãn ngắn; giữ nguyên kiểm tra tính toán/lưu/UID.

## Xem trên điện thoại

1. Chạy lại app: phần đầu Hôm nay bớt chữ, thanh dưới vẫn đủ 5 ô.
2. Cuộn xuống mở/đóng Mục tiêu và tổng kết; chỉnh mục tiêu, mở báo cáo tuần.
3. Bấm ⓘ ở Dinh dưỡng, Nước uống/Vận động và form bữa; kiểm tra đọc/đóng ở chữ lớn.
4. Ghi/sửa bữa, nước, vận động; so tổng trước/sau, thử ngày trống và ngày có dữ liệu.
5. Kiểm tra tên món dài, bàn phím, cỡ chữ lớn và chế độ sáng/tối.

Ảnh trong docs/ux/mfp tiếp tục là fixture tổng hợp từ widget test. Chưa nghiệm thu
camera, API AI/mã vạch hoặc tương tác trên điện thoại thật trong lượt này.

## Kết quả kiểm tra

- Format 20 file: qua, kiểm tra lại không có thay đổi.
- Flutter test: 490/490 qua, 65 giây.
- Analyze: 21 info có sẵn, không warning/error; exit 1.
- Build APK debug: qua, assembleDebug 49,1 giây.
- Không commit, push hoặc deploy Firebase.
