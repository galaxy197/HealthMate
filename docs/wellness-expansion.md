# Mở rộng HealthMate — nghiệm thu mã nguồn 26/10/2026

**Bản mới hơn:** đã hoàn thiện mục2–3–4, bổ sung calo bước/ngân sách xác nhận,
tiến độ cân nặng, thống kê và nhắc giờ ngủ. Dùng APK wellness-insights mới và
[báo cáo này](wellness-insights.md) thay cho bản APK ban đầu bên dưới.

**Cập nhật rollout:** người dùng đã yêu cầu làm mục1; Rules MVP đã triển khai và
đọc lại đúng hash ngày26/10, 61/61 ca kiểm thử lại qua. Chưa cài/thử điện thoại vì
người dùng chọn kết nối sau. Xem [wellness-rollout.md](wellness-rollout.md).

Người dùng yêu cầu trong cùng đợt: nhắc ghi bữa, dữ liệu món Việt/khẩu phần,
dưỡng chất mở rộng, lập thực đơn, đếm bước chân và đếm giờ ngủ. Yêu cầu này là
phạm vi mở rộng được chủ động cho phép, gồm các mục ngoài MVP cũ. Không tự
thêm dịch vụ trả phí. Giấc ngủ đã chốt: bấm ngủ/dậy, sửa giờ và có lịch sử.

Người dùng yêu cầu **sau khi hoàn tất công việc thì tự tắt laptop**. Thao tác
tắt máy thường sẽ được gửi sau khi lưu code, tài liệu, APK và kết quả kiểm thử;
không ép đóng ứng dụng và không tự bật lại công việc ở lần khởi động sau.

Đã thực hiện trong source:

- Android AlarmManager thông báo cục bộ, quyền thông báo khi opt-in; bỏ qua
  bữa đã ghi nhận trên máy, khôi phục lịch sau reboot/timezone; không exact alarm.
- Android step-counter sensor + foreground health service, opt-in và quyền
  Hoạt động thể chất/thông báo, không GPS/micro/camera để suy ra bước/ngủ.
- SQLite public cache v3 và asset offline 162 thực phẩm có nguồn/công thức
  tham khảo; bổ sung món hoàn chỉnh và khẩu phần tham khảo. Không tự cập nhật
  danh mục production hoặc thay snapshot nhật ký cũ.
- 8 dưỡng chất: đường, béo bão hòa, natri, kali, canxi, sắt, vitamin C,
  cholesterol. Lấy USDA/OFF/nhãn người dùng; thiếu dữ liệu không phải số0.
- Firestore riêng theo UID: sleep_logs, wellness_state/sleep, meal_plans,
  step_logs; Rules MVP đã kiểm thử, triển khai và đọc lại xác nhận trên production.

## Sử dụng

Sau khi cài APK mới: **Thêm → Thói quen & kế hoạch**. Năm tab là Nhắc bữa,
Thực đơn, Bước chân, Giấc ngủ, Dưỡng chất. Phần món Việt/khẩu phần tích hợp
trong tìm kiếm và hộp chọn khẩu phần hiện có.

- Nhắc bữa: chọn giờ riêng cho sáng/trưa/tối/phụ, bật theo nhu cầu, có nút
  thử thông báo. Không tự yêu cầu quyền trước khi bật. Nhấn thông báo mở Nhật ký;
  thông báo không chứa thông tin sức khỏe. Đổi/đăng xuất tài khoản dừng lịch cũ.
- Thực đơn: tạo/sửa/xóa từng bữa trong 7 ngày, xem trước gợi ý từ món Việt rồi
  xác nhận thêm. Chưa cá nhân hóa theo mục tiêu kcal, bệnh hay dị ứng. Kế hoạch
  tách biệt nhật ký; bấm đã ăn vẫn phải xác nhận món/khẩu phần/thời điểm. Mã ghi
  ổn định tránh nhân đôi khi thử lại. Xóa kế hoạch không xóa bữa đã ghi.
- Bước chân: opt-in cảm biến TYPE_STEP_COUNTER và foreground health service,
  thông báo đang theo dõi; không dùng GPS. Ghi phần bước đã quan sát sau khi bật,
  không truy hồi toàn bộ ngày. Có lịch sử và đồng bộ Firestore; nhiều thiết bị
  giữ giá trị ngày cao nhất, không cộng chồng. Có nút dừng và yêu cầu quyền rõ ràng.
- Giấc ngủ: bắt đầu/ngủ dậy, kiểm tra/sửa giờ trước khi lưu, thêm giờ thủ công,
  xem/sửa/xóa 60 lần gần nhất. Một lần tối đa 24 giờ. Không đo chất lượng/giai đoạn ngủ.
- Dưỡng chất: xem tổng phần dữ liệu đã biết theo ngày và tỷ lệ món có dữ liệu.
  Nhập bổ sung theo nhãn trong Thư viện món → Món của tôi → Dưỡng chất mở rộng.
  Giá trị được giữ qua món riêng, công thức, mẫu bữa, kế hoạch, bản nháp và nhật ký;
  không tự sửa các snapshot lịch sử đã lưu trước đây.

## Dữ liệu và quyền riêng tư

162 món offline: 101 mục tham chiếu VDD, 54 công thức giả định có nguyên liệu/
khối lượng/yield, 3 nhãn nhà sản xuất, 4 mục USDA Legacy. Bổ sung 7 món hoàn chỉnh;
không gắn công thức ước tính thành số đo chính xác của mọi quán. Giữ URL, mã/trang
nguồn trong asset. Khẩu phần tham khảo có thể sửa gram; không suy khối lượng từ tên bát/đĩa.

Không thêm dependency hoặc dịch vụ trả phí. SQLite public cache lên v3, giữ
aliases, khẩu phần và dưỡng chất; xóa riêng preload `vn_` cũ không có nguồn để
thay bằng asset có phiên bản. Không xóa nhật ký/món riêng Firestore hoặc bản nháp.
Không ghi danh mục mới vào production trong đợt này.

Lịch nhắc và mẫu bước cục bộ nằm trong AES-GCM/Android Keystore, tách namespace
theo UID, noBackupFilesDir; không ghi đè kho bản nháp hiện có. Giữ tối đa 31 ngày
bước cục bộ, hiển thị 30 ngày Firestore. Đổi tài khoản không trả về cache của UID
cũ; xóa tài khoản dọn cả bốn collection mới và các namespace native.

Chi tiết schema/vector dưỡng chất xem [database-design.md](database-design.md).
Server Rules vẫn là lớp bảo vệ chính; kiểm tra SDK ownership bổ sung để chặn
cache khi chuyển UID. Kiểm thử đã phát hiện và sửa một truy cập Ref đã dispose
trong luồng mealLogs/recentMeals và một lần chờ catalog autoDispose trong editor.

## Kết quả thật

| Kiểm tra cuối | Kết quả |
| --- | --- |
| Format các file thuộc thay đổi | Kiểm tra cuối exit0, không có file cần format lại |
| `git diff --check` | exit0; chỉ có thông báo LF/CRLF, không có lỗi whitespace |
| `flutter analyze --no-pub` | 0 issues, 25,7 giây |
| `flutter test --no-pub` | 597/597, 66 giây |
| `node --test tool/food_catalog.test.cjs` | 10/10 |
| `tool/test_emulators.ps1` | 70/70 Rules + 22/22 Firebase SDK, exit0 |
| Candidate MVP không admin | 61/61 Rules, exit0 |
| Android native acceptance | 1 kịch bản + teardown, exit0; thông báo/cache/ngủ/thực đơn/dưỡng chất/UID |
| Quét secret trong source | 424 file, 0 kết quả theo các mẫu kiểm tra; không phải kiểm toán APK |
| `flutter build apk --debug --no-pub` | Thành công; Gradle 14,7 giây |

APK: `build/releases/healthmate-wellness-debug.apk`, 236630807 bytes.
SHA256: `0B3A90A09D48F1ED6D76AC0926DB034656E953E0D609D3C4B9545616EDFCF84F`.
Bản này dùng entry point app thật, cấu hình chat hiện tại và debug App Check cục bộ;
không phải APK có entry point integration test. Chưa cài lên điện thoại.

Log cuối: `build/wellness-{analyze-final-2,flutter-final-3,sdk-final-3,candidate-tests,build-final}.log`;
native và 5 ảnh UI: `build/wellness-android/`. Những lượt lỗi trước đó là lịch sử
điều tra, không được tính là nghiệm thu thành công.

## Trạng thái triển khai và giới hạn cần thử thật

**Production Rules đã triển khai theo yêu cầu “làm mục1”.** Candidate đã dùng tại
`build/wellness-production-candidate/`, SHA256
`2bb6a4a230da4d516cb757c564944782924e875ff9cc1f3b7397951773d59f62`.
Đã loại toàn bộ nhánh quản trị đang tạm gác, không dùng nguyên Rules local để deploy.
Baseline production đã được đọc lại và khớp trước rollout; sau rollout đã đọc lại
server khớp hash trên. Không ghi/xóa dữ liệu người dùng, không push/commit, không
đổi quota/model/billing. Chưa kiểm thao tác app với Firebase thật trên điện thoại.

QA dùng AVD Android11/API30 dành riêng + Firebase Auth/Firestore Emulator demo,
không dùng tài khoản/dữ liệu production. AVD không có step counter: app báo không
hỗ trợ, chưa chứng minh độ chính xác bước chân trên phần cứng thật. Cần thử quyền
thông báo Android13+, quyền hoạt động, cảm biến, pin/OEM, đổi ngày/reboot trên máy thật.
Thông báo inexact có thể trễ do Android; force-stop cần mở lại app. Việc bỏ qua
bữa đã ghi chỉ dựa trên dữ liệu mà thiết bị đã nhận, không tự đọc cloud trong receiver.
Step service không tự khởi động lại sau force-stop/reboot; phải mở/bật lại. Mẫu đầu
sau reboot/đổi ngày làm baseline, không phân bổ bước trong khoảng không quan sát.

Build còn thông báo tương thích Built-in Kotlin của một số plugin; build debug
vẫn thành công. Release ký phát hành chưa cấu hình, không coi APK debug là bản phát hành.

Việc còn lại: cài và nghiệm thu trên điện thoại khi người dùng kết nối lại.
Yêu cầu tắt laptop chỉ thuộc đợt viết mã trước, không tự lặp lại trong lượt rollout.

## Tài liệu nguồn

- Android: [AlarmManager](https://developer.android.com/develop/background-work/services/alarms),
  [health foreground service](https://developer.android.com/develop/background-work/services/fgs/service-types),
  [step sensor](https://developer.android.com/health-and-fitness/fitness/basic-app/overview).
- [USDA API](https://fdc.nal.usda.gov/api-guide/),
  [Open Food Facts nutrient units](https://openfoodfacts.github.io/documentation/docs/Product-Opener/schemas/schemas/product_nutrition/).
- Nguồn thực phẩm và giả định recipe cụ thể giữ tại `data/food_catalog/` và asset.
