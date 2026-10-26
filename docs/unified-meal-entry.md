# Thêm bữa ăn hợp nhất — 23/10/2026

Phạm vi Giai đoạn 5: tích hợp nhập tay, quét ảnh/mã vạch và món yêu thích trong
một màn hình bữa ăn, theo bố cục tham khảo người dùng gửi. Giữ nghiệp vụ và dữ
liệu hiện có; không chuyển giai đoạn, push hoặc deploy Firebase.

## Cách dùng

- **+ → Thêm bữa ăn** hoặc nút thêm bữa trong Nhật ký mở tab **Nhập tay**.
  Lối tắt **Quét món** mở thẳng tab **Ảnh** của cùng màn hình.
- Thanh dưới có **Nhập tay · Ảnh · Yêu thích**. Đổi tab giữ các món đang chọn,
  loại bữa/thời gian và nháp. Tab Ảnh đóng bàn phím, mở camera xem trước với
  khung hướng dẫn, nút chụp lớn, thư viện ảnh và nút Mã vạch.
- Chụp/chọn ảnh chỉ tạo ảnh trong bước kiểm tra. Người dùng đọc thông báo,
  đồng ý và bấm **Phân tích** mới gửi ảnh đến Google. Nút thông tin trên cùng
  giải thích cách quét và xử lý dữ liệu. Không tự phân tích mỗi frame camera.
- Kết quả AI có bước kiểm tra tên, nguồn và gram; vẫn giữ bản sửa không ghép
  một nguyên liệu cho cả đĩa. Món mới có thể kiểm tra/lưu vào Món của tôi.
  **Xác nhận món đã chọn** đưa món vào nháp đang có rồi về Nhập tay; không mở
  một bữa mới và không tự ghi nhật ký. Chưa chọn món thì chuyển sang tìm tay.
- **Mã vạch** dừng và giải phóng camera ảnh trước khi mở máy quét hiện có.
  Sản phẩm/gram được xác nhận thêm vào cùng nháp, giữ đúng quy đổi trên 100 g.
- Tab **Yêu thích** dùng danh sách thật của tài khoản, có loading/lỗi/rỗng;
  chọn món, xác nhận lượng rồi trở về Nhập tay. Danh sách không dùng dữ liệu giả.
- Kiểm tra các món đã chọn rồi bấm **Lưu** hoặc **Lưu bữa ăn**. Giữ giới hạn
  5 món, kiểm tra dữ liệu, bước chờ xác nhận máy chủ, chống gửi lặp, UID guard
  và cơ chế nháp mã hóa Android đã có.

## Camera và dependency

Thêm `camera 0.12.0+2` đang có trong cache và tương thích SDK dự án qua
`flutter pub add --offline camera:^0.12.0+2`. Pub ghi phiên bản chính xác
0.12.0+2; chỉ thêm các dependency chuyển tiếp camera, không nâng package cũ.
Chọn camera sau, ảnh độ phân giải high, `enableAudio: false`. Ảnh chụp và ảnh
thư viện cùng đi qua xử lý pixel/giới hạn 1024 px, tối đa 8 MB, không chuyển
EXIF/GPS gốc tới AI. Camera có thể giữ file tạm trong cache thiết bị.

Service tuần tự hóa khởi tạo/chụp/đóng camera; chuyển tab, xuống nền, đóng màn
hình và chuyển mã vạch sẽ giải phóng camera. Khi trở lại tab Ảnh/app có thể
mở lại; kết quả chụp đến muộn bị bỏ qua nếu phiên camera đã đổi. Khi chưa được
cấp quyền hoặc không có camera, vẫn có Chọn ảnh/Nhập tay và nút thử lại.

Manifest loại quyền RECORD_AUDIO và WRITE_EXTERNAL_STORAGE được plugin video
khai báo kèm theo vì luồng này chỉ chụp ảnh cache. Quyền CAMERA vẫn còn; không
đụng các quyền đọc thư viện hiện có. Không thêm ghi âm, lưu ảnh cloud, backend,
schema, Rules, model AI, billing hoặc thay enforcement App Check.

Tài liệu chính thức đã đối chiếu:

- [Flutter: chụp ảnh bằng camera](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)
- [Camera API và lifecycle](https://pub.dev/documentation/camera/latest/)
- [Camera changelog](https://pub.dev/packages/camera/changelog)

## Kiểm tra và giới hạn

Chi tiết lệnh/kết quả cuối được ghi trong test-report.md và
implementation-progress.md. Test camera/AI/barcode dùng adapter/fake khi cần,
không chứng minh camera hoặc API cloud thật hoạt động trên thiết bị. Ảnh
`build/unified-meal-camera.png` là screenshot widget thật với font ứng dụng;
vùng camera đen do session giả trong test, không phải ảnh chụp điện thoại.

Cần nghiệm thu quyền camera, preview/chụp/khôi phục sau xuống nền và chuyển
sang mã vạch trên Android thật. Hiện ADB chưa nhận thiết bị nên chưa cài APK
của lượt UI này. Thông tin dinh dưỡng từ ảnh vẫn là ước tính, không có kiểm định
độ chính xác mới trong lượt này. iOS/web chưa được nghiệm thu camera; luồng
preview hiện giới hạn Android và có thông báo đường lui khi không hỗ trợ.

Kết quả cuối lượt UI: full suite 518/518 qua, analyze 18 info cũ (0 warning/error),
APK debug build qua; format 18 file 0 thay đổi, whitespace check qua. Kiểm tra
APK không có quyền microphone/ghi public storage. Chưa có điện thoại ADB để cài
và nghiệm thu native camera. Chi tiết log/giới hạn ở test-report.md.

Bộ test UI cũng cập nhật bốn ảnh menu hành động `docs/ux/mfp/actions-*.png`
(sáng/tối, scale 1 và 1,5) theo nhãn “Thêm bữa ăn” mới; các ảnh này được giữ
cùng thay đổi giao diện. Mọi thay đổi có trước lượt này vẫn được bảo toàn.
