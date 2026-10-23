# Bàn giao sang chat mới — HealthMate

Cập nhật: 20/10/2026 (Asia/Saigon). Đây là bối cảnh tiếp tục dự án, không phải yêu
cầu triển khai thêm tính năng. Đọc AGENTS.md và kiểm tra code/Git hiện tại trước
khi sửa; nếu trạng thái đã đổi, ưu tiên dữ liệu thực tế.

**Cập nhật Git ngày 23/10/2026:** người dùng đã yêu cầu commit và push đầy đủ
các thay đổi UI/test/tài liệu lên GitHub. Mô tả “chưa commit” và HEAD bên dưới là
ảnh chụp ngày 20/10, trước đợt đồng bộ này; chat mới phải đọc `git status`,
`git log` và đối chiếu origin/main để xác định trạng thái mới nhất.

## Dự án và Git

- Thư mục: `C:\Users\LEGION\OneDrive - Ho Chi Minh City University of Foreign Languages and Information Technology - HUFLIT\Documents\ChatGPT\HealthMate 2`.
- Flutter/Dart, Riverpod, go_router, Firebase Auth/Firestore/AI Logic; Android trước.
- Nhánh đang làm: main. HEAD khi bàn giao: `ba0557d` — `feat: Add MyFitnessPal-style UI components`.
- Có nhiều file sửa và file mới **chưa commit/push** của các lượt UI gần đây.
  Phải đọc git status và diff; không reset, clean, ghi đè hoặc pull đè thay đổi.
- Không commit/push/deploy Firebase nếu chưa có yêu cầu mới. Không thực hiện lại
  yêu cầu tắt laptop cũ: yêu cầu đó thuộc công việc trước, hiện người dùng đang chạy app.

## Trạng thái gần nhất

1. UI được sửa theo ảnh MyFitnessPal người dùng gửi: giao diện tối xanh đen,
   điểm nhấn xanh dương, thẻ lớn, số liệu thật. Giữ theme sáng và font Be Vietnam Pro
   đóng gói sẵn. Không dùng ảnh/số liệu của MyFitnessPal làm dữ liệu ứng dụng.
2. Thanh dưới có đúng **5 ô Hôm nay / Nhật ký / + / Tiến độ / Thêm**, + ở giữa.
   Nhật ký, Quest, Chat, Cá nhân và Tiến độ giữ route/branch có sẵn.
3. **+ → Quét món** mở FoodScannerDialog. Scanner/Chat hiển thị mặc định qua
   bool.fromEnvironment(defaultValue: true) trong appFeatureFlagsProvider.
   Constructor AppFeatureFlags vẫn mặc định false cho cấu hình tường minh/test;
   test helper mặc định core-only. Build có hai define=false vẫn tắt được AI.
   Không bỏ kiểm tra hồ sơ 18+, consent, UID hoặc Firebase App Check.
4. **Thêm** đưa Mục tiêu/Nhiệm vụ và Chat lên đầu; + cũng có hai lối tắt này.
   Quest/Chat được ánh xạ trạng thái chọn về Thêm trên thanh dưới.
5. Quét mã vạch đã chuyển ra phần chung MealFormDialog để xuất hiện cả trong
   luồng thật có sourcesBuilder/MealFoodSources. Chặn mở lúc lưu/bỏ nháp hoặc đủ
   5 món. Chưa nghiệm thu camera/API sản phẩm thật trong lượt sửa UI này.
6. Hôm nay dùng ngày chọn, bữa ngày trước cho sao chép, các nguồn nước/vận động/
   cân nặng thật. Form dùng chung journal_meal_entry.dart giữ UID guards, nháp,
   operation ID và xác nhận lưu. Tìm món đã sửa debounce/response đến trễ và
   duyệt catalog khi chưa nhập chữ; test dùng fake API.
7. Yêu cầu mới nhất đã hoàn thành: **giảm thông tin chen chúc**. Hôm nay giữ số
   liệu/bữa/ghi nhanh; mục tiêu dinh dưỡng, Goal/Quest và WeeklyReflection nằm
   trong “Mục tiêu và tổng kết” mặc định đóng, nội dung chỉ dựng khi mở.
   Bỏ nút tiến độ trùng tab, UTC chuyển vào tooltip ngày, giảm nhãn lặp và chiều
   cao thẻ phụ. Nút ⓘ mở giải thích dinh dưỡng/nước/vận động/khẩu phần. Nước dùng
   ml, không lặp lít. Không ẩn lỗi cần xử lý, nhãn ước tính, consent hoặc xác nhận.
   Dấu — vẫn phân biệt với 0. Cá nhân bỏ email bị lặp.

## Báo cáo tuần/tháng: câu hỏi đã trả lời, chưa có yêu cầu sửa

- Tiến độ có Tuần (chọn tuần trước), 30 ngày và 90 ngày, số liệu/biểu đồ thực.
- “30 ngày” là khoảng lùi 30 ngày đến hôm nay, **chưa phải tháng lịch**.
- Có xuất nhật ký CSV theo khoảng ngày. Người dùng mới hỏi đã có báo cáo chưa;
  không tự thêm tháng lịch nếu chưa được yêu cầu.

## Kiểm thử đã chạy thực tế

- Dart format 20 file của đợt rút gọn: qua, kiểm tra lại 0 thay đổi.
- `flutter --no-version-check test --no-pub --reporter expanded`: **490/490 qua**,
  65 giây. Log `build/compact-full-final.log`.
- `flutter --no-version-check analyze --no-pub`: **21 info, 0 warning/error**,
  exit 1, 21,7 giây. Log `build/compact-analyze.log`. Không gọi analyze sạch.
  Info có sẵn: withOpacity cũ, print trong search, http đang ở dev_dependencies
  nhưng được import trong lib.
- `flutter --no-version-check build apk --debug --no-pub`: qua, assembleDebug
  49,1 giây; vẫn có cảnh báo Kotlin plugin. Log `build/compact-build.log`.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Git diff whitespace check có cấu hình cr-at-eol: qua.
- Chưa QA trực tiếp điện thoại/camera/AI/API mã vạch trong lượt UI này. Chưa chạy
  lại security emulator vì không đổi Rules. Không đổi schema/index/package,
  không deploy hoặc ghi dữ liệu production trong các lượt này.
- Test/ảnh dùng dữ liệu tổng hợp. Không bỏ test hay assertion tính toán để né lỗi;
  một số test cũ được cập nhật thao tác mở chi tiết hoặc nhãn rút gọn.

## Tài liệu và file cần đọc

- AGENTS.md; docs/implementation-progress.md; docs/test-report.md.
- docs/mfp-ui-redesign.md; docs/compact-ui.md; docs/ux/mfp/README.md.
- lib/core/widgets/app_shell.dart, details_disclosure.dart, information_button.dart.
- lib/features/dashboard/presentation/dashboard_screen.dart và widgets/mfp_*.
- lib/features/journal/presentation/journal_meal_entry.dart, journal_screen.dart.
- lib/features/nutrition/presentation/meal_form_dialog.dart.
- lib/features/progress/presentation/progress_screen.dart, progress_overview.dart.
- lib/features/reports/presentation/period_report_panel.dart.
- test/compact_ui_test.dart, navigation_features_test.dart, mfp_ui_test.dart,
  mfp_search_test.dart và các fake trong test/support.

## Môi trường chạy

- Flutter: `D:\Flutter\flutter\bin\flutter.bat`.
- Dart: `D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe`.
- Java: `C:\Program Files\Android\Android Studio\jbr` (JAVA_HOME).
- TEMP/TMP dùng khi kiểm thử: `D:\HealthMateMaintenanceQA\tmp`.
- VS Code: `D:\VS Code\Microsoft VS Code\bin\code.cmd`; đã mở đúng dự án và
  lib/main.dart ở cuối chat trước. Dừng debug cũ rồi F5 để áp dụng cờ compile-time.

Tiếp tục bằng việc xác nhận yêu cầu tiếp theo của người dùng; không tự chuyển
giai đoạn, push code hoặc triển khai Firebase.
