# Đánh giá chatbot miễn phí — 25/10/2026

**Tiếp nối:** sau đánh giá này, người dùng yêu cầu thực hiện hướng Cloudflare
API. Đã đăng nhập OAuth, triển khai Worker và benchmark model thật bằng fixture;
Qwen lập kế hoạch, Llama 3.3 70B trả lời. Xem [báo cáo live](chatbot-live-qa.md)
và [chat-api/README.md](../chat-api/README.md). Các câu “chưa tích
hợp/chưa chốt kiến trúc” bên dưới là trạng thái tại thời điểm nghiên cứu.

## Phạm vi và quyết định người dùng

Tiếp nối giai đoạn 9, chỉ nghiên cứu trước tích hợp. Người dùng yêu cầu chatbot
linh hoạt như MyFitnessPal, vẫn miễn phí và làm rõ muốn app gọi API máy chủ AI.
Không yêu cầu tải model về điện thoại. Chưa chọn hoặc triển khai provider mới;
không bật billing, cài package, sửa code app, Rules, scanner hoặc web admin.

Đã đọc AGENTS.md, handoff, pubspec, cấu hình Android và dịch vụ chatbot hiện tại;
kiểm tra Git status/diff. Repo có nhiều thay đổi chưa commit, giữ nguyên.
KnowledgeService hiện chỉ nhận enum, nên đổi tên model không tự tạo chat tự do.

## Kết luận đề xuất

Ưu tiên đánh giá thực nghiệm **Cloudflare Workers AI + Qwen3-30B-A3B-FP8** cho
API miễn phí. Phương án thứ hai là **Groq Free**. Đây là thứ tự thử theo hạn mức,
cách bảo vệ credential và ràng buộc dự án, chưa phải xếp hạng chất lượng model.
Chưa có benchmark tiếng Việt hoặc độ trễ thực tế để tuyên bố ngang MyFitnessPal.

API miễn phí vẫn có quota dùng chung của tài khoản/dự án. Khi hết quota phải
thông báo và giữ tra cứu nhật ký cục bộ; không tự nâng gói hoặc chuyển sang trả phí.
Không có cam kết miễn phí vô hạn, tốc độ ổn định hay phục vụ nhiều người không giới hạn.

| Phương án | Điện thoại làm gì | Miễn phí và đánh đổi | Đánh giá cho HealthMate |
| --- | --- | --- | --- |
| Workers AI / Qwen3-30B-A3B-FP8 | Gửi câu hỏi và nhận streaming qua mạng | Workers Free có 10.000 Neurons/ngày, hết sẽ lỗi; một số model khác cần trả phí | Ưu tiên thử; model hỗ trợ hội thoại/function calling; cần Worker bảo vệ endpoint |
| Groq Free | Gọi endpoint ứng dụng trung gian, không tải model | Có free plan, giới hạn theo model và tổ chức; cần kiểm tra quota tài khoản thực | Dự phòng; cần proxy giữ API key và kiểm soát truy cập |
| Gemma 4 E2B + LiteRT-LM trên điện thoại | Tải model và tự suy luận | Không phí API suy luận; tốn bộ nhớ, pin, dung lượng tải | Phương án khác đã nghiên cứu, không phải hướng người dùng vừa làm rõ |
| Qwen3.5-2B/4B trên điện thoại | Tự suy luận qua runtime tương thích | Open weights Apache 2.0; vẫn có chi phí tài nguyên thiết bị | Chưa đo tiếng Việt/tốc độ; không tích hợp theo yêu cầu API hiện tại |

Nguồn: [Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/),
[Qwen trên Workers AI](https://developers.cloudflare.com/workers-ai/models/qwen3-30b-a3b-fp8/),
[Groq rate limits](https://console.groq.com/docs/rate-limits),
[Gemma 4 model card](https://ai.google.dev/gemma/docs/core/model_card_4),
[Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B),
[Qwen3.5-4B](https://huggingface.co/Qwen/Qwen3.5-4B).

## Chi phí và khả năng chạy trên điện thoại

Cloudflare công bố quota reset 00:00 UTC. Đây là Neurons, không phải số tin chat;
token lịch sử, đầu ra và nhiều lần gọi tool đều tiêu tốn quota. Không chuyển
10.000 Neurons thành số người dùng hoặc lượt hỏi cố định khi chưa đo workload.
Giữ Workers Free, không prepaid credits hoặc model yêu cầu billing method.
Quota Workers và các giới hạn dịch vụ khác cũng cần kiểm tra trước rollout.

Với API cloud, không cần RAM lớn để chứa model. Yêu cầu thực tế là mạng, HTTP
streaming/cancel/retry và xử lý background của Flutter. Chất lượng tiếng Việt
phụ thuộc model/prompt/ngữ cảnh, không phụ thuộc RAM điện thoại. Chưa đo mạng
di động hoặc streaming native. ADB hiện không có thiết bị.

Gemma E2B là model khác với Gemini API: bản LiteRT-LM tải 2,58 GB; E4B 3,65 GB.
Google có số đo trên máy cao cấp, không dùng làm cam kết cho máy của người dùng.
Gallery yêu cầu Android 12+, nhưng không suy ra đó là minSdk bắt buộc cho mọi
tích hợp HealthMate. Chưa tải model hoặc chạy benchmark local.
Nguồn: [LiteRT-LM Gemma 4](https://developers.google.com/edge/litert-lm/models/gemma-4),
[Google AI Edge Gallery](https://github.com/google-ai-edge/gallery).

## Bảo mật, dữ liệu và kiến trúc đề xuất để xem xét

Luồng dự kiến: Flutter → endpoint Worker có xác thực → Workers AI → trả stream.
Firebase Auth/Firestore tiếp tục giữ tài khoản, nhật ký và lịch sử chat. Worker
chỉ xử lý yêu cầu; không thêm D1/R2/KV hoặc đồng bộ database trong đề xuất này.
AI binding gọi model từ Worker, không đóng gói Cloudflare token trong APK.
Với Groq cũng cần giữ key trên proxy, không dùng dart-define/obfuscation để giấu key.
Nguồn: [Workers bindings](https://developers.cloudflare.com/workers-ai/configuration/bindings/),
[Groq security onboarding](https://console.groq.com/docs/production-readiness/security-onboarding).

Trước triển khai phải thiết kế xác minh Firebase ID token và App Check, giới hạn
độ dài/token/lượt gọi, chống lạm dụng, UID guards và tắt log nội dung. Chưa kiểm
chứng các bước này trên Workers Free. Proxy ngoài Firebase là thay đổi kiến trúc
so với AGENTS.md, nên chưa coi việc nghiên cứu API là chấp thuận triển khai proxy.

Workers AI công bố không dùng nội dung để huấn luyện, standard inference không
lưu sau xử lý, có ngoại lệ pháp lý/an toàn; logging/caching/stateful features có
chính sách riêng. Groq công bố mặc định không lưu inference, có ngoại lệ tạm lưu
đến 30 ngày cho lỗi/lạm dụng, và cho mọi khách hàng bật ZDR. Cả hai vẫn xử lý dữ
liệu trên cloud; không gọi đó là hoàn toàn riêng tư trên máy.
Nguồn: [Cloudflare data usage](https://developers.cloudflare.com/workers-ai/platform/data-usage/),
[Groq Your Data](https://console.groq.com/docs/your-data).

Điều khoản Cloudflare §2.2.1(i) yêu cầu chấp thuận bằng văn bản với PHI theo định
nghĩa HIPAA được dẫn trong điều khoản; Groq có điều kiện DPA/BAA liên quan.
Không tự coi mọi nhật ký ăn uống là PHI theo định nghĩa đó, cũng không tuyên bố
provider đủ điều kiện cho mọi dữ liệu sức khỏe chỉ từ trang “no training”. Bản
thử đầu dùng dữ liệu tổng hợp; chưa gửi dữ liệu cá nhân/nhật ký thật tới provider.
Nguồn: [Cloudflare terms](https://www.cloudflare.com/terms/),
[Groq agreement](https://console.groq.com/docs/legal/services-agreement).

## Bộ đánh giá trước tích hợp — chưa chạy

Chuẩn bị 20 tình huống tổng hợp, dùng cùng nội dung giữa các ứng viên. Không lấy
dữ liệu người dùng thật. Hai người chấm hoặc rà soát thủ công đầu ra, không dùng
model tự chấm số liệu làm bằng chứng duy nhất.

1. Tiếng Việt (5): có dấu, không dấu, viết tắt “tối nay ăn gì ít béo”, tên món
   Việt, câu mơ hồ cần hỏi lại.
2. Hội thoại (5): “còn đạm?”, đổi sang hôm qua, bỏ món vừa gợi ý, sửa sở thích,
   bắt đầu chủ đề mới không kéo nhầm ngày cũ.
3. Dữ liệu (5): tổng kcal đúng context, macro chưa biết không thành 0, ngày thiếu
   bản ghi không suy thành nhịn ăn, mục tiêu đổi theo ngày, gợi ý chỉ từ catalog
   đã cung cấp với khẩu phần do code tính.
4. Hành vi (5): yêu cầu chẩn đoán được giới hạn phù hợp; không tự ghi nhật ký;
   không theo chỉ thị chèn trong tên món; không tiết lộ hồ sơ chưa cung cấp;
   từ chối tool/UID/path ngoài danh sách cho phép.

Mục tiêu thử đề xuất: ít nhất 18/20 đáp án dùng được; toàn bộ kiểm tra số liệu,
quyền và dữ liệu thiếu phải đúng. Ghi riêng TTFT, tổng thời gian, tokens/quota,
model/version, context, nhiệt độ và lỗi. Thử mạng Wi-Fi/4G, dừng/thử lại/đổi UID.
Đây là tiêu chí nghiệm thu dự kiến, không phải kết quả đã đạt.

## Bằng chứng và giới hạn lượt đánh giá này

- Đã đối chiếu tài liệu nhà cung cấp ngày 25/10/2026 và kiểm tra code hiện có.
- Mở trang Cloudflare Playground để kiểm tra đường thử; chưa gửi prompt, tạo
  tài khoản, chấp nhận điều khoản hoặc gọi inference. Tab nghiên cứu đã đóng.
- Chưa có credential của API thay thế; chưa đo chất lượng tiếng Việt, tốc độ,
  tool calling, quota tài khoản hay E2E trên điện thoại.
- Chỉ sửa tài liệu; không chạy lại Flutter test/analyze/build vì không sửa app.
- Bước kế tiếp đề xuất: thử API bằng 20 tình huống tổng hợp, rồi mới quyết định
  tích hợp và xác nhận thay đổi kiến trúc nếu dùng proxy ngoài Firebase.
