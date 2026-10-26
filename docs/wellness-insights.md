# Mục 2–3–4 — Năng lượng bước chân, tiến độ cân nặng và giấc ngủ

Người dùng yêu cầu làm cả mục2,3,4 trong một đợt mở rộng ngày26/10/2026.
Không quay lại web admin, không thêm package/backend trả phí, không thay đổi
nhật ký cũ hoặc tự đặt mức ăn cá nhân. Người dùng đã chọn kết nối điện thoại sau;
không lặp lại yêu cầu shutdown của đợt trước.

## Người dùng làm được gì

Mở **Thêm → Thói quen & kế hoạch**. Giữ các tab cũ và thêm tab **Tiến độ**.
Từ tab Tiến độ chính của app cũng có nút mở màn hình cân nặng/ngân sách.

### Bước chân và ngân sách ăn

- Tab Bước chân hiển thị khoảng cách và calo đi bộ **ước tính**, khi đã có số
  bước, cân nặng gần nhất trong90ngày và độ dài một bước người dùng tự đo.
  Không lấy chiều cao/giới tính để tự đoán độ dài bước. Thiếu dữ liệu không điền0.
- Vào Thiết lập độ dài bước: nhập cm của **một bước**, không phải sải hai bước.
  Khi chưa biết mức bước đã tính trong mục tiêu gốc, để trống; vẫn có thể xem
  ước tính vận động nhưng không cộng vào ngân sách.
- Mặc định chưa có điều chỉnh. Người dùng tự nhập mức bước đã tính sẵn trong mục
  tiêu, xem phần vượt mức và xác nhận số kcal muốn cộng **chỉ cho hôm nay**.
  Checkbox xác nhận không được chọn sẵn. Không tự áp dụng ngày sau; có nút bỏ.
- Bản ghi theo dateKey ổn định, cập nhật/thử lại không cộng dồn nhiều lần. Mục
  tiêu gốc, macro và kcal món ăn không bị sửa. Nếu đổi phiên bản/giá trị mục tiêu
  gốc thì điều chỉnh cũ ngừng áp dụng cho tới khi xác nhận lại.
- Nếu ngày đó có bất kỳ vận động nhập tay nào, app tạm không cộng bước để tránh
  trùng. Đây là chính sách thận trọng vì chưa có phân đoạn cảm biến theo bài tập;
  không phải thuật toán tổng tiêu hao của MyFitnessPal. Không tự cộng cả kcal của
  bài tập nhập tay vào ngân sách mới.
- Tổng quan, Nhật ký, thẻ ngân sách và câu trả lời chatbot “còn bao nhiêu kcal”
  dùng cùng phép đối chiếu. Lỗi tải điều chỉnh/vận động không bị coi là0 để đưa
  ra một ngân sách chưa xác nhận. Báo cáo tuần/tháng cũ ghi rõ so với mục tiêu gốc.

Mô hình tham khảo: phần ngang trên mức nghỉ của phương trình đi bộ ACSM trên
đường bằng; suy ra xấp xỉ `0,5 × cân nặng(kg) × khoảng cách(km)` với quy đổi oxy
khoảng5kcal/L. Đây là phép suy ra dùng trong app, không phải phép đo hoặc mô hình
được hiệu chuẩn trên điện thoại này. Không biết tốc độ/độ dốc, không áp dụng như
phép đo chạy bộ/leo dốc và không cộng lại chuyển hóa nghỉ.
[Nghiên cứu trình bày phương trình và giới hạn](https://pmc.ncbi.nlm.nih.gov/articles/PMC7896743/).

Giới hạn nhập liệu: bước0..150000, độ dài bước20..200cm, cân nặng dùng cho mô hình
20..300kg, phần cộng>0..5000kcal và không vượt ước tính phần bước ngoài baseline.
Đó là giới hạn dữ liệu kỹ thuật, không phải khuyến nghị vận động hoặc khẩu phần.

### Tiến độ cân nặng

- Xem ngân sách hôm nay, bữa đã ghi, cân nặng mục tiêu trong hồ sơ, lần cân gần
  nhất và thay đổi trong cửa sổ7/30/90ngày. Có nút về Hồ sơ để cập nhật.
- Dùng biểu đồ cân nặng hiện có, tối đa12lần gần nhất trong khoảng; trung bình
  theo tuần tính trung bình từng ngày trước để các ngày cân nhiều lần không có
  trọng số lớn hơn. Không tạo dữ liệu cho tuần/ngày thiếu.
- Hiển thị số ngày có bữa và tổng bước đã đồng bộ trong khoảng. Lịch sử bước
  hiện tải tối đa30 ngày có dữ liệu; không coi đó là đủ toàn bộ90ngày.
- Không quy đổi thay đổi cân thành kg mỡ, không suy thâm hụt thực tế từ nhật ký
  chưa đầy đủ và không tự tăng mức cắt giảm ăn khi cân không đổi.

### Thống kê và nhắc giờ ngủ

- Biểu đồ7/30ngày có khoảng ngày rõ ràng, trung bình thời lượng ngày có ghi,
  mục tiêu giờ ngủ tự đặt và số ngày đạt trong các ngày có dữ liệu.
- Gộp các khoảng ghi chồng lắp trước khi tính, xếp theo ngày thức dậy. Giấc ngắn
  cộng thời lượng; giờ bắt đầu giấc chính dùng tính độ lệch giờ đi ngủ trung bình
  theo vòng24giờ, nên23:50 và00:10 không bị tính lệch gần24giờ.
- Ngày thiếu không phải0giờ; tổng khoảng ghi trong một ngày thức dậy vượt24giờ
  bị đánh dấu cần sửa, chưa dùng vào trung bình/mục tiêu. Không chấm điểm sức khỏe.
- Nhắc giờ ngủ Android là thông báo local, opt-in và có nút thử, lưu mã hóa theo
  UID. Khôi phục lịch sau boot/đổi giờ/múi giờ, dừng khi đổi/đăng xuất tài khoản.
  Nhấn thông báo mở tab Giấc ngủ đúng tài khoản; thông báo không chứa số liệu riêng.
- Dùng AlarmManager inexact, không quyền exact-alarm, không Cloud Functions/push.
  Có thể trễ do Android/Doze/OEM; force-stop phải mở lại app. Đây không phải báo thức.
  [Hướng dẫn Android về alarm](https://developer.android.com/develop/background-work/services/alarms).
- Không suy giai đoạn/chất lượng giấc ngủ và không tự cộng/trừ calo từ giờ ngủ.

## Dữ liệu và triển khai

Hai collection mới dưới `users/{uid}`:

- `wellness_preferences/main`: stepLengthCm, baselineSteps, sleepGoalMinutes
  nullable; updatedAt server, schemaVersion1.
- `energy_adjustments/{dateKey}`: dateKey/offset, steps/baselineSteps/stepLengthCm,
  weightKg/weightMeasuredAt, targetFromDateKey/baseKcalTarget, kcal, confirmedAt
  server, source walking_net_v1, schemaVersion1. Snapshot được xác nhận theo ngày.

Rules yêu cầu chủ tài khoản đã xác minh email, đúng ngày hiện tại theo offset khi
ghi điều chỉnh, cân gần đây, mục tiêu tham chiếu tồn tại/khớp giá trị và kcal trong
phần ước tính cho phép. Xóa tài khoản dọn cả hai collection. SDK kiểm chủ UID trước
và sau đọc để không trả cache của tài khoản cũ. Prompt chatbot chỉ thêm tổng kcal
đã xác nhận; không thêm dữ liệu độ dài bước/cân nặng vào câu trả lời năng lượng.

Lịch nhắc ngủ nằm trong namespace mã hóa native `sleepReminder`, tách khỏi nhắc
bữa, bước chân và bản nháp. Không lưu trong public SQLite hoặc thêm ảnh/nghe micro.

Đã deploy **chỉ firestore:rules**, đọc lại server đúng SHA256:
`6a1762dd899ebdac732a9d55e4c4444a27e06a584c1fad982e36088f7108c374`.
Ruleset: `e0057d3e-f72e-405c-b50c-cd5063e25c6c`.
Release26/10/2026 lúc **16:55:44 Asia/Saigon**. Đối chiếu candidate sau khi bỏ hai
block mới khớp nguyên bản production trước đó; không rollout admin hoặc sửa quyền
nghiệp vụ cũ. Không đọc/ghi fixture hoặc dữ liệu người dùng trong production.

Backup trước: `build/wellness-insights-before-20261026/` và bản đọc sát deploy
`build/wellness-insights-predeploy-20261026/`. Sau: `build/wellness-insights-after-20261026/`.
Candidate riêng: `build/wellness-insights-production-candidate/`; không ghi đè
candidate của rollout mục1. Không đổi quota, model AI, billing, indexes hoặc Hosting.

## Kiểm thử và APK

| Kiểm tra | Kết quả thật |
| --- | --- |
| Full Flutter cuối | 608/608,82giây, exit0 |
| Analyzer cuối | 0 issues,49,2giây |
| Format cuối trong scope | 34file,0thay đổi cần format, exit0 |
| `git diff --check` | exit0 |
| Quét mẫu secret trong source | 438file,0patternfindings; không phải audit APK |
| Rules local + SDK emulator | 73/73 Rules và23/23 Firebase SDK thật, exit0 |
| Candidate không admin | 64/64,24,9giây, exit0 |
| Android acceptance cuối | 1kịch bản+teardown,51giây trong test, exit0 |
| Build APK debug cuối | Thành công, assembleDebug24giây |

Native kiểm thông báo7300 thật, lịch nhắc riêng không làm mất nhắc bữa, UI lưu
thiết lập, biểu đồ ngủ30ngày, xác nhận50kcal từ fixture6000bước → ngân sách1850,
trang tiến độ và cách ly UID/cache/thông báo. Đã xem ba ảnh UI chính. AVD không có
step counter, app báo không hỗ trợ. Dữ liệu6000bước chỉ là fixture kiểm giao diện/
công thức, không phải kết quả đo cảm biến. Chưa cài hoặc nghiệm thu trên điện thoại.

Các lượt lỗi giữ log: lần đầu sửa cú pháp/trình bày test và kiểu nullable, Rules
phải dùng mẫu số100000.0 để không chia nguyên khi payload dùng int; một fixture
cân nặng đổi thành lần đo trước1giờ để không kiểm sự đồng bộ đồng hồ AVD/server.
Không nới Rules cho timestamp tương lai hoặc bỏ assertion kiểm dữ liệu sai.

Log: `build/wellness-234-{full-final,sdk-3,candidate,analyze-last,build-final,deploy}.log`.
Native và ảnh: `build/wellness-insights-android/`. Analyzer/format/diff/source audit
cuối được lưu cạnh các log; không tính các lượt thất bại trước là nghiệm thu.

APK bàn giao: `build/releases/healthmate-wellness-insights-debug.apk`, entry point
app thật với cấu hình chat/debug App Check cục bộ; không phải integration APK.
Giữ riêng APK cũ. Đây vẫn là bản debug, chưa cấu hình khóa release.
Kích thước236693862bytes, SHA256:
`231C2BF1E4529185B3273AF38F3C6D1D2F67866FEE4B4DB93715F66E2B3429CD`.
Metadata cạnh APK trong file `.json`. Sau các lượt kiểm tra chỉ format whitespace
ở file cleanup tài khoản trong scope; không thay đổi logic hoặc dữ liệu.

Việc còn lại: người dùng kết nối điện thoại khi thuận tiện để cài đè `adb install -r`
giữ dữ liệu, thử cảm biến/quyền Android, đồng bộ dữ liệu, thông báo/ngủ và luồng
điều chỉnh trên tài khoản thật. Không tự mở thêm tính năng hoặc tự tắt máy lần nữa.
