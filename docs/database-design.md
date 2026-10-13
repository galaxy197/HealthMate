# Thiết kế dữ liệu HealthMate

## Giai đoạn 3 — Hồ sơ và Body Metrics

Cloud Firestore mặc định của project `healthmate-app-20261013` đặt tại
`asia-southeast1` (Singapore). Dữ liệu riêng tư được đặt dưới UID của Firebase
Authentication; client không được chọn UID khác để đọc hoặc ghi.

```text
users/{uid}
  displayName: string            # 0–50 ký tự; rỗng khi vừa bootstrap
  email: string                  # đồng bộ từ token Auth, không sửa tự do
  heightCm: number | null        # 80–250 nếu có
  birthDate: timestamp | null    # bắt buộc khi hoàn tất onboarding
  healthGoal: string | null      # một trong bốn mục tiêu được hỗ trợ
  targetWeightKg: number | null  # chỉ bắt buộc với giảm/tăng cân
  onboardingCompletedAt: timestamp | null
  createdAt: timestamp           # server timestamp, bất biến
  updatedAt: timestamp           # server timestamp
  schemaVersion: integer         # hiện là 2

users/{uid}/body_metrics/{metricId}
  weightKg: number               # 20–500
  measuredAt: timestamp          # không ở tương lai
  note: string                   # tối đa 200 ký tự, có thể rỗng
  createdAt: timestamp           # server timestamp, bất biến
  updatedAt: timestamp           # server timestamp
```

Các lần đo thông thường dùng `metricId` do Firestore tự sinh nên không ghi đè
lịch sử. Riêng lần đo trong transaction onboarding dùng ID ổn định được mô tả
bên dưới. Danh sách được sắp xếp giảm dần theo `measuredAt`; truy vấn này chỉ cần
single-field index mặc định.

## Đợt 6.3 — Onboarding và mục tiêu sức khỏe

`healthGoal` nhận một trong các giá trị `lose_weight`, `maintain_weight`,
`gain_weight_or_muscle`, `healthier_habits`. `targetWeightKg` chỉ được yêu cầu
cho mục tiêu giảm cân hoặc tăng cân/tăng cơ; ứng dụng không thu thập giới tính,
mức vận động hoặc dữ liệu khác khi chưa có nghiệp vụ sử dụng chúng.

Hồ sơ chỉ được coi là hoàn tất khi `onboardingCompletedAt` có giá trị và các
field bắt buộc hợp lệ. Hồ sơ schema 1 hoặc hồ sơ mới thiếu dữ liệu được bổ sung
các field nullable qua `ensureProfile`, sau đó được điều hướng tới onboarding.
Thời điểm hoàn tất được giữ bất biến sau lần ghi đầu tiên.

Transaction hoàn tất onboarding cập nhật hồ sơ và ghi cân nặng hiện tại vào
`users/{uid}/body_metrics/onboarding-current`. ID ổn định giúp retry không tạo
nhiều lần đo trùng. Sau onboarding, người dùng tiếp tục cập nhật cân nặng qua
lịch sử Body Metrics, còn ngày sinh, chiều cao và mục tiêu được sửa tại hồ sơ.

Rules kiểm tra danh sách mục tiêu, khoảng chiều cao/cân nặng, ngày sinh không ở
tương lai, dữ liệu bắt buộc khi hoàn tất và quyền sở hữu UID. Giới hạn tuổi
13–120 được kiểm tra ở ứng dụng; Rules hiện chỉ chặn ngày sinh ở tương lai vì
việc tính tuổi chính xác theo ngày không phù hợp để lặp lại trong Rules.

## Giai đoạn 4–5 — Food Catalog và Meal Logs

```text
food_catalog/{foodId}
  name: string
  alternateNames: list<string>
  category: string
  servingBasis: "per_100g"
  unit: "g"
  kcalPer100g, proteinGPer100g, carbsGPer100g, fatGPer100g: number
  sourceLabel: string
  sourceUrl: string
  isEstimated: boolean
  updatedAt: timestamp

users/{uid}/meal_logs/{mealId}
  mealType: breakfast | lunch | dinner | snack
  consumedAt: timestamp
  dateKey: string                # yyyy-MM-dd theo lịch địa phương khi ghi
  timezoneOffsetMinutes: integer # -720 đến +840
  items: list<map>               # 1–5 snapshot món đã xác nhận
  totalKcal, totalProteinG, totalCarbsG, totalFatG: number
  source: manual | ai_assisted
  createdAt: timestamp           # bất biến
  updatedAt: timestamp
  schemaVersion: 2
```

Mỗi item lưu `foodId`, tên, gram, macro đã tính, nhãn nguồn và cờ ước tính. Nhờ
snapshot, nhật ký cũ không đổi khi catalog được cập nhật. Công thức cho mọi giá
trị là `giá trị trên 100 g × gram / 100`; Gemini chỉ gợi ý tên/mô tả và không
được ghi số dinh dưỡng. Ảnh nguồn không được lưu trong Firestore hoặc Storage.

Meal schema 2 dùng cùng quy ước `dateKey` và `timezoneOffsetMinutes` với nước và
vận động. Truy vấn chính lọc equality theo `dateKey`, rồi client sắp xếp giảm dần
theo `consumedAt`; single-field index mặc định đủ dùng nên không thêm composite
index. `dateKey` được tính lại từ `consumedAt` và offset mỗi khi thêm hoặc sửa.

Bữa schema 1 đã có trước Đợt 6B chưa chứa hai field mới. Trong giai đoạn chuyển
tiếp, repository mở thêm một truy vấn giới hạn theo khoảng nửa mở
`[đầu ngày địa phương, đầu ngày kế tiếp)` và chỉ nhận document thiếu `dateKey`.
Kết quả được gộp theo document ID để không lặp bữa schema 2. Khi người dùng sửa
một bữa cũ, document được nâng lên schema 2. Cách tương thích này không ghi hàng
loạt và không cần migration production trong Đợt 6B, nhưng tạm thời tạo thêm một
listener cho ngày đang xem.

Kế hoạch kết thúc chuyển tiếp: sau khi thống kê cho thấy còn nhiều bữa schema 1,
chuẩn bị script quản trị riêng để backfill `dateKey` và offset từ `consumedAt`
theo múi giờ đã thống nhất với người dùng, chạy thử trên emulator/export trước,
xin xác nhận người dùng rồi mới chạy production. Chỉ sau khi xác minh không còn
bữa thiếu field mới được bỏ truy vấn tương thích. Đợt 6B chưa chạy migration này.

Catalog hiện có 10 seed tham khảo từ USDA FoodData Central. Tất cả được gắn
`isEstimated: true` vì giống thực phẩm và cách chế biến thực tế có thể khác.

## Giai đoạn 6 — Water và Activity Logs

```text
users/{uid}/water_logs/{logId}
  amountMl: integer              # 50–5.000 ml mỗi lần ghi
  consumedAt: timestamp
  dateKey: string                # yyyy-MM-dd theo lịch địa phương khi ghi
  timezoneOffsetMinutes: integer # -720 đến +840
  createdAt: timestamp           # server timestamp, bất biến
  updatedAt: timestamp

users/{uid}/activity_logs/{activityId}
  activityType: walking | running | cycling | strength | yoga | other
  durationMinutes: integer       # 1–1.440
  performedAt: timestamp
  dateKey: string                # yyyy-MM-dd theo lịch địa phương khi ghi
  timezoneOffsetMinutes: integer # -720 đến +840
  note: string                   # tối đa 200 ký tự, có thể rỗng
  createdAt: timestamp           # server timestamp, bất biến
  updatedAt: timestamp
```

`dateKey` phục vụ tổng hợp theo ngày người dùng đã chọn; offset được lưu để giữ
ngữ cảnh múi giờ của lần nhập. Khi sửa thời điểm, cả hai giá trị được tính lại.
Mỗi collection có composite index cho `dateKey` và timestamp giảm dần.

Client tạo `dateKey` từ timestamp UTC cộng `timezoneOffsetMinutes`, kiểm tra ngày
lịch thực sự tồn tại và có test cho ranh giới nửa đêm. Repository không nhận
`dateKey` rời từ form; khi thêm hoặc sửa, nó luôn lấy lại `dateKey` và offset từ
draft chứa timestamp nên các field phụ thuộc được cập nhật cùng nhau.

Security Rules kiểm tra định dạng năm-tháng-ngày, khoảng tháng 01–12, ngày 01–31
và offset -720 đến +840. Với schema hiện tại, Rules không thể chuyển chuỗi
`yyyy-MM-dd` thành các thành phần số để đối chiếu chính xác với timestamp đã cộng
offset. Vì vậy Rules chưa thể loại riêng các ngày như `2026-02-30`, hoặc ngăn một
client tùy biến gửi cặp timestamp/dateKey hợp lệ về hình thức nhưng không khớp.
Để kiểm tra tuyệt đối ở server cần đổi schema sang các thành phần ngày dạng số
hoặc dùng backend tin cậy; Đợt 6.1 không thực hiện thay đổi không tương thích đó.

## Quyền truy cập

- Chỉ người dùng đã đăng nhập có UID trùng với `{uid}` mới đọc hoặc ghi hồ sơ và
  `body_metrics` của mình.
- Chủ tài khoản được xóa hồ sơ và dữ liệu con trong luồng xóa tài khoản. Client
  phải xác thực lại, xóa các subcollection theo lô, xóa `users/{uid}` cuối cùng
  rồi mới xóa Firebase Auth. UID khác không thể đọc hoặc xóa dữ liệu này.
- Chỉ các field trong schema được chấp nhận; `createdAt` không thể thay đổi.
- Email phải khớp claim email trong Firebase Auth token.
- Giá trị số, chuỗi và timestamp được kiểm tra lại tại Security Rules, không chỉ
  dựa vào validation của giao diện.
- Mọi collection và đường dẫn chưa được khai báo đều bị từ chối mặc định.
- Người dùng đã đăng nhập được đọc `food_catalog`; mọi client write vào catalog
  bị chặn. Seed/catalog maintenance dùng quyền quản trị project.
- Meal log chỉ chủ sở hữu UID được CRUD. Rules giới hạn field, kiểu, khoảng tổng,
  nguồn, timestamp, `dateKey`, offset và 1–5 item; mọi vị trí item 0–4 đang tồn
  tại đều được kiểm tra đầy đủ schema và khoảng giá trị. Document schema 1 hiện
  hữu vẫn đọc/xóa được và có thể được nâng cấp bằng một lần sửa hợp lệ.
- Water/activity log chỉ chủ UID được CRUD. Rules giới hạn schema, đơn vị, khoảng
  giá trị, định dạng `dateKey`, offset múi giờ và giữ `createdAt` bất biến.

Các tổng `totalKcal`, `totalProteinG`, `totalCarbsG`, `totalFatG` tiếp tục được
tính từ snapshot item ở client và kiểm thử bằng unit test. Rules kiểm tra kiểu và
khoảng tổng nhưng chưa cộng lại toàn bộ item: biểu thức cho 5 item đã ở gần giới
hạn 1.000 biểu thức của một lần đánh giá Rules, còn so sánh số thực cần sai số
làm tròn nên không thể bảo đảm đối chiếu tuyệt đối. Một client tùy biến vẫn có
thể gửi tổng nằm trong khoảng nhưng không khớp chi tiết; đây là rủi ro còn lại.

Rules nguồn nằm tại `firestore.rules`; cấu hình emulator và deploy nằm trong
`firebase.json`.

## Giai đoạn 6A — Xóa tài khoản và dữ liệu

Ứng dụng xóa lần lượt `body_metrics`, `meal_logs`, `water_logs`,
`activity_logs`, `goals`, `daily_quests`, các `messages` bên trong
`chat_sessions`, rồi các session và document `users/{uid}`. Các lần xóa dùng lô
tối đa 400 document và có thể chạy lại an toàn nếu mạng lỗi giữa chừng. Chỉ khi
toàn bộ dữ liệu Firestore đã xóa xong, ứng dụng mới yêu cầu Firebase Auth xóa
người dùng hiện tại.

Firestore client không có API liệt kê động mọi subcollection. Danh sách xóa vì
vậy bao phủ toàn bộ collection đang triển khai và toàn bộ collection riêng tư
đã định nghĩa trong thiết kế HealthMate hiện tại. Khi thêm một subcollection
người dùng mới ở giai đoạn sau, repository xóa tài khoản phải được cập nhật cùng
schema. Wildcard Rules chỉ cho UID sở hữu đọc để liệt kê và xóa dữ liệu riêng;
không cấp quyền tạo hoặc cập nhật cho đường dẫn chưa có rules nghiệp vụ.
