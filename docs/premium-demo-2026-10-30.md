# Premium demo — 30/10/2026

Đợt mở rộng theo yêu cầu người dùng: **mô phỏng mua Premium 20.000đ/30 ngày**
và báo cáo doanh thu mô phỏng trên admin. Không thu tiền, không tự gia hạn,
không tích hợp ngân hàng hoặc Google Play Billing. Không thêm dịch vụ trả phí
hay dependency mới. Đây là phạm vi độc lập đã được chốt, không triển khai thêm
các giai đoạn khác của MVP.

## Quyền lợi và cách tính lượt

| Mỗi ngày theo giờ Việt Nam | Miễn phí | Premium demo |
| --- | ---: | ---: |
| Phân tích ảnh món ăn | 3 | 20 |
| Câu hỏi gửi AI chatbot | 5 | 50 |

Chụp ảnh và chọn ảnh là hai lối vào cùng lượt phân tích; không tính hai lần.
Hủy chọn ảnh, ảnh rỗng/định dạng không hỗ trợ/quá 8 MB không trừ lượt.
Tra mã vạch và câu trả lời tra cứu nhật ký tại ứng dụng không trừ lượt AI.
Lượt được giữ bằng transaction trước khi gọi dịch vụ; yêu cầu đã giữ lượt vẫn
tính nếu AI lỗi, người dùng dừng hoặc quyền dùng AI thay đổi ngay sau đó.
Thử lưu lại câu trả lời đã sinh không gọi AI/trừ lượt lần nữa.

Lượt theo tài khoản, dùng chung giữa thiết bị, đặt lại lúc **00:00 UTC+7**.
Mua gói nâng trần của ngày hiện tại, giữ số lượt đã dùng. Hết hạn trở về trần
miễn phí; nếu đã dùng quá trần thì đợi ngày mới. Một loại lượt đã quá trần sau
hết hạn không chặn loại còn lại. Gói đang còn hạn không mua chồng thêm.

## Trải nghiệm

- **Cá nhân → Premium:** giá/thời hạn, so sánh lượt, số lượt hôm nay, ngày hết
  hạn và xác nhận giao dịch demo. Hủy xác nhận không ghi giao dịch. Thử lại một
  giao dịch chưa rõ kết quả giữ ID để không tạo doanh thu lần hai.
- **Admin → Doanh thu:** chọn khoảng ngày (tối đa 366 ngày), tổng số tiền mô
  phỏng, giao dịch, số UID mua trong kỳ, số bản ghi gói còn hạn hiện tại; tổng
  theo ngày, chi tiết 100 giao dịch mới nhất và xuất Excel toàn bộ kỳ đã tải.
- Không suy doanh thu từ số người có Premium. Chỉ cộng receipt demo hợp lệ
  `simulated_paid`, đúng 20.000 VND. Dữ liệu sai/môi trường khác hoặc tải không
  đủ thì không trình bày một tổng doanh thu thiếu. Bộ tải hiện giới hạn 5.000
  bản ghi mỗi collection; vượt giới hạn cần nâng thiết kế truy vấn/báo cáo.
- Màn hình, xác nhận và Excel đều ghi rõ **DEMO / KHÔNG THU TIỀN**.

## Bật và đóng gói

Cờ `HEALTHMATE_ENABLE_PREMIUM_DEMO` mặc định false để APK cũ không gọi
collection Premium trước khi Rules sẵn sàng. Build bằng:

```powershell
.\tool\build_android.ps1 -PremiumDemo
```

Script dùng cấu hình admin/AI hiện có trong các file config bị gitignore,
chạy 7 kiểm thử cấu hình admin trước build và xuất riêng
`build/releases/healthmate-premium-demo-debug.apk` cùng manifest JSON có SHA-256.
Không thay APK mặc định. Đây là bản debug phục vụ đồ án.

Admin bundle: `build/admin-premium-demo-review-20261030/`. Đã backup, đối
chiếu với Rules đang chạy và triển khai ngày 30/10/2026 tới đúng project
`healthmate-app-20261013`. Ngoài namespace Premium mới, khác biệt duy nhất là
bản sửa allowlist `personalization` đã có kiểm thử, giúp tài khoản mới lưu
cá nhân hóa khi onboarding. Không đổi validation hoặc quyền đối với UID khác.
Đã đọc lại Rules từ server: khớp bản đã kiểm thử; cả 13 file Hosting trả HTTP200
và hash khớp bundle. Web admin:
[healthmate-admin-vn.web.app](https://healthmate-admin-vn.web.app)
(địa chỉ rút gọn cập nhật cùng ngày).
Không nâng billing, đổi App Check hoặc cấp thêm role. APK bật demo đã có
Rules tương ứng để mua/giữ lượt. Cài APK mới và tải lại web để tự nghiệm thu.

## Dữ liệu và bảo vệ

- `demo_premium_accounts/{uid}`: trạng thái gói, thời hạn và ID giao dịch mới
  nhất. Chủ tài khoản/admin đọc; client chỉ ghi kèm receipt mới đúng quy tắc.
- `demo_premium_transactions/{20-character-auto-id}`: receipt bất biến,
  UID, giá VND cố định, thời hạn, nhãn demo và server timestamp. Chủ tài khoản
  đọc receipt của mình; admin đọc danh sách báo cáo. Không cấp admin quyền
  đọc nhật ký sức khỏe.
- `demo_ai_usage/{uid}/days/{UTC7-day-start-millis}`: số scan/chat, ngày và
  thời gian cập nhật. Chỉ chủ tài khoản truy cập; Rules buộc đúng ngày server,
  tăng đúng một loại lượt, không giảm/reset hoặc ghi cho UID khác.
- Purchase ghi account và receipt nguyên tử. Rules buộc gói 30 ngày, giá
  20.000 VND, `mode:demo`, timestamp ghi nhận từ server; bắt đầu chênh tối đa
  2 phút để không tự gia hạn bằng giờ máy. Thiết bị cần đồng bộ giờ.
- Bản demo **chưa tự xóa receipt/account/usage khi xóa tài khoản**. Các bản
  ghi chỉ có UID và metadata giao dịch/lượt, không chứa ảnh hay nhật ký sức
  khỏe. UI đã công khai hạn chế này trước khi mua. Cần thiết kế thời hạn lưu
  và quy trình xóa/ẩn danh trước khi chuyển thành sản phẩm thương mại.

## Giới hạn thực tế

Giới hạn bảo vệ counter Firestore và đường gọi trong client chính thức.
Không có backend xác minh thanh toán hoặc proxy AI kiểm entitlement; client
đã sửa có thể bỏ qua bước quota rồi gọi API AI trực tiếp. Vì vậy đây chưa phải
cơ chế chống gian lận cho gói trả tiền thật. Premium **không nâng hạn mức**
Gemini/Firebase/Worker hoặc bảo đảm API ngoài luôn hoạt động.

Mua/giữ lượt cần mạng và xác nhận server. Màn hình không dùng cache làm bằng
chứng gói; khi offline có thể chờ kết nối. Chưa chạy lại luồng Android, chưa
nghiệm thu AI thật hoặc đăng nhập/mua demo trên production; người dùng sẽ tự
test theo yêu cầu. Không tạo doanh thu mẫu trên database production.

## Kiểm chứng đã chạy

- Flutter toàn bộ: **697/697 qua**; analyzer: **No issues found**.
- Admin web: **25/25 qua**, kiểm syntax qua.
- Firestore Rules Emulator: **84/84 qua**, trong đó 6 test Premium bao gồm
  giá/thời hạn, nguyên tử, bất biến receipt, quyền giữa UID/admin, trần 3/5
  và 20/50, hết hạn, hai thiết bị tranh lượt cuối.
- Widget test Premium gồm xác nhận/Hủy/thử lại/chặn mua chồng và màn rộng
  320 px với cỡ chữ 1/1,5/2; scanner không gọi API khi hết lượt; chatbot tra
  cứu local không trừ lượt và thử lưu lại không trừ hai lần.

Log và kết quả build chi tiết: `docs/test-report.md`, phần 30/10/2026.
