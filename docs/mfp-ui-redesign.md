# Đợt UI theo ảnh MyFitnessPal — HealthMate

Ngày: 20/10/2026. Nền code: ba0557d, giữ bản sửa palette chưa commit từ lượt trước.
Đây là một đợt chỉnh trải nghiệm hiện có, không mở giai đoạn backend mới.

## 1. Hành vi đã tích hợp

- **Hôm nay**: tiêu đề giữ ở đầu khi cuộn; chọn ngày bằng lịch hoặc dải tuần.
  Thẻ năng lượng dùng tổng meal log của đúng ngày; so sánh còn/vượt chỉ khi
  tài khoản có mục tiêu thật áp dụng cho ngày đó. Không cộng calo vận động ước tính.
- **Macro**: các chất theo màu riêng; đổi gram/tỷ lệ năng lượng 4/9/4. Khi thiếu
  chất hoặc tổng năng lượng bằng 0, không bịa phần trăm. Chưa tải được dữ liệu
  hiển thị dấu —, không thay thành 0. Khung tiến độ đứng yên khi chưa tính được,
  không để lỗi đọc tạo spinner vô hạn.
- **Bốn loại bữa**: sáng/trưa/tối/phụ, nút Ghi bữa chọn sẵn loại và ngày.
  Gợi ý dùng lại là bản ghi gần nhất thuộc cùng loại ở ngày trước ngày đang xem;
  tên món được hiển thị rõ và phải xác nhận trong form. Không tự ghi vào Firestore.
- **Ghi nhận bổ sung**: nước, phút vận động, số bản ghi bữa, cân nặng gần nhất;
  thêm nhanh 250 ml theo ngày đang xem. Giữ mục tiêu chi tiết và nhìn lại tuần.
- **Tiến độ**: Tổng quan/Năng lượng/Dưỡng chất/Macro; cột bo tròn theo từng ngày,
  biểu đồ cân nặng thật. Trung bình chia theo số ngày có giá trị đã ghi, gồm số
  0 được ghi có chủ ý; không xem ngày trống hoặc tương lai là 0. Có lựa chọn tuần
  và báo cáo 30/90 ngày hiện có; các tab chỉ số tuần chỉ hiện khi chọn tuần.
  Chi tiết từng ngày/mục tiêu lịch sử vẫn mở được bằng nút riêng.
- **Điều hướng** (cập nhật theo yêu cầu 5 ô): Hôm nay – Nhật ký – + – Tiến độ –
  Thêm; nút + ở giữa. Thêm mở phần Cá nhân hiện có, đặt Mục tiêu/Nhiệm vụ và
  Chat lên đầu. Menu + có ghi nhận, Quét món và lối tắt Mục tiêu/Chat.
  Các route Quest/Chat/Auth/Onboarding không bị xóa. Scanner/Chat hiện mặc định;
  build chỉ tính năng cơ bản vẫn có thể đặt hai cờ AI=false. Quyền AI/consent
  giữ nguyên. Quét mã vạch nằm trong phần chung của form thêm bữa, kể cả khi
  dùng MealFoodSources; không phụ thuộc cờ AI.
- **Xuất dữ liệu**: icon trên Tiến độ mở dialog CSV có consent hiện có;
  không thêm một nút xuất giả hoặc tự động xuất dữ liệu.
- **Chọn món**: có thể duyệt danh mục thật ngay khi mở; tìm kiếm có debounce,
  kết quả danh mục sẵn có hiện ngay, kết quả đến trễ không thay từ khóa mới.
  Xóa từ khóa phục hồi danh sách; tìm trong món gần đây/yêu thích chuẩn hóa dấu
  tiếng Việt. Không gọi tìm kiếm ngoài khi đang lọc các tab nguồn riêng.

## 2. Thiết kế và dữ liệu

Nền tối #171824, thẻ #252832, chữ sáng, nút xanh; giao diện sáng vẫn được hỗ trợ.
Card 24 dp, chữ số nổi bật, spacing thống nhất. Dùng Be Vietnam Pro có sẵn trong
assets; giấy phép SIL OFL trong assets/fonts/be_vietnam_pro/OFL.txt; không tải font
qua mạng. Test tương phản kiểm tra chữ chính/phụ, nút chính và bốn cặp màu chỉ số
ở cả sáng/tối, tối thiểu 4,5:1. Thang cyan và orange500 được giữ hợp lệ.

Hai listener bữa trên Hôm nay: ngày chọn và ngày trước để hiển thị gợi ý thật,
không tải 100 bữa hoặc toàn bộ lịch sử. Nước/vận động giữ dateKey, bữa giữ truy
vấn repository hiện có. Provider ngày trước được hủy khi đổi ngày/rời tab.
Tiến độ dùng chung một weeklyLogsProvider cho các tab; không thêm 7 listener.
Mục tiêu tải độc lập nên lỗi mục tiêu không che tổng nhật ký đã xác nhận.

Luồng form được chuyển nguyên nghiệp vụ sang journal_meal_entry.dart để Hôm nay
và Nhật ký cùng dùng: account guard, nháp mã hóa, operation ID, retry và xác nhận.
Listener danh mục được giữ riêng đúng vòng đời mở form để provider autoDispose
không hủy future trước khi trả dữ liệu. Không đổi schema, Rules, indexes, migration,
credential, package, cấu hình AI hoặc cài dịch vụ mới.

## 3. File chính

- lib/core/theme/app_colors.dart, design_tokens.dart
- lib/core/widgets/app_shell.dart, tracking_page.dart (mới)
- lib/features/dashboard/presentation/dashboard_screen.dart
- lib/features/dashboard/presentation/widgets/mfp_calories_card.dart,
  mfp_macros_card.dart, mfp_meal_card.dart
- lib/features/progress/presentation/progress_screen.dart, progress_overview.dart (mới)
- lib/features/journal/presentation/journal_screen.dart, journal_meal_entry.dart (mới)
- lib/features/food_library/presentation/meal_food_sources.dart
- lib/features/nutrition/presentation/meal_form_dialog.dart
- test/mfp_ui_test.dart, mfp_search_test.dart (mới)
- test/support/fake_food_search_service.dart (mới), test_app.dart
- Cập nhật dashboard/progress/weekly_reflection/nutrition_targets test theo đường
  vào mới; giữ assertions số liệu, UID, pending/error, xác nhận và số lần truy vấn.
- Bổ sung ProviderScope vào hai fixture form độc lập vốn thiếu sau khi upstream
  chuyển MealFormDialog sang ConsumerStatefulWidget. Fake external food search
  giúp widget test không gọi USDA thật hoặc plugin SQLite trên host test.

## 4. Kiểm chứng và giới hạn

Kết quả lệnh cuối được ghi trong implementation-progress.md và test-report.md.
Ảnh widget QA tại ux/mfp/ sử dụng dữ liệu tổng hợp, không phải nhật ký người dùng.
Các ảnh này không chứng minh luồng camera hoặc API online đã qua trên điện thoại.
Không chạy lại emulator security/production QA trong đợt UI vì không sửa Rules.

Các lượt kiểm tra phát triển thất bại được giữ ở build/mfp-*.log: tương phản
cân nặng 4,10:1 (đã chỉnh màu); capture hình ngoài runAsync gây treo (đã sửa
harness); tap vào card khi chỉ định chụp làm chuyển route (đã tách thao tác);
catalog provider autoDispose (đã giữ subscription đúng vòng đời); tràn hàng tiêu
đề khi chữ lớn (đã cho xuống hàng); thiếu metadata thời gian trong fixture ảnh
cân nặng (đã bổ sung). Không đổi expected số liệu hoặc xóa case để che lỗi.

## 5. Người dùng cần xem trên điện thoại

1. Dừng phiên debug cũ, F5 từ lib/main.dart. Để giống ảnh tham chiếu tối, chọn
   **Thêm → Giao diện → Tối**; lựa chọn trên thiết bị vẫn được giữ.
2. Cuộn Hôm nay/Tiến độ để kiểm tra tiêu đề giữ ở đầu; bật cỡ chữ lớn và bàn phím.
3. Chọn ngày trống, ngày có bữa và ngày trước: so calo/macro/nước với Nhật ký.
4. Ghi bữa và ghi lại bữa trước: đúng loại/ngày, không lưu trước Lưu; thử hủy/nháp.
5. Đổi tab báo cáo, mở chi tiết và so ngày có dữ liệu với ngày chưa ghi.
6. Thử +, thêm nước/cân nặng, xuất CSV có consent, đăng xuất/đăng nhập lại.
7. Camera barcode, App Check, mạng thật, USDA/Open Food Facts và offline trên
   thiết bị vẫn cần QA riêng; bộ widget test dùng fake repository/service.

Chưa commit/push hoặc deploy Firebase trong đợt này. Công việc tiếp theo được
đề xuất là nghiệm thu trên điện thoại; không tự triển khai giai đoạn khác.
