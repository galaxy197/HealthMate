# U1 — Ảnh trước/sau và bằng chứng viewport

Ảnh widget render thật với font Be Vietnam Pro/Material Icons đóng gói; repository
fake và dữ liệu tổng hợp, không phải dữ liệu production. Cùng390×844 logical px,
textScale1.0, ngày18/10/2026, offset0, hai bữa195kcal (hôm nay/hôm trước), target
2000kcal/100gđạm/250gtinh bột/60gbéo,750ml/25phút, cân70→69,5kg. Không cuộn hoặc
ensureVisible trước phép đo/ảnh viewport đầu. Ảnh baseline lấy trước sửa UX từ
fd2f72b; không coi ảnh ở vị trí đã cuộn là viewport đầu.

| Màn hình/theme | Trước | Sau |
|---|---|---|
| Nhật ký sáng | [Ảnh trước](before-journal-light-390-1.0.png) | [Ảnh sau](after-journal-light-390-1.0.png) |
| Nhật ký tối | [Ảnh trước](before-journal-dark-390-1.0.png) | [Ảnh sau](after-journal-dark-390-1.0.png) |
| Tiến độ sáng | [Ảnh trước](before-progress-light-390-1.0.png) | [Ảnh sau](after-progress-light-390-1.0.png) |
| Tiến độ tối | [Ảnh trước](before-progress-dark-390-1.0.png) | [Ảnh sau](after-progress-dark-390-1.0.png) |

| Chỉ số đo | Trước | Sau |
|---|---:|---:|
| Vùng bấm thêm Bữa sáng, top–bottom |1319–1367dp|497–545dp|
| Vùng biểu đồ tuần, top–bottom |888–1128dp|362–602dp|
| Đáy viewport không bị bottom bar che |748dp|748dp|
| Scroll offset lúc đo |0|0|
| Dùng lại món Gần đây, số lần bấm |5|5|
| Số lần cuộn cho luồng đó |1|0|
| Số lần nhập tìm kiếm |0|0|
| Xác nhận khẩu phần đã có / xác nhận thêm mới |1 / 0|1 / 0|

Luồng5bấm: Thêm theo bữa → Gần đây → Dùng lại món → xác nhận khẩu phần đã có →
Lưu. Test xác minh ngày đang xem16/10 và loại Bữa sáng,150g/195kcal, chỉ1write;
không dùng helper+ toàn cục của hôm nay. Baseline luồng này được chạy lại trên copy
code fd2f72b trước khi sync U1;6file UI/form liên quan so git blob đều khớp
([bằng chứng](before-flow-source.json)). Các JSON measurements/recent-flow trong
thư mục này chứa kết quả máy đo cho cả hai theme, trước/sau.

Android E2E dùng SDK/repository thật qua Auth/Firestore Emulator, AVD riêng API30,
UTC+07, không dữ liệu production. Thêm kiểm tra viewport đầu với target đủ macro
và dùng lại món5bấm. Ảnh Android là fixture E2E khác với fixture widget ở bảng trên,
không dùng chúng thay ảnh so sánh cùng dữ liệu:

- [Android Nhật ký viewport đầu](android-journal-first-viewport.png): nút584–632dp,
  đáy body685,1dp, hit-test được.
- [Android Tiến độ viewport đầu](android-progress-first-viewport.png): chart bắt
  đầu386dp, khoảng tuần và tổng cùng hiển thị.

12matrix360×800/412×915 × chữ100/150/200% × sáng/tối kiểm tra đọc/cuộn, form và
nút Lưu không bị bàn phím260dp che. Chữ lớn không bị ép đạt lượng nội dung như
chữ100%. Native còn có bước tối/chữ200%; ảnh/log ở build/u1-android (ignored).
QA máy thật, Play Integrity, release ký phát hành và E2E production còn chờ;
[báo cáo chi tiết](../../test-report.md), [playbook U2](../../firebase-deployment-plan.md).
