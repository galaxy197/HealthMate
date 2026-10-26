# Chatbot API — snapshot tổng hợp

Chụp widget Flutter với endpoint/service/repository fake, **không phải kết quả
Qwen thật hoặc nghiệm thu cloud**. Font Be Vietnam Pro và Material Icons thật;
viewport 360×800, pixelRatio 2, cỡ chữ 100%/200%. Disclosure có vùng nội dung
cuộn; nút xác nhận vẫn truy cập được khi chữ lớn. Không chứa dữ liệu người dùng.

- consent-1.0.png, consent-2.0.png: thông tin chia sẻ dữ liệu trước gửi.
- conversation-1.0.png, conversation-2.0.png: trạng thái có hội thoại và composer.

Tái tạo từ thư mục dự án:

```powershell
flutter test --dart-define=HEALTHMATE_CAPTURE_CHAT_API=true test/chatbot_api_test.dart --plain-name "flexible chat and consent fit"
```
