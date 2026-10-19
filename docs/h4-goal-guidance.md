# H4 — hướng dẫn mục tiêu duy trì

Tùy chọn trong form mục tiêu, không thay nhập tay. Chỉ đưa kcal tham khảo vào
form sau khi người dùng xem kết quả; vẫn chỉnh được và phải Lưu mục tiêu. Ba mục
tiêu chất hiện có được giữ; cảnh báo kcal/macros lệch vẫn cần xác nhận. Không
cộng kcal từ phút vận động, không tự áp thâm hụt/dư năng lượng cho giảm/tăng cân.

Nguồn chính: FAO/WHO/UNU Human Energy Requirements, bảng5.1/5.2/5.3:
https://www.fao.org/4/y5686e/y5686e07.htm (kiểm tra19/10/2026).
Schofield từkg, nam18–<30:15.057W+692.2, nữ14.818W+486.6;
nam30–<60:11.472W+873.1, nữ8.126W+845.6. Nhóm tuổi tại30 dùng nhánh30–60.
Nhân ví dụ PAL1.53/1.76/2.25 trong bảng5.1 theo người dùng tự chọn, làm tròn10kcal.
Đây là suy rộng mức trung bình nhóm, không phải đo tiêu hao cá nhân hoặc một
mô hình điều trị. FAO cũng nêu hạn chế áp dụng khác quần thể; chưa được chuyên
gia kiểm định riêng cho người Việt/HealthMate. Cần chuyên gia dinh dưỡng rà soát
trước phát hành rộng; không gắn nhãn chính xác/cá nhân hóa y khoa.

Phạm vi sản phẩm cho helper mới18–59tuổi, người dùng xác nhận sức khỏe thông
thường/không mang thai/cho con bú/chế độ điều trị/vận động chuyên nghiệp. Ngoài
phạm vi, không nhận hệ số gốc hoặc không muốn cung cấp dữ liệu: quay về nhập tay
và chuyên gia. Ranh giới tuổi/20–300kg là phạm vi/giới hạn kỹ thuật của helper,
không phải phân loại thể trạng. Không đoán hệ số sinh lý/mức hoạt động từ hồ sơ,
không thu thập chiều cao vì phương pháp này không dùng nó. Không lưu đầu vào
helper vào Firestore/local storage. Chỉ giá trị người dùng chỉnh/xác nhận được
lưu bằng repository nutrition_targets hiện có, source user_manual (lựa chọn
đã được người dùng xác nhận), ngày hiệu lực>=hôm nay, không viết lại lịch sử.

File mới: models/energy_estimate.dart, presentation/energy_estimate_dialog.dart,
test/h4_energy_estimate_test.dart. Form mục tiêu có nút tùy chọn; không schema/
Rules mới ởH4. Luồng cũ retry/serverack/UIDguard/createdAt/history giữ nguyên.
Core-scope.md từng hoãn BMR/TDEE là baseline; yêu cầu H4 hiện tại chủ động mở
helper tham khảo hạn chế này, không mở rộng sang gym hoặc AI.

Focused cuối9/9 pass7s; analyze sạch12.9s. Các vòng đầu widget chưa cuộn tới
trường lazy và dùng nhầm Scrollable của SelectableText nguồn; sửa harness và
SelectionArea thay SelectableText (giữ chọn/copy nguồn), không bỏ assertion.
Toàn suite/Android đang được kiểm chứng riêng; cập nhật kết quả cuối bên dưới.

## H4 — đạt local/Android Emulator

Helper tùy chọn mức duy trì từ FAO/WHO/UNU/Schofield; đầu vào tự chọn, chưa lưu
sinh lý, phạm vi18–59 và đường quay về nhập tay. Xem cách tính, đưa kcal vàoform,
chỉnh rồi xác nhận lưu với ngày hiệu lực; giữ macro/historical target. Không tự
thâm hụt/dư năng lượng hoặc cộng kcal vận động. Quyết định/nguồn/giới hạn và file
chính trong h4-goal-guidance.md; cần chuyên gia rà soát trước phát hành rộng.
Format10file/5đổi rồi9file0; analyze sạch12.9s; focused9/9(7s); full407/407(49s).
Android h4-android-final.log:10checkpoint +H1/H2/H3/H4pass235s trênAVDQA/API30,
demo-healthmate-rules. H4 UIxemkếtquả2670kcal chưa ghi, sửa2600rồiLưu, đọcSDK
đúng2600, ngàytrước1800khôngđổi; BkhôngđọcA. Ảnhdocs/ux/h4/maintenance-estimate.png.
Lượt nativeđầu bị guardchặn vìAVDđãđóng trong khoảngnghỉ; khởi độnglạiđúngAVDQA,
khôngchuyểnsangmáythật. KGP/SwiftShaderwarningscũcòn. H4khôngđổischema/Rules,
khôngdeploy/importproduction, khôngcommit/push, AIgiữtắt. TiếptheoH5.
