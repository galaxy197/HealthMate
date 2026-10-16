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

Catalog ban đầu có 10 seed tham khảo USDA FoodData Central. Ngày 16/10/2026
đã thêm 101 thực phẩm theo Viện Dinh dưỡng 2007 và 47 món từ công thức ước tính,
tổng **158 mục**; giữ nguyên 10 mục cũ. Tất cả mục mới `isEstimated: true` vì
giống thực phẩm/cách chế biến thực tế có thể khác. Metadata quản trị bổ sung:
`sourceUrl`, `catalogVersion`, `sourceDetails` (mã/trang nguồn hoặc gram nguyên
liệu/khối lượng thành phẩm/giả định). Giữ các field đang được app đọc và đơn vị
`per_100g`/`g`; không đổi snapshot meal hoặc dữ liệu `users/{uid}`. Bộ nạp chỉ
create-if-absent, không ghi đè; xem [food-catalog.md](food-catalog.md).

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

## Giai đoạn 7 — Goals và Daily Health Quest

Định hướng `healthGoal`/`targetWeightKg` trong hồ sơ tiếp tục được giữ nguyên.
Ứng dụng không tự chuyển định hướng onboarding thành mục tiêu định lượng hoặc
ghi đè hồ sơ khi người dùng tạo mục tiêu mới. Không cần migration.

### `users/{uid}/goals/{goalId}`

- `goalType`: `meals | water | activity | weight`.
- `targetValue`, `unit`: tương ứng bữa (1–10), ml (50–5000), phút (1–180),
  kg (20–500). Đây là giới hạn nhập liệu, không phải khuyến nghị y tế cá nhân.
- `startDateKey`, `endDateKey`: ngày địa phương `yyyy-MM-dd`, bao gồm cả hai
  ngày; kết thúc không trước bắt đầu. Dùng ngày lịch thay vì UTC midnight để
  thời hạn theo ngày không bị dịch khi chuyển múi giờ thiết bị.
- `status`: `active | paused | completed` do người dùng chọn.
- `baselineWeightKg`: số kg ban đầu cho weight, `null` với loại khác.
- `createdAt`, `updatedAt`: server timestamps; `schemaVersion: 1`.

Loại, đơn vị và baseline giữ nguyên khi sửa. Mục tiêu thói quen được tính lại
mỗi ngày bằng số bữa, tổng nước hoặc tổng phút từ nhật ký thực của ngày đó.
Không dùng tiến độ của ngày hiện tại để suy diễn ngày quá hạn.

Mục tiêu cân nặng dùng `(latest - baseline) / (target - baseline)`, giới hạn
0–1 và hỗ trợ cả tăng/giảm. Chỉ dùng lần cân từ ngày bắt đầu đến hết ngày đang
xem. Khi baseline bằng target, đánh dấu đạt khi sai lệch dưới 0,1 kg; đây chỉ
là quy ước hiển thị số liệu, không phải đánh giá sức khỏe. Không có lần cân
trong thời hạn thì hiển thị chưa có dữ liệu.

### `users/{uid}/daily_quests/{yyyy-MM-dd}`

- ID document bằng `dateKey`; đúng một gợi ý được giữ cho mỗi UID/ngày.
- `questType`: `meal | water | activity | reflection`.
- `title`, `description`, `reason`: snapshot nội dung và lý do quy tắc.
- `targetValue`, `unit`: bữa (1), ml (1–250), phút (1–10), lần (1).
- `status`: `available | completed | skipped`.
- `createdAt`, `updatedAt`: server timestamps; `completedAt` chỉ có timestamp
  khi completed, còn lại `null`; `ruleVersion: 1`.

Engine thuần ưu tiên mục tiêu đang hoạt động/chưa đủ theo thứ tự loại rồi ID.
Chỉ gợi ý nước/vận động khi người dùng đã chọn mục tiêu tương ứng. Nếu không
có mục tiêu phù hợp, gợi ý ghi bữa đầu tiên hoặc xem lại nhật ký. Không suy
diễn sức khỏe từ việc thiếu log và không sử dụng AI hay điểm/phạt.

Provider chờ dữ liệu goals/meal/water/activity tải thành công trước khi sinh
gợi ý. Repository dùng transaction đọc trước khi tạo; khi document đã tồn tại
thì không ghi lại. Thay mục tiêu/log hoặc mở màn hình nhiều lần không thay
gợi ý hay trạng thái đã lưu. Hoàn thành/bỏ qua là xác nhận người dùng, không
tự ghi nhật ký và không tự cộng tiến độ mục tiêu. Trạng thái terminal không
được chuyển ngược. Transaction cần mạng; lỗi có nút thử lại.

Rules kiểm tra schema, đơn vị, khoảng giá trị, timestamp và chuyển trạng thái,
đồng thời chặn truy cập chéo UID. Client tự quyết định gợi ý từ engine nên Rules
không chứng minh nội dung engine đã được chạy đúng; quest không phải điểm thưởng
hay chứng nhận sức khỏe. Xóa tài khoản đã bao phủ cả hai collection này.

Không thêm composite index: goals dùng collection listener, quest dùng document
listener. Không deploy Rules/indexes production trong Giai đoạn 7.

## Giai đoạn 8 — Các lượt đọc Tổng quan và Nhìn lại tuần

Không tạo collection/schema thống kê mới; tổng được tính từ snapshot nhật ký.
Không sửa Rules/indexes trong giai đoạn này. Các Rules Giai đoạn 7 vẫn cần được
review/deploy riêng trước khi ghi goals/quests production.

- Tổng quan dùng provider ngày chung với Nhật ký; nước/vận động theo `dateKey`,
  bữa mới theo `dateKey`, bữa cũ thiếu khóa ngày theo khoảng timestamp địa phương
  nửa mở. Không tải catalog/recent meals chỉ để tính tổng Dashboard.
- Cân nặng Tổng quan dùng một query `measuredAt < startOfNextDay`, orderBy
  `measuredAt` giảm dần, `limit(1)`. Không nghe toàn bộ lịch sử chỉ để hiển thị
  một lần cân. Goals/Quest dùng provider/document đã có; Dashboard không tự tạo
  nhiệm vụ khi chỉ xem tiến độ.
- Báo cáo tuần dùng tuần lịch Thứ Hai–Chủ nhật. Các khoảng repository đều là
  `[start, end)` với mốc ngày địa phương, end là đầu Thứ Hai kế tiếp.
- Mỗi lượt mở/làm mới báo cáo có **5 query get từ server**: 2 cho meal (dateKey
  range và consumedAt range để tương thích legacy), 1 water dateKey range,
  1 activity dateKey range và 1 body_metrics measuredAt range. Meal có dateKey
  bị bỏ khỏi nguồn legacy rồi gộp theo ID, tránh cộng trùng hoặc đổi ngày đã lưu.
- Các query chỉ lọc/order cùng một field nên dùng single-field index mặc định.
  Không có 21 listener theo 7 ngày. Future được chia sẻ theo UID/tuần; rebuild
  cùng tuần không lặp lại query. Đóng báo cáo hoặc rời tab giải phóng provider;
  mở lại lấy snapshot mới. Một nguồn lỗi thì không công bố tổng chưa đủ dữ liệu.
- Chọn server cho lượt đọc tuần để không coi tập cache offline thiếu bản ghi là
  báo cáo đầy đủ. Có nút tải lại và nhãn giờ lấy snapshot; không hứa báo cáo tự
  realtime sau khi sửa log. Đồng hồ địa phương làm mới khi qua phút/ngày và khi
  app trở lại foreground.
- Screen trong indexed shell ngừng watch khi TickerMode của branch bị tắt.
  AutoDispose hủy meal/water/activity/metrics/Goals/Quest/catalog/recent listeners
  khi không còn consumer. Trạng thái chọn ngày Nhật ký vẫn ở provider hiện có.

Tổng dinh dưỡng/nước/phút chỉ phản ánh phần đã ghi; ngày trống không đại diện
cho giá trị sức khỏe bằng 0. Trung bình kcal chia cho số ngày có bữa ghi nhận,
không chia mặc định 7. Ngày chưa tới không được tính vào tổng hay số ngày đã tới.
Cân nặng ít hơn hai lần đo không được mô tả xu hướng; chênh lệch chỉ là phép trừ
giữa số đo, không giải thích nguyên nhân.

Bộ đếm fake repository xác minh số lần gọi range và listener active trong test;
chưa đo số document read/billing trên project Firebase production. Emulator test
xác minh query range, ranh giới ngày, limit cân nặng và chặn UID khác.
## Hội thoại — Giai đoạn 9

`users/{uid}/chat_sessions/{sessionId}`:
`title` (nhãn chung, <=80 ký tự), `messageCount` (số chẵn 2..40), `lastTurnId`
(20 chữ/số), `createdAt`, `updatedAt` (server timestamps), `schemaVersion: 1`.

`.../messages/{turnId}_u` và `{turnId}_a`:
`turnId`, `role: user|assistant`, `text` (user 1..1000, assistant 1..6000 ký tự),
`source: journal|ai|help`, `sequence` (0..39), `createdAt` (server timestamp),
`schemaVersion: 1`. Không lưu ảnh, toàn bộ hồ sơ hoặc payload context riêng.

Một transaction tạo cả hai messages và cập nhật parent; Rules getAfter kiểm
tra cặp và sequence. Tin đã tạo bất biến; delete theo UID cho quy trình xóa
tài khoản. Retry cùng turnId là no-op khi user message đã tồn tại. Read lịch
sử phiên: `orderBy(updatedAt desc).limit(20)`; messages: `orderBy(sequence)`
`.limit(40)`. Không thêm composite index; không deploy Rules/index trong lượt.

Nguồn `journal` là tổng snapshot tính tại ứng dụng từ các repository range;
nguồn `ai` chỉ dành cho chủ đề kiến thức chung định sẵn theo lựa chọn free tier.
Không gửi nhật ký hoặc hội thoại tới AI. Chi tiết: [chatbot.md](chatbot.md).

## Rà soát Giai đoạn 10

Không thêm collection, schemaVersion, field, composite index hoặc migration.
Quy ước dateKey/UTC offset đã có được kiểm tra chặt hơn trên **create/update**:
`dateKey` phải bằng ngày lịch của `consumedAt` (meal/water) hoặc `performedAt`
(activity) sau khi cộng `timezoneOffsetMinutes`. Ngày không tồn tại hay offset
ngoài giới hạn bị từ chối. Ví dụ 17:30 UTC +420 phút thuộc ngày kế tiếp ở UTC+7.
Không đổi dữ liệu lịch sử; các bữa legacy thiếu dateKey vẫn dùng range timestamp
hiện có. Thay đổi Rules chỉ ở source, đã test emulator, chưa deploy.

Onboarding giữ nguyên `onboardingCompletedAt` đã lưu khi chạy lại, phù hợp quy
tắc completion marker bất biến; không ghi serverTimestamp mới vào marker cũ.
Người dùng đã duyệt MVP/demo 18+: client dùng ngày sinh đầy đủ để kiểm tra tuổi
18–120 và điều hướng bổ sung hồ sơ khi thiếu/không hợp lệ. Dữ liệu cũ vẫn được
giữ. Cổng AI kiểm tra cùng UID và onboarding hợp lệ ngay trước yêu cầu.
Đây là tự khai/kiểm tra client, không phải chứng thực tuổi hay identity ở Rules.

Rules mặc định không cho tạo/cập nhật path chưa định nghĩa; owner read/delete
wildcard phục vụ cleanup dữ liệu của chính UID vẫn được giữ. Không cấp quyền
cross-UID, guest hoặc catalog write. Mọi match allow là OR, không dựa vào nhánh
deny để che nhánh allow khác. Xóa account dọn các collection hiện có, bao gồm
chat messages trước session rồi mới profile/Auth; phải cập nhật cleanup khi
schema có subcollection mới.

Không lưu ảnh vào Firestore/Storage. Scanner mã hóa lại từ pixel để bỏ metadata
gốc và xin đồng ý từng ảnh trước khi gửi; không gửi dữ liệu cá nhân với free AI.
Cache native có thể giữ lại dữ liệu trên máy sau logout; app không tự clear
pending writes. Cấu hình backup Android đã bổ sung, chưa thử device transfer.
Kết quả **31 Rules + 4 SDK integration** và giới hạn tại [test-report.md](test-report.md).
