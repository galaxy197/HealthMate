# HealthMate — làm lại giao diện theo Figma

Ngày: 27/10/2026. Trạng thái: hoàn tất phần sửa UI được yêu cầu sau phản hồi “giao diện chưa giống Figma”. Đây là UI system/polish thuộc phạm vi Giai đoạn 1 trên ứng dụng đã có nghiệp vụ; không chuyển sang giai đoạn nghiệp vụ khác.

## Nguồn đối chiếu

- [File Figma của người dùng](https://www.figma.com/design/JkRhiyNlWBinz1yhOd7n5u/24dh113420_Figma?node-id=76-1561).
- Đã mở trực tiếp Page 3 của file, chọn [frame T01](https://www.figma.com/design/JkRhiyNlWBinz1yhOd7n5u/24dh113420_Figma?node-id=158-8452) và đối chiếu với UI Kit v2 local.
- Bộ `Downloads/HealthMate-Figma-UI-Kit-v2/HealthMate-UI-v2`: previews T01/J01/W01/P01/R01, tokens và `figma-plugin/design.json`. Đọc kích thước, vị trí, cỡ chữ và path gốc thay vì chỉ suy đoán từ ảnh tổng quan.
- Handoff, AGENTS.md và tài liệu trong repository được dùng làm bối cảnh. Chỉ dẫn lịch sử trong tài liệu không trở thành yêu cầu triển khai mới.

## Đã làm lại

| Màn | Kết quả |
|---|---|
| Hôm nay | Đúng ngọn lửa xanh từ file thiết kế; bỏ tiêu đề thừa; sắp lại kcal, thanh tiến độ, phần còn lại và footer macro; vòng gồm 64 nét hướng tâm theo path Figma; Carb/Đạm/Chất béo; năm lối tắt theo đúng thứ tự khi scanner bật |
| Nhật ký | Lề 20, bộ chọn ngày ba phần, tổng kcal nổi bật với caption nhỏ, thanh tỷ lệ macro, lưới bốn bữa khoảng 170px và nút xác nhận trước phần CRUD; chi tiết gram/mục tiêu vẫn mở được qua nút ba chấm |
| Thói quen | Ngày nằm dưới tiêu đề, lưới chỉ số khoảng 195px, lối tắt năm mục; bước chân/ngủ vẽ từ bản ghi đã có; nước và vận động trống được giải thích rõ |
| Cá nhân | Tách tiêu đề khỏi hàng danh tính; avatar 57px, nút Sửa; mục tiêu và tiến độ cân nặng khi đủ dữ liệu; “Nhìn lại hôm nay”, thanh macro/đủ bữa và lưới chỉ số có biểu đồ nhỏ |
| Tiến độ | Bộ chọn kỳ trên cùng; số trung bình, tab và tuần nằm trong thẻ biểu đồ; giảm chiều cao vùng vẽ theo mẫu; đưa hai thẻ tổng kết ngay sau biểu đồ; điều khiển tuần vẫn có khi loading/error |
| Dùng chung | Chữ thường, độ đậm và khoảng cách gần mẫu hơn; thanh dưới tràn ngang, không còn khoảng thụt; chiều cao tự tính theo nhãn khi tăng cỡ chữ; theme tối tương ứng |

Các nút mở luồng thật sẵn có. Avatar tại Hôm nay/Nhật ký/Thói quen mở Cá nhân. Header Tiến độ theo thiết kế chỉ có tiêu đề và xuất; từ đây có thể về Hôm nay rồi mở avatar. Các test điều hướng đã được đổi theo đường đi thực tế, vẫn kiểm tra route và việc không khởi tạo AI khi chỉ duyệt tab.

Không sao chép số liệu Figma vào ứng dụng thật. Các ảnh populated dùng repository giả chỉ trong `test/reference_ui_test.dart`, có nhãn dữ liệu kiểm thử. Nhật ký vẫn giữ ngày lịch sử; dấu + shell vẫn dùng hôm nay. Lưu bữa/quét món vẫn cần xác nhận. Các kiểm thử về validation, đổi UID, giữ bản nháp, lỗi, phản hồi đến muộn và tính tổng vẫn được giữ.

Biểu đồ không tự thêm điểm để trang trí. Ngày thiếu giữ khoảng trống. Sparkline nước tại Hồ sơ là tổng lũy kế những lần uống trong ngày; cân nặng dùng các lần cân theo thứ tự thời gian. Thanh mục tiêu cân nặng so lần cân mới nhất với lần cân đầu tiên và cân nặng đích, chỉ tính khi có ít nhất hai lần cân; không gán phần trăm cho mục tiêu không áp dụng.

## File chính đã tạo/sửa

- `lib/core/theme/{app_theme,design_tokens,reference_palette}.dart`.
- `lib/core/widgets/{app_shell,app_card,feature_page,tracking_page,profile_avatar,reference_shortcuts,reference_segments,recorded_sparkline,design_illustration}.dart`.
- `lib/features/dashboard/presentation/dashboard_screen.dart`, `widgets/mfp_{calories,macros}_card.dart`.
- `lib/features/journal/presentation/{journal_screen,journal_date_selector,journal_nutrition_overview,meal_summary_grid}.dart`.
- `lib/features/nutrition/presentation/macro_distribution.dart`.
- `lib/features/profile/presentation/{profile_screen,personal_overview}.dart`.
- `lib/features/wellness/presentation/{wellness_screen,wellness_hub}.dart`.
- `lib/features/progress/presentation/{progress_screen,progress_overview}.dart`.
- `assets/design/` gồm 12 PNG nhỏ, tổng 65.366 byte; `tool/import_reference_art.cjs`, `tool/compare_reference_ui.cjs`.
- `test/reference_ui_test.dart` cùng các test/helper bị ảnh hưởng bởi nhãn, vị trí nút và phần chi tiết; docs và ảnh dưới đây.

## Kiểm tra bản cuối

| Lệnh/kiểm tra | Kết quả thật | Log |
|---|---|---|
| `dart format --output=none --set-exit-if-changed` trên 50 file Dart tạo/sửa | Exit 0, 0 file thay đổi | `build/figma-v2/redo-format-accepted.log` |
| `flutter analyze --no-pub` | Exit 0, No issues found, 36,3s | `build/figma-v2/redo-analyze-accepted.log` |
| `flutter test --no-pub --reporter expanded` | Exit 0, **655/655 qua**, 78s | `build/figma-v2/redo-all-tests-accepted.log` |
| `flutter build apk --debug --no-pub` với runtime/config hiện có | Exit 0, thành công, Gradle 23,1s | `build/figma-v2/redo-android-build-accepted.log` |
| `node --check` cho hai script ảnh | Exit 0 | Terminal |
| `git diff --check` | Qua | Terminal |
| `adb devices` | Không có thiết bị kết nối | Terminal |

Có 9 test reference, gồm một lượt dựng năm màn với fixture và native safe areas tại 390×844; kiểm tra điều hướng/empty states ở 320/390/412px, cỡ chữ 100–200%, hai theme; dữ liệu bước/ngủ và ngày lịch sử. Kiểm thử cũ tiếp tục kiểm tra các luồng nghiệp vụ.

Đã xem ảnh Flutter thật do widget test render với font/icon đã nạp, và ảnh so cạnh Figma ở cùng chiều rộng. Cắt phần status/navigation bar của hệ điều hành khi so để tránh giả UI hệ thống trong ứng dụng. Đây là kiểm tra UI bằng fixture, không chứng minh Firebase/camera/AI end-to-end.

## Ảnh và APK

- [Ảnh tổng quan Flutter](ux/reference-v2/flutter-overview.png).
- [Bảng đối chiếu cả năm màn](ux/reference-v2/comparison-board.png).
- Ảnh chi tiết: [Hôm nay](ux/reference-v2/comparison-today.png), [Nhật ký](ux/reference-v2/comparison-journal.png), [Thói quen](ux/reference-v2/comparison-habits.png), [Cá nhân](ux/reference-v2/comparison-profile.png), [Tiến độ](ux/reference-v2/comparison-reports.png).
- [Thư mục ảnh](ux/reference-v2/) có thêm 10 empty-state sáng/tối và 5 populated captures.
- **APK mới:** `build/releases/healthmate-figma-redo-debug.apk` (236.834.416 byte).
- SHA-256: `D5457B7E361900FFC95CCF281CE1B0A75844BC10D0AE966A6AB7FE914D91E96C`.
- APK này thay bản `healthmate-figma-v2-debug.apk` từ lượt UI trước.

## Giới hạn và bước tiếp theo

Giữ BeVietnamPro đã có để hỗ trợ tiếng Việt; không phân phối Arial từ Windows. Font, icon điều hướng dùng Material, màu chữ/nút đậm hơn để đọc rõ và dữ liệu thật có thể khác ảnh Figma. Không tuyên bố giống từng pixel. Không đặt chuông hoặc biểu đồ dữ liệu giả để lấp chỗ trống; giữ nút cài mục tiêu/thông tin cần thiết và navigation tới các tính năng đang có.

Không đổi schema, Rules, backend, dependencies, provider AI hoặc billing. Scanner và chatbot giữ cấu hình đang có. Không deploy, commit hoặc push. Giữ nguyên handoff chưa track của người dùng. Không cần cấu hình Firebase mới chỉ cho lượt sửa UI này.

Build còn cảnh báo KGP từ các plugin Firebase/mobile_scanner đối với Flutter tương lai; build hiện tại thành công. Chưa cài APK hoặc thử camera/cảm biến/Firebase/AI trên Android thật vì không có thiết bị. Cần người dùng cài APK mới và nghiệm thu giao diện/luồng trên máy thật. Giai đoạn kế tiếp đề xuất: nghiệm thu UI trên Android; chưa tự triển khai giai đoạn nghiệp vụ khác.
