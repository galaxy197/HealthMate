# ADR — Gói 4: vòng đời xóa tài khoản và dữ liệu liên quan

Ngày: 31/10/2026. Phạm vi: HealthMate hiện tại, giữ Firestore là database
duy nhất. Tài liệu này mô tả quyết định và giới hạn; kết quả kiểm thử thực tế
được ghi riêng trong `test-report.md` và `improvement-progress.md`.

## Bối cảnh và quyết định

Luồng cũ xóa từng collection rồi xóa Auth. Chưa có dấu trạng thái độc lập
với `users/{uid}`, nên thiết bị thứ hai, write offline hoặc bootstrap hồ sơ
có thể tạo dữ liệu lại trong hoặc sau cleanup. `owns(uid)` đồng thời kiểm
trạng thái suspended, khiến tài khoản bị khóa không thể tự dọn dữ liệu.
Cleanup cũ cũng bỏ sót Premium demo và phụ thuộc build flag khi xóa directory.

Chọn dấu xóa tại `account_deletions/{uid}`, độc lập với hồ sơ. Sau khi yêu
cầu được máy chủ xác nhận, mọi create/update sản phẩm của UID phải bị Rules
từ chối; chủ tài khoản còn quyền tối thiểu để xem tiến độ và cleanup. Không
xóa/reset tombstone từ client. Xóa user parent không mở lại quyền sử dụng.
Suspended owner vẫn có quyền yêu cầu xóa nhưng không lấy lại quyền ghi nhật ký.

Ưu tiên dài hạn là job chạy bởi identity server có quyền giới hạn. Repository
hiện chưa có hạ tầng đó; Gói 4 dùng giao diện job và phương án client có
tombstone để giảm rủi ro, không coi client là tác nhân server đáng tin cậy.
Không tự thêm Cloud Functions, Blaze, Worker binding, secret hoặc hạ tầng trả phí.

## Kiểm kê dữ liệu và chính sách

Các nhóm dưới đây bao gồm đường đọc/ghi đang có trong source, không chỉ
document parent tồn tại. Xóa Firestore document không tự xóa subcollection.
Mọi bước phải giới hạn UID, đọc từ server, lặp batch nhỏ và xác minh rỗng.

| Đường dữ liệu | Nội dung/đường ghi hiện tại | Xử lý và lý do |
| --- | --- | --- |
| `users/{uid}` | Hồ sơ, email, thông số cơ thể, cá nhân hóa, onboarding; `FirebaseHealthProfileRepository.ensureProfile/updateProfile/completeOnboarding` | Xóa sau dữ liệu con. Bootstrap create/update bị tombstone chặn, kể cả parent đã mất. |
| `users/{uid}/body_metrics/*` | Cân nặng/lịch sử; profile repository | Xóa; dữ liệu sức khỏe riêng tư. |
| `users/{uid}/meal_plans/*` | Kế hoạch, snapshots và pointer; `WellnessRepository` | Xóa trước meal_logs để tương thích guard liên kết Gói 3. |
| `users/{uid}/meal_logs/*` | Bữa đã ăn và snapshot dinh dưỡng; nutrition repository/atomic plan confirmation | Xóa; chặn mọi đường tạo/cập nhật sau tombstone, gồm retry cũ. |
| `users/{uid}/water_logs/*`, `activity_logs/*` | Nhật ký nước/vận động; các repository tương ứng | Xóa. |
| `users/{uid}/goals/*`, `daily_quests/*` | Mục tiêu, trạng thái nhiệm vụ; goals repository | Xóa. |
| `users/{uid}/nutrition_targets/*` | Lịch sử chỉ tiêu; nutrition target repository | Xóa, không giữ để tính báo cáo sau khi chủ tài khoản xóa. |
| `users/{uid}/favorite_foods/*`, `custom_foods/*`, `recipes/*`, `meal_templates/*` | Thư viện riêng, công thức và tổ hợp; food library/template repositories | Xóa; catalog dùng chung không thay thế dữ liệu thư viện riêng. |
| `users/{uid}/day_reviews/*` | Xác nhận ngày và dữ liệu tổng kết; day review repository | Xóa. |
| `users/{uid}/sleep_logs/*`, `wellness_state/*` | Giấc ngủ/timer; wellness repository | Xóa; timer đang hoạt động không được kết thúc thành log sau tombstone. |
| `users/{uid}/step_logs/*`, `wellness_preferences/*`, `energy_adjustments/*` | Bước đã đồng bộ, lựa chọn và điều chỉnh chỉ tiêu; wellness/energy repositories | Xóa; đồng bộ đến muộn bị Rules chặn. |
| `users/{uid}/data_migrations/*`, hiện có `meal_date_key_v1` | Marker/cursor thống kê và trạng thái phân vùng truy vấn Gói 6; chỉ migration đặc quyền được create/update | Xóa cùng dữ liệu riêng, sau meal logs theo inventory hiện tại; owner chỉ đọc hoặc xóa khi có deletion marker. Không giữ UID/cursor migration để tự tái tạo hồ sơ sau xóa. |
| `users/{uid}/chat_sessions/*/messages/*`, `users/{uid}/chat_sessions/*` | Câu hỏi/trả lời/lịch sử; chat repository | Xóa messages trước sessions. Không chỉ xóa session parent. |
| `users/{uid}/{collection khác}/...` | Hiện không có đường create/update ngoài các nhóm đã khai báo | Không giả định client liệt kê được collection mới/lồng sâu tùy ý. Server job cần duyệt thực tế; inventory phải cập nhật khi thêm feature. |
| `support_tickets/{ticketId}` với `uid == chủ tài khoản`, cùng `messages/*` | Báo lỗi/góp ý và toàn thread, cả trả lời admin; support repositories/web admin | Đóng băng theo trạng thái xóa tài khoản/ticket, xóa messages rồi ticket. Admin không được reply/status update sau mốc tombstone. |
| `demo_premium_accounts/{uid}` | Membership demo, transaction ID, thời hạn; premium repository | Xóa. Không phải entitlement thanh toán thật. |
| `demo_premium_transactions/{id}` với `uid == chủ tài khoản` | Phiếu mua mô phỏng 20.000 VND; premium checkout | Xóa trong cleanup được kiểm soát. Không coi dữ liệu mô phỏng là chứng từ tài chính bắt buộc giữ. Báo cáo demo sau xóa chỉ phản ánh dữ liệu còn tồn tại; không tạo sổ phụ giữ UID để lách chính sách. |
| `demo_ai_usage/{uid}/days/*`, parent `demo_ai_usage/{uid}` nếu có | Số lượt scan/chat, ngày; premium consume | Xóa mọi ngày rồi parent. Subcollection vẫn có thể tồn tại khi parent chưa từng được tạo. Write tiêu thụ lượt bị tombstone chặn. |
| `ai_gateway_usage/{uid}/days/*`, parent `ai_gateway_usage/{uid}` | Candidate Gói 5: counter chat theo ngày Việt Nam và active leases, chỉ server create/update | Xóa days, đọc server kiểm rỗng rồi xóa parent; duyệt đường days trực tiếp kể cả parent không tồn tại. Không coi counter cũ/demo là quyền gọi model. Mọi transition gateway đọc tombstone trong transaction để callback tới muộn không tái tạo scope đã xóa. |
| `ai_gateway_reservations/{uid}/requests/*`, parent `ai_gateway_reservations/{uid}` nếu có | Candidate Gói 5: request ID, UID, feature, trạng thái phase/job, ngày và timestamps/lease; không prompt/response/ảnh/token | Xóa requests, xác minh rỗng rồi parent. Không phụ thuộc parent tồn tại để tìm requests. Client không được create/update metadata đáng tin cậy, chỉ owner cleanup sau tombstone; server phải tôn trọng marker trước mọi ghi. |
| `user_directory/{uid}` | Tên/email để admin quản lý; directory sync provider | Xóa dù build hiện tại không bật admin runtime. Directory sync không được tạo lại sau tombstone. |
| `account_controls/{uid}` | Active/suspended, lý do, admin provenance | Xóa trạng thái hiện hành qua cleanup giới hạn UID. Tombstone tiếp tục chặn quyền dù control đã mất; lịch sử an ninh riêng nằm trong audit. |
| Firebase Authentication identity `uid` | Email/provider metadata, trạng thái đăng nhập | Xóa sau cleanup dữ liệu và dữ liệu app-private của thiết bị hiện tại. Auth lỗi thì giữ trạng thái chờ, cho thử lại; không thông báo đã xóa tài khoản thành công. |
| `account_deletions/{uid}` | UID là key, trạng thái, timestamps, checkpoint và phiên bản; không email/hồ sơ/nhật ký | Giữ để chặn token/write cũ tái tạo dữ liệu. Không xóa bằng client; thời hạn/purge đáng tin cậy còn bị chặn bởi hạ tầng server, xem mục lưu giữ. |
| `admin_audit/{auditId}` | `actorUid`, `entityType/entityId`, thời điểm, fields và lý do thao tác | Giữ bất biến, chỉ admin được đọc, client không update/delete. Không xóa audit để vượt kiểm thử. Không chứa snapshot nhật ký theo schema; lý do là văn bản do admin nhập nên không bảo đảm hoàn toàn không có PII tự nhập. |
| `admin_roles/{uid}` nếu chủ tài khoản là admin | Vai trò/quyền quản trị, provision bởi hạ tầng đặc quyền | Cần server thu hồi/xóa khi xóa admin identity. Không cấp quyền cho owner sửa role. Client fallback không được tuyên bố đã thu hồi role trên server. |
| `food_catalog/*`, `app_config/*` | Nội dung chung và `updatedBy`/`lastAdminOperationId` của admin | Giữ nội dung chung, không xóa theo UID. Nếu xóa admin, tham chiếu provenance đến UID cần xử lý trong chính sách audit đặc quyền; không làm mất lịch sử bằng client. |
| Support messages do admin này viết trong ticket của người khác | `authorUid`, role và text của người hỗ trợ | Không cho owner xóa ticket người khác. Đây là phạm vi server rà soát để ẩn danh danh tính hỗ trợ hoặc giữ có lý do theo chính sách; fallback chưa bảo đảm xóa mọi dấu vết admin UID. |

`chat_id_allocator` và các lệnh `.doc().id` khác chỉ cấp ID cục bộ; source
không ghi document vào collection đó. Không dựng cleanup xóa dữ liệu không có.
Ứng dụng không dùng Cloud Storage để lưu ảnh món ăn gốc theo mặc định.
Client duyệt chat/support qua document cha còn tồn tại. Các messages legacy
đã mồ côi vì parent bị xóa trước đó không được chứng minh là đã hết qua
traversal này; server cần inventory đệ quy để phát hiện và xử lý. Việc xác
minh ở checkpoint 4/5 chỉ bao phủ các đường đã biết và có thể liệt kê bằng
client, không phải chứng nhận mọi dữ liệu trên server đã bị xóa.

### Dữ liệu trên thiết bị và bản sao ngoài ứng dụng

| Nơi lưu | Chính sách/thực thi cần có |
| --- | --- |
| Meal drafts Android: file AES-GCM trong `noBackupFilesDir`, key alias `hm-draft-v1-{sha256(uid)}` | Chặn UID trước khi đợi queue, xóa file/backup và key. Chặn bền vững ở native để process mới hoặc callback cũ không ghi lại. Không chỉ dựa vào `_blocked` in-memory của `MealDraftStore`. |
| Wellness Android: `settings`, `steps`, `recordedMeals`, `sleepReminder`, scope thiết bị `active` | Đánh dấu UID đang xóa, dừng sensor service, hủy alarm/thông báo và active UID trước cleanup. Xóa các file mã hóa/key tương ứng; clear lặp lại phải thành công ngay cả khi active đã null. `setAccount(uid)`/callback sensor/boot không được kích hoạt lại UID đã chặn. |
| Firestore SDK persistence/cache và UI đang mở | Tombstone/Rules chặn ghi khi kết nối lại; app đóng luồng sản phẩm theo trạng thái xóa. Không thể dùng Rules từ xa để xóa ngay mọi bản cache trên điện thoại khác đang offline. Không mô tả chặn server write thành xóa vật lý mọi bản sao. |
| SQLite `foods` | Chỉ danh mục public local/USDA; cache từ chối private library foods. Không gắn UID, không xóa danh mục dùng chung vì một account bị xóa. |
| SQLite `recent_foods` | Có `food_id`, `last_used`, `use_count` toàn thiết bị; hiện chỉ có API `markFoodUsed`, không có caller sản phẩm trong source. Không coi đây là nhật ký đã ăn. Nếu kích hoạt lại, cần tách UID/cleanup hành vi cá nhân trước phát hành. |
| Theme preferences | Lựa chọn sáng/tối toàn thiết bị, không UID và không dữ liệu sức khỏe; giữ. |
| Chat resume và nội dung UI | `chatResumeProvider` chỉ in-memory UID/session selection và reset theo Auth. Không có history chat ghi SharedPreferences. Cần loại bỏ/đóng tác vụ của account đang xóa, không chỉ đợi Auth null. |
| Ảnh camera/picker | Payload AI được tái mã hóa loại metadata; file tạm của picker có thể còn ở thiết bị. Ảnh gốc do người dùng lưu trong thư viện không thuộc quyền xóa account HealthMate. Không tuyên bố xóa ảnh thư viện hoặc dữ liệu provider đã xử lý trước đây. |
| CSV/Excel người dùng hoặc admin đã xuất, nơi lưu do người dùng chọn | Nằm ngoài kho riêng, không tự động thu hồi khi account xóa. Thông báo giới hạn này; không tự xóa tài liệu người dùng đã lưu. |
| Log/backup/hệ thống Firebase, AI provider hoặc dịch vụ bên ngoài | Không có API app xóa mọi bản đã xử lý. Chính sách provider/hạ tầng áp dụng; không hứa xóa ngay mọi bản sao hoặc thông tin đã gửi trước đó. Không thêm log token/prompt/ảnh/health context vào job. |

## Hợp đồng job client fallback

Document có định danh ổn định là UID; không tạo job mới mỗi lần retry.
Schema v1 chỉ dùng `uid`, `schemaVersion: 1`, `executor: 'client'`, `state`,
`checkpoint` trong 0–5, `requestedAt`, `updatedAt`. Không lưu password,
credential, email, lý do y tế, danh sách món hoặc lỗi thô vào job.

Trạng thái một chiều:

1. `requested`: yêu cầu xóa đã được xác nhận ở Firestore, sản phẩm bị khóa.
2. `cleaning`: đang dọn dữ liệu; checkpoint tăng, không giảm/reset; retry
   tiếp tục trên cùng document và luôn kiểm tra máy chủ trước khi báo hoàn tất.
3. `auth_pending`: cleanup client đã đi tới bước chờ xóa Auth. Không có
   `completed` hoặc `serverVerified` do client tự chứng nhận.

Checkpoint là thông tin tiến độ **không đáng tin cậy do client ghi**. Không
được dùng giá trị này làm chứng cứ để bỏ qua việc đọc/xóa/xác minh dữ liệu
thực tế. Cả job `auth_pending` cũng có thể cần cleanup lại khi retry.
Timestamp `requestedAt` giữ nguyên; `updatedAt` do server xác nhận. Rules
không cấp quyền xóa/reset job để mở lại tài khoản hoặc tạo job cho UID khác.

Yêu cầu xóa phải gắn với identity Auth thực và xác thực lại gần đây. Tài
khoản suspended có quyền xóa tối thiểu, không có quyền ghi sản phẩm. Không
dùng boolean `reauthenticated` trong request như bằng chứng. Client mất kết
nối trước khi tombstone được server xác nhận thì không coi tài khoản đã khóa.

Kill app giữa batch không hủy tombstone. Lần mở lại cung cấp tiếp tục xóa
hoặc đăng xuất; không quay về onboarding để tạo hồ sơ mới. Client cleanup
không chạy khi app chết, không tự tiếp tục trên server và không có SLA hoàn
tất. Đây là giới hạn sản phẩm phải hiển thị trung thực.

Nếu dọn dữ liệu xong nhưng Auth delete lỗi, giữ `auth_pending` và có thông
báo đúng phần còn lại; phải xác thực lại rồi thử tiếp. Ngay cả khi Auth
delete trả thành công, client không còn quyền ghi job sau đó; job vẫn ở
`auth_pending`. Không tự suy rằng mọi tài nguyên đã được server chứng nhận
xóa sạch từ việc Auth hiện null hoặc document parent không còn.

## Hợp đồng server job cần provision trước production

Đây là yêu cầu cho implementation tương lai, **không phải endpoint đã chạy**:

- Nhận request có ID ổn định và Auth bearer; kiểm signature/issuer/audience/
  expiry của ID token bằng SDK tin cậy, đồng thời kiểm revoked/disabled và
  đối chiếu UID server lấy từ token. Không nhận UID tùy ý từ body làm quyền.
- Xác minh `auth_time` thật của token với clock server, tối đa 5 phút kể từ
  reauthentication và không chấp nhận thời gian tương lai. Chỉ kiểm `iat`
  hoặc refresh ID token không chứng minh user vừa xác thực lại. Kiểm App
  Check token đúng app/project, kích thước request và rate limit phù hợp.
- Suspended không tự động cấm quyền xóa; kiểm identity khác với account
  product access. Job một chiều, idempotent theo UID; hai tác nhân không
  thực thi cạnh tranh không kiểm soát. Cần lease/attempt và retry/backoff.
- Tạo tombstone trước cleanup; server identity giữ quyền tối thiểu theo
  inventory. Credential chỉ ở runtime/secret manager/identity được cấp,
  không đưa service-account JSON/Admin SDK key vào Flutter hay repository.
  Có quyền đọc/xóa health data để cleanup không đồng nghĩa được log/export nó.
- Mỗi batch cập nhật checkpoint đáng tin cậy, xử lý subcollections không
  có parent, kiểm rỗng từ server, và rà soát collection ngoài allowlist thay
  vì lặng lẽ báo xong. Checkpoint client không được tin hoặc nhập thẳng làm
  checkpoint server. Kiểm kê mới phải được duyệt khi thêm feature.
- Thu hồi quyền admin/session theo chính sách, xử lý Auth delete với identity
  server, rồi xác minh Auth identity không còn và mọi phạm vi phải xóa đã
  trống. Chỉ server được cấp trạng thái `completed` với bằng chứng phiên bản
  inventory và thời gian xác minh. Đó sẽ là schema/rollout riêng, không thêm
  trường `completed` client có thể tự ghi trong schema fallback v1.
- Phân biệt lỗi có thể retry, Auth đã mất nhưng còn data, data đã mất nhưng
  Auth còn, tài nguyên cần admin review. Báo mã lỗi hữu hạn, không lưu token,
  password, prompt, ảnh, text support hay health record vào diagnostics.
- Cleanup và retention run phải có audit bảo mật tối thiểu riêng, giới hạn
  truy cập, không làm thay đổi/xóa lịch sử `admin_audit` cũ để che thao tác.

Hạ tầng đang có: Firebase client Auth/Firestore và Worker `chat-api` chỉ
xác minh token với public signing keys và gọi AI. Worker ghi rõ không có
Admin SDK/service-account secret/Firestore access; `verifyIdentity` kiểm
`auth_time` có định dạng hợp lệ nhưng chưa áp dụng tuổi xác thực 5 phút hoặc
kiểm revocation cho deletion. Không tái sử dụng nó thành deletion endpoint
bằng cách thêm cờ tin client. Repo không có server deletion worker/job được
provision; Firebase config hiện chỉ có Firestore/Hosting và emulator.

## Thời hạn lưu giữ và blocker phải công khai

- Health records, hồ sơ, support của chính account, Premium demo/usage và
  directory là dữ liệu phải xóa trong cleanup; không có thời hạn giữ mặc định
  sau yêu cầu. Có thể còn trong lúc cleanup chưa hoàn tất, phải báo chờ.
- Candidate Gói 5–6 bổ sung gateway days/requests/lease parent và migration
  markers vào cùng inventory phải xóa. Repository thực tế duyệt trực tiếp
  hai subcollection gateway, xác minh rỗng rồi xóa parents; `_verifyEmpty`
  kiểm lại children/parents cùng `data_migrations` trước Auth. Không có purge
  metadata gateway tự động khi account còn hoạt động; thời hạn request-ID
  idempotency và job retention vẫn cần quyết định/hạ tầng server. Không đặt
  TTL tùy ý làm ID cũ được gọi model lại hoặc gọi đó là đã purge production.
- Tombstone tối thiểu được giữ **không thời hạn tự động trong fallback**,
  vì chưa có server chứng minh thu hồi token/offline writes, hoàn tất job và
  thực thi purge an toàn. Không đặt TTL tùy tiện rồi cho UID hồi sinh. Giữ
  UID/trạng thái/timestamps/checkpoint là vẫn giữ metadata; phải nói rõ.
- `admin_audit` hiện bất biến, không có lịch purge tự động hoặc thời hạn
  vận hành đã được phê duyệt trong repo. Gói này giữ để truy vết an ninh,
  hạn chế truy cập và ghi blocker retention thay vì bịa thời hạn pháp lý.
  Chính sách server phải đặt thời hạn có lý do, ví dụ điều tra/an ninh,
  quy trình ẩn danh UID, xử lý legal hold nếu thực sự có, và xóa theo lịch.
- Admin provenance/role hoặc messages trong ticket người khác cần quy
  trình đặc quyền; không thể bảo đảm mọi dấu vết admin UID biến mất bằng
  owner cleanup. Tránh quảng cáo fallback là xóa mọi dữ liệu vĩnh viễn.
- Không phát hành production như đã có server job bền vững khi những
  blocker identity, inventory và retention này chưa được xử lý. Triển khai
  Rules/client phải phối hợp, có phương án hỗ trợ tài khoản ở trạng thái dở.

Không có migration production, xóa tài khoản thật, cấp quyền server, triển
khai Firebase/Worker hay thay billing được thực hiện bởi tài liệu này.

## Các lớp nghiệm thu cần phân biệt

Rules primitives cần chứng minh identity/UID isolation, chặn viết đồng thời
và write offline sau tombstone, owner suspended cleanup, job một chiều,
Premium/support/admin reply/directory guards. SDK integration cần chứng minh
batch/retry/kill tương đương tạo context mới, bootstrap không tái tạo hồ sơ,
cleanup đầy đủ, Auth delete lỗi đúng trạng thái. Unit/widget/fake native
chứng minh thứ tự dừng tác vụ/clear, lỗi và retry UI; không thay thế native
Android E2E. Server job chưa provision thì ghi rõ chưa nghiệm thu job/E2E
server hoàn chỉnh, dù Rules hoặc client emulator tests xanh.

SDK integration của candidate đã qua 8/8 ca trên Auth/Firestore Emulator
(theo kết quả kiểm thử Gói 4). Kết quả này không chứng nhận native Android,
production hoặc server job; xem báo cáo kiểm thử để biết môi trường và log.

## Bổ sung inventory Gói 8 — 31/10/2026

`support_usage/{uid}` là metadata giới hạn tần suất tạo ticket (ngày/count/
lastTicketId/timestamp), không phải sổ audit phải giữ. Xóa trực tiếp theo UID
sau tombstone, cùng giai đoạn cleanup metadata; `_verifyEmpty` kiểm document
không còn trước Auth. Không cho owner xóa/reset trong sử dụng bình thường.
SDK deletion fixture có counter để xác minh cleanup thực, không chỉ kiểm
allowlist. Không tạo retention job/TTL mới; marker và audit vẫn giữ theo các
giới hạn đã nêu. Không tuyên bố server deletion job hoàn tất từ thay đổi này.
