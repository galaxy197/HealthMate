# Chatbot: 50 lượt và khôi phục hội thoại — 25/10/2026

Phạm vi Giai đoạn 9 theo yêu cầu người dùng: nâng lên 50 lượt mỗi cuộc, quay
lại tab tiếp tục đúng cuộc đang dùng, tiết kiệm hạn mức AI. Không tăng rate
limit, đổi model, thêm database, bật billing hoặc triển khai phần admin/scanner.
Người dùng chọn cài/thử điện thoại sau; lượt này xuất APK, không cài thiết bị.

## Hành vi hiện tại

- Mỗi cuộc có tối đa 50 lượt hỏi–đáp (100 messages). Lượt thứ 51 bị chặn ở cả
  app và Firestore Rules. Cuộc cũ vẫn đọc và tiếp tục được, không cần migration.
- Chuyển sang tab khác rồi quay lại: tải lại messages của cuộc đã chọn. Mở app
  vào chat lần đầu: mở cuộc mới nhất từ danh sách server. Khi chủ động bấm
  “Cuộc trò chuyện mới”, màn hình trống vẫn được giữ qua chuyển tab.
- Con trỏ cuộc đã chọn chỉ nằm trong bộ nhớ, gắn UID và được xóa khi đổi phiên
  tài khoản. Không giữ bản sao messages trong provider lâu dài. Một lần lưu
  kết thúc muộn không được ghi đè lựa chọn mới hơn hoặc lựa chọn của UID khác.
- Đọc lịch sử không gọi AI. Nút tra cứu nhanh dùng repository và phép tính
  trong app, không gọi Qwen/Llama/Gemini; giao diện có nhãn giải thích.
- Hội thoại gửi cho AI vẫn tối đa 3 lượt gần nhất, mỗi tin tối đa 1.200 ký tự.
  Loại bảng tham chiếu do app đính kèm khỏi history gửi lại để giảm dữ liệu lặp.
  Câu hỏi tự do vẫn dùng Cloudflare sau consent, không giới hạn vào các mẫu.
- Rate bindings vẫn 8 API requests/phút/UID và 60/phút theo location, mỗi lượt
  chat tự do thường dùng 2 requests. Không tăng hạn mức Neurons miễn phí.
- Rời tab khi AI còn trả lời vẫn hủy stream và bỏ partial. Composer/consent tạm
  không được khôi phục qua khởi động lại. Khi mất mạng, tải lịch sử báo lỗi và
  có thể tải lại, không giả rằng cuộc trò chuyện chưa từng tồn tại.

## Kiểm thử và artifact

| Kiểm tra | Kết quả thật |
| --- | --- |
| Format các file Flutter thay đổi | Qua, không thay đổi file ngoài phạm vi |
| 4 file test chatbot | 62/62, khoảng 6 giây |
| Toàn bộ `flutter test --no-pub` | 578/578, khoảng 67 giây |
| `flutter analyze --no-pub` cuối | 18 info có sẵn, 0 warning/error; exit 1 do info |
| Rules local toàn bộ file test | Lần cuối 52/52 |
| Rules candidate từ production | 4/4 ca chat: atomic pair, UID, validation, 50/51 lượt |
| Android debug có URL API thật | Build thành công, 42,2 giây |
| `git diff --check`, syntax các script Node mới | Qua |

Lần chạy Rules tổng thể đầu tiên có 51/52, lỗi assertion onboarding tại dòng
423 (ghi lại completion timestamp). Ca đó chạy riêng trên Rules trước khi
đổi giới hạn đã qua, và chạy lại toàn bộ cũng qua 52/52. Có dấu hiệu kiểm thử
phụ thuộc thời điểm; không sửa test/onboarding để che lỗi và không coi đã tìm
được nguyên nhân chắc chắn. Log đầu và cuối được giữ trong build/.

APK: `build/releases/healthmate-chat-50-debug.apk`, 236.539.039 bytes.
SHA-256: `214FFD9EA23869A50DFEA7A4B6320B44C31134F6E806CEC21E32C24603459BB2`.
Đây là bản debug để cài đè bản thử hiện tại; không gỡ app hoặc xóa dữ liệu trước
khi cài. App Check debug token đọc từ file local, không in hoặc chép vào source.

## Rules production

Local firestore.rules còn nhiều thay đổi chưa triển khai từ các công việc trước.
Đã lấy backup Rules đang chạy, tạo candidate chỉ đổi đúng điều kiện chat
`messageCount <= 40` thành `messageCount <= 100`, kiểm tra phần chat trùng local,
kiểm thử emulator, đọc lại baseline trước deploy và so hash sau deploy.
Không deploy nguyên file local, indexes hoặc các thay đổi tính năng khác.

- Trước: ruleset `423ff6c8-79b7-4158-ba4f-2de9871a715d`;
  hash `d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877`.
- Sau: ruleset `4d084994-cde1-4c8f-b8bd-dbfb52611baa`, release cập nhật
  `2026-10-25T14:45:18.604973Z`;
  hash `873887eb91e67a19caaa063e4c8f0a8b0f36d5a08d81c7c124f61914e2f7590c`.
- Backup/candidate/metadata/config rollback nằm trong `build/chat-limits-production-*`.
  Rollback là bản dự phòng, chưa chạy. Không có credential trong các file này.

Script prepare fail nếu snapshot/project/hash hoặc phần chat khác dự kiến.
`tool/test_chat_rules_candidate.cjs` chỉ chạy với emulator local, không đọc/ghi
document production. Không gọi model thật để thử 50 lượt và không tốn quota AI.

## Cần thử trên điện thoại sau khi cài

Gửi một câu, rời tab và quay lại; chọn cuộc cũ rồi chuyển tab; bấm cuộc mới rồi
chuyển tab; dùng tra cứu nhanh; hỏi tự do tiếp và kiểm tra lịch sử khi mở lại app.
Các trường hợp này đã có widget tests nhưng chưa nghiệm thu bản APK mới trên máy.
Chưa commit/push. Giai đoạn kế tiếp đề xuất: 10 — kiểm thử tích hợp và bảo mật,
không tự triển khai.
