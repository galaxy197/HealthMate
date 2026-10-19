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

## Core C1 — 17/10/2026

C1 chỉ thêm cờ tính năng cục bộ và chặn lối vào Chatbot/Scanner, không thêm/sửa
collection, field, serializer, Rules hoặc indexes. Giữ lịch sử AI và cleanup
chat_sessions/messages, snapshot dinh dưỡng, quy ước dateKey/timezoneOffset và
reader legacy consumedAt hiện có. Không chạy migration hoặc sửa dữ liệu server.

Thiết kế dự kiến nutrition_targets (C2), favorite_foods (C3), custom_foods/recipes
(C4), công thức scale/yield/serving, lịch sử hiệu lực và các ràng buộc test/cleanup:
[core-scope.md](core-scope.md#schema-dự-kiến-và-kế-hoạch-c2c6-chưa-triển-khai).
Các collection mới **chưa triển khai**. Mỗi giai đoạn sẽ cập nhật chi tiết schema,
bounds, Rules và index theo truy vấn thực tế trước khi thêm tính năng.

Rules production đã đọc lại trong C1, vẫn khác source và thiếu match ghi cho
Goals/Quest/Chat. Local Rules31/31 và SDK6/6 pass trên demo emulator; chưa deploy,
chưa nghiệm thu production. Không đồng nhất test local với quyền production.

## C2 — Mục tiêu dinh dưỡng theo ngày hiệu lực (thiết kế trước triển khai)

`users/{uid}/nutrition_targets/{effectiveFromDateKey}`:
- effectiveFromDateKey: ngày lịch địa phương chuẩn yyyy-MM-dd, trùng documentID.
- kcalTarget: số hữu hạn >0 và <=20000.
- proteinGTarget/carbsGTarget/fatGTarget: cùngnull hoặc cùng số hữu hạn0..5000g.
- source=user_manual, schemaVersion=1, createdAt/updatedAt=server timestamp.

Đây là giới hạn kỹ thuật chống payload xấu, không phải khuyến nghị y khoa.
Query một bản có effectiveFromDateKey<=ngàyD, orderBy giảm dần,limit1; không có
thì chưa đặt. Dùng single-field index mặc định, chưa cần composite index mới.
Đọc server để lỗi/offline không bị coi là chưa đặt; không fetch toàn bộ lịch sử.

Form và repository chỉ cho lưu từ ngày hôm nay địa phương trở đi; không sửa/xóa
phiên bản quá khứ qua UI. Rules kiểm tra ngày hợp lệ, schema/bounds/UID/timestamps;
Rules không biết múi giờ thiết bị nên không giả vờ chứng thực ngày địa phương
hiện tại hoặc mức mục tiêu y khoa. Không thêm timezone field vào schema đã chốt.
Upsert transaction theoIDngày, giữ createdAt, không timeout write giả định đã hủy;
retry cùngngày không nhân đôi. Không tạo counter/tổng ngày dẫn xuất hoặc thay Goals.
Lệch năng lượng macro4P+4C+9F so với kcal>5% cần xác nhận giữ giá trị, không tự sửa.
Thêm nutrition_targets vào cleanup tài khoản và kiểm thử Rules/SDK.

### Kết quả triển khai C2 và xác nhận ghi

Schema nêu trên được triển khai local, chưa deploy. UI dùng chung provider theo
UID/ngày cho Tổng quan, Nhật ký và Cá nhân, không thêm listener hoặc counter ngày.
Một query server lấy tối đa1document. Sau lưu, invalidate các ngày đã cache để
chọn lại đúng phiên bản; Future cũ/UID cũ không cập nhật UI tài khoản mới.

SDK web + disableNetwork trong emulator đã tái hiện transaction hoàn tất và bản
ghi xuất hiện trên server sau reconnect, trong khi Source.server read bị từ chối.
Vì vậy repository đọc lại đúng document từ server sau transaction và kiểm tra
kcal/macros + metadata (không cache/pending) trước khi báo thành công. Nếu thiếu
xác nhận, bản nháp còn và retry dùng cùng ID ngày; không coi lỗi là rollback.
Chi phí thêm1đọc sau mỗi lần lưu là để xác nhận nội dung, không phải query lặp
trong build. createdAt được giữ khi update, updatedAt là server timestamp.

UI không có xóa phiên bản mục tiêu hoặc sửa ngày quá khứ. Rules owner vẫn được
xóa phục vụ cleanup tài khoản; không coi giới hạn UI là chứng thực ngày/múi giờ
hoặc quyền quản trị. Không thay đổi hay migration dữ liệu bữa ăn đã có.

## C3 — Thiết kế trước triển khai (17/10/2026)

Thêm users/{uid}/favorite_foods/{catalog_<sourceId>}: sourceKind=catalog,
sourceId (1..100 ký tự, không có slash), createdAt/updatedAt server timestamp,
schemaVersion=1. ID ghép nguyên sourceId phân biệt hoa/thường; namespace catalog_
không va chạm custom_/recipe_ ở C4. C3 chưa cho client tạo nguồn custom/recipe.
Rules kiểm tra ID/field/type/timestamp/UID và catalog tồn tại khi tạo; owner vẫn
đọc/xóa yêu thích khi nguồn biến mất. Không cache số dinh dưỡng vào yêu thích.

Chỉ mở nguồn yêu thích trong form và khi chọn tab tương ứng. Query phân trang
createdAt giảm dần, limit40 rồi tăng40 khi bấm Xem thêm. Không listener toàn lịch
sử nhật ký; recent giới hạn20bữa, khử món trùng từ snapshot. Metadata cache của
nguồn gần đây/yêu thích được chuyển tới UI, cache rỗng không bị gọi là chưa có.
Lưu yêu thích là thao tác set mong muốn=true theoIDổnđịnh, không phải toggle mù;
bỏ yêu thích ở tab Yêu thích. Thao tác lặp không tạo hai bản.

MealLog không đổi schema. Mỗi form tạo mới/copy cấp operationId một lần, dùng
create-if-absent transaction; retry cùngpayload là no-op, payload khác cho lỗi rõ
ràng để tải lại/chủ động sửa, không ghi đè bản đã tạo. Kiểm tra server read-back
trước success, không timeout write để giả định hủy. Sửa bữa có sẵn vẫn updateIDcũ.
Copy chỉ mang snapshot/type/source, không mangID/dateKey/offset/createdAt nguồn;
ngày/offset mới tính từ thời điểm chọn, không cho thời điểm tương lai. Một lần mở
copy mới có ID riêng. Không migration/gộp MealLogs hoặc nâng giới hạn5món/bản ghi.
Thêm favorite_foods vào cleanup. Chưa cần composite index mới hoặc deploy.

### C3 — Kết quả triển khai và kiểm chứng

Thiết kế trên đã triển khai local; không tạo collection trên production trong
lượt này. `FavoriteFood` chỉ giữ tham chiếu catalog, không giữ số dinh dưỡng.
Chọn thêm từ yêu thích dùng dữ liệu catalog hiện tại; món gần đây/copy dùng snapshot
đã ghi. Sửa gram scale từ snapshot; không tra lại catalog để thay số lịch sử.
Catalog thiếu một trong bốn số dinh dưỡng hợp lệ có `hasNutritionData=false` trong
model đọc local (không thêm field Firestore). UI chặn thêm món đó, không coi số
mặc định 0 là dữ liệu đã biết. Nguồn mất có hướng dẫn và vẫn bỏ yêu thích được.

Một listener recent giới hạn20bữa dùng chung khi mở nguồn Gần đây, khử trùng lấy
tối đa8món. Yêu thích query limit40/tăng40 theo thao tác người dùng, không tải tất
cả ngầm. Đổi UID hủy subscription và bỏ completion cũ. Không thêm daily counter,
listener trong build hoặc index composite. Các MealLog cùng loại bữa vẫn độc lập;
tổng nhóm/ngày là phép cộng từ provider ngày đang chọn, cập nhật sau sửa/xóa.

Transaction + Source.server read-back được kiểm tra bằng SDK web/emulator, cả khi
disableNetwork: transaction có thể đã tới server trong khi read-back bị lỗi.
Không báo thành công thiếu ack, không coi lỗi là rollback; giữ form và retry cùng
ID/payload. Retry payload khác báo tải lại/chọn Sửa, không ghi đè bản đã tồn tại.
Mỗi lần chủ động mở form mới/copy mới có ID mới. Không lưu draft qua đóng app.
Favorite set=true idempotent giữ createdAt; bỏ yêu thích offline chờ reconnect và
xác nhận xóa. Cleanup favorite_foods được kiểm tra cùng dữ liệu khác trước xóa Auth,
đồng thời kiểm tra yêu thích của UID B vẫn còn sau cleanup UID A.

39Rules +9SDK tests pass trên demo-healthmate-rules. GET production read-only
12:45:30 ngày17/10/2026 UTC+07 xác nhận release vẫn 2026-10-13T06:25:21.345792Z,
chưa có favorite_foods/nutrition_targets. Không deploy/migration/ghi dữ liệu thật.

## C4 — Thiết kế thư viện món và công thức (17/10/2026)

Bổ sung riêng dưới UID, không sửa schema MealLog hoặc migration lịch sử:
- custom_foods/{id}: name, alternateNames (tối đa 5 tên, 60 ký tự/tên),
  servingBasis=per_100g, kcalPer100g/proteinGPer100g/carbsGPer100g/fatGPer100g,
  defaultServingGrams, servingLabel+servingGrams cùng null hoặc có đủ cặp,
  sourceLabel, isEstimated, schemaVersion=1, createdAt/updatedAt server timestamp.
  Tên 2–100 ký tự, kcal/100g 0–10000, mỗi macro 0–1000g; gram >0 và <=2000.
- recipes/{id}: name, ingredients từ 1 đến 6 dòng snapshot có 9 field giống
  MealItemSnapshot, yieldGrams >0..20000, servingsCount null hoặc >0..1000,
  sourceLabel, isEstimated=true, schemaVersion=1, createdAt/updatedAt server.
  Mỗi nguyên liệu gram >0..2000, kcal 0..10000, mỗi macro 0..1000. Không lồng
  recipe; tên/nguồn/snapshot giữ độc lập khi catalog/món cá nhân bị sửa/xóa.
  Giới hạn 6 đồng bộ model/UI/Rules và được kiểm tra ngân sách Rules bằng Emulator.
- Tổng recipe = tổng snapshot; /100g = tổng*100/yieldGrams. Yield có thể khác
  tổng nguyên liệu. Gram/phần = yieldGrams/servingsCount; số phần ăn được nhập
  thập phân, quy về gram rồi mới tạo snapshot. Không cache tổng/per100g dẫn xuất.
- ID snapshot mới có namespace custom:<id> hoặc recipe:<id>; catalog và snapshot
  nhập tay cũ không đổi ý nghĩa. Không thêm field bắt buộc vào MealLog.
- favorite_foods mở sourceKind custom/recipe, ID custom_<id>/recipe_<id>, giữ
  catalog_<id> cũ. Create chỉ nếu nguồn của đúng UID tồn tại; nguồn mất vẫn đọc/
  bỏ yêu thích được. Không dùng query trang đầu để kết luận nguồn không tồn tại:
  favorite private đọc nguồn trực tiếp theo ID, lỗi tách biệt với missing.

Watch thư viện theo createdAt desc, limit40 rồi tăng40 qua hành động rõ ràng.
Chỉ mở nguồn khi cần, autoDispose và UID-bound. Create có ID ổn định mỗi form;
transaction create-if-absent và server read-back, retry cùng payload không trùng.
Edit không tạo lại nguồn đã xóa; createdAt bất biến. Delete chờ xác nhận server.
Không timeout write để suy ra rollback. Draft chỉ giữ RAM, không qua đóng app.
Nhập ngoài catalog một lần vẫn là mặc định; lưu Món của tôi là lựa chọn chủ động.
Khi nguồn thư viện đã lưu mà bữa chưa lưu, hiển thị hai trạng thái riêng.
Thêm custom_foods/recipes vào cleanup trước Auth; chưa deploy hoặc đổi index.
Các giới hạn trên là giới hạn kỹ thuật, không phải khuyến nghị dinh dưỡng.

### C4 — Kết quả triển khai và xác nhận ghi

Schema trên đã triển khai local; 47 Rules và 11 SDK tests trên
`demo-healthmate-rules` pass. Công thức đủ 6 dòng ban đầu vượt ngân sách 1.000
biểu thức khi gọi lại validator MealLog. Validator recipe hiện dùng allowlist
field chung, giữ các giá trị số vào biến và regex kiểm tra type/độ dài string;
kiểm tra đủ cả 6 dòng, không bỏ kiểm tra dòng giữa/cuối. Test cả create/update
payload tối đa và payload xấu tại dòng 0/2/5 đều có kết quả đúng.

Khẩu phần tạo snapshot vẫn chịu giới hạn MealItem: >0..2000g, kcal <=10000,
mỗi macro <=1000g. Dialog kiểm tra cả số dinh dưỡng sau quy đổi, không chỉ gram.
Recipe /100g được tính lại khi đọc; client từ chối kết quả ngoài giới hạn món.
Các giới hạn này là kỹ thuật, không xác nhận mức ăn hoặc dinh dưỡng y khoa.

Reader library kiểm tra schema/nutrients/timestamps và báo lỗi có kiểm soát thay
vì thay field thiếu bằng 0. Cache list được ghi nhãn; nguồn private favorite đọc
server trực tiếp theo UID/kind/ID, không kết luận mất nguồn vì nó ở ngoài trang40.
Delete không cascade vào snapshot hoặc tự xóa favorite; favorite mất nguồn vẫn
bỏ được. Library controller invalidate các nguồn đang dùng sau save/delete, không
thêm kho tổng hợp hoặc listener ở startup. Nút Thêm vào bữa chỉ đổi bản nháp;
MealLog chỉ ghi sau nút Lưu của form bữa ăn.

Create/retry cùng ID dùng transaction + read-back; khác payload không ghi đè.
Edit không tự tạo lại nguồn đã xóa. SDK test disableNetwork tái hiện lỗi ack dù
transaction có thể đã tới server; reconnect/retry vẫn một bản đúng nội dung.
Delete offline giữ pending tới reconnect và xác nhận server. Đổi UID bỏ completion
cũ; form account-bound được đóng, không chuyển draft sang tài khoản khác.

Cập nhật cleanup custom_foods/recipes; SDK xác nhận dữ liệu A được xóa trước Auth,
trong khi món, công thức và yêu thích của B vẫn còn. Không migration, đổi schema
MealLog, dependency hoặc composite index. Rules production GET read-only lúc
16:11:23 UTC+07 ngày17/10/2026 vẫn thiếu custom_foods/recipes/favorite_foods/
nutrition_targets; release vẫn 2026-10-13T06:25:21.345792Z. Chưa deploy.


## 2026-10-17 — Core C5: đọc Tiến độ và mục tiêu tuần

Không thêm collection, field, dependency, migration, Rules hoặc composite index
trong C5. Giữ nguyên schema C1–C4, snapshots, cleanup và quyền owner theo UID.
Tổng hợp tiếp tục suy ra từ nhật ký qua `weeklyLogsProvider`/`summarizeWeek`,
không lưu một bản sao tổng kcal hoặc counter ngày trong Firestore.

- Một lần mở/đổi tuần đọc một khoảng lịch địa phương `[Monday, nextMonday)`.
  MealLog dùng dateKey đã lưu; truy vấn consumedAt nửa mở giữ tương thích dữ liệu
  cũ thiếu dateKey, khử trùng ID trước tổng hợp. Water/activity dùng dateKey.
  Cân nặng query measuredAt trong cùng khoảng, không tải toàn bộ lịch sử.
  Các query nhật ký bị giới hạn bởi tuần, không cắt 100 bản ghi làm thiếu tổng.
- Mục tiêu dùng `NutritionTargetRepository.loadForRange(uid,startKey,endKey)`,
  chỉ chấp nhận 1–7 ngày lịch: query `effectiveFromDateKey <= startKey`, desc,
  limit1; query `effectiveFromDateKey > startKey && < endKey`, asc, limit7.
  Mỗi ngày hiệu lực có một ID nên tối đa7 phiên bản liên quan cho một tuần.
  Cùng một field range/order dùng single-field index hiện có; không cần composite.
  Cả hai đọc Source.server, dùng parser schema/timestamps/validation chung với
  loadForDay; lỗi/offline/dữ liệu hỏng không biến thành danh sách mục tiêu rỗng.
- Với mỗi ngày D chọn phiên bản lớn nhất <=D. Không có phiên bản thì chưa đặt;
  mục tiêu hiệu lực sau D không áp ngược. Không cộng mục tiêu tương lai vào tổng.
  Thành công khi lưu mục tiêu invalidate cả provider ngày và tuần.
- Tổng kcal/macros/nước/phút chỉ cộng ngày đã tới. Ghi 0 có chủ ý vẫn tính là có
  ghi; ngày không có bữa không vào mẫu số trung bình. Tương lai không tính vào
  số ngày đã tới. Không suy ra lượng ăn thực hoặc tuân thủ từ nhật ký thiếu.
- WeightChart tự sort timestamp trước lấy12 lần gần nhất, vẽ x theo thời gian
  thực để giữ khoảng cách ngày trống. Bên dưới có ngày/giờ và số cân; không
  mô tả thay đổi nếu <2 điểm. Chênh lệch tuần dùng lần cuối trừ lần đầu của tuần,
  không khẳng định nguyên nhân hoặc xu hướng ngoài khoảng được chọn.
- Future providers được chia sẻ cho cùng UID/tuần, không mở listener ngày hoặc
  toàn lịch sử ở Tiến độ. Khi ẩn tab, card nhả subscriptions nhưng giữ lựa chọn
  tuần; quay lại tải mới. Có giờ tải và refresh thủ công sau sửa nhật ký.
  Loading khi đổi UID/tuần không tái hiển thị payload cũ. Mục tiêu tải riêng:
  permission/offline ở mục tiêu không che tổng nhật ký đã tải thành công.
- Nút+ thêm cân nặng tái dùng FirebaseHealthProfileRepository.addBodyMetric và
  form hiện có qua ConfirmedSave. Chờ Future xác nhận, chặn gửi lặp, giữ draft
  khi lỗi; AccountBoundDialog bỏ draft khi đổi UID. Thành công làm mới tuần.
  Không tạo collection cân nặng thứ hai hoặc tự thêm chỉ số sức khỏe khác.

Rules production chỉ được GET metadata/source để so sánh; không deploy C5.
Bằng chứng mới nhất và kiểm thử server emulator trong docs/test-report.md phần C5.

## Core C6 — Nghiệm thu và vòng đời tài khoản (17/10/2026)

C6 không thêm collection/field/index, không đổi Rules so với C5 và không chạy
migration. Giữ snapshot MealLog và quy ước dateKey/UTC offset hiện có.

- BodyMetric mới giữ thời điểm hiện tại thay vì cắt về 00:00; vì vậy lần cân
  sau onboarding trong cùng ngày được sắp xếp đúng là lần gần nhất. Sửa riêng
  cân nặng giữ nguyên measuredAt, kể cả giờ/phút/phần lẻ. Khi chọn ngày khác,
  giữ phần giờ và chặn thời điểm tương lai. Bản ghi cũ không bị viết lại.
- ProfileController và AccountSecurityController gắn thao tác với UID/generation;
  kết quả của phiên cũ không ghi trạng thái thành công/lỗi vào phiên mới. Đổi mật
  khẩu/xóa Auth kiểm tra expectedUid ngay trong FirebaseAuthRepository, trước SDK
  mutation. Cleanup vẫn xóa dữ liệu UID đã xác thực trước rồi mới xóa Auth; nếu
  đổi phiên giữa chừng thì dừng bước tiếp theo. Không biến thao tác A thành B.
- Các subscription repository được hủy khi đổi phiên. Lỗi Future cancel từ
  async* khi quyền cũ bị thu hồi chỉ được xử lý tại biên hủy subscription;
  lỗi đọc/ghi của subscription còn hoạt động vẫn được chuyển đầy đủ tới UI.
  Không thay permission/error thành dữ liệu trống hoặc thành công giả.
- Form hồ sơ/cân nặng ở Cá nhân chờ server xác nhận, giữ draft khi lỗi và bỏ
  draft khi đổi UID; không đóng trước khi biết kết quả lưu.
- E2E dùng named Firebase app, Auth/Firestore Emulator với project cố định
  demo-healthmate-rules và dữ liệu tổng hợp. Không gọi production main/bootstrap.
  Debug Android chỉ mở HTTP cho localhost/127.0.0.1/10.0.2.2 để kết nối emulator;
  release không dùng network_security_config này. Không bỏ App Check production.

Rules production vẫn khác source: GET chỉ đọc 17:04:32 UTC+07 ngày17/10/2026,
release cập nhật lần cuối 2026-10-13T06:25:21.345792Z; thiếu match của targets,
favorites và thư viện core (cùng Goals/Quest/Chat trước đó). Hai composite index
nước/vận động ở trạng thái READY. Không deploy trong C6; production chưa nghiệm thu.

## H2 schema local — 19/10/2026

users/{uid}/meal_templates/{id}: name,1–5items snapshot,schemaVersion1,
createdAt/updatedAt server; ID ổn định qua create/retry, owner CRUD. Mẫu không có
ngày/bữa áp dụng; chép items vào bản nháp ngày/bữa đang chọn, không tự log.
Snapshot bữa/mẫu độc lập nguồn, CRUD mẫu không thay nhật ký. Cleanup client mới
thêm meal_templates; phải phối hợp nâng client trước production để client cũ
không bỏ sót collection mới khi xóa tài khoản. Chưa deploy/migrate trong H2.
Rules local kiểm thử owner/A-B/guest/bounds/timestamps, index single-fieldupdatedAt.
Chi tiết và rollback trong h2-templates-deployment.md. U2 Rules đã deploy18/10 là
lịch sử và chưa bao gồm thay đổi H2 này; không coi snapshot metadata cũ là trạng
thái đồng bộ source hiện tại.

## H3 — snapshot nhãn / dữ liệu ba chất chưa đầy đủ (local, chưa deploy)

Meal schemaVersion 2 giữ nguyên các snapshot gram đầy đủ. SchemaVersion 3 dùng
khi có chất chưa biết hoặc lượng không phải gram. Mỗi chất vẫn có key nhưng
null có nghĩa chưa biết; 0 có nghĩa số 0 do người dùng nhập/nhãn công bố.
Snapshot gram giữ grams >0 và không thêm quantity metadata. Snapshot không phải
gram lưu grams:null, quantityUnit:ml|serving|entry và quantity>0, tối đa2000.
Không suy ra khối lượng hoặc mật độ từ thể tích. Mỗi món tối đa10000kcal/1000g
mỗi macro; cả bữa tối đa20000kcal/2000g mỗi macro biết được.

NutritionTotals giữ tổng phần đã biết với cờ proteinKnown/carbsKnown/fatKnown;
phép cộng AND coverage, không suy ra phần thiếu. Với meal schema3, reader tính
lại subtotal/coverage từ snapshot. Wire total macro=null nếu thiếu bất cứ món
nào; kcal vẫn biết. UI ghi Chưa đủ dữ liệu/— hoặc ≥subtotal, không báo thiếu=0
hay so phần thiếu với mục tiêu. Export H7 sau này phải đọc cờ coverage và đơn vị,
không xuất sentinel grams=0 nội bộ thành số đo thật.

meal_templates schema1 cũ; schema2 dùng codec snapshot mở rộng tương tự. Rules
vẫn1–5 món, tổng giới hạn như meal; tính subtotal để validation không sửa null
trong payload. Numeric interval được viết math.abs(x-midpoint)<=midpoint nhằm
giữ đủ5 món dưới1000expressions (https://firebase.google.com/docs/reference/rules/rules.math).
Các hàm meal/template riêng tránh cộng chi phí thống kê trong meal không cần.
Món riêng/công thức vẫn dùng đủ macro theo gram; Quick Add không bị ép vào hợp
đồng đó. Có thể dùng lại bằng Gần đây/bữa mẫu/copy và chỉnh đúng đơn vị snapshot.

Không migration bữa cũ, không sửa catalog/hồ sơ để thêm field sinh lý. Client cũ
không hiểu schema3/template2. Cần nâng client/cleanup H2 trước khi cho dùng dữ liệu
mới ở production, deploy Rules riêng có review/ủy quyền; không downgrade sang
client cũ sau khi đã ghi v3. Backup/rollback phải giữ các document v3, không đổi
null thành0 để tương thích. Firebase production chưa được deploy trong H0–H3.

## H5 — day_reviews, chưa deploy

Schema và giới hạn đọc theo khoảng, xác nhận đủ bữa có revision, cách xử lý ngày
trống/macro thiếu/đổi target/đổi múi giờ, rollout client/cleanup và kiểm thử trong
[h5-period-reports.md](h5-period-reports.md). Collection mới UID-owner only,
không migration log cũ hoặc index mới. Báo cáo không coi tự có meal là ngày đủ dữ liệu.


## H6 — Chất xơ tùy chọn và phiên bản tương thích

Xem h6-fiber.md cho nguồn và quy trình rollout. Catalog/món riêng có fiberGPer100g
(g/100 g, tùy chọn). Snapshot có fiberG (g); fiberIncomplete:true đánh dấu tổng chỉ
biết một phần. Không có field là chưa biết; fiberG:0 không kèm cờ là 0 thật.
Tổng nhật ký/báo cáo tính từ snapshot, giữ cờ thiếu xuyên suốt khi nhân/chia khẩu phần.
Meal schema 4, custom_foods/recipes schema 2; bản ghi cũ tiếp tục đọc, không migration.
Bữa mẫu schema 3 chuẩn hóa quantity + quantityUnit cho mọi đơn vị, bỏ macro chưa
biết (reader phục hồi null). fiberValues cùng độ dài/thứ tự items chứa số hoặc null;
fiberPartialMask tùy chọn đánh dấu bit của các giá trị chỉ là lower bound. Không
thêm collection/index. Giới hạn 5 món/6 nguyên liệu, UID, timestamp và chống hạ phiên
bản vẫn được kiểm tra. Chưa deploy Rules/indexes hoặc cập nhật catalog production.

## H7 — Nháp local và CSV, không đổi schema Firestore

Không collection/Rules/index mới. Android giữ JSON local v1 mã hóa AES-GCM trong
noBackupFilesDir, khóa AndroidKeyStore theo UID; operationId, mealId khi sửa,
snapshot, UTC/offset/dateKey và minimumSchema được giữ. Giới hạn20nháp/UID,
512KiB, hết hạn7ngày và dọn ở lần mở kho tiếp theo. Không migration nhật ký cũ.
MealDraft.timezoneOffsetOverride chỉ là hợp đồng Dart/local; repository tiếp tục
ghi dateKey/timezoneOffsetMinutes đã có. Xóa tài khoản dọn local đúng UID sau
Firestore và trước Auth; callback trễ không tạo lại nháp đã xóa.

CSV healthmate_journal_csv_v1 gồm từng món của meal, water, activity và body_metric;
không bao gồm toàn bộ hồ sơ/chat/goals/thư viện/draft. Cột schema nguồn, đơn vị,
UTC/dateKey/offset/basis và status mỗi nutrient giữ missing/0/partial. Tải có giới
hạn bằng repository H5. UID kiểm tra trực tiếp SDK qua AuthRepository.currentUid,
thêm generation phiên trước/sau async và picker. Tệp người dùng xuất nằm ngoài
vòng đời xóa tài khoản. Chi tiết: [h7-private-data.md](h7-private-data.md).
