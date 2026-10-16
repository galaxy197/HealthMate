# Giai đoạn 9 — Trò chuyện HealthMate

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

40 messages/phiên (20 lượt), câu hỏi <=1000, đáp án <=6000 ký tự, tải tối đa 20
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
