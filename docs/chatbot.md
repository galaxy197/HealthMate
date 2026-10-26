# Giai đoạn 9 — Trò chuyện HealthMate

## Cập nhật mới nhất 25/10 — 50 lượt và khôi phục hội thoại

Đã nâng 50 lượt/cuộc ở app và Rules production; trở lại tab mở đúng cuộc đang
dùng, chủ động tạo cuộc mới giữ màn hình trống. Tra cứu nhanh không gọi AI,
history gửi AI bỏ bảng tham chiếu lặp. 578 Flutter tests và Rules 52+4 ca qua;
APK đã xuất để người dùng cài/thử sau. Không tăng quota/rate hoặc bật billing.
Chi tiết: [báo cáo nâng giới hạn](chatbot-capacity-update.md).

## Tiếp nối 25/10 — API Cloudflare đã triển khai, chờ nghiệm thu điện thoại

Người dùng đã yêu cầu thực hiện phương án API miễn phí sau khi làm rõ không
cần chạy model trên điện thoại. Đã có `chat-api/` Worker dùng Qwen lập kế hoạch,
Llama 3.3 70B trả lời (hai model cố định trong cùng Cloudflare Workers AI) và
Flutter ChatAssistant/ChatDataReader mới. Firebase vẫn giữ toàn bộ dữ liệu;
Worker không có credential hoặc quyền truy cập Firestore. Đây là thay đổi
provider cho chat được người dùng yêu cầu, không thay scanner/Gemini hoặc admin.

Luồng mới dùng model lập JSON kế hoạch nguồn dữ liệu thay cho regex 10 chủ đề,
app kiểm tra và đọc tối đa 3 nguồn được phép rồi model trả SSE. Mỗi nguồn nhật
ký tối đa 7 ngày, cân gần nhất tìm trong 90 ngày; gợi ý tối đa 5 món catalog có
nguồn và tính khẩu phần bằng code. Lịch sử gửi tối đa 3 lượt gần nhất, mỗi tin
cắt tối đa 1200 ký tự. Không gửi UID/email/profile field; raw user text có thể
chứa dữ liệu tự nhập, nên disclosure nêu rõ nội dung nhập cũng được gửi.

Chỉ dùng luồng mới khi cấu hình `HEALTHMATE_CHAT_API_URL` bằng URL thật. Có
consent trước khi gửi, giữ AI access gate, stop/UID guards/retry cùng turn ID;
không lưu partial stream. Chế độ tra cứu không gọi provider AI nào. Phần Gemini
10 enum dưới đây chỉ còn áp dụng khi chưa cấu hình API; không dùng làm fallback
gửi dữ liệu riêng tư nếu Cloudflare lỗi. Nhãn tin nhắn AI đổi thành thông tin tham khảo.

Chủ dự án đã tạo tài khoản và hoàn tất OAuth Wrangler. API thật đã triển khai;
public URL lưu ở config/chat-api.json và APK debug đã build với URL này. Đã gọi
model thật qua Cloudflare REST bằng fixture tổng hợp, chưa gửi nhật ký thật.
Điện thoại đã nối lại USB, APK cài đè thành công. Đã sửa lỗi SSE budget32KB đếm
cả envelope. Người dùng xác nhận câu kiến thức chung trả lời đầy đủ, câu hỏi
mục tiêu kcal/follow-up về đạm xử lý đúng. Native mất mạng/đổi UID/lịch sử mở lại
và CPU riêng vẫn chưa nghiệm thu thủ công.
Kết quả và giới hạn: [báo cáo live](chatbot-live-qa.md). Không coi rollout hoàn tất.
Hướng dẫn, rủi ro và nguồn: [chat-api/README.md](../chat-api/README.md).

## Mở rộng trước đó 25/10/2026 — luồng cũ khi chưa cấu hình API

Theo yêu cầu xây chatbot, bản hiện tại mở rộng trợ lý riêng tư trên nền code
đã có. Không đổi provider/billing, không thêm package, không deploy Rules,
không sửa scanner/USDA/admin hoặc dữ liệu người dùng. Web admin tiếp tục tạm gác.

- Hỏi bằng tiếng Việt có/không dấu: một ngày, hôm nay/hôm qua/hôm kia,
  dd/MM[/yyyy], yyyy-MM-dd, tuần này (thứ Hai đến hôm nay), tuần trước hoặc
  7 ngày gần nhất. Khoảng khác/ngày sai/tương lai/hai ngày tự nhập được giải
  thích rõ, không âm thầm dùng ngày đang chọn.
- Đọc kcal, từng macro/chất xơ có đủ dữ liệu, nước, vận động, tóm tắt và
  cân nặng. Cân nặng một ngày tìm bản ghi gần nhất trong90ngày kết thúc ngày
  đã chọn; hiển thị ngày đo, không giả là cân hôm nay.
- “Còn bao nhiêu kcal/đạm?” đối chiếu mục tiêu dinh dưỡng thực đã đặt. Theo
  tuần áp dụng đúng từng phiên bản mục tiêu theo ngày; thiếu mục tiêu hoặc
  macro thì báo thiếu, không tự đặt mức ăn hay thay bằng0. Có thống kê số ngày
  đạm đã ghi đạt ít nhất mục tiêu, chỉ xét ngày có đủ dữ liệu/mục tiêu.
- Tổng tuần ghi rõ số ngày có nhật ký; trung bình chỉ trên ngày có bản ghi.
  Không kết luận ngày trống là không ăn hoặc khuyến nghị ăn bù phần còn lại.
- Câu nối tiếp như “còn đạm thì sao?” giữ phạm vi ngày của lượt cá nhân vừa
  hoàn tất. Ngày viết rõ ưu tiên hơn; chọn lịch, mở lịch sử, phiên mới, câu hỏi
  trợ giúp/AI hoặc đổi UID xóa ngữ cảnh. Không suy ra mốc ngày cũ từ lịch sử.
- Giao diện chat, gợi ý, lịch, chủ đề AI, history/new/retry/stop dùng hành động
  thật. Gợi ý thu gọn khi đã có tin nhắn; snapshot dùng font Be Vietnam Pro
  trong docs/ux/chatbot/, dữ liệu fixture chứ không phải điện thoại production.

### Phạm vi AI và dữ liệu

Đã kiểm tra lại [điều khoản](https://ai.google.dev/gemini-api/terms#unpaid-services)
và [model Firebase](https://firebase.google.com/docs/ai-logic/models) ngày25/10.
Unpaid Services không nhận thông tin nhạy cảm/cá nhân. Giữ lựa chọn miễn phí:
`KnowledgeService` vẫn chỉ nhận enum, không thêm tham số free text/context.

AI có10chủ đề: bữa cân bằng, đọc nhãn, thói quen, đạm, chất xơ, carbohydrate,
chất béo, nước, khẩu phần, cân bằng năng lượng. Câu như “Protein là gì?” được
nhận diện ở app; sau disclosure/đồng ý, chỉ prompt chung cố định của chủ đề
được gửi. Nội dung tự nhập vẫn lưu vào hội thoại riêng trên Firestore nhưng
không gửi Gemini. Câu bệnh lý/yêu cầu ghi/xóa dữ liệu được xử lý tại app.

Đây là trợ lý có phạm vi xác định, chưa phải hội thoại LLM tự do hoặc model
phân tích hồ sơ cá nhân như MyFitnessPal AI Coach. Không nhận raw history,
không gợi ý thực đơn cá nhân, không ghi/sửa dữ liệu bằng chat, không chẩn đoán.
Gợi ý món theo lượng còn lại là phạm vi tiếp theo, chưa triển khai trong lượt này.

Model mặc định đổi sang `gemini-3.5-flash-lite`, thinking minimal để ưu tiên
độ trễ; model override khác dùng low. Duy trì tối đa2048output tokens,
6000ký tự,45s trả lời,20lượt/phiên,20phiên gần nhất. Không hứa free vô hạn.

### Kiến trúc và tương thích

`chat_request.dart` lập kế hoạch cục bộ có giới hạn; `PersonalChatContext`
chỉ lấy repository liên quan, tổng hợp tại Dart. Câu hỏi nước không đọc bữa,
truy vấn bữa không đọc profile/mục tiêu nếu không cần. Tóm tắt lỗi một nguồn
thì không xuất tổng hoàn chỉnh. Retry giữ ID/đáp án đã nhận; UID guard và
stream cancellation cũ được bảo toàn, cùng kiểm thử hồi quy.

Không đổi collection/field/source/schema/index hoặc Rules. Metadata kiểm tra
24/10 xác nhận production đã có Rules chat từ18/10; mô tả “Chat chưa deploy”
trong phần lịch sử bên dưới đã cũ. Rules mới cho verified claim và các schema
dinh dưỡng/admin vẫn chưa triển khai; không gọi cả production là đã đồng bộ.
Lỗi USDA được báo ở lượt audit vẫn ngoài phạm vi sửa chatbot này.

### Nghiệm thu thiết bị còn lại

Chưa có thiết bị ADB. Cần thử APK trên Android: hỏi ngày/tuần với dữ liệu đã
ghi; đổi target rồi hỏi lại; nhận câu trả lời Gemini, lỗi mạng/quota và stop;
đóng/mở lịch sử, đổi UID. Không coi test fake repositories là API Gemini
production hoặc xác nhận độ chính xác nội dung model.

Các phần bên dưới ghi thiết kế/bối cảnh trước bản mở rộng; ưu tiên phạm vi
và model trong mục cập nhật này khi có khác biệt.

## Điều kiện sử dụng bổ sung ở Giai đoạn 10

Người dùng đã chốt MVP/demo dành cho người từ **18 tuổi** theo
[điều khoản độ tuổi Gemini API](https://ai.google.dev/gemini-api/terms#age-requirements).
Onboarding kiểm tra ngày sinh đầy đủ, không chỉ năm sinh. Hồ sơ cũ thiếu dữ liệu
hoặc không đủ tuổi quay lại bước thiết lập, không bị xóa dữ liệu đã ghi.
Chat kiến thức và Scanner kiểm tra cùng `aiAccessProvider` ngay trước gọi AI:
phải có session đúng UID, hồ sơ tải thành công, ngày sinh hợp lệ và onboarding
hoàn tất. Việc tra cứu số liệu nhật ký vẫn tính tại ứng dụng.

Đây là cổng kiểm tra phía client dựa trên ngày sinh tự khai, không xác minh danh
tính hoặc chứng thực độ tuổi phía server. Không coi nó là bảo đảm tuyệt đối
người dùng đủ tuổi. Xem kiểm thử và giới hạn tại [test-report.md](test-report.md).

## Phạm vi đã được người dùng xác nhận

Giữ Gemini Developer API miễn phí. Khi kiểm tra ngày 16/10/2026,
[điều khoản Unpaid Services](https://ai.google.dev/gemini-api/terms#unpaid-services)
yêu cầu không gửi thông tin nhạy cảm, bí mật hoặc cá nhân. Google có thể sử dụng
nội dung để cải thiện sản phẩm và cho người đánh giá xem nội dung. Người dùng
đã chọn: **số liệu trả lời tại app, AI cho câu hỏi chung định sẵn**.

Do đó đây không phải chatbot gửi ngữ cảnh sức khỏe tới model. Không có công tắc
lách giới hạn bằng đồng ý chia sẻ. Không bật billing, không chuyển provider,
không thêm backend. Hội thoại riêng tư vẫn được lưu trong Firestore của tài khoản.

## Dữ liệu và prompt

`JournalChatContext` chỉ đọc repository cần cho câu hỏi: dinh dưỡng 2 truy vấn
range hiện có (dateKey + legacy consumedAt), nước 1, vận động 1. Tóm tắt ngày
cần cả ba nguồn; một nguồn lỗi thì báo lỗi và không tạo tổng giả. Không đọc hồ
sơ, cân nặng, catalog hoặc mục tiêu chỉ để trả lời kcal. Không thêm listener.
Mỗi lần gửi lấy dữ liệu mới từ server; đáp án lưu là snapshot tại thời điểm đó,
không tự thay đổi khi nhật ký được sửa sau này.

Ngày có nhãn dd/MM/yyyy và UTC offset lịch địa phương thiết bị. Hôm nay/hôm qua
được xác định khi gửi, không lấy ngày cũ của phiên. Ngày khác chọn bằng date
picker; không suy đoán ngày số/tuần/tháng từ câu hỏi ngoài phạm vi hỗ trợ.
Dữ liệu nhật ký theo quy ước dateKey hiện có; bữa cũ dùng range consumedAt
nửa mở. Không migration hoặc sửa dữ liệu gốc.

`KnowledgeService` chỉ nhận enum gồm ba chủ đề. System instruction và câu hỏi
chung cố định được tách qua SDK; không có tham số tự nhập, UID, history, profile
hoặc JSON sức khỏe. API model không được truy cập Firestore, tạo tool hoặc ghi
nhật ký. Mọi thao tác lưu hội thoại do ứng dụng thực hiện.

Firebase AI Logic `generateContentStream`, model `gemini-3.8-flash`, thinking
level low, output <=2048 tokens. Danh sách model và cấu hình đã đối chiếu:

- https://firebase.google.com/docs/ai-logic/models
- https://firebase.google.com/docs/ai-logic/chat?platform=flutter
- https://firebase.google.com/docs/ai-logic/thinking

Không dùng tên model 2.5 đã hết vòng đời. Dùng `HEALTHMATE_CHAT_MODEL` để thay
model khi cần sau khi kiểm tra tương thích. Giới hạn free tier có thể thay đổi.

## Phiên, retry và vòng đời

100 messages/phiên (50 lượt), câu hỏi <=1000, đáp án <=6000 ký tự, tải tối đa 20
phiên mới nhất. AI mỗi lần chỉ nhận một câu hỏi định sẵn, không gửi các lượt
cũ. Không có array tăng vô hạn trong session.

Cặp user/assistant và bộ đếm phiên được ghi trong một transaction. ID lượt ổn
định, retry kiểm tra message ID trước khi ghi; khi đã có đáp án mà lỗi lưu,
retry dùng đáp án cũ, không gọi AI. Chỉ đáp án hoàn chỉnh được ghi; partial
stream bị lỗi/trống/quá dài/bị chặn sẽ bị bỏ. Có timeout 45 giây cho trả lời,
20 giây cho thao tác Firestore. Một timeout ghi có thể xảy ra sau khi server
đã nhận transaction; cùng ID giúp thử lại không nhân bản.

Khi rời Chat, đổi UID hoặc đăng xuất: hủy subscription nhận stream, hủy cập nhật
giao diện/lưu đáp án từ yêu cầu cũ. UI không chờ network cleanup khi dừng. SDK
có thể vẫn xử lý yêu cầu đã gửi trên server và tính quota. Transaction đã bắt
đầu không thể hủy an toàn; nút dừng chỉ có trong lúc trả lời. Nếu rời app lúc
đang lưu, mở lại lịch sử để xác minh. Không có cơ chế khôi phục bản nháp qua
khởi động lại. Lịch sử không realtime; menu có tải lại.

Chat widget và state theo UID, chỉ được giữ khi nhánh đang hiển thị. Nội dung
composer, consent tạm và đáp án cũ được xóa khi chuyển tài khoản. Xóa tài khoản
sử dụng quy trình có sẵn xóa messages rồi sessions trước khi xóa Auth.

## Rules và giới hạn bảo đảm

Rules chỉ cho chủ UID đọc/ghi/xóa. Schema/role/source/độ dài/sequence, bộ đếm
và cặp message được kiểm tra; messages đã tạo không được sửa. Rules không xác
minh câu trả lời thật sự được tạo bởi AI vì client ghi hai role. Nhãn source
không phải chứng thực máy chủ; không sử dụng hội thoại để quyết định quyền
truy cập hay hành động y tế. Không có Cloud Functions hoặc Admin credential.

Không thay đổi indexes: orderBy một field dựa trên single-field index mặc định.
Rules thay đổi chỉ được kiểm tra trên emulator demo, chưa deploy production.

## Cần kiểm tra bằng mắt trên Android

1. Mở Cá nhân → Trò chuyện; thử sáng/tối, cỡ chữ lớn và bàn phím.
2. Chọn ngày có nhật ký, ngày trống, hôm nay/hôm qua; đối chiếu kcal/macro/ml/
   phút với Nhật ký. Sửa Nhật ký rồi gửi lại để lấy số mới.
3. Chọn chủ đề AI; đọc thông báo, thử Để sau/Tiếp tục. Kiểm tra streaming,
   cuộn, Dừng nhận và quay về màn khác trong lúc đang nhận.
4. Thử mất mạng/lỗi lưu và Thử lại; không được có cặp tin trùng hoặc lưu partial.
5. Mở lại lịch sử và đổi tài khoản; không lộ lịch sử/composer của tài khoản cũ.
6. Review Rules local rồi triển khai riêng khi được yêu cầu; không kỳ vọng
   lưu Chat production trước khi rule mới được triển khai.

Không thử xóa tài khoản thật chỉ để kiểm tra Chat; dùng tài khoản kiểm thử
riêng khi kiểm tra toàn bộ quy trình xóa dữ liệu.
