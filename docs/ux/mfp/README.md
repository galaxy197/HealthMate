# Ảnh QA giao diện theo ảnh tham chiếu

Các ảnh được render từ test/mfp_ui_test.dart với font asset thật, viewport
390 × 844, textScale 1.0 và 1.5, cả sáng/tối. Dữ liệu trong ảnh là fixture
kiểm thử tổng hợp (HealthMate Tester), không lấy từ tài khoản thật.

- today-*: đầu màn Hôm nay, năng lượng, macro, dải ngày và thanh điều hướng.
- meals-*: các loại bữa và hành động ghi lại, tiêu đề giữ ở đầu khi cuộn.
- progress-*: tổng quan tuần và cột năng lượng.
- weight-*: cân nặng và biểu đồ từ hai lần đo tổng hợp.
- macros-*: tab Macro và biểu đồ các chất.
- actions-*: bảng hành động của nút +.

Chạy lại bằng `flutter test --no-pub test/mfp_ui_test.dart`.
Đây là ảnh widget QA, chưa phải screenshot kiểm thử điện thoại thật.
