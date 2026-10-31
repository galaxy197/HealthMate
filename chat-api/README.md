# HealthMate Chat API — Cloudflare Workers Free

**Candidate Gói 5, 31/10/2026:** source hiện tại đã có policy/quota server,
nhưng chưa provision identity runtime hoặc triển khai. Wrangler để
`AI_GATEWAY_ENABLED=false`; deploy source này khi chưa cấu hình sẽ trả 503
trước model. Đọc [ADR hiện tại](../docs/ai-policy-quota-adr.md) trước mọi
rollout. Các đoạn trạng thái 25/10 dưới đây là lịch sử bản đã deploy trước
Gói 5, không phải chứng nhận candidate mới đã có quyền Firestore/revocation.

Client mới gửi `X-HealthMate-Request-Id` ổn định cho hai phase. Gateway kiểm
JWT/App Check và privileged Auth lookup, policy/deletion trong transaction,
reserve quota5/50 demo theo ngày Việt Nam; client không tự tăng counter.
Identity Firestore/Auth chỉ cấp qua runtime secrets theo ADR, không đưa key
vào Flutter/repo. Không tự chạy `npm run deploy` theo hướng dẫn lịch sử khi
chưa hoàn tất điều kiện production và quyết định rollout của chủ dự án.

Kiểm tra candidate: `npm test` 48/48, `npm run check`, Wrangler dry-run qua;
REST Firestore emulator opt-in 3/3 (OAuth/IAM mock), không gọi AI thật. Chưa
chặn được hạ tầng Firebase AI cho APK cũ/client sửa thì vẫn chưa sẵn sàng
release AI. Quyền server, retention, scan/knowledge gateway và hạ tầng khóa
đường gọi trực tiếp còn là blocker; không fallback gọi Gemini né quota.

Trạng thái 25/10/2026: đã đăng nhập Wrangler bằng OAuth của chủ dự án và triển khai
Worker thật tại `https://healthmate-chat-api.healthmate-chat-api.workers.dev/v1/chat`.
Đã build APK debug với URL này và chạy benchmark model bằng dữ liệu tổng hợp.
Đã cài đè APK qua USB; người dùng xác nhận câu kiến thức chung trả lời đầy đủ,
câu hỏi mục tiêu và follow-up về đạm khớp số liệu hoặc báo thiếu dữ liệu đúng.
Các ca native mất mạng/đổi UID/lịch sử mở lại còn chưa thử thủ công.
Xem [báo cáo live](../docs/chatbot-live-qa.md).
Không bật paid, thêm thẻ hoặc tạo database; không đưa OAuth token vào source/APK.

## Luồng và giới hạn

Flutter gọi `/v1/chat` qua HTTPS với Firebase ID token và App Check token:

1. `phase=plan`: Qwen đọc câu hỏi và tối đa 6 tin gần nhất, lập JSON các nguồn
   cần đọc. Đây là kế hoạch có schema, không phải SQL/Firestore query hoặc code
   do model tự chạy. Tối đa 3 yêu cầu trong danh sách cho phép.
2. Flutter kiểm tra schema/ngày/phạm vi rồi dùng repositories của UID hiện tại.
   Chỉ gửi kết quả liên quan: dinh dưỡng, mục tiêu còn lại, nước, vận động, cân
   nặng hoặc tối đa 5 món từ catalog. Không gửi ID/email/ngày sinh/hồ sơ đầy đủ.
3. `phase=answer`: Llama 3.3 70B trả lời tiếng Việt qua SSE, system prompt tách riêng
   và kết quả tra cứu là dữ liệu. Flutter chỉ lưu khi stream hoàn tất; retry lưu
   không gọi AI lại. Lựa chọn hai model dựa trên benchmark, không phải hai provider.

`nutrition`, `remaining`, `water`, `activity`, `weight` nhận khoảng 1–7 ngày,
hai đầu bao gồm. Với weight một ngày, repository tìm cân gần nhất trong 90 ngày
kết thúc ngày đó; không gửi private note. `foods` nhận query <=80 ký tự, khẩu phần
10–1000g; dinh dưỡng được app tính từ catalog có nguồn. Không gọi nhánh USDA API
đang có lỗi parser đã ghi trong audit. Không tạo số liệu nếu thiếu món/dữ liệu.

Không tự ghi/xóa nhật ký, thay mục tiêu hoặc tư vấn điều trị. AI vẫn có thể suy
diễn sai; số liệu app được đính kèm để đối chiếu nếu đoạn tham chiếu <=2100 ký tự.
Khi dài hơn, app nhắc đối chiếu nhật ký. Kiểm thử fake không chứng minh model
thực tế luôn tuân thủ prompt; phải nghiệm thu trước khi phát hành.

## An toàn và hạn mức

- JWT RS256 kiểm tra bằng public keys Google qua `jose`: issuer/audience/expiry,
  UID, email_verified; App Check đúng project và Android app. Không có Admin
  SDK hoặc service-account key. Xác minh chữ ký không kiểm tra token bị thu hồi
  trước expiry; không thay thế Security Rules hoặc cơ chế khóa tài khoản.
- Worker không có quyền Firestore. Mọi đọc nhật ký chạy từ SDK client theo UID
  và Rules. Tuổi/hồ sơ là gate tự khai trong app; Worker không xác minh tuổi.
- Fixed planner `@cf/qwen/qwen3-30b-a3b-fp8`, answer `@cf/meta/llama-3.3-70b-instruct-fp8-fast`;
  caller không chọn model, token budget,
  system prompt hoặc tool tùy ý. Body tối đa 40KB, lịch sử 6 tin, mỗi tin <=1200
  ký tự, question <=1000. Planner 700/output 1400 token; có thời gian chờ phía app.
- Rate binding 8 request/phút/UID, 60 request/phút cho Worker theo từng Cloudflare
  location, có thể vượt ngưỡng nhẹ; **không phải trần toàn cầu chính xác**. Một
  lượt chat bình thường gọi 2 request. Không thêm database cho limiter.
- Workers Free hiện có 10.000 Neurons/ngày dùng chung tài khoản, hết hạn mức
  sẽ lỗi. Giữ Free, không prepaid credits, không thêm billing method hoặc tự
  chuyển paid. Không cam kết miễn phí vô hạn/đủ quota cho mọi quy mô.
- Không log prompt/token/health data, observability tắt, response no-store;
  không bật AI Gateway logs/cache hoặc thêm R2/KV/D1. CORS chưa mở cho web;
  hiện chỉ cho Android App Check app ID được cấu hình.
- Flutter hỏi consent trước câu đầu gửi cloud. Có chế độ Tra cứu nhật ký không
  gọi cả Cloudflare lẫn Gemini. Không chuyển dữ liệu riêng tư sang Gemini unpaid
  khi Worker lỗi/hết quota. AI text và raw user text lưu riêng theo UID như chat
  schema hiện có; không đổi Rules/index/database trong lượt này.

## Chạy kiểm tra local

Tại thư mục `chat-api`, Node 24/npm có sẵn trên máy hiện tại:

```powershell
npm ci
npm test
npm run check
npm audit
npm run build
```

`build` chỉ `wrangler deploy --dry-run`, không deploy hay gọi model. Wrangler
4.152.0 và jose 6.2.13 được pin; override undici 7.30.1 sửa advisory trong dev
dependency Miniflare. Không hạ Wrangler xuống bản cũ thiếu rate-limit binding
theo gợi ý `npm audit fix --force`. Các bước install/audit/build đã chạy lại sau
override; cần đánh giá lại tương thích khi nâng phiên bản sau này.

## Tái lập triển khai/kết nối

1. Chủ tài khoản hoàn tất signup/điều khoản trên Cloudflare. Không gửi mật khẩu,
   OTP hoặc API token trong chat. Giữ Workers Free và không nhập thẻ trả phí.
2. Tại `chat-api`, chạy `npx wrangler login`, đăng nhập và cấp quyền qua trình
   duyệt; sau đó `npm run whoami`. Không chép token CLI vào source hoặc app.
3. Xác nhận đúng tài khoản Free. Nếu tài khoản có nhiều account, chọn account
   đích rồi cấu hình account_id công khai vào file local phù hợp. Đọc lại vars
   project/app trong wrangler.jsonc; chúng là ID công khai, không phải secret.
4. Sau kiểm thử và xác nhận tài khoản sẵn sàng, triển khai `npm run deploy`.
   CLI trả hostname workers.dev. Nếu bất kỳ bước nào yêu cầu Paid/billing, dừng
   và kiểm tra thay vì bật. AI binding dùng quyền Worker, không cần AI key trong APK.
5. Dùng hostname thực để chạy/build Flutter từ gốc repo:

```powershell
flutter run --dart-define-from-file=config/chat-api.json
```

Không có define thì app báo chat tự do chưa kết nối, vẫn giữ tra cứu cục bộ và
luồng kiến thức Gemini chuẩn hóa cũ. Không cấu hình URL giả để nút trông hoạt động.
`tool/run_android.ps1` đọc file public config này và debug token từ file local
đã có. `config/chat-api.json` chỉ chứa URL công khai, không có thông tin xác thực.
Nếu App Check chặn debug build, dùng quy trình đăng ký debug token hiện có;
không bỏ xác thực trong Worker. Không lưu debug token vào source/log chia sẻ.

## Nghiệm thu trước phát hành

Dùng 20 tình huống tổng hợp trong docs/chatbot-free-evaluation.md. Kiểm tra
model thực trả JSON plan/choice hoặc response SSE đúng phiên bản binding;
Benchmark model thật và hạn chế còn lại có trong docs/chatbot-live-qa.md;
không coi kết quả benchmark là chứng minh model luôn đúng hay native E2E đã qua.
Các số “140 ngôn ngữ” hoặc “201 ngôn ngữ” trong tài liệu model khác không chứng
minh chất lượng tiếng Việt trong HealthMate. Không tuyên bố ngang MyFitnessPal
trước khi có kết quả đọc được và thời gian đo thật.

Kiểm tra native: consent chấp nhận/từ chối, follow-up, mở lịch sử/new session,
ngày và dữ liệu thiếu, nguồn lỗi, quota/429, 4G ngắt giữa stream, stop, đổi UID,
retry lưu trùng ID, mục tiêu thay phiên bản, món Việt và đề nghị sửa/ghi/y tế.
Chưa gửi nhật ký thật cho provider để thử. CPU/JWKS verification và latency của
toàn luồng native có token hợp lệ vẫn cần kiểm tra trên điện thoại. Endpoint thật
đã từ chối request thiếu/sai token bằng 401; không tạo route bỏ qua xác thực để QA.

## Nguồn chính thức

- https://developers.cloudflare.com/workers-ai/models/qwen3-30b-a3b-fp8/
- https://developers.cloudflare.com/workers-ai/models/llama-3.3-70b-instruct-fp8-fast/
- https://developers.cloudflare.com/workers-ai/features/json-mode/
- https://developers.cloudflare.com/workers-ai/platform/pricing/
- https://developers.cloudflare.com/workers-ai/platform/data-usage/
- https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/
- https://firebase.google.com/docs/auth/admin/verify-id-tokens
- https://firebase.google.com/docs/app-check/custom-resource-backend

Điều khoản provider và xử lý dữ liệu sức khỏe có điều kiện, không chỉ dựa vào
“no training”; xem thêm đánh giá và phạm vi wellness trong docs/chatbot-free-evaluation.md.
