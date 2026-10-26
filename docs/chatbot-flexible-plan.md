# Chatbot linh hoạt theo nhật ký — phương án cần chốt25/10/2026

**Cập nhật quyết định:** người dùng chọn vẫn miễn phí, làm rõ muốn gọi API cloud
và sau đó yêu cầu thực hiện phương án Cloudflare. Đã OAuth Wrangler, triển khai
Worker, benchmark model thật và build APK với URL. Qwen lập plan, Llama 3.3 70B
trả lời trong cùng dịch vụ; xem [báo cáo live](chatbot-live-qa.md). Native E2E còn chờ USB. Không
chấp thuận hoặc bật Gemini billing. Xem [setup thực tế](../chat-api/README.md)
và [đánh giá phương án](chatbot-free-evaluation.md). Phần Gemini bên dưới là lịch
sử nghiên cứu, không phải provider đã chọn cho hội thoại tự do.

Người dùng yêu cầu linh hoạt như MyFitnessPal. Bản10chủ đề chưa đạt yêu cầu
này. Tài liệu chuẩn bị quyết định kiến trúc/phí; chưa thay code chatbot, bật
billing, gửi dữ liệu cá nhân tới AI, triển khai hoặc thay dữ liệu production.

## Kết quả cần đạt

1. Nhập câu hỏi tự do bằng tiếng Việt, không phải map sang10enum/chọn mẫu câu.
2. Nhớ ngữ cảnh các lượt gần nhất: “còn đạm thì sao?”, “đổi sang hôm qua”,
   “tôi không thích món đó, có món khác không?”.
3. Đọc số liệu thật khi cần: kcal/macros còn lại, so sánh ngày/tuần với mục tiêu,
   giải thích tiến độ; thiếu dữ liệu phải nói thiếu.
4. Gợi ý món theo phần còn lại, sở thích người dùng vừa nêu và nguồn món có
   dinh dưỡng. Tính khẩu phần bằng code từ nguồn; không khẳng định biết thực phẩm
   đang có trong nhà hoặc cân được món từ ảnh.
5. Không tự ghi/xóa nhật ký, đổi mục tiêu, chẩn đoán hoặc kê chế độ ăn điều trị.

## Phương án phù hợp stack hiện có

Flutter → Firebase AI Logic → Gemini với hội thoại nhiều lượt và function
calling. Phần mềm của HealthMate kiểm tra tool request, tự gắn UID từ session,
đọc repository rồi trả dữ liệu tối thiểu cho model. Gemini không có quyền đọc
Firestore trực tiếp và không được tạo truy vấn tùy ý.

Các tool chỉ đọc dự kiến:

- getNutritionSummary: tổng và mức độ đủ dữ liệu trong khoảng ngày hợp lệ.
- getNutritionTargets: mục tiêu đã đặt, đúng phiên bản theo ngày.
- getWaterActivitySummary: dữ liệu nước/phút vận động được yêu cầu.
- getWeightTrend: bản ghi cân nặng và thời điểm, không gửi hồ sơ đầy đủ.
- findFoodOptions: danh mục/thư viện riêng khi người dùng yêu cầu gợi ý món;
  chỉ trả tên/định lượng/dinh dưỡng/nguồn của một danh sách nhỏ.

Không có UID/path/query trong tham số model. Mỗi tool kiểm tra tên, kiểu, ngày,
đơn vị, giới hạn range/result và UID hiện tại trước/sau await. Mặc định tra7ngày;
khoảng dài hơn chỉ lấy khi được hỏi rõ và vẫn giới hạn90ngày hiện có.

System prompt, câu người dùng, lịch sử và tool result tách role. Tool data là
dữ liệu không đáng tin về mặt chỉ thị (kể cả tên món), không được ghi đè system.
Số liệu hiển thị lấy từ phép tính app; phần lời giải thích/gợi ý từ Gemini có
nhãn AI. Giữ streaming/stop, retry không nhân bản và guards đổi UID.

Đặt giới hạn số lượt tool/model cho một câu, số token đầu vào/đầu ra, cửa sổ
lịch sử gần (ban đầu tối đa6tin nhắn), số tin mỗi phiên và thời gian chờ.
Không gửi email, UID, ngày sinh, toàn bộ profile hoặc lịch sử không liên quan.
Hỏi người dùng đồng ý ngay trong app trước khi gửi câu tự nhập, lịch sử gần
và dữ liệu nhật ký/mục tiêu có liên quan cho Google. Đồng ý không thay thế
điều kiện xử lý dữ liệu của provider.

## Quyết định về Gemini hiện tại

Project đang dùng Spark/Gemini Developer API unpaid. Điều khoản hiện hành
cấm gửi sensitive/confidential/personal information tới Unpaid Services. Vì
vậy không mở hội thoại tự do có ngữ cảnh nhật ký trên cấu hình miễn phí này.

Phương án Gemini có billing: Google công bố Paid Services không dùng prompts/
responses để cải thiện sản phẩm, nhưng vẫn có logging/điều kiện xử lý dữ liệu.
Đây không phải cam kết zero retention hoặc tự động đủ điều kiện cho y tế.
Chủ dự án cần đồng ý thay đổi mô hình phí và hoàn tất bước billing/thanh toán.
Không tự chuyển hoặc coi yêu cầu linh hoạt là chấp thuận chi phí.

Lưu ý phạm vi dự án: liên kết billing cho project hiện tại chuyển TOÀN BỘ
Gemini Developer API usage trong project sang pay-as-you-go, gồm cả quét ảnh.
Firestore vẫn có mức miễn phí riêng, phần vượt hạn mức có thể phát sinh phí.
Budget alert không được coi là trần chi phí tự động; giới hạn trong app không
phải bảo vệ chi phí chắc chắn trước client bị chỉnh sửa/lạm dụng.

## Ví dụ ước tính để ra quyết định (không phải báo giá/cam kết trần)

Giá Standard gemini-3.5-flash-lite kiểm tra25/10/2026: input0,30USD/1triệu
token; output bao gồm thinking2,50USD/1triệu token. Giả sử mỗi lượt hỏi tổng
các lần gọi dùng3000input và600output token: chi phí model khoảng0,0024USD/lượt,
tức2,40USD/1000lượt. Lịch sử dài, tool loop và thinking làm số token tăng.
Chưa gồm quét ảnh, các dịch vụ khác, thuế/tỷ giá hoặc biến động giá.

Nếu vẫn bắt buộc0đồng, cần đánh giá giải pháp AI chạy trên thiết bị hoặc
provider khác cùng điều khoản/bảo mật và cách giữ secret. Không mặc định chúng
tương đương Gemini server hoặc tự đổi stack. Chưa chốt thư viện/model nào.

## Kiểm thử và rollout sau quyết định

- Unit: prompt/context không lẫn UID/PII field; tool arguments/unknown tool,
  bounds/date/quantity; số liệu đúng nguồn; missing/partial không thành0.
- Controller/widget: multi-turn, streaming, quota/network/timeout, cancel,
  đổi UID, retry/khôi phục lịch sử, không ghi dữ liệu ngoài save chat.
- SDK/thiết bị: câu tự do→tool→dữ liệu thật→đáp án; Gemini usage thực,
  App Check/consent và chính sách giữ dữ liệu của môi trường đã chọn.
- Giữ thay đổi chưa commit. Không triển khai Rules/admin còn treo hoặc sửa
  USDA trong cùng scope nếu chưa chặn trực tiếp. Nhánh USDA đang lỗi parser
  không được dùng làm nguồn gợi ý được coi là đã xác minh.

## Nguồn chính thức đã đối chiếu25/10/2026

- [Gemini terms: unpaid/paid](https://ai.google.dev/gemini-api/terms)
- [Firebase AI Logic pricing và ảnh hưởng khi liên kết billing](https://firebase.google.com/docs/ai-logic/pricing)
- [Gemini model pricing](https://ai.google.dev/gemini-api/docs/pricing)

AGENTS.md mục2.2 yêu cầu dừng hỏi trước quyết định có thể phát sinh chi phí,
đổi kiến trúc hoặc luồng nghiệp vụ. Chờ chốt dùng Gemini có billing hay tiếp
tục bắt buộc miễn phí; chưa thực hiện quyết định đó trong tài liệu này.
