# Gói 9 — Tách trách nhiệm MealFormDialog

## Phạm vi

Refactor nội bộ luồng ghi bữa hiện có; không đổi schema Firestore, đường dẫn UID, operation ID, quy tắc dinh dưỡng hoặc thêm dependency. Không triển khai tính năng/giai đoạn MVP mới.

- `meal_form_controller.dart`: sở hữu dữ liệu nháp, snapshot bất biến, validation, trạng thái lưu nháp theo revision và chờ ACK submit. Persistence vẫn do callback/repository hiện có thực hiện.
- `meal_search_controller.dart`: sở hữu debounce, request tìm kiếm/detail, generation chống kết quả cũ, guard UID/source, retry và phân trang hiển thị.
- `meal_entry_sources.dart`: render danh mục từ state và tách giao diện nguồn yêu thích. Camera/AI vẫn dùng `FoodScannerDialog`; nguồn thư viện vẫn dùng `MealFoodSources` hiện có.
- `meal_form_dialog.dart`: kết nối controller vào vòng đời widget, các nguồn nhập, xác nhận thực phẩm cần tránh và `ConfirmedSave`.

## Các hành vi được giữ

- Snapshot giữ timezone đã lưu, schema tối thiểu, nguồn và dinh dưỡng lịch sử; không tự sửa dữ liệu món hỏng.
- AI chỉ đổi nguồn khi đã có lựa chọn scanner; bản nháp vẫn chờ người dùng bấm Lưu.
- Không timeout ACK hoặc gửi write thứ hai khi write đầu còn pending. ACK thất bại giữ nháp để thử lại; operation ID do repository/caller quản lý.
- Khi đổi query/filter, chuyển nguồn, ẩn form hoặc dispose, request liên quan bị hủy. Generation và UID loại progress/result cũ kể cả provider không phản hồi cancellation ngay.
- UID của form được chụp từ phiên đã resolve đầu tiên (có thể sau `initState` nếu stream Auth còn loading). Controller không ghi nháp/submit mới cho phiên khác; ACK cũ không báo thành công. `AccountBoundDialog` hiện có chịu trách nhiệm đóng route khi đổi tài khoản.
- Retry/direct call cũng kiểm tra source còn hoạt động; debounce kiểm tra lại trước khi bắt đầu gọi dịch vụ. Bộ lọc áp dụng cho cả kết quả local và remote.

## Kiểm tra

Đã chạy `dart format` trên bốn file source và hai file test của refactor: thành công.

Các test controller độc lập dùng fake/completer, không cần Firebase: draft revision ACK ngược thứ tự, UID/dispose, submit single flight/retry, validation, query cancellation, progress cũ, debounce, detail retry/filter/cache warning và paging.

Agent phụ không đồng bộ workspace QA. Khi full QA phát hiện regression, đã sửa initial Auth loading bị hiểu nhầm thành đổi UID và đưa catalog rows về direct ListView children để giữ lazy layout/paging. Lượt focused cuối tại source workspace: `core_journal_test.dart`, `food_catalog_test.dart`, `unified_meal_entry_test.dart`, `mfp_search_test.dart`, `meal_form_controller_test.dart`, `meal_search_controller_test.dart`: **67/67 pass** (bao gồm lưu bản sao, giới hạn 5/6 món và duyệt catalog ở text scale 1/1.5). Agent chính chạy và ghi kết quả QA cuối vào báo cáo chung:

```powershell
flutter analyze
flutter test test/meal_form_controller_test.dart test/meal_search_controller_test.dart test/unified_meal_entry_test.dart test/mfp_search_test.dart test/food_search_lifecycle_test.dart
```

Không build APK, deploy, commit hoặc push trong gói này. Test controller không thay thế kiểm thử camera, Android, mạng thực hoặc Firebase Security Rules. Callback lưu nháp vẫn phải tuần tự hóa storage theo hợp đồng repository hiện có; revision trong controller chỉ bảo vệ trạng thái hiển thị khỏi ACK cũ.

Lượt bổ sung personalization: harness `nutrition_personalization_test.dart` cung cấp session Auth giả lập rõ ràng thay vì khởi tạo FirebaseAuth thật khi Firebase chưa initialize. Toàn bộ assertion xác nhận thực phẩm cần tránh được giữ nguyên; thêm test Auth lỗi chưa resolve không gọi callback persistence. Không nới production guard. Chạy lại bảy file focused (sáu file trên cùng personalization): **77/77 pass**; log `D:\HealthMateMaintenanceQA\package9-personalization-focused.log`.
