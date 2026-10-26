# Bản chụp Firestore Rules MVP

`firestore.mvp.rules` là bản Rules đã đọc lại từ Firebase vào 26/10/2026,
sau rollout năng lượng, tiến độ và giấc ngủ. Bản này không bật quyền admin.

- Project: `healthmate-app-20261013`.
- Ruleset: `e0057d3e-f72e-405c-b50c-cd5063e25c6c`.
- Release UTC: `2026-10-26T09:55:44.532520Z`.
- SHA256 sau chuẩn hóa CRLF thành LF và trim:
  `6a1762dd899ebdac732a9d55e4c4444a27e06a584c1fad982e36088f7108c374`.
- Cùng nội dung candidate đã qua 64 Rules tests. Không deploy lại trong đợt push GitHub.

`firebase.mvp.json` chỉ tham chiếu bản Rules này, không có Hosting/Functions/indexes.
Đây là bản chụp có thể kiểm tra khi clone repo, không bảo đảm còn là bản mới nhất
trên server về sau. Trước mỗi rollout cần đọc lại server, kiểm thử và review diff.

**Không dùng lệnh deploy mặc định ở gốc để đưa MVP lên production:**
`firestore.rules` và `firebase.json` ở gốc còn hỗ trợ thử nghiệm admin trên Emulator;
web admin đang tạm gác. Push Git không triển khai Firebase hay Cloudflare.
Các backup, credential, log, APK và dữ liệu Emulator cục bộ không được commit.
