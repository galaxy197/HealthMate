# SRS — Đặc tả yêu cầu phần mềm HealthMate

**Phiên bản:** 0.1 — Draft để review/nghiệm thu đồ án  
**Ngày:** 27/10/2026 · **Múi giờ tài liệu:** Asia/Saigon  
**Sản phẩm:** HealthMate (tên hiện tại trong GitHub; không tự đổi tên thành NutriTrack)  
**Repository:** https://github.com/luuxuantung285600/HealthMate  
**Baseline GitHub:** [`14bb579b6d1549db1569ee7710b7b1733e92c5de`](https://github.com/luuxuantung285600/HealthMate/commit/14bb579b6d1549db1569ee7710b7b1733e92c5de) · branch `main`  
**Tài liệu đi cùng:** [Product backlog](HealthMate-Backlog-2026-10-27.md)

| Phiên bản | Ngày | Thay đổi | Trạng thái |
|---|---|---|---|
| 0.1 | 27/10/2026 | Lập SRS/backlog từ GitHub, yêu cầu người dùng và rubric giảng viên | Chờ review của người dùng/giảng viên |

**Người duyệt/phụ trách:** chưa được chỉ định. Không suy ra tài liệu đã được giảng viên phê duyệt chỉ vì được tạo trong repository.

## 1. Mục đích, cách đọc và nguồn gốc yêu cầu

SRS mô tả hành vi cần có của ứng dụng di động HealthMate, web quản trị, các ràng buộc dữ liệu và tiêu chí nghiệm thu. Tài liệu giúp người phát triển, kiểm thử và giảng viên truy từ yêu cầu tới chức năng, test và bằng chứng.

GitHub API đã xác nhận `main` tại SHA trên trùng HEAD cục bộ khi lập tài liệu. Working tree có thay đổi USDA/catalog/form chưa commit; **các thay đổi đó được giữ nguyên và không tính là chức năng đã phát hành ở baseline này**. Không checkout/reset/commit/push, không cập nhật backend để làm SRS. Nếu nguồn đổi sau SHA này cần review và tăng phiên bản tài liệu.

Thứ tự nguồn: yêu cầu trực tiếp người dùng và rubric môn học → source/test tại baseline → tài liệu mới nhất có đối chiếu source. Ghi chú lịch sử như “tạm gác admin”, onboarding 5 bước hay điều hướng “Thêm” không được dùng thay trạng thái mới hơn đã kiểm tra. Handoff UX/UI đầu ngày được viết trước commit Figma v2, vì vậy không dùng làm mô tả UI mới nhất.

### 1.1 Trạng thái và mức yêu cầu

- **CODE:** có implementation trong baseline và có suite/bằng chứng liên quan; chưa có nghĩa mọi AC đã UAT production.
- **PARTIAL:** có nguồn dữ liệu/chức năng nền nhưng cần chuẩn hóa hoặc bổ sung trước khi nghiệm thu đúng rubric.
- **PROPOSED:** yêu cầu đề xuất để lấp khoảng trống; chưa triển khai, chưa tự được phê duyệt để đổi kiến trúc/chi phí.
- **P0:** ưu tiên đóng khoảng trống/chứng minh tiêu chí môn học. **P1:** chức năng nền phải bảo toàn. **P2:** mở rộng sau, ngoài baseline nghiệm thu.
- Mỗi FR là một yêu cầu kiểm chứng được; AC chi tiết và dependency nằm trong story tương ứng ở backlog. NFR là yêu cầu chất lượng, có cách đo/test riêng.
- Các chỉ tiêu hiệu năng mới là **mục tiêu đề xuất**, không phải số đo đã đạt.

### 1.2 Nguồn tham chiếu cố định theo baseline

| Mã | Nội dung | Nguồn |
|---|---|---|
| SRC-01 | Nguyên tắc/phạm vi | [AGENTS.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/AGENTS.md) |
| SRC-02 | Dependencies/nền tảng | [pubspec.yaml](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/pubspec.yaml) |
| SRC-03 | Routes và shell | [lib/core/widgets/app_shell.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/widgets/app_shell.dart) |
| SRC-04 | Khảo sát mới | [docs/personalization-questionnaire.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/personalization-questionnaire.md) |
| SRC-05 | Mục tiêu kcal | [docs/personalized-nutrition.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/personalized-nutrition.md) |
| SRC-06 | Dữ liệu/quyền | [docs/database-design.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/database-design.md) |
| SRC-07 | Admin đã hoàn thiện | [docs/admin-completion.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/admin-completion.md) |
| SRC-08 | Admin production | [docs/admin-production.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/admin-production.md) |
| SRC-09 | Android/admin mới | [docs/admin-runtime-integration.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/admin-runtime-integration.md) |
| SRC-10 | Figma/UI mới | [docs/figma-v2-implementation.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/figma-v2-implementation.md) |
| SRC-11 | Báo cáo năm | [docs/year-and-custom-reports.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/year-and-custom-reports.md) |
| SRC-12 | Wellness | [docs/wellness-insights.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/wellness-insights.md) |
| SRC-13 | Chat 50 lượt | [docs/chatbot-capacity-update.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/chatbot-capacity-update.md) |
| SRC-14 | Kiểm thử đã ghi nhận | [docs/test-report.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/test-report.md) |
| SRC-15 | Hợp nhất thêm bữa | [docs/unified-meal-entry.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/unified-meal-entry.md) |

**SRC-16 — Rubric do người dùng cung cấp trong chat:** tốc độ tải; dashboard ≥4 loại dữ liệu; danh mục CRUD/tìm/phân trang/STT/trạng thái màu/lọc loại; xóa hỏi; Excel toàn danh sách; người dùng/phân quyền; lưu ảnh; ≥4 báo cáo; Pie/Bar/click chi tiết; chức năng như gửi mail/OTP; 2 chức năng in; Figma, deploy, SRS, Jira, Unit Test. Không có tệp đề bài chính thức kèm theo để xác nhận thêm ngoài nội dung này.

## 2. Tổng quan sản phẩm

### 2.1 Vấn đề và mục tiêu

Người dùng cần một nơi ghi bữa, nước, vận động, cân nặng và thói quen; kiểm tra dinh dưỡng theo mục tiêu, xem lịch sử, được hỗ trợ bởi quét ảnh và Chat AI. Đơn vị vận hành cần duy trì danh mục món, kiểm soát truy cập và cấu hình tính năng có truy vết.

Mục tiêu sản phẩm là hỗ trợ nhận biết và duy trì thói quen. HealthMate không chẩn đoán, kê đơn hoặc thay tư vấn chuyên môn. Mọi số từ ảnh/cảm biến/thuật toán tham khảo phải có nguồn và giới hạn; không tạo chỉ số sức khỏe tổng hợp chưa định nghĩa.

### 2.2 Phạm vi

**Đã có trong baseline:** Auth email/Google, xác minh/reset email; hồ sơ/cân nặng; 20 câu cá nhân hóa và mục tiêu kcal; catalog/nhật ký/thư viện/công thức/mẫu bữa; ảnh và barcode; nước/vận động; nhắc local/thực đơn/bước/ngủ; mục tiêu/Quest; dashboard/báo cáo theo kỳ/CSV; Chat AI có ngữ cảnh và lịch sử; admin catalog/directory/control/config/audit/XLSX; UI theo Figma v2; test và cấu hình chạy/build.

**Đề xuất bổ sung để đủ rubric:** chuẩn hóa R01–R04, Pie và drill-down; hai luồng in; ảnh nghiệp vụ có quyền và phương án chi phí; benchmark/UAT và hồ sơ nghiệm thu/Jira.

**Ngoài phạm vi triển khai được phê duyệt của lượt tài liệu:** Facebook (đã bỏ), SMS bắt buộc khi chưa xác nhận, thanh toán/subscription, mạng xã hội, smartwatch/Health Connect, tự chẩn đoán, tự đo giai đoạn ngủ, huấn luyện model riêng, hệ thống bài tập/video hoàn chỉnh. Những ý tưởng workout/kiểm duyệt món/hỗ trợ mở rộng nằm trong danh sách xem xét, không tự chuyển thành chức năng đã có.

### 2.3 Tác nhân và quyền

| Tác nhân | Khả năng | Không suy diễn thành quyền |
|---|---|---|
| Khách/chưa đăng nhập | Đăng ký/đăng nhập, Google, yêu cầu reset | Không đọc sức khỏe hay admin |
| Người dùng chưa xác minh | Xác minh/gửi lại/kiểm tra phiên | Không vượt gate dữ liệu riêng |
| Thành viên đã xác minh | Dữ liệu của chính UID, consent AI, mục tiêu, xuất dữ liệu riêng | Không sửa catalog chung hoặc dữ liệu người khác |
| Quản trị viên có role enabled | Catalog, directory cơ bản, khóa/mở, config, audit, Excel | Không mặc nhiên đọc hồ sơ/nhật ký/chat/khảo sát riêng; không tự cấp role từ web |
| Chủ dự án/người vận hành hạ tầng | Cấu hình Firebase/Cloudflare, bootstrap role qua quyền đáng tin cậy | Không phải chức năng UI admin đã triển khai |
| Firebase/Auth/AI/Workers/OFF/Android | Dịch vụ bên ngoài thực hiện hợp đồng tích hợp | Không phải con người có quyền duyệt nghiệp vụ |

Vai trò chuyên gia dinh dưỡng/huấn luyện viên được người dùng cho xem dữ liệu **chưa có**. Muốn thêm cần yêu cầu và mô hình consent/quyền riêng, không dùng role admin hiện tại thay thế.

## 3. Bối cảnh hệ thống và giao diện bên ngoài

| Thành phần | Giao tiếp và trách nhiệm |
|---|---|
| Flutter Android | UI tiếng Việt, Riverpod, go_router; repository/service, kiểm tra và xác nhận ghi |
| Firebase Authentication | Email/password, Google, verification/reset, session và reauthentication |
| Cloud Firestore | Database cloud chính; dữ liệu theo UID, catalog, admin controls/config/audit; Rules phía máy chủ |
| App Check | Attestation theo môi trường và dịch vụ đã cấu hình; không quảng cáo tất cả endpoint đã enforce nếu chưa kiểm chứng |
| Firebase AI Logic/Gemini | Phân tích ảnh; cấu hình model từ build/source hiện có, cần kiểm tài liệu khi thay provider/model |
| Cloudflare Workers/Workers AI | Chat AI hiện tại, xác thực/token/rate-limit; khác provider scanner |
| Open Food Facts | Tra sản phẩm mã vạch; không đảm bảo mọi barcode có dữ liệu |
| Android native | Camera/quyền, TYPE_STEP_COUNTER/foreground service, notification/reminder, lưu cục bộ theo UID |
| Web admin trên Firebase Hosting | JS/CSS/Firebase Web SDK; role và App Check; quản trị không thay DB chính |
| Cache/bundle/SQLite | Hỗ trợ tải/tìm món, không phải database cloud thay Firestore |

Quyết định chatbot qua Cloudflare đã được người dùng cho làm sau AGENTS ban đầu. Tài liệu ghi implementation thực tế, không tự khôi phục lựa chọn chatbot Gemini cũ. Không thêm dịch vụ/billing trong lượt này.

### 3.1 Điều hướng và giao diện tại baseline

Thanh dưới là **Hôm nay | Nhật ký | + | Tiến độ | Thói quen**: bốn trang và một hành động. Hồ sơ/Cá nhân vào qua avatar ở các màn đã có header tương ứng. Từ Tiến độ có thể về Hôm nay để mở avatar. Không còn mô tả “Thêm” là mục dưới cùng ở baseline này.

Dấu + mở ghi nhanh cho hôm nay, có lối vào các nghiệp vụ thật; thêm trực tiếp tại ngày lịch sử của Nhật ký giữ ngày đã chọn. Wellness có hub và các panel nhắc bữa, thực đơn, bước, ngủ, dưỡng chất, tiến độ. Quest/Chat không vì thiếu tab riêng mà bị coi là chưa có.

Các route: `/dashboard`, `/journal`, `/progress`, `/wellness`, `/profile`, `/quest`, `/chat`, `/food-library`, `/personalization`, `/onboarding`, `/auth`, `/verify-email`, `/session`, `/about`, `/privacy`, `/disclaimer`.

Nguồn UI/Figma/frame và các ảnh đối chiếu đã được ghi ở SRC-10. Không coi việc đọc tài liệu repo là một lần nghiệm thu Figma/trình duyệt mới trong lượt này.

### 3.2 Môi trường và phụ thuộc

Android cần SDK/cấu hình Firebase, cảm biến/quyền phù hợp; mạng cần cho xác thực, AI và xác nhận server. App mới nhận admin runtime đầy đủ khi chạy/build theo script dùng `config/admin-runtime.json`; plain build bỏ define không được mặc định xem là tương đương.

Admin production đã được ghi nhận tại https://healthmate-app-20261013.web.app. Tài liệu không chứa UID người thật, mật khẩu, service-account hoặc debug token. Deployment và test lịch sử phải được kiểm lại khi nghiệm thu bản khác.

## 4. Danh mục yêu cầu chức năng

Có **52 FR**: 43 có code baseline, 4 có nền/chưa đủ nghiệm thu và 5 đề xuất mới. Các trạng thái không phải tỷ lệ hoàn thành đồ án; tiêu chí giáo viên còn cần UAT/bằng chứng.

AC cụ thể của từng yêu cầu nằm ở story được liên kết. Các yêu cầu đề xuất không tự cho phép thực hiện thay đổi có chi phí, quyền dữ liệu hoặc kiến trúc.

### 4.1 Tài khoản và xác thực

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-AUTH-01 | Đăng ký và đăng nhập email/mật khẩu: khách tạo và truy cập tài khoản HealthMate. | Có code tại baseline; còn UAT | [HM-US-001](HealthMate-Backlog-2026-10-27.md#hm-us-001) |
| FR-AUTH-02 | Tiếp tục với Google: khách vào app bằng tài khoản Google. | Có code tại baseline; còn UAT | [HM-US-002](HealthMate-Backlog-2026-10-27.md#hm-us-002) |
| FR-AUTH-03 | Xác minh email: người dùng chưa xác minh xác minh danh tính trước truy cập dữ liệu riêng. | Có code tại baseline; còn UAT | [HM-US-003](HealthMate-Backlog-2026-10-27.md#hm-us-003) |
| FR-AUTH-04 | Quên mật khẩu qua email: khách khôi phục quyền đăng nhập. | Có code tại baseline; còn UAT | [HM-US-004](HealthMate-Backlog-2026-10-27.md#hm-us-004) |
| FR-AUTH-05 | Phiên đăng nhập, đổi mật khẩu và đăng xuất: thành viên quản lý an toàn phiên tài khoản. | Có code tại baseline; còn UAT | [HM-US-005](HealthMate-Backlog-2026-10-27.md#hm-us-005) |
| FR-AUTH-06 | Xóa tài khoản và dữ liệu thuộc tài khoản: thành viên chủ động kết thúc sử dụng và dọn dữ liệu cá nhân. | Có code tại baseline; còn UAT | [HM-US-006](HealthMate-Backlog-2026-10-27.md#hm-us-006) |

### 4.2 Hồ sơ và cá nhân hóa

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-PRO-01 | Onboarding và khảo sát cá nhân hóa 20 câu: thành viên thiết lập hồ sơ và thói quen ban đầu. | Có code tại baseline; còn UAT | [HM-US-007](HealthMate-Backlog-2026-10-27.md#hm-us-007) |
| FR-PRO-02 | Đề xuất kcal và macro cá nhân hóa: thành viên tham khảo mục tiêu từ dữ liệu đã cung cấp. | Có code tại baseline; còn UAT | [HM-US-008](HealthMate-Backlog-2026-10-27.md#hm-us-008) |
| FR-PRO-03 | Mục tiêu dinh dưỡng có ngày hiệu lực: thành viên đặt hoặc thay mục tiêu mà giữ lịch sử. | Có code tại baseline; còn UAT | [HM-US-009](HealthMate-Backlog-2026-10-27.md#hm-us-009) |
| FR-PRO-04 | Hồ sơ, cân nặng và BMI tham khảo: thành viên theo dõi thay đổi thể trạng của mình. | Có code tại baseline; còn UAT | [HM-US-010](HealthMate-Backlog-2026-10-27.md#hm-us-010) |

### 4.3 Dữ liệu món và ghi bữa

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-NUT-01 | Tìm và chọn thực phẩm có nguồn: thành viên chọn món và khẩu phần có căn cứ. | Có code tại baseline; còn UAT | [HM-US-011](HealthMate-Backlog-2026-10-27.md#hm-us-011) |
| FR-NUT-02 | CRUD nhật ký bữa ăn và snapshot khẩu phần: thành viên ghi lại món thực sự đã ăn. | Có code tại baseline; còn UAT | [HM-US-012](HealthMate-Backlog-2026-10-27.md#hm-us-012) |
| FR-NUT-03 | Món riêng, công thức và yêu thích: thành viên tái sử dụng món thuộc thư viện cá nhân. | Có code tại baseline; còn UAT | [HM-US-013](HealthMate-Backlog-2026-10-27.md#hm-us-013) |
| FR-NUT-04 | Mẫu bữa, nháp và thêm nhanh: thành viên giảm thao tác nhập lặp. | Có code tại baseline; còn UAT | [HM-US-014](HealthMate-Backlog-2026-10-27.md#hm-us-014) |
| FR-NUT-05 | Macro, chất xơ và dưỡng chất mở rộng: thành viên hiểu dữ liệu dinh dưỡng có và chưa có. | Có code tại baseline; còn UAT | [HM-US-015](HealthMate-Backlog-2026-10-27.md#hm-us-015) |
| FR-NUT-06 | Xác nhận độ đầy đủ nhật ký ngày: thành viên giúp báo cáo không hiểu sai ngày thiếu ghi nhận. | Có code tại baseline; còn UAT | [HM-US-016](HealthMate-Backlog-2026-10-27.md#hm-us-016) |

### 4.4 Quét ảnh và mã vạch

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-SCN-01 | Camera, chọn ảnh và đồng ý gửi AI: thành viên nhận hỗ trợ ghi bữa từ ảnh. | Có code tại baseline; còn UAT | [HM-US-017](HealthMate-Backlog-2026-10-27.md#hm-us-017) |
| FR-SCN-02 | Kiểm tra thành phần và kết quả dinh dưỡng ảnh: thành viên sửa ước tính trước khi ghi nhận. | Có code tại baseline; còn UAT | [HM-US-018](HealthMate-Backlog-2026-10-27.md#hm-us-018) |
| FR-SCN-03 | Quét mã vạch và tra sản phẩm: thành viên nhập thực phẩm đóng gói nhanh. | Có code tại baseline; còn UAT | [HM-US-019](HealthMate-Backlog-2026-10-27.md#hm-us-019) |

### 4.5 Nước, vận động và thói quen

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-WEL-01 | Nhật ký nước uống: thành viên theo dõi lượng nước đã ghi. | Có code tại baseline; còn UAT | [HM-US-020](HealthMate-Backlog-2026-10-27.md#hm-us-020) |
| FR-WEL-02 | Nhật ký vận động thủ công: thành viên ghi loại hoạt động và thời lượng. | Có code tại baseline; còn UAT | [HM-US-021](HealthMate-Backlog-2026-10-27.md#hm-us-021) |
| FR-WEL-03 | Nhắc ghi bữa local: thành viên được nhắc theo giờ tự chọn. | Có code tại baseline; còn UAT | [HM-US-022](HealthMate-Backlog-2026-10-27.md#hm-us-022) |
| FR-WEL-04 | Lập thực đơn nhiều ngày: thành viên lên kế hoạch ăn và ghi khi đã ăn. | Có code tại baseline; còn UAT | [HM-US-023](HealthMate-Backlog-2026-10-27.md#hm-us-023) |
| FR-WEL-05 | Bước chân Android và lịch sử: thành viên theo dõi bước từ thiết bị sau opt-in. | Có code tại baseline; còn UAT | [HM-US-024](HealthMate-Backlog-2026-10-27.md#hm-us-024) |
| FR-WEL-06 | Ghi giấc ngủ thủ công và nhắc ngủ: thành viên lưu và xem thời gian ngủ tự khai. | Có code tại baseline; còn UAT | [HM-US-025](HealthMate-Backlog-2026-10-27.md#hm-us-025) |
| FR-WEL-07 | Ngân sách ăn và năng lượng bước đã xác nhận: thành viên chủ động áp dụng ước tính vận động vào hôm nay. | Có code tại baseline; còn UAT | [HM-US-026](HealthMate-Backlog-2026-10-27.md#hm-us-026) |

### 4.6 Mục tiêu và Quest

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-GOL-01 | Quản lý mục tiêu sức khỏe: thành viên đặt và theo dõi mục tiêu phù hợp. | Có code tại baseline; còn UAT | [HM-US-027](HealthMate-Backlog-2026-10-27.md#hm-us-027) |
| FR-GOL-02 | Nhiệm vụ sức khỏe hằng ngày: thành viên có gợi ý hành động nhỏ từ dữ liệu thật. | Có code tại baseline; còn UAT | [HM-US-028](HealthMate-Backlog-2026-10-27.md#hm-us-028) |

### 4.7 Dashboard và lịch sử báo cáo

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-RPT-01 | Dashboard ít nhất bốn nhóm dữ liệu: thành viên xem tổng quan dữ liệu và hành động tiếp theo. | Có code tại baseline; còn UAT | [HM-US-029](HealthMate-Backlog-2026-10-27.md#hm-us-029) |
| FR-RPT-02 | Tổng kết tuần và biểu đồ hiện có: thành viên xem xu hướng từ các ghi nhận của mình. | Có code tại baseline; còn UAT | [HM-US-030](HealthMate-Backlog-2026-10-27.md#hm-us-030) |
| FR-RPT-03 | Báo cáo theo năm và khoảng tùy chọn: thành viên xem lại lịch sử theo nhu cầu. | Có code tại baseline; còn UAT | [HM-US-031](HealthMate-Backlog-2026-10-27.md#hm-us-031) |
| FR-RPT-04 | Xuất nhật ký cá nhân CSV: thành viên lấy bản sao dữ liệu trong khoảng đã chọn. | Có code tại baseline; còn UAT | [HM-US-032](HealthMate-Backlog-2026-10-27.md#hm-us-032) |

### 4.8 Chat AI

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-CHT-01 | Chat AI sau đồng ý: thành viên hỏi linh hoạt về dinh dưỡng và thói quen. | Có code tại baseline; còn UAT | [HM-US-033](HealthMate-Backlog-2026-10-27.md#hm-us-033) |
| FR-CHT-02 | Ngữ cảnh cá nhân có nguồn và giới hạn quyền AI: thành viên nhận câu trả lời khớp số liệu của mình. | Có code tại baseline; còn UAT | [HM-US-034](HealthMate-Backlog-2026-10-27.md#hm-us-034) |
| FR-CHT-03 | Lịch sử chat và giới hạn 50 lượt mỗi cuộc: thành viên tiếp tục cuộc đang dùng khi đổi tab. | Có code tại baseline; còn UAT | [HM-US-035](HealthMate-Backlog-2026-10-27.md#hm-us-035) |

### 4.9 Quản trị ứng dụng

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-ADM-01 | Đăng nhập admin và kiểm tra quyền server: quản trị viên truy cập công cụ đúng role. | Có code tại baseline; còn UAT | [HM-US-036](HealthMate-Backlog-2026-10-27.md#hm-us-036) |
| FR-ADM-02 | CRUD catalog quản trị và xóa mềm: quản trị viên duy trì dữ liệu món dùng chung. | Có code tại baseline; còn UAT | [HM-US-037](HealthMate-Backlog-2026-10-27.md#hm-us-037) |
| FR-ADM-03 | Directory và khóa/mở quyền HealthMate: quản trị viên hỗ trợ kiểm soát truy cập app. | Có code tại baseline; còn UAT | [HM-US-038](HealthMate-Backlog-2026-10-27.md#hm-us-038) |
| FR-ADM-04 | Cấu hình runtime, bảo trì và tích hợp Android: quản trị viên điều chỉnh tính năng mà không phát hành lại mỗi lần. | Có code tại baseline; còn UAT | [HM-US-039](HealthMate-Backlog-2026-10-27.md#hm-us-039) |
| FR-ADM-05 | Dashboard, tìm/lọc/phân trang và Excel admin: quản trị viên tra cứu và xuất danh sách đầy đủ. | Có code tại baseline; còn UAT | [HM-US-040](HealthMate-Backlog-2026-10-27.md#hm-us-040) |
| FR-ADM-06 | Audit bất biến và cập nhật danh sách: quản trị viên truy vết thay đổi và xử lý xung đột. | Có code tại baseline; còn UAT | [HM-US-041](HealthMate-Backlog-2026-10-27.md#hm-us-041) |

### 4.10 UX/UI theo Figma

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-UI-01 | Điều hướng và giao diện theo Figma hiện có: thành viên tìm chức năng theo bố cục thống nhất. | Có code tại baseline; còn UAT | [HM-US-042](HealthMate-Backlog-2026-10-27.md#hm-us-042) |
| FR-UI-02 | Trạng thái, khả năng tiếp cận và xác nhận: người dùng thao tác được trên màn nhỏ và chữ lớn. | Có code tại baseline; còn UAT | [HM-US-043](HealthMate-Backlog-2026-10-27.md#hm-us-043) |

### 4.11 Hoàn thiện báo cáo và in theo yêu cầu môn học

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-REP-01 | Chuẩn hóa báo cáo dinh dưỡng cho nghiệm thu: thành viên có một báo cáo dinh dưỡng đủ tiêu chí môn học. | Có nền; chưa đủ nghiệm thu | [HM-US-044](HealthMate-Backlog-2026-10-27.md#hm-us-044) |
| FR-REP-02 | Chuẩn hóa báo cáo nước uống cho nghiệm thu: thành viên xem tổng và chi tiết lượng nước theo kỳ. | Có nền; chưa đủ nghiệm thu | [HM-US-045](HealthMate-Backlog-2026-10-27.md#hm-us-045) |
| FR-REP-03 | Chuẩn hóa báo cáo vận động cho nghiệm thu: thành viên xem thời lượng và loại vận động đã ghi. | Có nền; chưa đủ nghiệm thu | [HM-US-046](HealthMate-Backlog-2026-10-27.md#hm-us-046) |
| FR-REP-04 | Chuẩn hóa báo cáo cân nặng cho nghiệm thu: thành viên xem số đo và thay đổi theo kỳ. | Có nền; chưa đủ nghiệm thu | [HM-US-047](HealthMate-Backlog-2026-10-27.md#hm-us-047) |
| FR-REP-05 | Biểu đồ Pie và drill-down có ý nghĩa: thành viên hiểu thành phần tạo nên tỷ lệ báo cáo. | Đề xuất; chưa triển khai | [HM-US-048](HealthMate-Backlog-2026-10-27.md#hm-us-048) |
| FR-PRN-01 | In danh mục món ăn quản trị: quản trị viên in danh sách món để kiểm tra hoặc nộp minh chứng. | Đề xuất; chưa triển khai | [HM-US-049](HealthMate-Backlog-2026-10-27.md#hm-us-049) |
| FR-PRN-02 | In báo cáo theo kỳ của chính người dùng: thành viên in báo cáo sức khỏe riêng theo khoảng đã chọn. | Đề xuất; chưa triển khai | [HM-US-050](HealthMate-Backlog-2026-10-27.md#hm-us-050) |

### 4.12 Lưu trữ ảnh nghiệp vụ

| ID | Hệ thống phải hỗ trợ | Trạng thái | Story/AC |
|---|---|---|---|
| FR-IMG-01 | Thiết kế lưu ảnh catalog và kiểm tra chi phí/quyền: chủ dự án đáp ứng yêu cầu lưu ảnh mà không đổi riêng tư tùy tiện. | Đề xuất; chưa triển khai | [HM-US-051](HealthMate-Backlog-2026-10-27.md#hm-us-051) |
| FR-IMG-02 | Tải lên, thay và gỡ ảnh món catalog: quản trị viên quản lý ảnh minh họa gắn món ăn. | Đề xuất; chưa triển khai | [HM-US-052](HealthMate-Backlog-2026-10-27.md#hm-us-052) |

## 5. Yêu cầu phi chức năng và cách nghiệm thu

Các phương pháp dưới đây là kế hoạch kiểm chứng. Kết quả test lịch sử ở mục 11 không thay thế việc đo các mục tiêu mới.

| ID | Thuộc tính và trạng thái | Yêu cầu | Kiểm chứng |
|---|---|---|---|
| NFR-SEC-01 | **Phân quyền tại máy chủ** — Đã có Rules/test; UAT cuối còn chờ | Mặc định từ chối; member chỉ đọc/ghi dữ liệu UID mình; admin có role enabled mới quản trị, không mặc nhiên đọc sức khỏe/chat. | Emulator với A/B/admin/anonymous và UID giả mạo; khóa/mở, thu hồi role; client ẩn nút không được thay Rules. |
| NFR-SEC-02 | **Bí mật và tối thiểu hóa dữ liệu** — Đã có thiết kế; cần giữ khi mở rộng | Không chứa private key/service-account/App Check debug token trong repo/artifact công khai; không gửi toàn bộ hồ sơ/khảo sát cho AI. | Rà source và gói phát hành; kiểm prompt/context/exports; chỉ ghi log dữ liệu cần thiết. |
| NFR-DAT-01 | **Toàn vẹn và snapshot** — Đã có trong nghiệp vụ | Tính totals từ item/khẩu phần; snapshot lịch sử không bị cập nhật theo catalog; confirm-save, revision và audit nguyên tử ở luồng đã thiết kế. | Test sửa nguồn không đổi bữa cũ, retry không tạo trùng, revision xung đột, lỗi giữa các bước onboarding phải báo đúng phần đã lưu. |
| NFR-DAT-02 | **Ngày, đơn vị và dữ liệu thiếu** — Đã có trong model/test | kg/cm/ml/phút/kcal/g/mg thống nhất; dateKey theo ngày địa phương; null khác 0; tương lai/thiếu dữ liệu không thành điểm đo giả. | Test qua nửa đêm/năm nhuận, số ngày tính cả hai đầu, nhiều UID và dữ liệu thiếu từng nutrient. |
| NFR-PER-01 | **Tốc độ tải có phép đo** — Mục tiêu đề xuất, chưa benchmark | Đề xuất: dữ liệu ngày đầu tiên ≤5 giây ở ít nhất 95% của 20 lượt trên máy/mạng demo đã công bố; phản hồi bấm/chuyển trạng thái ≤300ms khi không chờ mạng. Không áp SLA này cho AI bên thứ ba. | Ghi máy, Android, mạng, dataset, cold/warm, từng mẫu và P95; thiếu/lỗi vẫn là mẫu, không bỏ để đạt; nếu không đạt lập issue thay vì sửa kết quả. |
| NFR-PER-02 | **Đọc có giới hạn và xuất đầy đủ** — Đã có giới hạn hiện tại | Admin cursor 200, trần 5.000 mục/collection, trang UI 25; báo cáo tối đa 366 ngày/lần chia đoạn ≤90; CSV ≤5MB và trần bản ghi theo service. | Test vượt trần thông báo rõ và không xuất một phần như đầy đủ; không diễn giải các giới hạn này thành hạn tự xóa dữ liệu. |
| NFR-REL-01 | **Mạng lỗi, retry và đổi tài khoản** — Đã có xử lý/test | Có loading/error/empty/retry riêng; bỏ phản hồi đến trễ khi đổi UID; không dùng cache làm bằng chứng quyền quản trị còn hiệu lực. | Test mất mạng, refresh, logout giữa request, lock/unlock và cấu hình thay lúc bị khóa; nêu rõ form nào chỉ giữ RAM. |
| NFR-USA-01 | **Tiếng Việt và giao diện tiếp cận được** — Đã có Figma/widget checks; UAT máy thật còn chờ | Font Việt offline, light/dark, safe area/keyboard; kiểm 320–412 logical px và chữ 150–200% ở màn trọng yếu; không che nút xác nhận/hủy. | Widget/render và thao tác máy thật, kiểm overflow, contrast, label, vùng bấm; giá trị Figma không thay dữ liệu thật. |
| NFR-MNT-01 | **Kiến trúc dễ kiểm thử** — Đã có trong code | Feature-first, Riverpod, repository/service/model tách trách nhiệm; không nhúng truy vấn dài trong mọi widget hoặc nâng dependency diện rộng khi làm tài liệu. | Code review, analyze và test đúng phần thay đổi; không hạ validation/Rules chỉ để test xanh. |
| NFR-TST-01 | **Bằng chứng kiểm thử có thể chạy lại** — Đã có suites; không phải test mới lượt này | Có unit/widget/integration/rules theo mức phù hợp; mỗi chức năng nghiệm thu có test case đầu vào/kết quả và giới hạn môi trường. | Ghi command/date/SHA/result/log; kết quả lịch sử không được trình bày là vừa chạy trên dirty tree. |
| NFR-OPS-01 | **Cấu hình, triển khai và chi phí** — Đã có deployment; còn UAT | Tách Emulator/debug/production; script Android dùng config/admin-runtime.json; không hứa plain flutter build tự bật admin; ưu tiên free, không bật billing ngầm. | Đối chiếu build manifest/config và HTTPS; thử admin→Android online; thay dịch vụ ảnh cần đánh giá riêng trước triển khai. |
| NFR-AUD-01 | **Truy vết thao tác và thay đổi yêu cầu** — Đã có audit; tài liệu v0.1 chờ review | Audit quản trị bảo vệ khỏi sửa/xóa; yêu cầu có ID→story→test→minh chứng, lịch sử phiên bản và phần chưa nghiệm thu. | Test audit nguyên tử/không sửa được; kiểm ID/link/dependency và review SRS/backlog trước chốt phạm vi. |

Giới hạn hiện tại không phải mục tiêu scalability vô hạn hoặc SLA của Firebase/AI. Hạn mức bên thứ ba và điều kiện Free cần đối chiếu lại khi triển khai, đặc biệt module lưu ảnh. Không tự bật billing để đáp ứng chỉ tiêu tài liệu.

## 6. Quy tắc nghiệp vụ

| ID | Quy tắc |
|---|---|
| BR-01 | Dữ liệu sức khỏe, thư viện riêng, lịch sử chat và khảo sát thuộc UID; admin vận hành không có quyền đọc mặc định. |
| BR-02 | Món/nguyên liệu có nguồn, cơ sở khẩu phần và cờ ước tính. Tổng bữa tính từ snapshot lượng ăn được xác nhận; ảnh không bảo đảm dinh dưỡng chính xác. |
| BR-03 | Thiếu dưỡng chất khác 0. Có thể hiển thị tổng phần đã biết nhưng phải cho biết độ phủ; không dùng tổng thiếu làm tổng đầy đủ. |
| BR-04 | Một bữa có giới hạn item theo schema hiện có; recipe/mẫu bữa có validation riêng. Không tăng array vô hạn để né giới hạn. |
| BR-05 | Cập nhật catalog/công thức không thay nhật ký cũ. Archive ẩn khỏi chọn mới và có thể khôi phục, không hard-delete lịch sử. |
| BR-06 | Ngày theo lịch địa phương; thời điểm ghi nhất quán. Mốc 7/30/90/366 là cửa sổ đọc/xuất, không tự xóa dữ liệu theo tuổi. |
| BR-07 | Đủ bữa là người dùng xác nhận khớp revision. Sửa nhật ký có thể làm xác nhận cũ không còn hợp lệ; ngày thiếu không được diễn giải là đã ăn 0. |
| BR-08 | Khảo sát có 20 câu/8 màn, nhánh còn 16–20; tên hiển thị ngoài bộ câu. Câu bổ sung cho để sau; không đoán đáp án null. |
| BR-09 | Đề xuất năng lượng dùng model Dart hiện có. Tăng cơ khởi đầu ở mức duy trì; không đồng nghĩa đã có giáo án/thặng dư cá nhân hóa. |
| BR-10 | Kcal/gram đề xuất là tham khảo trong phạm vi chính sách sản phẩm; ngoài phạm vi cần giải thích, cho bỏ qua/nhập mục tiêu riêng. Không biến rào validation thành tuyên bố an toàn y khoa. |
| BR-11 | Thay mục tiêu có hiệu lực theo ngày và cần xác nhận; không tự thay khi có cân mới. Onboarding lưu mục tiêu/hồ sơ qua các bước chưa phải transaction toàn bộ; lỗi từng bước phải báo đúng và retry không trùng. |
| BR-12 | Mức hoạt động chọn đã gồm tập thường lệ. Năng lượng bước chỉ cộng sau xác nhận và kiểm điều kiện, không cộng chồng activity; giờ ngủ không quy đổi thành kcal ăn. |
| BR-13 | Steps là quan sát sau opt-in/cấp quyền trên Android, không bảo đảm toàn ngày trước bật. Nhiều thiết bị không cộng hai snapshot ngày chồng nhau. |
| BR-14 | Sleep là timer/nhập thủ công, cần xem lại; mỗi log tối đa 24 giờ, không suy chất lượng/REM. Câu ngủ khảo sát không tự tạo log. |
| BR-15 | Thực đơn là kế hoạch; chỉ khi xác nhận ghi mới tạo bữa, retry tránh trùng. Xóa kế hoạch không tự xóa bữa đã ghi. |
| BR-16 | Chat 50 lượt hỏi–đáp/cuộc khác rate-limit request/phút; đọc lịch sử không dùng AI. Context tối thiểu đúng UID/ngày, không cho AI tự ghi/xóa dữ liệu. |
| BR-17 | Khóa quyền HealthMate chặn dữ liệu server, không đồng nghĩa disable Firebase Auth/Google hoặc xóa cache; flag UI không thay enforcement dịch vụ AI riêng. |
| BR-18 | Ghi admin cần audit/kiểm phiên bản. Người đang đăng nhập không tự khóa mình hoặc tài khoản role được bảo vệ; role cấp bởi quy trình đáng tin cậy, không client tự cấp. |
| BR-19 | Excel admin gồm toàn bộ kết quả lọc đã tải đủ, khác CSV riêng trên mobile; quá trần phải báo lỗi/chia phạm vi. |
| BR-20 | Không lưu ảnh scanner gốc dài hạn mặc định. Ảnh catalog là module đề xuất riêng, cần thiết kế quyền/vòng đời/chi phí. |
| BR-21 | Đồng ý gửi AI, xác nhận ghi bữa và đồng ý xuất dữ liệu là các hành động khác nhau; không gộp thành một consent ngầm. |
| BR-22 | Xóa dữ liệu, thay mục tiêu và tác vụ nhạy cảm cần xác nhận; hủy không ghi. Đổi UID làm bỏ phản hồi cũ để tránh lẫn tài khoản. |

### 6.1 Chính sách tính mục tiêu hiện có

Công thức REE được implementation mô tả: `9.99×kg + 6.25×cm − 4.92×tuổi + 5` cho hệ số nam, thay `+5` bằng `−161` cho hệ số nữ. Mức hoạt động tự chọn 1.4/1.6/1.8/2.0. Giảm cân dùng −10%/−15%, tăng cân +5%/+10%; duy trì/thói quen/tăng cơ khởi đầu theo maintenance. Kcal làm tròn tới 10, macro theo lựa chọn model hiện có và quy đổi 4/4/9.

Đây là mô tả thuật toán phiên bản hiện tại để kiểm thử, không phải chỉ định dinh dưỡng cho cá nhân. Các điều kiện tuổi/BMI/trường hợp cần hướng dẫn riêng và ngưỡng validation chi tiết phải lấy từ model cùng SRC-05. Không dùng SRS làm lý do tự đổi thuật toán hoặc suy cân nặng tương lai.

### 6.2 Bộ 20 câu

1. Ngày sinh; 2. Hệ số nam/nữ cho công thức; 3. Chiều cao; 4. Cân nặng hiện tại; 5. Mục tiêu; 6. Cân nặng đích; 7. Nhịp điều chỉnh; 8. Phạm vi nhận đề xuất/cần hướng dẫn riêng; 9. Hoạt động thường ngày; 10. Ngày tập/tuần; 11. Thời lượng/buổi; 12. Loại/cường độ; 13. Chế độ ăn; 14. Dị ứng/thực phẩm tránh; 15. Rau/trái cây; 16. Đồ uống thêm đường; 17. Giờ ngủ/24h; 18. Lịch ngủ; 19. Khó khăn; 20. Ưu tiên.

Bộ này được tổng hợp/rút gọn từ các nguồn được SRC-04 ghi lại, không là thang WHO/GPAQ/DSQ đã kiểm định. Chưa tự áp bộ lọc thực đơn đảm bảo dị ứng.

## 7. Đặc tả các use case trọng yếu

Các bước mô tả behavior cần nghiệm thu; không phải bằng chứng vừa thao tác trên production.

### UC-01 — Đăng ký, xác minh và vào app

**Tác nhân:** khách. **Tiền điều kiện:** mạng/provider được cấu hình. **Liên kết:** FR-AUTH-01..04, FR-PRO-01.  
**Luồng chính:** nhập email/mật khẩu/xác nhận → tạo tài khoản → gửi email → người dùng mở liên kết → app kiểm lại verified → tải/tạo hồ sơ → onboarding nếu chưa hoàn tất → dashboard.  
**Ngoại lệ:** email/sai mật khẩu/lỗi mạng hiện thông báo; gửi lại có thời gian chờ; chưa verify không mở dữ liệu riêng; người cũ hoàn tất không bị hỏi lại. Google thành công dùng cùng gate, hủy không tạo giả kết quả.  
**Hậu điều kiện:** phiên và hồ sơ đúng UID, không lưu password vào Firestore.

### UC-02 — Cá nhân hóa và thay mục tiêu

**Tác nhân:** thành viên. **Tiền điều kiện:** đã verify; hồ sơ/cân hợp lệ nếu tính tự động. **Liên kết:** FR-PRO-01..04.  
**Luồng chính:** trả lời nhóm câu → rẽ nhánh → xem đề xuất → xem mục tiêu đang có → xác nhận dùng/thay từ ngày hiệu lực → lưu và hoàn tất.  
**Ngoại lệ:** để sau/thiếu hệ số/ngoài phạm vi không tự đoán kcal; hủy không ghi; qua ngày mới cần xem lại; một bước lưu lỗi phải báo phần đã lưu, retry không nhân bản.  
**Hậu điều kiện:** mục tiêu đúng ngày, lịch sử cũ và số đo cũ giữ nguyên.

### UC-03 — Ghi bữa thủ công

**Tác nhân:** thành viên. **Tiền điều kiện:** chọn ngày, có quyền dữ liệu. **Liên kết:** FR-NUT-01..06.  
**Luồng chính:** mở thêm bữa → tìm/chọn món → nhập khẩu phần → xem tổng → chọn loại bữa/giờ → xác nhận → lưu snapshot → nhật ký/dashboard cập nhật.  
**Ngoại lệ:** validation lỗi không ghi; nguồn thiếu hiển thị thiếu; đổi UID/hủy bỏ nháp trong phạm vi thiết kế; xóa yêu cầu xác nhận. Từ + dùng hôm nay, từ Nhật ký lịch sử giữ ngày đang xem.  
**Hậu điều kiện:** chỉ một bữa đã xác nhận thuộc UID; revision độ đầy đủ được kiểm lại khi nhật ký đổi.

### UC-04 — Quét ảnh hoặc barcode và ghi bữa

**Tác nhân:** thành viên. **Tiền điều kiện:** camera/ảnh và AI eligibility/consent khi dùng ảnh. **Liên kết:** FR-SCN-01..03.  
**Luồng ảnh:** chọn/chụp → đồng ý gửi → phân tích → xem tên/thành phần/nguồn/lượng → sửa hoặc chọn catalog → kiểm tra/lưu món riêng nếu cần → xác nhận ghi bữa.  
**Luồng barcode:** quét mã → tra OFF → xem per-100g/khẩu phần → sửa gram → xác nhận đưa vào bữa.  
**Ngoại lệ:** từ chối quyền, không có sản phẩm, timeout/quota, dữ liệu không hợp lệ đều có thông báo và nhập tay. Không biến cả đĩa thành một nguyên liệu khớp từ khóa.  
**Hậu điều kiện:** ảnh không lưu dài hạn mặc định; không có meal log trước xác nhận.

### UC-05 — Ghi và xem bước chân/giấc ngủ

**Tác nhân:** thành viên. **Tiền điều kiện:** đăng nhập, Android hỗ trợ các quyền cần thiết. **Liên kết:** FR-WEL-05..07.  
**Bước:** mở panel → opt-in/cấp quyền → nhận quan sát sensor → hiển thị/đồng bộ ngày; credit kcal là xác nhận riêng khi đủ dữ liệu.  
**Ngủ:** bấm bắt đầu hoặc nhập tay → đã thức dậy → xem/sửa giờ → xác nhận log → lịch sử/tổng hợp; sửa/xóa hỏi khi phù hợp.  
**Ngoại lệ:** cảm biến không hỗ trợ/quyền bị thu hồi/service dừng phải giải thích; giờ ngủ sai/âm/quá giới hạn bị từ chối; retry kết thúc không trùng.  
**Hậu điều kiện:** không tự đo trước opt-in, không suy giai đoạn ngủ hay tự điều chỉnh khẩu phần ăn từ sleep.

### UC-06 — Hỏi Chat AI về dữ liệu cá nhân

**Tác nhân:** thành viên. **Tiền điều kiện:** consent, feature có thể dùng, rate-limit/hạn cuộc còn cho phép. **Liên kết:** FR-CHT-01..03.  
**Luồng chính:** chọn cuộc → hỏi hôm nay còn bao nhiêu kcal → app đọc mục tiêu/log đúng ngày/UID → tạo context tối thiểu → Worker trả lời → lưu cặp tin hợp lệ → tiếp tục hội thoại.  
**Ngoại lệ:** thiếu dữ liệu báo thiếu; API/mạng/quota có retry; rời tab hủy stream; đổi UID bỏ phản hồi; lượt 51 bị chặn.  
**Hậu điều kiện:** không tự bịa số, không ghi mục tiêu hoặc sửa nhật ký từ lời AI.

### UC-07 — Admin sửa/ẩn/khôi phục món

**Tác nhân:** admin. **Tiền điều kiện:** Auth verified, role/App Check theo cấu hình. **Liên kết:** FR-ADM-01..02,05..06.  
**Luồng chính:** tải đủ danh sách → tìm/lọc → xem/sửa → nhập dữ liệu/nguồn/lý do → xác nhận → kiểm revision → commit catalog cùng audit → đọc lại và hiển thị kết quả.  
**Ngoại lệ:** role thu hồi hoặc revision khác từ chối; lỗi giữ form; archive/restore hỏi xác nhận. Xuất Excel dùng toàn bộ kết quả lọc đã tải đủ, quá trần không báo là đầy đủ.  
**Hậu điều kiện:** lịch sử bữa không đổi, audit không được client sửa/xóa.

### UC-08 — Admin khóa/mở và đổi cấu hình

**Tác nhân:** admin và thành viên có bản app nhận runtime. **Liên kết:** FR-ADM-03..04.  
**Luồng chính:** admin chọn thành viên → nhập lý do/xác nhận khóa → server chặn đọc/ghi → Android hiển thị gate → admin mở → listener cấu hình nối lại → tính năng đúng config hiện tại.  
**Ngoại lệ:** không khóa admin được bảo vệ; offline/phiên bản cũ không bảo đảm cập nhật UI ngay; không coi flag UI là revoke token mọi dịch vụ AI.  
**Hậu điều kiện:** trạng thái và audit đúng, không disable Google, không xóa dữ liệu riêng.

### UC-09 — Xem báo cáo, drill-down và in

**Tác nhân:** thành viên với báo cáo riêng; admin với in catalog. **Liên kết:** FR-RPT-02..04, FR-REP-01..05, FR-PRN-01..02.  
**Luồng đã có:** chọn tuần/năm/khoảng → tải nguồn có giới hạn → xem tổng/biểu đồ/chi tiết → xuất CSV nếu chọn.  
**Luồng bổ sung đề xuất:** chọn lát/cột/điểm → mở đúng nguồn tạo tổng → quay lại giữ filter; chọn In → preview có kỳ/đơn vị/độ phủ → hộp in → in hoặc hủy. In catalog dùng toàn bộ kết quả lọc admin.  
**Ngoại lệ:** dữ liệu thiếu/quá trần/lỗi nguồn không giả thành đầy đủ; owner-only; không mở quyền admin đọc nhật ký để làm báo cáo.  
**Hậu điều kiện:** xem/in/xuất không sửa dữ liệu nghiệp vụ; luồng in và Pie chưa được xem là implemented.

## 8. Dữ liệu và vòng đời

Sơ đồ chi tiết/whitelist/schema ở SRC-06 và `firestore.rules`; bảng dưới là mô hình logic để hiểu yêu cầu, không là đề nghị migrate schema.

| Nhóm/đường dẫn | Nội dung và quyền |
|---|---|
| `users/{uid}` | Hồ sơ, onboarding, map personalization; owner verified, không password |
| `body_metrics`, `nutrition_targets` | Lần cân và các phiên bản mục tiêu theo ngày |
| `meal_logs`, `water_logs`, `activity_logs` | Nhật ký riêng; snapshot món/đơn vị/thời điểm |
| `custom_foods`, `recipes`, `favorite_foods`, `meal_templates` | Nguồn thư viện riêng, không tự public |
| `day_reviews` | Xác nhận đủ bữa gắn count/revision |
| `goals`, `daily_quests` | Mục tiêu, nhiệm vụ/ngày và trạng thái |
| `chat_sessions/{id}/messages` | Hội thoại riêng, giới hạn session, trạng thái lưu |
| `meal_plans`, `step_logs`, `sleep_logs` | Kế hoạch chưa ghi bữa, bước quan sát, ngủ tự khai |
| `wellness_state`, `wellness_preferences`, `energy_adjustments` | Timer/thiết lập và credit bước đã xác nhận |
| `food_catalog` | Nguồn chung; member đọc, admin ghi có audit |
| `admin_roles` | Role bootstrap đáng tin cậy; không client tự cấp/list toàn bộ role |
| `user_directory` | Danh tính cơ bản đồng bộ từ app, không thay thế toàn bộ Auth |
| `account_controls`, `app_config/runtime`, `admin_audit` | Khóa/quyền, cấu hình và audit bảo vệ |
| Ảnh catalog đề xuất | Chưa chốt kho/metadata/rules/vòng đời; phải thiết kế trước triển khai |

Dữ liệu health không có TTL 7/30 ngày trong nghiệp vụ này. “Lưu lịch sử” không phải hứa lưu vô hạn không quota. Xóa tài khoản dùng cơ chế cleanup hiện có và phải kiểm thử khi thêm collection.

Ảnh food scanner có thể là tệp tạm camera/thư viện trên thiết bị. Không đồng nhất tệp tạm/asset Figma với yêu cầu kho ảnh nghiệp vụ có upload, liên kết, quyền và xử lý thay/xóa.

## 9. Báo cáo đề xuất để nghiệm thu rubric

Bốn mã sau dùng các nguồn đã có nhưng cần đóng thành luồng kiểm chứng rõ; không tuyên bố cả bốn đã được cô chấp nhận.

| Mã | Người xem | Lọc và chỉ số | Biểu đồ/chi tiết cần nghiệm thu |
|---|---|---|---|
| R01 — Dinh dưỡng theo kỳ | Chủ UID | Khoảng ngày, kcal/macro/chất xơ, độ phủ/đủ bữa | Xu hướng và Pie tỷ lệ năng lượng khi đủ dữ liệu; chi tiết ngày/bữa |
| R02 — Nước uống | Chủ UID | Khoảng ngày, ml/ngày, tổng theo kỳ | Bar; chọn cột mở các lần uống của ngày |
| R03 — Vận động | Chủ UID | Khoảng ngày/loại, số lần/phút | Bar hoặc phân loại cộng được; chọn nhóm mở log |
| R04 — Cân nặng | Chủ UID | Khoảng ngày, số lần, đầu/cuối/chênh lệch khi đủ | Trend; chọn điểm mở số đo, không đoán mỡ giảm |

**Hai luồng in đề xuất:** PR01 in danh mục admin; PR02 in báo cáo kỳ của chính thành viên. Cần chốt nền tảng/hộp in và preview khi giao triển khai. CSV/XLSX không thay thế lệnh in.

Nếu giảng viên yêu cầu cả bốn báo cáo phải nằm trên admin thay vì toàn sản phẩm, cần review lại: chọn dữ liệu vận hành/tổng hợp có quyền thích hợp, không âm thầm cấp admin đọc dữ liệu health cá nhân.

## 10. Ma trận đáp ứng rubric và khoảng trống

| Mã | Yêu cầu cô | Hiện trạng | FR/NFR | Task chứng minh/chốt |
|---|---|---|---|---|
| TC-01 | Load data nhanh | Có cache/phân trang/giới hạn; chưa có benchmark nghiệm thu | NFR-PER-01, NFR-PER-02 | HM-TASK-001 |
| TC-02 | Dashboard tổng quát ≥4 loại dữ liệu | Có mobile dinh dưỡng/nước/vận động/cân nặng; admin có 4 số đếm | FR-RPT-01, FR-ADM-05 | HM-TASK-006 |
| TC-03 | Danh mục CRUD, tìm, phân trang, STT, màu trạng thái, lọc loại | Có trên admin; xóa mềm/khôi phục | FR-ADM-02, FR-ADM-05 | HM-TASK-003 |
| TC-04 | Xóa phải hỏi | Có các luồng xác nhận; cần UAT các điểm demo | FR-NUT-02, FR-PRO-04, FR-UI-02, FR-ADM-02 | HM-TASK-002, HM-TASK-003 |
| TC-05 | Excel chứa tất cả nội dung trên danh sách | XLSX toàn bộ kết quả lọc đã tải đủ, không chỉ trang UI; mobile CSV khác luồng | FR-ADM-05, NFR-PER-02 | HM-TASK-003 |
| TC-06 | Người dùng, phân quyền | Có admin/user, server Rules, khóa/mở HealthMate; không có CRUD role trong client | FR-AUTH-01, FR-ADM-01, FR-ADM-03, NFR-SEC-01 | HM-TASK-002, HM-TASK-003 |
| TC-07 | Lưu trữ hình ảnh | Có assets/chụp ảnh tạm; chưa có upload/lưu/quản lý ảnh nghiệp vụ | FR-IMG-01, FR-IMG-02 | HM-TASK-006 |
| TC-08 | Ít nhất 4 báo cáo | Có nền tổng hợp nhiều nguồn; cần chuẩn hóa R01–R04 và nghiệm thu | FR-REP-01, FR-REP-02, FR-REP-03, FR-REP-04 | HM-TASK-006 |
| TC-09 | Pie, Bar, nhấn xem chi tiết | Có Bar/xu hướng/chi tiết ngày; Pie và drill-down đúng phần biểu đồ chưa đủ | FR-REP-05 | HM-TASK-006 |
| TC-10 | Gửi mail, OTP SMS, … | Có email verify/reset; SMS chưa có, chưa coi là bắt buộc nếu dấu … là ví dụ | FR-AUTH-03, FR-AUTH-04 | HM-TASK-003, HM-TASK-004 |
| TC-11 | Hai chức năng in | Chưa thấy luồng in sản phẩm hoàn chỉnh | FR-PRN-01, FR-PRN-02 | HM-TASK-006 |
| TC-12 | Figma | Có link/frame/UI kit và implementation v2 trong repo; không thiếu từ đầu | FR-UI-01, NFR-USA-01 | HM-TASK-002, HM-TASK-006 |
| TC-13 | Deploy | Admin có Hosting; Android có APK; tương tác production/máy thật còn chờ | NFR-OPS-01 | HM-TASK-002, HM-TASK-003 |
| TC-14 | SRS, Jira | SRS/backlog được soạn lượt này; Jira thật/link/approval chưa tạo | NFR-AUD-01 | HM-TASK-004, HM-TASK-005 |
| TC-15 | Unit Test | Có unit/widget/Rules/web/integration; kết quả có trong test-report, không chạy lại lượt tài liệu | NFR-TST-01 | HM-TASK-006 |

## 11. Cơ sở kiểm thử và giới hạn bằng chứng

Kết quả dưới đây lấy từ tài liệu đã commit tại baseline, không phải lệnh kiểm thử chạy mới khi soạn SRS:

| Hạng mục | Kết quả đã được ghi nhận |
|---|---|
| Flutter toàn bộ sau tích hợp admin | 656/656 qua |
| Runtime theo cấu hình build | 7/7 qua |
| Rules / web SDK / Flutter SDK Emulator | 77/77 / 4/4 / 3/3 qua |
| Web unit/DOM/validation/list/XLSX | 20/20 qua |
| Analyze | No issues found |
| Android debug build | Exit 0, Gradle 34,0 giây |
| Production admin | Có Hosting, role/App Check/Rules và kiểm tra server đã ghi nhận; tương tác trình duyệt/máy thật còn chờ |

Không quy đổi tổng số test thành mọi yêu cầu đã đạt. Bộ test gồm nhiều mức; cần giữ test cụ thể, dữ liệu đầu vào và môi trường. Những FR-REP/PRN/IMG mới chưa có bộ test nghiệm thu hoàn chỉnh. Dirty tree hiện tại không được bao phủ bằng số test của commit cũ.

**Definition of Done cho thay đổi tiếp theo:** AC và requirement link đầy đủ → code review/validation/quyền → test phù hợp thực sự chạy → analyze/format/build khi có thay đổi Flutter → UAT và minh chứng đúng môi trường → cập nhật tài liệu/giới hạn. Không bắt buộc build lại ứng dụng chỉ vì chỉnh Markdown.

## 12. Giả định, rủi ro và điểm cần review

| ID | Nội dung | Cách xử lý |
|---|---|---|
| Q-01 | Bốn báo cáo áp dụng toàn app/web hay chỉ admin? | HM-TASK-004, xác nhận với giảng viên trước triển khai phần mới |
| Q-02 | “Mail, OTP…” là ví dụ hay yêu cầu cả SMS? | Giữ email đã có; SMS chưa vào phạm vi bắt buộc tới khi được xác nhận |
| Q-03 | “Tất cả trên danh sách” là toàn kết quả lọc hay toàn collection bỏ filter? | Đặc tả hiện tại chọn toàn kết quả lọc; hiển thị filter/count trong file, cho clear filter để xuất toàn tập trong giới hạn |
| Q-04 | Lưu ảnh cần loại nào, chi phí chấp nhận ra sao? | Đề xuất ảnh catalog, FR-IMG-01 trước upload; không tự bật billing |
| Q-05 | Jira project, thành viên, sprint/estimate chưa được cung cấp | Backlog dùng ID tạm, không tạo issue hoặc bịa phân công |
| R-01 | Provider AI/free quota/model thay đổi | Có lỗi/quota/nhập tay; kiểm tài liệu khi đổi cấu hình, không hứa miễn phí vô hạn |
| R-02 | App đang cài chưa chắc là APK mới | HM-TASK-002 kiểm SHA/build flag/thiết bị trước UAT |
| R-03 | Directory chỉ gồm tài khoản app đã đồng bộ, trần admin 5.000 | Hiển thị giới hạn, không tự coi là thống kê toàn Auth; mở rộng server pagination là phạm vi riêng |
| R-04 | Thuật toán dinh dưỡng và cảm biến có sai số | Giữ nhãn tự khai/ước tính, review và không chẩn đoán |
| R-05 | Các thay đổi uncommitted có thể tiếp tục ở chat khác | Dùng SHA cố định cho tài liệu; review version mới sau merge, không sửa/xóa thay đổi đó |

## 13. Truy vết và quy trình thay đổi

Mỗi FR có story duy nhất `HM-US-xxx` ở backlog; mỗi story ghi nguồn, test hiện có, AC, dependency và TC liên quan. NFR gắn task hoặc story chứng minh. Đây là **ID tài liệu**, chưa phải issue key Jira.

Khi yêu cầu đổi: ghi lý do/nguồn → cập nhật FR/NFR, AC và phiên bản → đánh giá dữ liệu/quyền/chi phí → người dùng duyệt phần ảnh hưởng → triển khai đúng một phạm vi → kiểm thử → cập nhật bằng chứng. Không thay code/deploy chỉ vì một mục Proposed xuất hiện trong SRS.

## 14. Bảng thuật ngữ

| Thuật ngữ | Nghĩa |
|---|---|
| UID | Danh tính Firebase, khóa phạm vi riêng tư |
| CRUD | Tạo, đọc, sửa, xóa; catalog đang xóa mềm/archive |
| Snapshot | Bản giá trị dinh dưỡng lưu tại lúc ghi bữa |
| Macro | Protein, carbohydrate, chất béo |
| Kcal/REE/PAL | Năng lượng / năng lượng nghỉ ước tính / mức hoạt động tham khảo |
| Null/coverage | Chưa biết / phần dữ liệu đã có, khác 0 |
| Quest | Nhiệm vụ ngày theo quy tắc, không phải chẩn đoán |
| Runtime flag | Cấu hình tính năng app nhận từ server khi build hỗ trợ |
| Audit | Dấu vết thao tác quản trị có actor/thời điểm/lý do |
| Drill-down | Chọn phần biểu đồ/tổng để xem các bản ghi tạo nên nó |
| UAT | Nghiệm thu hành vi bởi người dùng trên môi trường đã chỉ rõ |
| Baseline | Phiên bản Git cố định được dùng để lập tài liệu |
| AC / FR / NFR | Tiêu chí nghiệm thu / yêu cầu chức năng / yêu cầu phi chức năng |

