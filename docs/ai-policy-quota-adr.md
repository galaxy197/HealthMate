# ADR — Gói 5: AI policy và quota tại gateway tin cậy

Ngày 31/10/2026. Trạng thái: candidate local, **chưa triển khai và chưa sẵn
sàng production AI**. Không provision identity/credential, thay billing,
deploy Worker/Firebase hoặc gọi model thật trong gói này.

## Quyết định và quyền hạ tầng còn thiếu

Mở rộng Worker `chat-api` hiện có, giữ Firestore là database duy nhất.
Không thêm Cloud Functions/Blaze, PostgreSQL, Durable Objects hoặc provider
AI mới. Gateway đọc policy và đặt quota bằng Firestore REST transaction
với identity server; không dùng bearer token của client làm quyền ghi quota.

Worker trước đây chỉ kiểm chữ ký ID token/App Check và không có quyền
Firestore. Candidate cần identity runtime có các quyền đọc policy, đọc/ghi
quota và tra cứu trạng thái Auth hiện hành (`firebaseauth.users.get`).
`TrustedFirestore` triển khai OAuth service-account assertion RS256,
`https://oauth2.googleapis.com/token`, scopes datastore + identitytoolkit.
Private key/email chỉ nhận qua runtime secrets; không có giá trị secret
thật trong source, app, cấu hình Wrangler hoặc fixture. OAuth token ngắn hạn
được cache nội bộ đến trước hết hạn, không log. Nên ưu tiên federation/token
broker ngắn hạn được cấp đúng phạm vi khi có hạ tầng; candidate chưa có nó.

Biến runtime:

- `AI_GATEWAY_ENABLED='true'`: bật rõ ràng sau khi provision/review.
- `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`:
  identity runtime (PKCS8), tuyệt đối không commit. Chưa cấp trong lượt này.
- `FIREBASE_PROJECT_ID`, `FIREBASE_PROJECT_NUMBER`,
  `FIREBASE_ANDROID_APP_ID`: vẫn phải đúng app/project được cho phép.
- `AI_GATEWAY_PREMIUM_DEMO='true'`: chỉ bật nếu muốn entitlement mua mô
  phỏng hiện có được dùng để tăng hạn mức demo. Mặc định false.

Wrangler candidate đặt hai cờ gateway/demo thành false. Thiếu flag,
credential, IAM hoặc không đọc được policy thì 503 trước model call; không
fallback sang đường gọi AI không quota. IAM server thường bỏ qua Security
Rules: Rules không thay thế least privilege cho identity đặc quyền. Quyền
Firestore theo IAM không tự giới hạn được từng document path như Rules;
cần review project/database isolation, credential custody và đường mã được
phép chạy trước rollout. Không tuyên bố đã có least-privilege provisioning.

## Hợp đồng client và policy

`POST /v1/chat` giữ body version 1 với phase `plan` và `answer`. Bắt buộc
header `X-HealthMate-Request-Id`: 16–80 ký tự `[A-Za-z0-9_-]`, ID ngẫu nhiên
ổn định cho một lượt chat, dùng chung hai phase. UID luôn lấy từ token,
không chấp nhận UID/model/quota do body chọn. Một ID khác UID không chiếm
reservation của người kia. ID đã gửi phase không được tự gọi model lại:
409 `request_already_sent`; client không retry bằng ID mới âm thầm.

Trước reserve: kiểm JWT Auth đúng issuer/audience/expiry/email và App Check
đúng project/app; sau đó dùng privileged Auth lookup kiểm account tồn tại,
không disabled, email hiện vẫn verified, và `auth_time >= validSince`.
`auth_time` và `validSince` cùng đơn vị giây epoch; refresh token mới không
tự coi là xác thực lại. Chữ ký hợp lệ không chứng minh chưa revoke. Lookup
được làm lại trước phase claim sau các bước chờ. Không cache kết quả active
để bỏ qua revoke cho request tiếp theo. Vẫn có cửa sổ từ lần lookup cuối
đến external model call; không hứa thu hồi nguyên tử qua hai dịch vụ.

Reserve và claim đọc trong cùng transaction: deletion marker, account
controls, runtime config, profile, entitlement, quota và reservation.
Suspended/deleting, maintenance, chatbot off hoặc thiếu config đều bị chặn.
Profile chỉ cần ngày sinh tối thiểu 18 tuổi và dấu hoàn thành onboarding;
đây vẫn là dữ liệu tự khai, không phải bằng chứng tuổi được xác minh.
Claim kiểm lại policy nên marker xuất hiện giữa reserve/claim sẽ chặn call.
Marker sau call không thể thu hồi request đã tới provider, nhưng finish
không được ghi lại usage/reservation đã cleanup sau tombstone.

## Firestore quota và trạng thái

Server-only create/update:

| Đường | Nội dung tối thiểu |
| --- | --- |
| `ai_gateway_usage/{uid}` | Map tối đa 2 active request leases, updatedAt |
| `ai_gateway_usage/{uid}/days/{yyyy-MM-dd}` | UID, ngày Việt Nam UTC+7, chats, updatedAt |
| `ai_gateway_reservations/{uid}/requests/{requestId}` | UID, feature `chat`, requestId, dayKey, state, trạng thái phase, timestamps và leaseUntil |

Không lưu prompt, câu trả lời, token, health context hoặc ảnh trong quota.
Các timestamp gateway là số nguyên milliseconds từ clock server; day key
UTC+7 độc lập timezone do client gửi. Counter + reservation + active lease
được commit nguyên tử: hai thiết bị tranh lượt cuối tối đa một reserve mới.
Retry cùng ID trả reservation cũ, không tăng counter. Parent active map
giới hạn concurrency cùng UID qua cả biên ngày; slot cũ hết hạn sau 120s.
Mỗi claim phase gia hạn slot 120s; model startup 40s, stream 40s, policy
transport 8s mỗi request. Đây là lease cho lời gọi do gateway quản lý,
không chứng minh provider đã dừng xử lý sau timeout/cancel.

Free: 5 chat/ngày. Nếu server bật demo và membership hiện có hợp lệ
`mode=demo`, đúng plan, thời hạn 30 ngày còn hiệu lực: 50 chat/ngày.
Demo receipt không phải chứng từ thanh toán thật; client có thể tạo qua
quy trình demo được Rules cho phép. Không mô tả entitlement demo là doanh
thu thật hoặc quyền Premium thương mại đáng tin cậy. Scanner chưa có route
gateway nên không tạo scan reservation; UI phải nói rõ scan chưa sẵn sàng.

Trạng thái:

- `reserved`: đã tính một lượt, chưa claim phase plan.
- `sent`: claim đã commit trước model call. Plan/answer có trạng thái
  `pending|sent|completed|failed|unknown`; answer chỉ sau plan completed.
- `completed`: answer stream kết thúc với marker `[DONE]` hợp lệ và finish
  đã commit. Không lưu answer để replay sau mất ACK.
- `failed`: lỗi xác định như provider 429 hoặc phản hồi model không hợp lệ.
- `unknown`: timeout, client hủy, stream cụt, lỗi mạng hoặc không thể xác
  định provider xử lý đến đâu. Không tự gọi lại model cho phase đó.

Mọi reservation đã commit đều **giữ lượt**, kể cả chưa gửi/failed/unknown;
không refund tự động vì tránh double-spend khi mất ACK. Lease hết hạn giải
phóng khả năng xử lý request mới nhưng không hoàn counter. Cần UX công khai
chính sách bảo thủ này; không hứa exactly-once với model API ngoài transaction.
Mất ACK reserve có thể thử lại cùng ID; mất ACK claim có thể để state sent
dù model chưa gọi. Finish commit lỗi có thể giữ sent; không suy thành success.

Model/token/prompt server kiểm soát: giữ model router/answer hiện có, không
nhận tên model từ app; max tokens 700/1400, request 40KB + body deadline 8s,
history/result giới hạn từ protocol, output stream 64KB + `[DONE]`. Stream
lỗi không trả provider diagnostics. Per-user/global Cloudflare rate binding
là giới hạn theo location và có tính xấp xỉ; không gọi là trần toàn cầu.
Quota chính xác nằm ở Firestore transaction, không ở rate binding này.

## Quyền riêng tư, cleanup và retention

Không chuyển ảnh scanner hoặc hồ sơ đầy đủ qua Cloudflare. Chat vẫn chỉ
gửi context đã được luồng consent và lookup hiện tại cho phép; gateway
không tự đọc nhật ký để đưa vào model. Đọc profile eligibility không gửi
profile/DOB/UID vào model. Không log exception thô chứa health/token.

Root candidate Rules phải chặn client tạo/update counter/reservation và
chỉ cho owner cleanup sau tombstone; thêm hai cây gateway vào inventory
xóa, kể cả days/requests tồn tại khi parent không có. Mọi server transition
đọc tombstone trong transaction để không tái tạo dữ liệu sau cleanup.
Metadata request IDs/counters không có purge job tự động. Cần chính sách
retention idempotency/cửa sổ retry được duyệt và job server cleanup trước
production; không tự đặt TTL khiến request cũ replay được hoặc UID hồi sinh.

## Đường AI trực tiếp và điều kiện phát hành

Candidate Flutter chặn gọi Firebase AI trực tiếp mặc định, giữ đường nhập
thủ công/local khi scanner hoặc knowledge AI chưa có gateway tương ứng.
Đây không tự chặn APK cũ/client bị sửa gọi Firebase AI project trực tiếp.
Chủ hạ tầng phải vô hiệu đường provider trực tiếp hoặc cấu hình quyền/API
phù hợp để nó không né gateway, rồi kiểm tra trên app/project thực. App Check
chứng minh app, không tự chứng minh đã reserve quota. Không nhúng shared
secret vào Flutter để thay enforcement. Chưa có bằng chứng hạ tầng chặn
đường trực tiếp thì **Gói 5 chưa đạt production AI** dù local tests xanh.

Chưa provision/deploy server identity, chưa xác minh IAM thật/OAuth thật,
Auth revoke thực trên project production, Workers AI thật, free-tier còn
bao nhiêu hoặc release Android. Firestore transaction/lookup phát sinh reads,
writes, Auth API requests và Worker/AI usage theo bảng giá/hạn mức hiện hành;
không hứa miễn phí vô hạn, không bật billing trong gói này. Người sở hữu
cần quyết định identity, quyền, retention và chi phí từ bản candidate cụ thể.

## Kiểm chứng local và tài liệu chính thức

Node default suite hiện 48/48: JWT/App Check sai; revoked/disabled/deleted
và malformed lookup qua mocked transport; race lượt cuối, request ID,
lost reserve/claim ACK, provider timeout/429, stream cụt/cancel, day boundary,
policy/deletion và fail closed khi chưa cấu hình. Test model dùng stub.
Adapter OAuth ký bằng RSA fixture sinh trong RAM, không dùng credential thật.

Opt-in `test/firestore.integration.mjs`: 3/3 trên emulator Firestore thật,
~16s; chạy chính adapter production REST begin/batchGet/commit/rollback,
fetch rewrite chỉ tới `127.0.0.1:8080`, project `demo-healthmate-gateway`,
UID ngẫu nhiên, không reset. Hai client adapter tranh lượt cuối/phase,
idempotency và tombstone chặn late finish. OAuth/IAM ở fixture là mock;
không gọi đó là nghiệm thu IAM/revocation server production.

Đã đọc HTTP 200 ngày 31/10/2026 trước chọn API:

- [Admin accounts lookup và quyền firebaseauth.users.get](https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/lookup)
- [UserInfo validSince (giây epoch), disabled](https://cloud.google.com/identity-platform/docs/reference/rest/v1/UserInfo)
- [OAuth service-account JWT RS256/token endpoint](https://developers.google.com/identity/protocols/oauth2/service-account)
- [Firestore beginTransaction](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/beginTransaction)
- [Firestore batchGet](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/batchGet)
- [Firestore commit](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/commit)
- [Firestore rollback](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/rollback)
- [Cloudflare rate limiting binding và giới hạn theo location](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)
