# H7 — Nháp bền vững và xuất nhật ký riêng tư

## Phạm vi và cách dùng

Nhật ký → biểu tượng **Bản nháp trên thiết bị** cạnh tiêu đề Bữa ăn, hoặc các
hành động thêm/sửa/copy/quét mở cùng
MealFormDialog. Nếu tài khoản có nháp, người dùng chủ động chọn ngày/bữa để khôi
phục hoặc tạo bản mới. Không tự gửi khi mở ứng dụng hay đăng nhập. Đóng form giữ
nháp; **Bỏ bản nháp này** xóa riêng nháp đó. Món/khẩu phần, loại bữa, thời điểm,
snapshot nguồn, missing/0/partial và minimum schema được giữ; tìm kiếm không phải
dữ liệu nhật ký nên không lưu. Không bổ sung nháp cho các form nước/vận động.

Cá nhân → **Xuất nhật ký CSV** → chọn ngày đầu/cuối (bao gồm ngày cuối) → đọc và
xác nhận thông tin riêng tư → chọn nơi lưu trong Android. Có thể hủy. Chọn bộ nhớ
thiết bị để giữ cục bộ; chọn provider đám mây là lựa chọn của người dùng. Không tự
email/upload/chia sẻ. Chỉ báo thành công sau khi đọc lại byte của tệp và đối chiếu.

## Lưu trữ và giới hạn bảo mật

- Android là nền tảng được triển khai. Web/desktop báo rõ nháp chỉ tồn tại trong
  form và chưa hỗ trợ xuất tệp; không âm thầm lưu health JSON vào preferences.
- Không thêm package hoặc database backend. MethodChannel nối Dart với API Android
  sẵn có; min SDK hiện tại phù hợp Android Keystore AES/GCM.
- JSON nháp mã hóa AES-256/GCM với IV mới cho mỗi lần ghi; UID là authenticated
  additional data. Khóa không xuất được từ AndroidKeyStore. Mỗi UID có alias và
  tên file SHA-256 riêng, trong `noBackupFilesDir`; backup/extraction tiếp tục tắt.
  Không tuyên bố thiết bị/AVD nào cũng có phần cứng bảo vệ khóa.
- AtomicFile ghi thay thế nguyên tử; công việc crypto/I/O chạy worker riêng. Kho
  Dart tuần tự hóa read/modify/write để không mất cập nhật hoặc xóa nhầm nháp khác.
- Contract local v1: UID, operationId, mealId khi sửa, UTC/offset/dateKey, type,
  source, minimumSchema, items snapshot, updatedAt. Tối đa 20 nháp/UID, 512 KiB;
  không âm thầm đẩy nháp còn hạn ra. Nháp quá 7 ngày bị loại và dọn khi mở kho lần
  tiếp theo; không có tác vụ nền hứa xóa đúng một thời điểm khi app đã đóng.
- File/khóa hỏng báo lỗi đọc; không giả là kho rỗng rồi ghi đè. Dữ liệu không được
  log. Mã hóa lưu trữ không thay thế khóa màn hình và không chống được toàn bộ
  tình huống ứng dụng/thiết bị đang mở bị chiếm quyền. Xóa app/xóa dữ liệu hoặc mất
  khóa thiết bị có thể làm mất nháp; nháp không đồng bộ giữa thiết bị.
- UI và chooser đóng khi UID thay đổi; không phục hồi A trong B. Kho vẫn có thể
  giữ file mã hóa của A để A chủ động đăng nhập lại trên cùng thiết bị.

## Chống lưu trùng và lỗi giữa chừng

operationId được lưu cùng payload xuống thiết bị **trước** lần gọi Firestore đầu
tiên. Khôi phục/retry dùng lại ID; transaction hiện có đối chiếu payload rồi đọc
server xác nhận, không thêm bữa thứ hai nếu lần trước đã commit. Payload khác trên
cùng ID báo xung đột và hướng dẫn tải lại bữa để sửa; không tự tạo ID mới để né lỗi.
Lỗi ghi local chặn gửi server; lỗi mạng giữ nháp; chỉ dọn sau acknowledgement.
Nếu dọn local thất bại sau commit, báo rõ bữa đã lưu và ID cũ vẫn bảo vệ retry.

`MealDraft.timezoneOffsetOverride` giữ offset khi phục hồi kể cả timezone thiết bị
đổi; chọn lại ngày/giờ là hành động mới và dùng timezone thiết bị lúc chọn. Không
đổi dateKey chỉ vì đọc JSON UTC. Không thay schema Firestore trong H7.

Xóa tài khoản: xác thực lại → xóa Firestore như trước → xóa file/khóa nháp đúng UID
trên thiết bị này → xóa Auth. Nếu cleanup local lỗi thì giữ Auth, báo phần dữ liệu
có thể đã xóa và cho thử lại. Kho chặn callback trễ ghi lại UID đang xóa. Sau một
lần xóa dữ liệu đã bắt đầu, nếu Auth chưa xóa được thì cần hoàn tất/xác thực lại;
không hứa khôi phục dữ liệu đã xóa. Không xóa nháp UID khác hoặc file CSV người dùng
đã xuất. Không thể từ xa xóa file offline trên thiết bị khác; việc này cần được
giải thích cùng các bản sao xuất và quản lý thiết bị.

## Hợp đồng CSV và quyền tài khoản

- Tải một lần bằng bốn repository range H5, 1–90 ngày, nguồn nào lỗi thì dừng toàn
  bộ xuất; mỗi nguồn dùng sentinel 2.001 để từ chối vượt 2.000, không truncate.
  Không listener mới, truy vấn không nằm trong widget và không đọc UID tùy ý từ UI.
- Giữ UID và phiên; kiểm tra sau tải, sau OS picker và trước gửi bytes. Dùng SDK
  currentUid trực tiếp, không chỉ chờ state UI, kể cả khi Flutter tạm ngừng frame
  trong lúc OS picker mở. Đổi A→B→A cũng hủy phiên xuất. Chọn file chỉ trả ticket,
  chưa có health
  bytes. Native chỉ ghi URI vừa được chọn qua ticket dùng một lần.
- Khoảng nửa mở `[start, ngày sau ngày cuối)`. Meal/water/activity dùng dateKey và
  offset lưu; legacy/cân nặng ghi rõ basis thiết bị lúc xuất khi không có offset.
- Một món của bữa là một dòng, không cộng thêm dòng tổng gây đếm hai lần. Nước,
  vận động, cân nặng có loại dòng/đơn vị riêng. `healthmate_journal_csv_v1` và schema
  nguồn được ghi; đây là export nhật ký, **không phải toàn bộ dữ liệu tài khoản**:
  không hồ sơ, chat, goals/targets, thư viện, review hoặc draft.
- UTF-8 BOM, CRLF, quote toàn bộ, escape quote/newline/delimiter; text có đầu công
  thức sau whitespace/control/BOM/bidi được thêm apostrophe. Số do app sinh vẫn là
  số; không đánh đồng null với zero. Mỗi nutrient có status known/partial/unknown.
- Tối đa 5 MiB; ngày trống chỉ có tiêu đề. Native ghi rồi đọc lại đúng byte; nếu
  lỗi thử xóa document vừa tạo. Provider không cho đọc/xóa có thể cần người dùng
  dọn tệp chưa hoàn chỉnh; UI không báo thành công giả.
- Không quyền truy cập toàn bộ storage, không giữ quyền URI lâu dài, không cache
  plaintext xuất trong ứng dụng thường. File đã xuất thuộc nơi người dùng chọn,
  có thể tồn tại sau đăng xuất/xóa tài khoản; người dùng tự quản lý bản sao.

## Kiểm chứng

Kết quả chạy cuối cập nhật trong `test-report.md` và `implementation-progress.md`.
Lượt cuối: Flutter454/454 (43s), analyze sạch (17.4s). Native12s +32s và runner
exit0; file thực trong Downloads1554byte khớp byte-for-byte với CSV dựng từ các
repository thật, có BOM và đủ bốn loại dữ liệu. Lệnh xác minh bổ sung:
`tool/verify_h7_export.ps1` (chỉ AVD QA, không in nội dung).
`tool/test_h7_android.ps1` giới hạn AVD HealthMateMaintenanceQA / emulator-5580,
project demo-healthmate-rules, Auth9099/Firestore8080, AI tắt. Hai phase giữ backend
và dữ liệu app, force-stop giữa phase; không uninstall/clear-data/đụng điện thoại.
Phase 1 tạo nháp qua UI, xác nhận chưa có meal server. Phase 2 khôi phục, thử mạng
lỗi/retry, tái hiện commit trước ack, xuất qua OS picker, đổi UID khi picker mở,
chặn truy cập chéo SDK và cleanup A/B. Host chỉ bấm Save đã đọc từ cây accessibility
Android thật; không thay picker bằng fake trong kết luận Android.

Widget/unit test dùng fake riêng cho codec/TTL/lỗi đĩa/queue/UID đổi lúc tải và
picker, A→B→A, nút consent/xuất tại 360/390/412, chữ1/1.5/2, sáng/tối. Những test này
không thay cho Android/SDK. Kiểm tra thêm điện thoại người dùng, bàn phím và provider
lưu tệp thực tế trước phát hành rộng. APK E2E trỏ Emulator không phải APK phát hành.

## Tài liệu API đã đối chiếu

- [Android Keystore](https://developer.android.com/privacy-and-security/keystore)
- [Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files)
- [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)

Không commit/push/deploy Rules/indexes/import catalog production trong H7. H0–H6
được giữ nguyên ngoài các chỗ nối form/model/auth cần cho nháp và xuất.
