# Giai đoạn 9 — kết nối Cloudflare thật, 25/10/2026

API: `https://healthmate-chat-api.healthmate-chat-api.workers.dev/v1/chat`.
Worker `healthmate-chat-api`, account `adfd92f2dcd7fd6171ef7c67120444fb`.
Version triển khai cuối: `b886ff1f-270d-458c-b508-fc443655651e`.

Chủ dự án tạo tài khoản và cấp OAuth Wrangler. Không nâng gói, thêm phương thức
thanh toán, prepaid credits, database hoặc dịch vụ lưu ảnh. API subscriptions trả
403 do OAuth không có Billing Read; không lấy `default_usage_model=standard`
làm bằng chứng độc lập rằng tài khoản Free. Dựa lựa chọn tài khoản Free của chủ
dự án; mọi lệnh trong lượt này không đổi billing.

## Model và lỗi đã xử lý

- Qwen `@cf/qwen/qwen3-30b-a3b-fp8` lập kế hoạch JSON, tối đa 3 nguồn đọc.
- Llama `@cf/meta/llama-3.3-70b-instruct-fp8-fast` diễn đạt đáp án tiếng Việt.
  Cả hai chạy trong Cloudflare Workers AI; không tự chuyển dữ liệu qua Gemini.
- Qwen dùng cho cả hai bước ban đầu diễn giải sai khoảng tuần và có lúc suy
  mục tiêu từ lịch sử. Llama làm planner có JSON lỗi trong lượt so sánh. Vì thế
  chọn Qwen planner + Llama answer sau benchmark, không tuyên bố một model
  hoàn hảo hoặc đạt chất lượng MyFitnessPal trên mọi câu hỏi.
- Bổ sung ngày neo tính bằng code cho hôm qua/7 ngày/tuần này, ví dụ phân biệt
  catalog với nhật ký và câu hỏi tiếp nối về mục tiêu. Hai schema foods/date
  tách biệt; server lẫn app vẫn kiểm tra giới hạn.
- Kế hoạch tương lai đúng schema bị loại bỏ, không đổi về hôm nay và không đọc
  dữ liệu khác thay thế. Sai schema/extra UID/path/đọc hơn7ngày vẫn bị chặn.
- Deployment lần đầu lỗi vì compatibility_date vượt ngày UTC của server;
  dùng 2026-10-19. Lần tiếp theo upload xong nhưng API lookup Worker trả10007;
  kiểm tra script tồn tại và retry đã thành công. Không bỏ xác thực để deploy.

## Kiểm tra thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| `npm test` | 21/21, gồm JWT ký thật bằng khóa test, project/App Check, schema, ngày và stream |
| `npm run check` | Qua syntax cho ba module Worker |
| `npm audit --omit=dev` | 0 vulnerabilities |
| `npm run deploy` | Qua, bundle49,88KiB, gzip14,81KiB, startup2ms |
| POST endpoint thật thiếu token / token sai | 401 / 401; không gọi inference |
| GET `/v1/chat` / GET `/` | 405 / 404 |
| `flutter build apk --debug --dart-define-from-file=config/chat-api.json …` | Qua45,9s, APK236.545.889bytes |
| Flutter tests/analyze gần nhất trước thay đổi config/tooling | 569/569;18info có sẵn,0warning/error; không chạy lại toàn bộ trong lượt kết nối |

APK dùng debug App Check token từ file local đã có; không ghi token vào tài liệu,
source hoặc output chia sẻ. Gradle vẫn cảnh báo plugin KGP cũ, build thành công;
không nâng dependencies ngoài scope.

Benchmark cuối chạy từ `2026-10-24T19:50:38.579Z` (25/10 giờ Việt Nam):

- 20/20 hoàn tất, chọn đúng loại nguồn và khoảng ngày theo fixture trong lượt này.
- Hai call model qua Cloudflare REST, gồm đọc plan và nhận hết SSE: thấp nhất
  1.258ms, trung vị1.891,5ms, cao nhất5.494ms. Không phải latency native E2E:
  chưa cộng Firebase token/App Check, repository Firestore và mạng điện thoại.
- Tổng usage provider báo cho lượt benchmark cuối khoảng661,10Neurons. Đây
  không phải tổng usage tài khoản/ngày, không chứng minh hạn mức đủ cho sản phẩm lớn.
- Hỏi có/không dấu, kcal, nước7ngày, tóm tắt3nguồn, mục tiêu/macros thiếu, đổi
  ngày theo hội thoại, thay món không thích,150gđậu phụ, cân gần nhất, hoạt động,
  mục tiêu tuần, ngày không có dữ liệu, tên món chứa chỉ thị, yêu cầu xóa, điều
  trị, ngày tương lai và thời tiết đều được thử.
- Đọc thủ công xác nhận mẫu cuối giữ số114kcal/12gđạm cho150gđậu phụ, không đoán
  đạm thiếu, diễn đạt đúng19–25/10 cho tuần, không theo chỉ thị đổi đạm9999g,
  không tự xóa/đưa thuốc. Một số câu còn văn phong máy móc, chưa luôn nhắc nguồn
  ước tính trong prose; app đính kèm số liệu/nguồn gốc để đối chiếu.
- Dữ liệu hoàn toàn tổng hợp; không đọc Firebase và không gửi nhật ký thật.
  Script QA giữ OAuth trong bộ nhớ; báo cáo model có nội dung fixture dưới
  `build/chat-api-live-benchmark*.json` (Git ignored), không có token.

## Nghiệm thu điện thoại

Điện thoại AAK_AN00 đã được ADB nhận lại. `adb install -r` trả Success, không
uninstall hoặc clear data; `am start -n com.example.healthmate/.MainActivity`
thành công, package lastUpdateTime25/10/2026 02:54:03. Bản đầu gặp lỗi SSE đã sửa
ở bản cài thứ hai bên dưới; không xóa dữ liệu.

Đã build/cài APK với endpoint thật. Benchmark REST riêng không chứng minh native
E2E. Kết quả do người dùng xác nhận sau bản sửa: câu kiến thức chung trả lời đầy
đủ; câu hỏi mục tiêu kcal và hỏi tiếp về đạm khớp số liệu hoặc báo thiếu dữ liệu
đúng. Như vậy luồng gọi thật có Auth/App Check và đọc dữ liệu theo app đã chạy
qua các tình huống này. Không có phép đo CPU/JWKS native riêng.
Stop/retry, mất mạng, mở lại lịch sử/session mới, quota và đổi UID trên điện
thoại chưa được nghiệm thu thủ công trong lượt này; local tests có bao phủ.
Không tạo tài khoản Firebase production hoặc route bỏ qua token chỉ để thử.

## File chính

### Sửa tiếp sau lượt thử native đầu

Người dùng thử câu hỏi kiến thức chung trên bản cài đầu: app báo "Phản hồi AI
vượt giới hạn". Đây là lỗi client, không được ghi native E2E thành công. Budget
32.000 ký tự cộng cả JSON SSE của từng token. Capture thật câu hỏi tổng hợp có
45.817byte/95events, đáp án chỉ844ký tự. Dart replay bộ đọc mới nhận đủ844ký tự.

Sửa `decodeChatEvents`: wire2MiB theo byte trước UTF-8, event16.000ký tự,
raw text16.000; giữ budget đáp án3.800. EOF thiếu DONE/stop, provider lỗi hoặc
token cutoff vẫn không được lưu. Hai regression tests kiểm tra envelope lớn
nhưng ít chữ và wire/event quá lớn.55/55tests ở ba file chatbot qua8s, format
3file qua, APK sửa build qua17,1s. Cài đè lần hai Success, package lastUpdateTime
25/10/2026 02:59:04, app đã mở. Targeted analyze3file
không lỗi/cảnh báo/info. Full analyze trước sửa import tool có19info gồm18info
cũ và1avoid_relative_lib_imports; import đã sửa sang package và kiểm tra lại.

Người dùng đã xác nhận bản cài thứ hai: "Đã trả lời đầy đủ" cho câu kiến thức
chung. Native gọi API/xác thực và hiển thị câu trả lời không còn lỗi wire budget
trong lượt này. Sau đó người dùng thử "Hôm nay còn bao nhiêu kcal so với mục
tiêu?" và tiếp nối "Còn đạm thì sao?", xác nhận "Khớp số liệu hoặc báo thiếu
dữ liệu đúng". Không suy ra một con số cụ thể từ lựa chọn này hoặc ghi các
kiểm tra offline/đổi UID/lịch sử mở lại là đã qua.

Full `flutter analyze --no-pub` cuối:18info có sẵn,0warning/error,8,9s,exit1 do
lint info. Không còn info mới ở tool replay. Không chạy lại full571tests sau
sửa SSE;55focusedchat tests là kết quả mới,569fulltests là kết quả trước sửa.

`chat-api/src/protocol.mjs`, `src/index.mjs`, `test/api.test.mjs`,
`wrangler.jsonc`, `tool/*.mjs`; `config/chat-api.json`, `tool/run_android.ps1`.
Sửa native: `lib/features/chatbot/data/cloudflare_chat_assistant.dart`,
`test/chatbot_api_test.dart`, `tool/replay_chat_stream.dart`.
Không sửa scanner, admin, Firestore Rules/schema trong lượt kết nối.

Nguồn API/model kiểm tra25/10:
[Qwen](https://developers.cloudflare.com/workers-ai/models/qwen3-30b-a3b-fp8/),
[Llama](https://developers.cloudflare.com/workers-ai/models/llama-3.3-70b-instruct-fp8-fast/),
[JSON mode](https://developers.cloudflare.com/workers-ai/features/json-mode/).
Chất lượng ở trên là quan sát benchmark, không suy ra từ quảng cáo model.
