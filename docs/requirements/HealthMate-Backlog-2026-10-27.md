# Product Backlog — HealthMate

**Phiên bản:** 0.1 · **Ngày:** 27/10/2026 · **Baseline:** `14bb579b6d1549db1569ee7710b7b1733e92c5de` trên GitHub `main`.  
**SRS liên quan:** [HealthMate SRS](HealthMate-SRS-2026-10-27.md).  
**Quy mô:** 13 Epic, 52 User Story, 6 Task chất lượng/hồ sơ; bốn ý tưởng ngoài phạm vi ở cuối. Các ID là ID tài liệu tạm, **chưa phải issue Jira thật**.

## 1. Cách sử dụng và quy ước

Backlog gồm cả inventory chức năng đã có và công việc còn thiếu, để lập Jira mà không bỏ qua phần đã làm. Không phải danh sách 52 tính năng phải viết lại từ đầu.

- **CODE (43 story):** đã có source ở SHA baseline; kiểm lại bằng UAT/test liên quan khi đóng issue.
- **PARTIAL (4 story):** có nền dữ liệu/UI nhưng chưa đủ AC/rubric; hoàn thiện phần thiếu, không tạo bản sao chức năng.
- **PROPOSED (5 story):** chưa có code; là đề xuất để đủ rubric, không tự phê duyệt chi phí/kiến trúc.
- **P0:** khoảng trống hoặc bằng chứng chặn nghiệm thu. **P1:** nền phải bảo toàn. **P2:** mở rộng sau.
- **Assignee, story points, sprint, hạn chót:** chưa được người dùng/nhóm chỉ định; để trống, không ước lượng hoặc dựng lịch sử hoàn thành thay nhóm.
- **Done trên Jira:** chỉ khi có bằng chứng đáp ứng Definition of Done. Code tồn tại hoặc có tên file test chưa chứng minh mọi AC đã pass.
- Bản USDA/catalog đang uncommitted không được tính như đã phát hành trong baseline này; không reset hoặc ghi đè các thay đổi đó.

### 1.1 Workflow đề xuất cho Jira

`Backlog → Ready → In Progress → In Review → Testing/UAT → Done`; dùng `Blocked` khi có nguyên nhân/phụ thuộc rõ. Chức năng CODE nên nhập với nhãn `implemented-baseline` và task xác minh phù hợp, không tự đặt Done theo số test lịch sử.

**Definition of Ready:** có FR/NFR và nguồn; AC đo được; phụ thuộc rõ; thiết kế/quyền/chi phí đã được chốt khi ảnh hưởng; hiểu dữ liệu demo và đường lỗi.

**Definition of Done:** AC thực hiện được; kiểm tra tính toán/validation/quyền; test phù hợp có command/commit/kết quả thật; UI thực hiện hành động thật; thay đổi dữ liệu không làm mất lịch sử; UAT/minh chứng đúng môi trường; cập nhật docs/giới hạn; không lộ secret. Với task tài liệu, dùng review nội dung/link/trace thay vì giả chạy Flutter tests.

### 1.2 Nguồn kiểm chứng

Mỗi story ghi file nguồn và test hiện có tại SHA. Link thư mục chỉ dẫn phạm vi feature, không khẳng định mọi file trong đó là implementation trực tiếp của tất cả AC. Test tương lai còn thiếu được ghi “cần thiết kế”; không tạo tên test giả để làm như đã có coverage.

Rubric `TC-01..TC-15` và chính sách nghiệp vụ/NFR ở SRS. Lượt này không tạo Jira board/issue, không sửa source hoặc triển khai các story đề xuất.

## 2. Danh sách Epic

| Epic tạm | Mục tiêu | Inventory hiện tại |
|---|---|---|
| HM-EP-01 | Tài khoản và xác thực | 6 story: 6 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-02 | Hồ sơ và cá nhân hóa | 4 story: 4 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-03 | Dữ liệu món và ghi bữa | 6 story: 6 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-04 | Quét ảnh và mã vạch | 3 story: 3 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-05 | Nước, vận động và thói quen | 7 story: 7 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-06 | Mục tiêu và Quest | 2 story: 2 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-07 | Dashboard và lịch sử báo cáo | 4 story: 4 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-08 | Chat AI | 3 story: 3 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-09 | Quản trị ứng dụng | 6 story: 6 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-10 | UX/UI theo Figma | 2 story: 2 CODE / 0 PARTIAL / 0 PROPOSED |
| HM-EP-11 | Hoàn thiện báo cáo và in theo yêu cầu môn học | 7 story: 0 CODE / 4 PARTIAL / 3 PROPOSED |
| HM-EP-12 | Lưu trữ ảnh nghiệp vụ | 2 story: 0 CODE / 0 PARTIAL / 2 PROPOSED |
| HM-EP-13 | Chất lượng, nghiệm thu và hồ sơ dự án | 6 task chất lượng/hồ sơ |

## 3. Chỉ mục User Story

| ID tạm | Epic | Yêu cầu | Nội dung | Trạng thái | Ưu tiên |
|---|---|---|---|---|---|
| [HM-US-001](#hm-us-001) | HM-EP-01 | FR-AUTH-01 | Đăng ký và đăng nhập email/mật khẩu | CODE | P1 |
| [HM-US-002](#hm-us-002) | HM-EP-01 | FR-AUTH-02 | Tiếp tục với Google | CODE | P1 |
| [HM-US-003](#hm-us-003) | HM-EP-01 | FR-AUTH-03 | Xác minh email | CODE | P1 |
| [HM-US-004](#hm-us-004) | HM-EP-01 | FR-AUTH-04 | Quên mật khẩu qua email | CODE | P1 |
| [HM-US-005](#hm-us-005) | HM-EP-01 | FR-AUTH-05 | Phiên đăng nhập, đổi mật khẩu và đăng xuất | CODE | P1 |
| [HM-US-006](#hm-us-006) | HM-EP-01 | FR-AUTH-06 | Xóa tài khoản và dữ liệu thuộc tài khoản | CODE | P1 |
| [HM-US-007](#hm-us-007) | HM-EP-02 | FR-PRO-01 | Onboarding và khảo sát cá nhân hóa 20 câu | CODE | P1 |
| [HM-US-008](#hm-us-008) | HM-EP-02 | FR-PRO-02 | Đề xuất kcal và macro cá nhân hóa | CODE | P1 |
| [HM-US-009](#hm-us-009) | HM-EP-02 | FR-PRO-03 | Mục tiêu dinh dưỡng có ngày hiệu lực | CODE | P1 |
| [HM-US-010](#hm-us-010) | HM-EP-02 | FR-PRO-04 | Hồ sơ, cân nặng và BMI tham khảo | CODE | P1 |
| [HM-US-011](#hm-us-011) | HM-EP-03 | FR-NUT-01 | Tìm và chọn thực phẩm có nguồn | CODE | P1 |
| [HM-US-012](#hm-us-012) | HM-EP-03 | FR-NUT-02 | CRUD nhật ký bữa ăn và snapshot khẩu phần | CODE | P1 |
| [HM-US-013](#hm-us-013) | HM-EP-03 | FR-NUT-03 | Món riêng, công thức và yêu thích | CODE | P1 |
| [HM-US-014](#hm-us-014) | HM-EP-03 | FR-NUT-04 | Mẫu bữa, nháp và thêm nhanh | CODE | P1 |
| [HM-US-015](#hm-us-015) | HM-EP-03 | FR-NUT-05 | Macro, chất xơ và dưỡng chất mở rộng | CODE | P1 |
| [HM-US-016](#hm-us-016) | HM-EP-03 | FR-NUT-06 | Xác nhận độ đầy đủ nhật ký ngày | CODE | P1 |
| [HM-US-017](#hm-us-017) | HM-EP-04 | FR-SCN-01 | Camera, chọn ảnh và đồng ý gửi AI | CODE | P1 |
| [HM-US-018](#hm-us-018) | HM-EP-04 | FR-SCN-02 | Kiểm tra thành phần và kết quả dinh dưỡng ảnh | CODE | P1 |
| [HM-US-019](#hm-us-019) | HM-EP-04 | FR-SCN-03 | Quét mã vạch và tra sản phẩm | CODE | P1 |
| [HM-US-020](#hm-us-020) | HM-EP-05 | FR-WEL-01 | Nhật ký nước uống | CODE | P1 |
| [HM-US-021](#hm-us-021) | HM-EP-05 | FR-WEL-02 | Nhật ký vận động thủ công | CODE | P1 |
| [HM-US-022](#hm-us-022) | HM-EP-05 | FR-WEL-03 | Nhắc ghi bữa local | CODE | P1 |
| [HM-US-023](#hm-us-023) | HM-EP-05 | FR-WEL-04 | Lập thực đơn nhiều ngày | CODE | P1 |
| [HM-US-024](#hm-us-024) | HM-EP-05 | FR-WEL-05 | Bước chân Android và lịch sử | CODE | P1 |
| [HM-US-025](#hm-us-025) | HM-EP-05 | FR-WEL-06 | Ghi giấc ngủ thủ công và nhắc ngủ | CODE | P1 |
| [HM-US-026](#hm-us-026) | HM-EP-05 | FR-WEL-07 | Ngân sách ăn và năng lượng bước đã xác nhận | CODE | P1 |
| [HM-US-027](#hm-us-027) | HM-EP-06 | FR-GOL-01 | Quản lý mục tiêu sức khỏe | CODE | P1 |
| [HM-US-028](#hm-us-028) | HM-EP-06 | FR-GOL-02 | Nhiệm vụ sức khỏe hằng ngày | CODE | P1 |
| [HM-US-029](#hm-us-029) | HM-EP-07 | FR-RPT-01 | Dashboard ít nhất bốn nhóm dữ liệu | CODE | P1 |
| [HM-US-030](#hm-us-030) | HM-EP-07 | FR-RPT-02 | Tổng kết tuần và biểu đồ hiện có | CODE | P1 |
| [HM-US-031](#hm-us-031) | HM-EP-07 | FR-RPT-03 | Báo cáo theo năm và khoảng tùy chọn | CODE | P1 |
| [HM-US-032](#hm-us-032) | HM-EP-07 | FR-RPT-04 | Xuất nhật ký cá nhân CSV | CODE | P1 |
| [HM-US-033](#hm-us-033) | HM-EP-08 | FR-CHT-01 | Chat AI sau đồng ý | CODE | P1 |
| [HM-US-034](#hm-us-034) | HM-EP-08 | FR-CHT-02 | Ngữ cảnh cá nhân có nguồn và giới hạn quyền AI | CODE | P1 |
| [HM-US-035](#hm-us-035) | HM-EP-08 | FR-CHT-03 | Lịch sử chat và giới hạn 50 lượt mỗi cuộc | CODE | P1 |
| [HM-US-036](#hm-us-036) | HM-EP-09 | FR-ADM-01 | Đăng nhập admin và kiểm tra quyền server | CODE | P1 |
| [HM-US-037](#hm-us-037) | HM-EP-09 | FR-ADM-02 | CRUD catalog quản trị và xóa mềm | CODE | P1 |
| [HM-US-038](#hm-us-038) | HM-EP-09 | FR-ADM-03 | Directory và khóa/mở quyền HealthMate | CODE | P1 |
| [HM-US-039](#hm-us-039) | HM-EP-09 | FR-ADM-04 | Cấu hình runtime, bảo trì và tích hợp Android | CODE | P1 |
| [HM-US-040](#hm-us-040) | HM-EP-09 | FR-ADM-05 | Dashboard, tìm/lọc/phân trang và Excel admin | CODE | P1 |
| [HM-US-041](#hm-us-041) | HM-EP-09 | FR-ADM-06 | Audit bất biến và cập nhật danh sách | CODE | P1 |
| [HM-US-042](#hm-us-042) | HM-EP-10 | FR-UI-01 | Điều hướng và giao diện theo Figma hiện có | CODE | P1 |
| [HM-US-043](#hm-us-043) | HM-EP-10 | FR-UI-02 | Trạng thái, khả năng tiếp cận và xác nhận | CODE | P1 |
| [HM-US-044](#hm-us-044) | HM-EP-11 | FR-REP-01 | Chuẩn hóa báo cáo dinh dưỡng cho nghiệm thu | PARTIAL | P0 |
| [HM-US-045](#hm-us-045) | HM-EP-11 | FR-REP-02 | Chuẩn hóa báo cáo nước uống cho nghiệm thu | PARTIAL | P0 |
| [HM-US-046](#hm-us-046) | HM-EP-11 | FR-REP-03 | Chuẩn hóa báo cáo vận động cho nghiệm thu | PARTIAL | P0 |
| [HM-US-047](#hm-us-047) | HM-EP-11 | FR-REP-04 | Chuẩn hóa báo cáo cân nặng cho nghiệm thu | PARTIAL | P0 |
| [HM-US-048](#hm-us-048) | HM-EP-11 | FR-REP-05 | Biểu đồ Pie và drill-down có ý nghĩa | PROPOSED | P0 |
| [HM-US-049](#hm-us-049) | HM-EP-11 | FR-PRN-01 | In danh mục món ăn quản trị | PROPOSED | P0 |
| [HM-US-050](#hm-us-050) | HM-EP-11 | FR-PRN-02 | In báo cáo theo kỳ của chính người dùng | PROPOSED | P0 |
| [HM-US-051](#hm-us-051) | HM-EP-12 | FR-IMG-01 | Thiết kế lưu ảnh catalog và kiểm tra chi phí/quyền | PROPOSED | P0 |
| [HM-US-052](#hm-us-052) | HM-EP-12 | FR-IMG-02 | Tải lên, thay và gỡ ảnh món catalog | PROPOSED | P0 |

## 4. User Story và tiêu chí nghiệm thu

Các AC trong story CODE là các hành vi cần giữ và kiểm chứng, không là kết quả test mới chạy. AC trong PARTIAL/PROPOSED là phần cần đóng trước khi nghiệm thu.

## HM-EP-01 — Tài khoản và xác thực

<a id="hm-us-001"></a>

### HM-US-001 — Đăng ký và đăng nhập email/mật khẩu

**Loại:** Story · **Yêu cầu:** FR-AUTH-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò khách, tôi muốn đăng ký và đăng nhập email/mật khẩu để tạo và truy cập tài khoản HealthMate.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Email/mật khẩu không hợp lệ phải bị từ chối với thông báo phù hợp; đăng ký có xác nhận mật khẩu.
2. **AC-2:** Đăng nhập thành công tạo phiên Firebase Auth; không lưu mật khẩu trong Firestore.
3. **AC-3:** Đang gửi phải chặn thao tác lặp; lỗi mạng giữ khả năng thử lại.

**Phụ thuộc:** Không có phụ thuộc story khác trong backlog này; vẫn cần cấu hình nền tảng phù hợp.  
**Nguồn:** [lib/features/auth/data/firebase_auth_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/data/firebase_auth_repository.dart); [lib/features/auth/presentation/auth_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/presentation/auth_screen.dart).  
**Test/bằng chứng hiện có:** [test/auth_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/auth_test.dart); [test/auth_completion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/auth_completion_test.dart)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-002"></a>

### HM-US-002 — Tiếp tục với Google

**Loại:** Story · **Yêu cầu:** FR-AUTH-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò khách, tôi muốn tiếp tục với google để vào app bằng tài khoản Google.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Google sign-in thành công phải dùng đúng danh tính Firebase và đi qua kiểm tra onboarding.
2. **AC-2:** Hủy/chặn popup hoặc lỗi provider phải có đường thử lại; không tạo tài khoản giả.
3. **AC-3:** Không hiển thị Facebook như chức năng đã triển khai.

**Phụ thuộc:** FR-AUTH-01 (HM-US-001)  
**Nguồn:** [lib/features/auth/data/firebase_auth_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/data/firebase_auth_repository.dart).  
**Test/bằng chứng hiện có:** [test/auth_completion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/auth_completion_test.dart)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-003"></a>

### HM-US-003 — Xác minh email

**Loại:** Story · **Yêu cầu:** FR-AUTH-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò người dùng chưa xác minh, tôi muốn xác minh email để xác minh danh tính trước truy cập dữ liệu riêng.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có gửi lại liên kết và kiểm tra lại trạng thái xác minh.
2. **AC-2:** Email chưa xác minh không được vượt gate bằng cách mở route trực tiếp.
3. **AC-3:** Thời gian chờ và lỗi gửi lại được thông báo; cần UAT thư thật để đóng nghiệm thu.

**Phụ thuộc:** FR-AUTH-01 (HM-US-001)  
**Nguồn:** [lib/features/auth/providers/email_verification_provider.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/providers/email_verification_provider.dart); [lib/core/router/auth_redirect.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/router/auth_redirect.dart).  
**Test/bằng chứng hiện có:** [test/auth_completion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/auth_completion_test.dart); [rules-tests/auth-emulator.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/auth-emulator.test.cjs)  
**Rubric liên quan:** TC-06, TC-10  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-004"></a>

### HM-US-004 — Quên mật khẩu qua email

**Loại:** Story · **Yêu cầu:** FR-AUTH-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò khách, tôi muốn quên mật khẩu qua email để khôi phục quyền đăng nhập.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Nhập email hợp lệ và gọi Firebase Auth gửi liên kết reset tới địa chỉ đó.
2. **AC-2:** Báo trạng thái gửi/lỗi thân thiện, tránh tiết lộ không cần thiết việc email có tồn tại.
3. **AC-3:** Nghiệm thu riêng thao tác nhận thư, mở liên kết, đổi mật khẩu và đăng nhập lại.

**Phụ thuộc:** FR-AUTH-01 (HM-US-001)  
**Nguồn:** [lib/features/auth/presentation/auth_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/presentation/auth_screen.dart); [lib/features/auth/data/firebase_auth_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth/data/firebase_auth_repository.dart).  
**Test/bằng chứng hiện có:** [test/account_security_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/account_security_test.dart); [test/auth_completion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/auth_completion_test.dart)  
**Rubric liên quan:** TC-10  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-005"></a>

### HM-US-005 — Phiên đăng nhập, đổi mật khẩu và đăng xuất

**Loại:** Story · **Yêu cầu:** FR-AUTH-05 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn phiên đăng nhập, đổi mật khẩu và đăng xuất để quản lý an toàn phiên tài khoản.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Phiên hợp lệ được phục hồi; hết phiên có đường đăng nhập lại.
2. **AC-2:** Đổi mật khẩu yêu cầu reauthentication khi cần và chỉ áp dụng provider có mật khẩu.
3. **AC-3:** Đăng xuất/đổi UID hủy dữ liệu và phản hồi đến trễ của tài khoản trước.

**Phụ thuộc:** FR-AUTH-01 (HM-US-001)  
**Nguồn:** [lib/features/auth/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth); [lib/core/router/auth_redirect.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/router/auth_redirect.dart).  
**Test/bằng chứng hiện có:** [test/account_security_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/account_security_test.dart); [test/security_regression_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/security_regression_test.dart)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-006"></a>

### HM-US-006 — Xóa tài khoản và dữ liệu thuộc tài khoản

**Loại:** Story · **Yêu cầu:** FR-AUTH-06 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn xóa tài khoản và dữ liệu thuộc tài khoản để chủ động kết thúc sử dụng và dọn dữ liệu cá nhân.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có xác nhận rõ ràng và xác thực lại nếu cần; hủy không xóa dữ liệu.
2. **AC-2:** Dọn các collection/namespace cá nhân theo repository hiện có; lỗi không giả báo hoàn tất.
3. **AC-3:** Sau xóa không còn phiên hoặc dữ liệu của UID cũ được hiển thị trên UI.

**Phụ thuộc:** FR-AUTH-05 (HM-US-005)  
**Nguồn:** [lib/features/auth/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/auth); [lib/features/profile/presentation/profile_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/profile/presentation/profile_screen.dart).  
**Test/bằng chứng hiện có:** [test/account_security_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/account_security_test.dart); [test/h7_private_data_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h7_private_data_test.dart)  
**Rubric liên quan:** TC-04, TC-06  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-02 — Hồ sơ và cá nhân hóa

<a id="hm-us-007"></a>

### HM-US-007 — Onboarding và khảo sát cá nhân hóa 20 câu

**Loại:** Story · **Yêu cầu:** FR-PRO-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn onboarding và khảo sát cá nhân hóa 20 câu để thiết lập hồ sơ và thói quen ban đầu.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Người mới đi qua 8 màn ngắn, bộ 20 câu đánh số; nhánh liên quan còn 16–20 câu.
2. **AC-2:** Không tập bỏ câu 11–12; mục tiêu không đổi cân nặng bỏ câu 6–7; null không bị đổi thành 0.
3. **AC-3:** Người cũ không bị ép làm lại; có sửa và xem lại; chỉ hoàn tất sau xác nhận.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/profile/presentation/onboarding_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/profile/presentation/onboarding_screen.dart); [lib/features/profile/models/personalization_answers.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/profile/models/personalization_answers.dart).  
**Test/bằng chứng hiện có:** [test/personalization_questionnaire_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/personalization_questionnaire_test.dart); [test/onboarding_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/onboarding_test.dart)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-008"></a>

### HM-US-008 — Đề xuất kcal và macro cá nhân hóa

**Loại:** Story · **Yêu cầu:** FR-PRO-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn đề xuất kcal và macro cá nhân hóa để tham khảo mục tiêu từ dữ liệu đã cung cấp.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Dùng bộ tính Dart hiện có; thiếu đầu vào/ngoài phạm vi phải giải thích và cho thiết lập sau hoặc nhập tay.
2. **AC-2:** Hiện kcal, protein, carb, fat và nhãn tham khảo; không hứa giảm bao nhiêu kg theo thời gian.
3. **AC-3:** Tính toán/xem đề xuất không tự lưu; người dùng phải chọn và xác nhận.

**Phụ thuộc:** FR-PRO-01 (HM-US-007)  
**Nguồn:** [lib/features/nutrition_targets/models/personal_nutrition_plan.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition_targets/models/personal_nutrition_plan.dart); [lib/features/nutrition_targets/presentation/personal_nutrition_planner.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition_targets/presentation/personal_nutrition_planner.dart).  
**Test/bằng chứng hiện có:** [test/personal_nutrition_plan_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/personal_nutrition_plan_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-009"></a>

### HM-US-009 — Mục tiêu dinh dưỡng có ngày hiệu lực

**Loại:** Story · **Yêu cầu:** FR-PRO-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn mục tiêu dinh dưỡng có ngày hiệu lực để đặt hoặc thay mục tiêu mà giữ lịch sử.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Mục tiêu nhập tay và đề xuất xác nhận cùng lưu qua repository mục tiêu.
2. **AC-2:** Thay mục tiêu từ ngày hiệu lực cần xác nhận; lịch sử trước đó không bị ghi đè.
3. **AC-3:** Dashboard, Nhật ký và Chat dùng cùng mục tiêu đúng ngày; lỗi đọc không bị coi là chưa có.

**Phụ thuộc:** FR-PRO-02 (HM-US-008)  
**Nguồn:** [lib/features/nutrition_targets/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition_targets).  
**Test/bằng chứng hiện có:** [test/nutrition_targets_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/nutrition_targets_test.dart); [test/personal_nutrition_plan_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/personal_nutrition_plan_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-010"></a>

### HM-US-010 — Hồ sơ, cân nặng và BMI tham khảo

**Loại:** Story · **Yêu cầu:** FR-PRO-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn hồ sơ, cân nặng và bmi tham khảo để theo dõi thay đổi thể trạng của mình.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Thêm/sửa/xóa lần cân có validation và xác nhận xóa; chỉ chủ UID được thao tác.
2. **AC-2:** BMI chỉ xuất hiện khi đủ số đo hợp lệ, có ghi chú tham khảo.
3. **AC-3:** Sửa khảo sát không ghi đè số đo cũ; cân thay đổi thêm lần đo riêng, không đổi không tạo trùng.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/profile/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/profile).  
**Test/bằng chứng hiện có:** [test/profile_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/profile_test.dart); [test/personalization_questionnaire_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/personalization_questionnaire_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-03 — Dữ liệu món và ghi bữa

<a id="hm-us-011"></a>

### HM-US-011 — Tìm và chọn thực phẩm có nguồn

**Loại:** Story · **Yêu cầu:** FR-NUT-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn tìm và chọn thực phẩm có nguồn để chọn món và khẩu phần có căn cứ.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tìm trong catalog/cache đã có, hiển thị nguồn và trạng thái ước tính.
2. **AC-2:** Món server bị vô hiệu hóa không được nguồn bundle cùng ID phục hồi.
3. **AC-3:** Không có kết quả/lỗi nguồn phải có thông báo phù hợp; không biến dữ liệu chưa xác minh thành chính xác.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/nutrition/data/firebase_nutrition_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition/data/firebase_nutrition_repository.dart); [lib/features/nutrition/models/catalog_food_reader.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition/models/catalog_food_reader.dart).  
**Test/bằng chứng hiện có:** [test/food_catalog_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/food_catalog_test.dart); [test/h1_catalog_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h1_catalog_test.dart)  
**Rubric liên quan:** TC-03  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-012"></a>

### HM-US-012 — CRUD nhật ký bữa ăn và snapshot khẩu phần

**Loại:** Story · **Yêu cầu:** FR-NUT-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn crud nhật ký bữa ăn và snapshot khẩu phần để ghi lại món thực sự đã ăn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Chọn ngày, giờ, loại bữa và lượng ăn; quy đổi từ per-100g/khẩu phần theo nguồn.
2. **AC-2:** Chỉ lưu sau xác nhận; sửa/xóa cập nhật tổng và yêu cầu xác nhận xóa.
3. **AC-3:** Snapshot bữa giữ nguyên khi catalog/công thức sau đó bị sửa; nhập ở ngày lịch sử giữ đúng ngày.

**Phụ thuộc:** FR-NUT-01 (HM-US-011)  
**Nguồn:** [lib/features/nutrition/presentation/meal_form_dialog.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition/presentation/meal_form_dialog.dart); [lib/features/nutrition/data/firebase_nutrition_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition/data/firebase_nutrition_repository.dart).  
**Test/bằng chứng hiện có:** [test/nutrition_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/nutrition_test.dart); [test/core_journal_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/core_journal_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-013"></a>

### HM-US-013 — Món riêng, công thức và yêu thích

**Loại:** Story · **Yêu cầu:** FR-NUT-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn món riêng, công thức và yêu thích để tái sử dụng món thuộc thư viện cá nhân.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tạo/sửa/xóa món và công thức theo UID; thêm/bỏ yêu thích theo nguồn món.
2. **AC-2:** Quy đổi yield/khẩu phần của công thức tính đúng từ thành phần; xác nhận trước ghi.
3. **AC-3:** Không sửa hoặc công bố món cá nhân của người khác; thay nguồn không sửa nhật ký cũ.

**Phụ thuộc:** FR-NUT-01 (HM-US-011)  
**Nguồn:** [lib/features/food_library/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_library).  
**Test/bằng chứng hiện có:** [test/food_library_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/food_library_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-014"></a>

### HM-US-014 — Mẫu bữa, nháp và thêm nhanh

**Loại:** Story · **Yêu cầu:** FR-NUT-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn mẫu bữa, nháp và thêm nhanh để giảm thao tác nhập lặp.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có tái sử dụng mẫu bữa và bản nháp trong phạm vi cơ chế lưu hiện có; không hứa nháp RAM tồn tại qua mọi lần tắt app.
2. **AC-2:** Dùng mẫu/nháp vẫn cần kiểm tra ngày và xác nhận ghi bữa.
3. **AC-3:** Đổi UID không phục hồi nháp/yêu thích của tài khoản trước; thao tác lỗi có thể thử lại.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/meal_templates/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/meal_templates); [lib/features/meal_drafts/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/meal_drafts).  
**Test/bằng chứng hiện có:** [test/h2_templates_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h2_templates_test.dart); [test/h3_quick_add_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h3_quick_add_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-015"></a>

### HM-US-015 — Macro, chất xơ và dưỡng chất mở rộng

**Loại:** Story · **Yêu cầu:** FR-NUT-05 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn macro, chất xơ và dưỡng chất mở rộng để hiểu dữ liệu dinh dưỡng có và chưa có.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Giữ kcal, protein/carb/fat, chất xơ và tám dưỡng chất mở rộng khi nguồn cung cấp.
2. **AC-2:** Thống nhất g/mg; null khác 0; tổng phần đã biết không giả là tổng đầy đủ.
3. **AC-3:** Ghi nhãn nguồn/ước tính và độ phủ dữ liệu; sửa form không làm mất schema/dưỡng chất mới.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/nutrition/models/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition/models); [lib/features/food_library/presentation/food_nutrition_text.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_library/presentation/food_nutrition_text.dart).  
**Test/bằng chứng hiện có:** [test/h6_fiber_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h6_fiber_test.dart); [test/wellness_expansion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_expansion_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-016"></a>

### HM-US-016 — Xác nhận độ đầy đủ nhật ký ngày

**Loại:** Story · **Yêu cầu:** FR-NUT-06 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn xác nhận độ đầy đủ nhật ký ngày để giúp báo cáo không hiểu sai ngày thiếu ghi nhận.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Người dùng chủ động xác nhận đủ bữa; không tự suy từ một bữa đã ghi.
2. **AC-2:** Thêm/sửa/xóa bữa làm thay đổi revision và yêu cầu kiểm lại xác nhận.
3. **AC-3:** Ngày trống không trở thành 0 kcal thực tế; trung bình năng lượng dùng các ngày đủ điều kiện.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/reports/data/day_review_repository.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports/data/day_review_repository.dart); [lib/features/reports/presentation/day_review_controls.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports/presentation/day_review_controls.dart).  
**Test/bằng chứng hiện có:** [test/h5_period_report_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h5_period_report_test.dart)  
**Rubric liên quan:** TC-08  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-04 — Quét ảnh và mã vạch

<a id="hm-us-017"></a>

### HM-US-017 — Camera, chọn ảnh và đồng ý gửi AI

**Loại:** Story · **Yêu cầu:** FR-SCN-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn camera, chọn ảnh và đồng ý gửi ai để nhận hỗ trợ ghi bữa từ ảnh.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có chụp/chọn ảnh và xử lý quyền, hủy, ảnh không hợp lệ/quá lớn.
2. **AC-2:** Chỉ gửi ảnh cho AI khi đồng ý và bấm phân tích; không lưu ảnh gốc dài hạn mặc định.
3. **AC-3:** Timeout/quota/lỗi mạng có thông báo và đường lui nhập thủ công.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/food_scanner/presentation/food_camera_view.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/presentation/food_camera_view.dart); [lib/features/food_scanner/data/firebase_food_scanner_service.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/data/firebase_food_scanner_service.dart).  
**Test/bằng chứng hiện có:** [test/food_scanner_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/food_scanner_test.dart); [test/unified_meal_entry_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/unified_meal_entry_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-018"></a>

### HM-US-018 — Kiểm tra thành phần và kết quả dinh dưỡng ảnh

**Loại:** Story · **Yêu cầu:** FR-SCN-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn kiểm tra thành phần và kết quả dinh dưỡng ảnh để sửa ước tính trước khi ghi nhận.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Hiển thị tên/thành phần/khẩu phần và nguồn; không ghép đĩa nhiều thành phần vào riêng cơm trắng chỉ vì trùng từ.
2. **AC-2:** Người dùng sửa lượng/món hoặc chọn nguồn phù hợp; thiếu dữ liệu được ghi rõ.
3. **AC-3:** Lưu vào Món của tôi là thao tác riêng, không tự lưu bữa trước xác nhận.

**Phụ thuộc:** FR-SCN-01 (HM-US-017); FR-NUT-03 (HM-US-013)  
**Nguồn:** [lib/features/food_scanner/presentation/food_scanner_dialog.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/presentation/food_scanner_dialog.dart); [lib/features/food_scanner/models/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/models).  
**Test/bằng chứng hiện có:** [test/food_scan_catalog_matcher_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/food_scan_catalog_matcher_test.dart); [test/food_scanner_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/food_scanner_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-019"></a>

### HM-US-019 — Quét mã vạch và tra sản phẩm

**Loại:** Story · **Yêu cầu:** FR-SCN-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn quét mã vạch và tra sản phẩm để nhập thực phẩm đóng gói nhanh.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Quét mã bằng scanner và tra Open Food Facts theo service hiện có.
2. **AC-2:** Giữ lượng gram người dùng chỉnh và quy đổi đúng per-100g; trường thiếu khác 0.
3. **AC-3:** Không tìm thấy/lỗi mạng có đường nhập tay, không tạo dữ liệu sản phẩm giả.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/food_scanner/data/barcode_product_service.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/data/barcode_product_service.dart); [lib/features/food_scanner/presentation/barcode_product_detail_sheet.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/food_scanner/presentation/barcode_product_detail_sheet.dart).  
**Test/bằng chứng hiện có:** [test/barcode_scanner_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/barcode_scanner_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-05 — Nước, vận động và thói quen

<a id="hm-us-020"></a>

### HM-US-020 — Nhật ký nước uống

**Loại:** Story · **Yêu cầu:** FR-WEL-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn nhật ký nước uống để theo dõi lượng nước đã ghi.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Thêm/sửa/xóa số ml và thời điểm; từ chối giá trị ngoài miền validation hiện có.
2. **AC-2:** Có thêm nhanh; tổng ngày cập nhật sau sửa/xóa.
3. **AC-3:** Xóa cần xác nhận và mọi đọc/ghi đúng UID, ngày địa phương.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/water/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/water).  
**Test/bằng chứng hiện có:** [test/daily_logs_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/daily_logs_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-021"></a>

### HM-US-021 — Nhật ký vận động thủ công

**Loại:** Story · **Yêu cầu:** FR-WEL-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn nhật ký vận động thủ công để ghi loại hoạt động và thời lượng.

**Tiêu chí nghiệm thu:**

1. **AC-1:** CRUD hoạt động/phút/thời điểm; xác nhận xóa và kiểm tra giá trị.
2. **AC-2:** Tổng theo ngày đúng sau sửa/xóa; không nhầm nhật ký với chương trình tập có hướng dẫn.
3. **AC-3:** Năng lượng nếu ước tính phải có nhãn và không tự cộng ngân sách hai lần.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/activity/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/activity).  
**Test/bằng chứng hiện có:** [test/daily_logs_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/daily_logs_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-022"></a>

### HM-US-022 — Nhắc ghi bữa local

**Loại:** Story · **Yêu cầu:** FR-WEL-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn nhắc ghi bữa local để được nhắc theo giờ tự chọn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Chủ động bật/tắt và chọn giờ; xử lý quyền thông báo bị từ chối.
2. **AC-2:** Lưu theo phạm vi tài khoản/thiết bị, đổi UID không nhắc theo cài đặt người trước.
3. **AC-3:** Không hứa push từ server hoặc lịch đồng bộ toàn thiết bị khi chỉ có local reminder.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/wellness/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness); [android/app/src/main/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/android/app/src/main).  
**Test/bằng chứng hiện có:** [test/wellness_expansion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_expansion_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-023"></a>

### HM-US-023 — Lập thực đơn nhiều ngày

**Loại:** Story · **Yêu cầu:** FR-WEL-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn lập thực đơn nhiều ngày để lên kế hoạch ăn và ghi khi đã ăn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có tạo/sửa/xóa kế hoạch và xem trước gợi ý trước xác nhận.
2. **AC-2:** Kế hoạch chưa tính vào lượng đã ăn; ghi bữa cần xác nhận và ID tránh ghi trùng.
3. **AC-3:** Không tự đảm bảo kế hoạch an toàn dị ứng chỉ từ câu tự khai trong khảo sát.

**Phụ thuộc:** FR-NUT-02 (HM-US-012)  
**Nguồn:** [lib/features/wellness/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness).  
**Test/bằng chứng hiện có:** [test/wellness_expansion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_expansion_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-024"></a>

### HM-US-024 — Bước chân Android và lịch sử

**Loại:** Story · **Yêu cầu:** FR-WEL-05 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn bước chân android và lịch sử để theo dõi bước từ thiết bị sau opt-in.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Bật đếm và xin quyền; giải thích khi thiếu cảm biến/quyền hoặc dịch vụ bị hệ thống chặn.
2. **AC-2:** Dùng TYPE_STEP_COUNTER và dịch vụ hiện có, không khẳng định đo được trước khi bật.
3. **AC-3:** Đồng bộ ngày theo UID và giữ số quan sát cao nhất, không cộng chồng snapshot hai thiết bị.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/wellness/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness); [android/app/src/main/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/android/app/src/main).  
**Test/bằng chứng hiện có:** [test/wellness_expansion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_expansion_test.dart); [integration_test/wellness_acceptance_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/integration_test/wellness_acceptance_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-025"></a>

### HM-US-025 — Ghi giấc ngủ thủ công và nhắc ngủ

**Loại:** Story · **Yêu cầu:** FR-WEL-06 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn ghi giấc ngủ thủ công và nhắc ngủ để lưu và xem thời gian ngủ tự khai.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có Bắt đầu ngủ/Đã thức dậy, kiểm tra giờ và nhập thủ công; sửa/xóa có validation.
2. **AC-2:** Khoảng ngủ dương và tối đa 24 giờ mỗi bản ghi; retry kết thúc không tạo trùng.
3. **AC-3:** Có lịch sử/tổng hợp và mục tiêu/nhắc theo lựa chọn; không suy REM/ngủ sâu hay đổi kcal từ giờ ngủ.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/wellness/presentation/sleep_insights.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness/presentation/sleep_insights.dart); [lib/features/wellness/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness).  
**Test/bằng chứng hiện có:** [test/wellness_expansion_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_expansion_test.dart); [test/wellness_insights_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_insights_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-026"></a>

### HM-US-026 — Ngân sách ăn và năng lượng bước đã xác nhận

**Loại:** Story · **Yêu cầu:** FR-WEL-07 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn ngân sách ăn và năng lượng bước đã xác nhận để chủ động áp dụng ước tính vận động vào hôm nay.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Ước tính cần baseline, bước, cân và mục tiêu phù hợp; mặc định không tự cộng.
2. **AC-2:** Chỉ áp dụng sau xác nhận, một snapshot/ngày; tránh cộng chồng hoạt động nhập tay.
3. **AC-3:** Đổi mục tiêu/điều kiện làm credit cũ không áp dụng; Dashboard/Journal/Chat nhất quán, lịch sử không tính lại âm thầm.

**Phụ thuộc:** FR-WEL-05 (HM-US-024); FR-PRO-03 (HM-US-009)  
**Nguồn:** [lib/features/wellness/presentation/energy_panel.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/wellness/presentation/energy_panel.dart); [lib/features/nutrition_targets/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition_targets).  
**Test/bằng chứng hiện có:** [test/wellness_insights_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/wellness_insights_test.dart); [test/h4_energy_estimate_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h4_energy_estimate_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-06 — Mục tiêu và Quest

<a id="hm-us-027"></a>

### HM-US-027 — Quản lý mục tiêu sức khỏe

**Loại:** Story · **Yêu cầu:** FR-GOL-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn quản lý mục tiêu sức khỏe để đặt và theo dõi mục tiêu phù hợp.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tạo/sửa/xóa mục tiêu với loại, giá trị, đơn vị, thời hạn/trạng thái hợp lệ.
2. **AC-2:** Tiến độ tính theo từng loại, không áp cùng một công thức cho mọi mục tiêu.
3. **AC-3:** Xác nhận xóa và không thay lịch sử nguồn để tạo tiến độ giả.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/goals/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/goals).  
**Test/bằng chứng hiện có:** [test/goals_quest_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/goals_quest_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-028"></a>

### HM-US-028 — Nhiệm vụ sức khỏe hằng ngày

**Loại:** Story · **Yêu cầu:** FR-GOL-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn nhiệm vụ sức khỏe hằng ngày để có gợi ý hành động nhỏ từ dữ liệu thật.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Nhiệm vụ theo quy tắc, ngày/UID và ID ổn định; mở lại không sinh trùng.
2. **AC-2:** Hoàn thành/bỏ qua được lưu; không suy bệnh từ ngày thiếu nhật ký.
3. **AC-3:** Không phạt nặng hoặc để AI tự ghi/xóa dữ liệu qua quest.

**Phụ thuộc:** FR-GOL-01 (HM-US-027)  
**Nguồn:** [lib/features/daily_quest/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/daily_quest).  
**Test/bằng chứng hiện có:** [test/goals_quest_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/goals_quest_test.dart); [test/maintenance_quest_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/maintenance_quest_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-07 — Dashboard và lịch sử báo cáo

<a id="hm-us-029"></a>

### HM-US-029 — Dashboard ít nhất bốn nhóm dữ liệu

**Loại:** Story · **Yêu cầu:** FR-RPT-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn dashboard ít nhất bốn nhóm dữ liệu để xem tổng quan dữ liệu và hành động tiếp theo.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có dinh dưỡng, nước, vận động, cân nặng khi nguồn có; hiện empty/error đúng nguồn.
2. **AC-2:** Tổng đúng với Nhật ký/ngày đang xem; có lối thêm ghi nhận và mục tiêu.
3. **AC-3:** Không dùng fixture/giá trị Figma trong luồng thật.

**Phụ thuộc:** FR-NUT-02 (HM-US-012); FR-WEL-01 (HM-US-020); FR-WEL-02 (HM-US-021); FR-PRO-04 (HM-US-010)  
**Nguồn:** [lib/features/dashboard/presentation/dashboard_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/dashboard/presentation/dashboard_screen.dart).  
**Test/bằng chứng hiện có:** [test/dashboard_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/dashboard_test.dart); [test/mfp_ui_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/mfp_ui_test.dart)  
**Rubric liên quan:** TC-02  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-030"></a>

### HM-US-030 — Tổng kết tuần và biểu đồ hiện có

**Loại:** Story · **Yêu cầu:** FR-RPT-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn tổng kết tuần và biểu đồ hiện có để xem xu hướng từ các ghi nhận của mình.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tổng hợp dinh dưỡng/nước/vận động/cân nặng từ repository; biểu đồ không bịa điểm ở ngày thiếu.
2. **AC-2:** Chỉ mô tả xu hướng, không kết luận giảm mỡ hoặc quan hệ nhân quả từ tương quan.
3. **AC-3:** Phân biệt ngày thiếu dữ liệu với 0; có chi tiết và trạng thái dữ liệu ít/trống.

**Phụ thuộc:** FR-RPT-01 (HM-US-029); FR-NUT-06 (HM-US-016)  
**Nguồn:** [lib/features/weekly_reflection/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/weekly_reflection); [lib/features/progress/presentation/progress_overview.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/progress/presentation/progress_overview.dart).  
**Test/bằng chứng hiện có:** [test/weekly_reflection_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/weekly_reflection_test.dart); [test/progress_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/progress_test.dart)  
**Rubric liên quan:** TC-08  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-031"></a>

### HM-US-031 — Báo cáo theo năm và khoảng tùy chọn

**Loại:** Story · **Yêu cầu:** FR-RPT-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn báo cáo theo năm và khoảng tùy chọn để xem lại lịch sử theo nhu cầu.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Chọn tuần/30/90 ngày, năm lịch hoặc khoảng/số ngày 1–366; năm hiện tại dừng ở hôm nay.
2. **AC-2:** Đọc theo các đoạn có giới hạn, tổng hợp tháng và chi tiết ngày; thiếu/lỗi một nguồn không báo đủ dữ liệu.
3. **AC-3:** Chuyển kỳ không xóa lịch sử và phản hồi UID cũ phải bị bỏ.

**Phụ thuộc:** FR-RPT-02 (HM-US-030)  
**Nguồn:** [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports); [lib/features/progress/presentation/progress_screen.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/progress/presentation/progress_screen.dart).  
**Test/bằng chứng hiện có:** [test/year_reports_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/year_reports_test.dart); [test/h5_period_report_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h5_period_report_test.dart)  
**Rubric liên quan:** TC-08  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-032"></a>

### HM-US-032 — Xuất nhật ký cá nhân CSV

**Loại:** Story · **Yêu cầu:** FR-RPT-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn xuất nhật ký cá nhân csv để lấy bản sao dữ liệu trong khoảng đã chọn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Xác nhận xuất, chọn nơi lưu và khoảng tối đa 366 ngày.
2. **AC-2:** Bao gồm bữa/món, nước, hoạt động, cân nặng; không ngầm xuất chat/hồ sơ/khảo sát.
3. **AC-3:** Giữ đơn vị/null/snapshot, chống ô công thức, báo vượt giới hạn thay vì xuất một phần như đầy đủ.

**Phụ thuộc:** FR-RPT-03 (HM-US-031)  
**Nguồn:** [lib/features/data_export/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/data_export).  
**Test/bằng chứng hiện có:** [test/h7_csv_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h7_csv_test.dart); [test/year_reports_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/year_reports_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-08 — Chat AI

<a id="hm-us-033"></a>

### HM-US-033 — Chat AI sau đồng ý

**Loại:** Story · **Yêu cầu:** FR-CHT-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn chat ai sau đồng ý để hỏi linh hoạt về dinh dưỡng và thói quen.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có consent trước gửi API, trạng thái trả lời, lỗi/quota và thử lại.
2. **AC-2:** Câu hỏi tự do dùng Worker hiện có; không coi chatbot chỉ là bộ FAQ cố định.
3. **AC-3:** Rời tab hủy stream theo implementation; không lưu câu trả lời chưa hoàn tất như đã thành công.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [lib/features/chatbot/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/chatbot); [chat-api/src/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/chat-api/src).  
**Test/bằng chứng hiện có:** [test/chatbot_api_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/chatbot_api_test.dart); [chat-api/test/api.test.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/chat-api/test/api.test.mjs)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-034"></a>

### HM-US-034 — Ngữ cảnh cá nhân có nguồn và giới hạn quyền AI

**Loại:** Story · **Yêu cầu:** FR-CHT-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn ngữ cảnh cá nhân có nguồn và giới hạn quyền ai để nhận câu trả lời khớp số liệu của mình.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Câu hỏi số liệu cá nhân phải đọc repository đúng ngày/UID, có đơn vị; thiếu thì báo thiếu.
2. **AC-2:** Chỉ gửi phần ngữ cảnh tối thiểu, không tự gửi khảo sát/toàn bộ hồ sơ/bước/ngủ.
3. **AC-3:** AI không tự truy vấn tùy ý hoặc ghi/xóa Firestore; không chẩn đoán/kê toa.

**Phụ thuộc:** FR-CHT-01 (HM-US-033); FR-RPT-01 (HM-US-029); FR-PRO-03 (HM-US-009)  
**Nguồn:** [lib/features/chatbot/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/chatbot); [chat-api/src/protocol.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/chat-api/src/protocol.mjs).  
**Test/bằng chứng hiện có:** [test/chatbot_personal_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/chatbot_personal_test.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-035"></a>

### HM-US-035 — Lịch sử chat và giới hạn 50 lượt mỗi cuộc

**Loại:** Story · **Yêu cầu:** FR-CHT-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn lịch sử chat và giới hạn 50 lượt mỗi cuộc để tiếp tục cuộc đang dùng khi đổi tab.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Messages/session lưu riêng UID; chọn cuộc cũ/mới và trở lại đúng cuộc đang chọn.
2. **AC-2:** Mỗi cuộc tối đa 50 cặp hỏi–đáp; lượt 51 bị chặn cả client và Rules; đọc lịch sử không gọi AI.
3. **AC-3:** Rate limit API tách giới hạn cuộc; đổi UID xóa con trỏ cũ và bỏ phản hồi đến trễ.

**Phụ thuộc:** FR-CHT-01 (HM-US-033)  
**Nguồn:** [lib/features/chatbot/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/chatbot); [firestore.rules](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/firestore.rules).  
**Test/bằng chứng hiện có:** [test/chatbot_resume_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/chatbot_resume_test.dart); [rules-tests/firestore.rules.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/firestore.rules.test.cjs)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-09 — Quản trị ứng dụng

<a id="hm-us-036"></a>

### HM-US-036 — Đăng nhập admin và kiểm tra quyền server

**Loại:** Story · **Yêu cầu:** FR-ADM-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn đăng nhập admin và kiểm tra quyền server để truy cập công cụ đúng role.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tài khoản đã xác minh có role enabled mới vào admin; ưu tiên Google với tài khoản đã cấp.
2. **AC-2:** Member/anonymous/role bị thu hồi không đọc hoặc ghi được dữ liệu quản trị.
3. **AC-3:** Đợi App Check đúng cấu hình; không tự cấp role trong client.

**Phụ thuộc:** FR-AUTH-03 (HM-US-003)  
**Nguồn:** [admin-web/dist/firebase.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/firebase.mjs); [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs); [firestore.rules](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/firestore.rules).  
**Test/bằng chứng hiện có:** [rules-tests/admin.rules.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/admin.rules.test.cjs); [admin-web/test/sdk.integration.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/test/sdk.integration.mjs)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-037"></a>

### HM-US-037 — CRUD catalog quản trị và xóa mềm

**Loại:** Story · **Yêu cầu:** FR-ADM-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn crud catalog quản trị và xóa mềm để duy trì dữ liệu món dùng chung.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Tạo/xem/sửa dinh dưỡng, khẩu phần, nguồn; xác nhận ẩn/khôi phục và lý do.
2. **AC-2:** Xóa là isActive:false, không xóa snapshot nhật ký; kiểm tra phiên bản tránh ghi đè cập nhật khác.
3. **AC-3:** Ghi catalog và audit phải cùng thành công hoặc cùng thất bại.

**Phụ thuộc:** FR-ADM-01 (HM-US-036)  
**Nguồn:** [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs); [admin-web/dist/validation.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/validation.mjs); [firestore.rules](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/firestore.rules).  
**Test/bằng chứng hiện có:** [admin-web/test/validation.test.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/test/validation.test.mjs); [rules-tests/admin.rules.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/admin.rules.test.cjs)  
**Rubric liên quan:** TC-03, TC-04  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-038"></a>

### HM-US-038 — Directory và khóa/mở quyền HealthMate

**Loại:** Story · **Yêu cầu:** FR-ADM-03 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn directory và khóa/mở quyền healthmate để hỗ trợ kiểm soát truy cập app.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Chỉ liệt kê tài khoản đã đồng bộ directory, không giả là toàn bộ Firebase Auth.
2. **AC-2:** Khóa/mở có xác nhận/lý do, bảo vệ admin hiện tại và UID có role.
3. **AC-3:** Khóa chặn dữ liệu server, không xóa cache/disable Google; không cho admin đọc nhật ký sức khỏe/chat riêng.

**Phụ thuộc:** FR-ADM-01 (HM-US-036)  
**Nguồn:** [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs); [lib/core/config/admin_runtime.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/config/admin_runtime.dart); [firestore.rules](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/firestore.rules).  
**Test/bằng chứng hiện có:** [test/admin_runtime_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/admin_runtime_test.dart); [rules-tests/admin.rules.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/admin.rules.test.cjs)  
**Rubric liên quan:** TC-06  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-039"></a>

### HM-US-039 — Cấu hình runtime, bảo trì và tích hợp Android

**Loại:** Story · **Yêu cầu:** FR-ADM-04 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn cấu hình runtime, bảo trì và tích hợp android để điều chỉnh tính năng mà không phát hành lại mỗi lần.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Cho sửa bật/tắt scanner/chat, bảo trì/thông báo với xác nhận và audit.
2. **AC-2:** Bản Android qua script có cờ admin nhận listener online; khóa rồi mở lại phải nối lại cấu hình.
3. **AC-3:** Không hứa bản cũ/đang offline hoặc API AI độc lập bị chặn tuyệt đối; không sửa UI bằng remote flag.

**Phụ thuộc:** FR-ADM-03 (HM-US-038)  
**Nguồn:** [lib/core/config/admin_runtime.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/config/admin_runtime.dart); [config/admin-runtime.json](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/config/admin-runtime.json); [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs).  
**Test/bằng chứng hiện có:** [test/admin_runtime_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/admin_runtime_test.dart); [test/admin_runtime_integration.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/admin_runtime_integration.dart)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-040"></a>

### HM-US-040 — Dashboard, tìm/lọc/phân trang và Excel admin

**Loại:** Story · **Yêu cầu:** FR-ADM-05 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn dashboard, tìm/lọc/phân trang và excel admin để tra cứu và xuất danh sách đầy đủ.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Dashboard có món, tài khoản đồng bộ, bị khóa, thao tác; danh sách có STT, trạng thái màu và lọc loại khi có.
2. **AC-2:** Tải từng cursor 200, giới hạn 5.000 mục; tìm không dấu và 25 mục/trang sau tải đủ.
3. **AC-3:** XLSX chứa toàn bộ kết quả lọc qua mọi trang; vượt giới hạn/lỗi thì không xuất âm thầm một phần.

**Phụ thuộc:** FR-ADM-02 (HM-US-037)  
**Nguồn:** [admin-web/dist/list-model.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/list-model.mjs); [admin-web/dist/xlsx-export.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/xlsx-export.mjs); [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs).  
**Test/bằng chứng hiện có:** [admin-web/test/list-model.test.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/test/list-model.test.mjs); [admin-web/test/xlsx.test.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/test/xlsx.test.mjs)  
**Rubric liên quan:** TC-02, TC-03, TC-05  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-041"></a>

### HM-US-041 — Audit bất biến và cập nhật danh sách

**Loại:** Story · **Yêu cầu:** FR-ADM-06 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò quản trị viên, tôi muốn audit bất biến và cập nhật danh sách để truy vết thay đổi và xử lý xung đột.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có actor/thời điểm/đối tượng/trường thay đổi/lý do; client không sửa/xóa audit.
2. **AC-2:** Sửa dữ liệu kiểm tra revision; lỗi giữ form và không báo thành công trước xác nhận server.
3. **AC-3:** Danh sách web tải lại theo thao tác; không quảng cáo mọi bảng tự realtime.

**Phụ thuộc:** FR-ADM-01 (HM-US-036)  
**Nguồn:** [admin-web/dist/firebase.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/firebase.mjs); [admin-web/dist/app.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist/app.mjs); [firestore.rules](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/firestore.rules).  
**Test/bằng chứng hiện có:** [rules-tests/admin.rules.test.cjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/rules-tests/admin.rules.test.cjs); [admin-web/test/sdk.integration.mjs](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/test/sdk.integration.mjs)  
**Rubric liên quan:** Nghiệp vụ sản phẩm; góp phần demo và regression, không là tiêu chí cô riêng biệt.  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-10 — UX/UI theo Figma

<a id="hm-us-042"></a>

### HM-US-042 — Điều hướng và giao diện theo Figma hiện có

**Loại:** Story · **Yêu cầu:** FR-UI-01 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò thành viên, tôi muốn điều hướng và giao diện theo figma hiện có để tìm chức năng theo bố cục thống nhất.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Thanh dưới Hôm nay / Nhật ký / + / Tiến độ / Thói quen; + là hành động, không phải tab dữ liệu.
2. **AC-2:** Avatar ở các màn đã thiết kế mở Cá nhân; có lối vào bước/ngủ và giữ route nghiệp vụ thật.
3. **AC-3:** Nhật ký giữ ngày lịch sử, dấu + dùng hôm nay; light/dark và font tiếng Việt không đưa số fixture vào sản phẩm.

**Phụ thuộc:** FR-RPT-01 (HM-US-029)  
**Nguồn:** [lib/core/widgets/app_shell.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/widgets/app_shell.dart); [lib/core/widgets/profile_avatar.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/widgets/profile_avatar.dart); [docs/figma-v2-implementation.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/figma-v2-implementation.md).  
**Test/bằng chứng hiện có:** [test/reference_ui_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/reference_ui_test.dart); [test/navigation_features_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/navigation_features_test.dart)  
**Rubric liên quan:** TC-12  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-043"></a>

### HM-US-043 — Trạng thái, khả năng tiếp cận và xác nhận

**Loại:** Story · **Yêu cầu:** FR-UI-02 · **Ưu tiên:** P1 · **Trạng thái kiểm kê:** Có code tại baseline — chờ nghiệm thu cuối.  
**User Story:** Với vai trò người dùng, tôi muốn trạng thái, khả năng tiếp cận và xác nhận để thao tác được trên màn nhỏ và chữ lớn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Luồng dữ liệu có loading/empty/error/retry; nút không là giả và busy chặn gửi trùng.
2. **AC-2:** Giữ safe area/bàn phím/scroll và đọc được tiếng Việt ở các cỡ đã kiểm thử.
3. **AC-3:** Hủy không ghi; đổi tài khoản bỏ nháp/phản hồi cũ; xóa phải xác nhận.

**Phụ thuộc:** FR-UI-01 (HM-US-042)  
**Nguồn:** [lib/core/widgets/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/core/widgets); [lib/features/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features).  
**Test/bằng chứng hiện có:** [test/maintenance_layout_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/maintenance_layout_test.dart); [test/reference_ui_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/reference_ui_test.dart); [test/security_regression_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/security_regression_test.dart)  
**Rubric liên quan:** TC-04  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-11 — Hoàn thiện báo cáo và in theo yêu cầu môn học

<a id="hm-us-044"></a>

### HM-US-044 — Chuẩn hóa báo cáo dinh dưỡng cho nghiệm thu

**Loại:** Story · **Yêu cầu:** FR-REP-01 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Có nền — cần hoàn thiện/nghiệm thu.  
**User Story:** Với vai trò thành viên, tôi muốn chuẩn hóa báo cáo dinh dưỡng cho nghiệm thu để có một báo cáo dinh dưỡng đủ tiêu chí môn học.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Đặt tên/mã R01, chọn khoảng, hiển thị kcal/macro/chất xơ và độ phủ dữ liệu theo đúng nguồn.
2. **AC-2:** Có danh sách ngày/bữa tương ứng và tổng khớp; không lấy ngày thiếu làm 0.
3. **AC-3:** Gắn màn/luồng testcase và ảnh demo; nền tảng đã có không đủ để tự đánh dấu báo cáo đã nghiệm thu.

**Phụ thuộc:** FR-RPT-03 (HM-US-031)  
**Nguồn:** [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports); [lib/features/progress/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/progress).  
**Test/bằng chứng hiện có:** [test/h5_period_report_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h5_period_report_test.dart); [test/year_reports_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/year_reports_test.dart)  
**Rubric liên quan:** TC-08  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-045"></a>

### HM-US-045 — Chuẩn hóa báo cáo nước uống cho nghiệm thu

**Loại:** Story · **Yêu cầu:** FR-REP-02 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Có nền — cần hoàn thiện/nghiệm thu.  
**User Story:** Với vai trò thành viên, tôi muốn chuẩn hóa báo cáo nước uống cho nghiệm thu để xem tổng và chi tiết lượng nước theo kỳ.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Đặt mã R02, lọc ngày/kỳ, tổng ml/ngày và biểu đồ Bar có nhãn đơn vị.
2. **AC-2:** Chọn ngày/cột mở đúng các water_logs của chủ UID và đối chiếu tổng.
3. **AC-3:** Empty/error/không đủ dữ liệu phải được kiểm thử và có minh chứng.

**Phụ thuộc:** FR-WEL-01 (HM-US-020); FR-RPT-03 (HM-US-031)  
**Nguồn:** [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports); [lib/features/water/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/water); [lib/features/weekly_reflection/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/weekly_reflection).  
**Test/bằng chứng hiện có:** [test/weekly_reflection_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/weekly_reflection_test.dart); [test/daily_logs_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/daily_logs_test.dart)  
**Rubric liên quan:** TC-08, TC-09  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-046"></a>

### HM-US-046 — Chuẩn hóa báo cáo vận động cho nghiệm thu

**Loại:** Story · **Yêu cầu:** FR-REP-03 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Có nền — cần hoàn thiện/nghiệm thu.  
**User Story:** Với vai trò thành viên, tôi muốn chuẩn hóa báo cáo vận động cho nghiệm thu để xem thời lượng và loại vận động đã ghi.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Đặt mã R03, lọc kỳ và nhóm theo ngày/loại với phút là đơn vị rõ ràng.
2. **AC-2:** Mở chi tiết các activity_logs tạo nên tổng; bước cảm biến không bị gộp như bản ghi nhập tay.
3. **AC-3:** Có test nguồn thiếu/giá trị 0/chuyển UID; minh chứng không dùng sức khỏe của người khác.

**Phụ thuộc:** FR-WEL-02 (HM-US-021); FR-RPT-03 (HM-US-031)  
**Nguồn:** [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports); [lib/features/activity/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/activity).  
**Test/bằng chứng hiện có:** [test/h5_period_report_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/h5_period_report_test.dart); [test/daily_logs_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/daily_logs_test.dart)  
**Rubric liên quan:** TC-08, TC-09  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-047"></a>

### HM-US-047 — Chuẩn hóa báo cáo cân nặng cho nghiệm thu

**Loại:** Story · **Yêu cầu:** FR-REP-04 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Có nền — cần hoàn thiện/nghiệm thu.  
**User Story:** Với vai trò thành viên, tôi muốn chuẩn hóa báo cáo cân nặng cho nghiệm thu để xem số đo và thay đổi theo kỳ.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Đặt mã R04, lọc kỳ, số lần cân, đầu/cuối và chênh lệch khi đủ dữ liệu.
2. **AC-2:** Chọn điểm mở lần cân thực tế; nhiều lần cùng ngày không bị thay bằng số liệu bịa.
3. **AC-3:** 0/1 lần cân có giải thích; không diễn giải chênh lệch thành lượng mỡ giảm.

**Phụ thuộc:** FR-PRO-04 (HM-US-010); FR-RPT-03 (HM-US-031)  
**Nguồn:** [lib/features/profile/presentation/weight_chart.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/profile/presentation/weight_chart.dart); [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports).  
**Test/bằng chứng hiện có:** [test/profile_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/profile_test.dart); [test/year_reports_test.dart](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/test/year_reports_test.dart)  
**Rubric liên quan:** TC-08, TC-09  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-048"></a>

### HM-US-048 — Biểu đồ Pie và drill-down có ý nghĩa

**Loại:** Story · **Yêu cầu:** FR-REP-05 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Đề xuất — chưa triển khai.  
**User Story:** Với vai trò thành viên, tôi muốn biểu đồ pie và drill-down có ý nghĩa để hiểu thành phần tạo nên tỷ lệ báo cáo.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có Pie thật cho một đại lượng cộng được, ví dụ tỷ lệ năng lượng macro 4/4/9; ghi rõ mẫu số/nguồn.
2. **AC-2:** Thiếu macro thì hiển thị chưa đủ thay vì biểu diễn như đầy đủ; 0 tổng không chia 0.
3. **AC-3:** Bấm lát/cột/điểm đã quy định mở dữ liệu tương ứng cùng kỳ/UID; Back giữ bộ lọc.

**Phụ thuộc:** FR-REP-01 (HM-US-044); FR-REP-02 (HM-US-045); FR-REP-03 (HM-US-046); FR-REP-04 (HM-US-047)  
**Nguồn:** [lib/features/progress/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/progress); [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports).  
**Test/bằng chứng hiện có:** Chưa có bộ test xác nhận chức năng mới này; phải thiết kế khi giao triển khai.  
**Rubric liên quan:** TC-09  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-049"></a>

### HM-US-049 — In danh mục món ăn quản trị

**Loại:** Story · **Yêu cầu:** FR-PRN-01 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Đề xuất — chưa triển khai.  
**User Story:** Với vai trò quản trị viên, tôi muốn in danh mục món ăn quản trị để in danh sách món để kiểm tra hoặc nộp minh chứng.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có lệnh In riêng và bản xem trước với tên báo cáo, thời điểm, bộ lọc, STT, nguồn và đơn vị.
2. **AC-2:** In toàn bộ kết quả lọc qua các trang, không chỉ trang đang hiển thị; báo vượt giới hạn.
3. **AC-3:** A4 nhiều trang không mất/cắt hàng, chữ Việt đúng; hủy hộp in không thay dữ liệu.

**Phụ thuộc:** FR-ADM-05 (HM-US-040)  
**Nguồn:** [admin-web/dist/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist).  
**Test/bằng chứng hiện có:** Chưa có bộ test xác nhận chức năng mới này; phải thiết kế khi giao triển khai.  
**Rubric liên quan:** TC-11  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-050"></a>

### HM-US-050 — In báo cáo theo kỳ của chính người dùng

**Loại:** Story · **Yêu cầu:** FR-PRN-02 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Đề xuất — chưa triển khai.  
**User Story:** Với vai trò thành viên, tôi muốn in báo cáo theo kỳ của chính người dùng để in báo cáo sức khỏe riêng theo khoảng đã chọn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Có lệnh In riêng cho báo cáo kỳ, thể hiện ngày/kỳ, đơn vị, tổng và lưu ý dữ liệu thiếu.
2. **AC-2:** Chỉ chủ tài khoản xuất/in dữ liệu mình; không mở quyền đọc sức khỏe cho admin.
3. **AC-3:** Có xem trước và kiểm tra A4/phân trang/font; cách tích hợp in Android/web cần chọn khi triển khai.

**Phụ thuộc:** FR-REP-01 (HM-US-044); FR-REP-02 (HM-US-045); FR-REP-03 (HM-US-046); FR-REP-04 (HM-US-047)  
**Nguồn:** [lib/features/reports/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/reports); [lib/features/data_export/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/data_export).  
**Test/bằng chứng hiện có:** Chưa có bộ test xác nhận chức năng mới này; phải thiết kế khi giao triển khai.  
**Rubric liên quan:** TC-11  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-12 — Lưu trữ ảnh nghiệp vụ

<a id="hm-us-051"></a>

### HM-US-051 — Thiết kế lưu ảnh catalog và kiểm tra chi phí/quyền

**Loại:** Story · **Yêu cầu:** FR-IMG-01 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Đề xuất — chưa triển khai.  
**User Story:** Với vai trò chủ dự án, tôi muốn thiết kế lưu ảnh catalog và kiểm tra chi phí/quyền để đáp ứng yêu cầu lưu ảnh mà không đổi riêng tư tùy tiện.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Chốt phạm vi ảnh món dùng chung do admin quản lý; không mặc định lưu ảnh scan của người dùng.
2. **AC-2:** Có thiết kế quyền đọc/ghi, định dạng, kích thước, vòng đời và phương án chi phí trước khi bật dịch vụ.
3. **AC-3:** Nếu cần billing/dịch vụ mới phải được người dùng duyệt; trạng thái này là discovery, chưa có upload thật.

**Phụ thuộc:** FR-ADM-02 (HM-US-037)  
**Nguồn:** [docs/database-design.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/docs/database-design.md); [AGENTS.md](https://github.com/luuxuantung285600/HealthMate/blob/14bb579b6d1549db1569ee7710b7b1733e92c5de/AGENTS.md).  
**Test/bằng chứng hiện có:** Chưa có bộ test xác nhận chức năng mới này; phải thiết kế khi giao triển khai.  
**Rubric liên quan:** TC-07  
**Estimate/assignee/sprint:** chưa phân công.

<a id="hm-us-052"></a>

### HM-US-052 — Tải lên, thay và gỡ ảnh món catalog

**Loại:** Story · **Yêu cầu:** FR-IMG-02 · **Ưu tiên:** P0 · **Trạng thái kiểm kê:** Đề xuất — chưa triển khai.  
**User Story:** Với vai trò quản trị viên, tôi muốn tải lên, thay và gỡ ảnh món catalog để quản lý ảnh minh họa gắn món ăn.

**Tiêu chí nghiệm thu:**

1. **AC-1:** Sau khi FR-IMG-01 được chốt, admin có upload/preview/replace/remove với kiểm tra file thật theo chính sách đã duyệt.
2. **AC-2:** Người thường không upload/xóa ảnh catalog; thiếu quyền/lỗi mạng không để tham chiếu giả.
3. **AC-3:** Ảnh gỡ/thay có xử lý tệp mồ côi và audit; ảnh không được sao chép vào snapshot lịch sử ngoài phạm vi đã chốt.

**Phụ thuộc:** FR-IMG-01 (HM-US-051)  
**Nguồn:** [admin-web/dist/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/admin-web/dist); [lib/features/nutrition/](https://github.com/luuxuantung285600/HealthMate/tree/14bb579b6d1549db1569ee7710b7b1733e92c5de/lib/features/nutrition).  
**Test/bằng chứng hiện có:** Chưa có bộ test xác nhận chức năng mới này; phải thiết kế khi giao triển khai.  
**Rubric liên quan:** TC-07  
**Estimate/assignee/sprint:** chưa phân công.

## HM-EP-13 — Chất lượng, nghiệm thu và hồ sơ dự án

Các task sau không thêm chức năng nghiệp vụ ngoài yêu cầu, mà đóng khoảng trống đo lường, nghiệm thu và hồ sơ.

<a id="hm-task-001"></a>

### HM-TASK-001 — Đo hiệu năng trên dataset và môi trường demo

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Backlog — chưa có phép đo chuẩn.  
**Liên kết yêu cầu:** NFR-PER-01, NFR-PER-02.  
**Phụ thuộc:** FR-RPT-01 (HM-US-029); FR-ADM-05 (HM-US-040)

**Tiêu chí hoàn tất:**

1. Chốt máy/mạng/dataset và cold/warm; ghi tối thiểu 20 lượt cho tình huống đã chọn.
2. Bảng thời gian có từng mẫu, P95, lỗi và số bản ghi; so với mục tiêu đề xuất trong SRS.
3. Có issue cải thiện nếu không đạt; không thay số đo bằng nhận xét cảm tính.

**Rubric:** TC-01. **Estimate/assignee/sprint:** chưa phân công.

<a id="hm-task-002"></a>

### HM-TASK-002 — Nghiệm thu Android thật và điều khiển admin trực tiếp

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Backlog — chưa xác nhận cài APK mới.  
**Liên kết yêu cầu:** NFR-OPS-01, NFR-USA-01, NFR-REL-01.  
**Phụ thuộc:** FR-ADM-04 (HM-US-039); FR-UI-01 (HM-US-042)

**Tiêu chí hoàn tất:**

1. Ghi rõ commit, APK/hash, thiết bị và cấu hình; cài cập nhật giữ dữ liệu.
2. Dùng tài khoản thử, xác minh khóa/mở và đổi config trong lúc khóa rồi mở lại; tránh thử phá dữ liệu thật.
3. Thử ngày lịch sử, khảo sát, camera/barcode, quyền cảm biến/ngủ và chữ lớn; lưu kết quả thật/pass/fail/blocker.

**Rubric:** TC-13, TC-12, TC-06. **Estimate/assignee/sprint:** chưa phân công.

<a id="hm-task-003"></a>

### HM-TASK-003 — Nghiệm thu web admin production và email thật

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Backlog — người dùng trước đó chọn thử sau.  
**Liên kết yêu cầu:** NFR-SEC-01, NFR-OPS-01, FR-AUTH-03, FR-AUTH-04.  
**Phụ thuộc:** FR-ADM-01 (HM-US-036); FR-ADM-05 (HM-US-040)

**Tiêu chí hoàn tất:**

1. Dùng Google đúng tài khoản role, thử member bị chặn và App Check hoạt động trong trình duyệt được cho phép.
2. Thử form, tìm/lọc/Excel/audit với fixture riêng; ghi ảnh/log đã loại thông tin nhạy cảm.
3. Thử nhận email xác minh/reset, mở link và đăng nhập sau đổi mật khẩu; nếu không nhận ghi kết quả thật.

**Rubric:** TC-10, TC-13. **Estimate/assignee/sprint:** chưa phân công.

<a id="hm-task-004"></a>

### HM-TASK-004 — Review và chốt SRS/backlog với người dùng, giảng viên

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Draft đã soạn — chờ review nội dung.  
**Liên kết yêu cầu:** NFR-AUD-01.  
**Phụ thuộc:** Review bản SRS/backlog v0.1 này; không đòi triển khai tính năng mới trước.

**Tiêu chí hoàn tất:**

1. Xác nhận tiêu chí bốn báo cáo tính trên app/web hay bắt buộc admin; SMS có bắt buộc hay email đủ.
2. Chốt phạm vi Excel, hai luồng in và ảnh trước khi giao việc triển khai.
3. Điền người duyệt, ngày duyệt và phiên bản; phần chưa đồng ý vẫn giữ Proposed.

**Rubric:** TC-14. **Estimate/assignee/sprint:** chưa phân công.

<a id="hm-task-005"></a>

### HM-TASK-005 — Tạo hoặc cập nhật Jira từ backlog đã duyệt

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Backlog — chưa có issue Jira thật trong lượt này.  
**Liên kết yêu cầu:** NFR-AUD-01.  
**Phụ thuộc:** HM-TASK-004

**Tiêu chí hoàn tất:**

1. Người dùng chỉ định workspace/project hiện có hoặc cho phép tạo mới; kiểm tránh issue trùng.
2. Tạo Epic/Story/Task với mô tả, AC, priority, dependency và mapping ID tài liệu→issue key thật.
3. Không tự bịa assignee, story points, sprint cũ hoặc trạng thái Done; giữ danh sách mapping và link board.

**Rubric:** TC-14. **Estimate/assignee/sprint:** chưa phân công.

<a id="hm-task-006"></a>

### HM-TASK-006 — Đóng gói hồ sơ nghiệm thu và ma trận truy vết

**Loại:** Task · **Ưu tiên:** P0 · **Trạng thái:** Backlog — có nền test/Figma/deploy, thiếu bộ hồ sơ cuối.  
**Liên kết yêu cầu:** NFR-TST-01, NFR-AUD-01.  
**Phụ thuộc:** HM-TASK-001; HM-TASK-002; HM-TASK-003; FR-REP-05 (HM-US-048); FR-PRN-01 (HM-US-049); FR-PRN-02 (HM-US-050); FR-IMG-02 (HM-US-052)

**Tiêu chí hoàn tất:**

1. Mỗi TC trong rubric có màn thao tác, test case, kết quả, ảnh/video hoặc artifact xác minh.
2. Kèm SRS đã duyệt, Figma/prototype, Jira link, URL deploy, APK/checksum và giới hạn.
3. Chạy lại checks đúng phạm vi code thay đổi khi triển khai; log gắn commit, không dùng số test lịch sử làm test của bản mới.

**Rubric:** TC-01, TC-07, TC-08, TC-09, TC-11, TC-12, TC-13, TC-14, TC-15. **Estimate/assignee/sprint:** chưa phân công.

## 5. Thứ tự triển khai đề xuất — chưa phải sprint đã chạy

| Đợt | Nội dung | Điều kiện hoàn tất |
|---|---|---|
| A — Chốt hồ sơ/phạm vi | HM-TASK-004; kiểm Jira hiện có trước HM-TASK-005; chốt 4 báo cáo, SMS, in và ảnh | SRS/AC được review, không còn mơ hồ ảnh hưởng quyền/chi phí |
| B — Báo cáo và in | FR-REP-01..05, FR-PRN-01..02; tận dụng nguồn tổng hợp đã có | Bốn báo cáo có tên/kỳ/nguồn/chi tiết; Pie/Bar và hai print flow kiểm được |
| C — Ảnh nghiệp vụ | FR-IMG-01 rồi FR-IMG-02 | Phương án được duyệt, có upload/quyền/vòng đời/test, không lưu ảnh scan ngầm |
| D — Nghiệm thu cuối | HM-TASK-001..003, HM-TASK-006; rà toàn bộ story CODE | Có đo hiệu năng, UAT app/admin/email, test và minh chứng đúng commit |

Không gán ngày hoặc story points trước khi nhóm ước lượng. Một số chuẩn bị test/benchmark có thể làm độc lập, nhưng không bỏ dependency về dữ liệu/quyền hoặc triển khai nhiều giai đoạn tự động trong một lượt.

## 6. Ma trận truy vết phi chức năng

| NFR | Story hoặc task kiểm chứng |
|---|---|
| NFR-SEC-01 — Phân quyền tại máy chủ | FR-ADM-01, FR-ADM-03, FR-AUTH-05; HM-TASK-003 |
| NFR-SEC-02 — Bí mật và tối thiểu hóa dữ liệu | FR-CHT-02, FR-SCN-01 |
| NFR-DAT-01 — Toàn vẹn và snapshot | FR-NUT-02, FR-ADM-02, FR-PRO-03 |
| NFR-DAT-02 — Ngày, đơn vị và dữ liệu thiếu | FR-RPT-03, FR-NUT-05 |
| NFR-PER-01 — Tốc độ tải có phép đo | FR-RPT-01, FR-ADM-05; HM-TASK-001 |
| NFR-PER-02 — Đọc có giới hạn và xuất đầy đủ | FR-ADM-05, FR-RPT-03, FR-RPT-04; HM-TASK-001 |
| NFR-REL-01 — Mạng lỗi, retry và đổi tài khoản | FR-AUTH-05, FR-ADM-04, FR-UI-02; HM-TASK-002 |
| NFR-USA-01 — Tiếng Việt và giao diện tiếp cận được | FR-UI-01, FR-UI-02; HM-TASK-002 |
| NFR-MNT-01 — Kiến trúc dễ kiểm thử | FR-UI-02 |
| NFR-TST-01 — Bằng chứng kiểm thử có thể chạy lại | FR-UI-02, FR-ADM-06; HM-TASK-006 |
| NFR-OPS-01 — Cấu hình, triển khai và chi phí | FR-ADM-04, FR-IMG-01; HM-TASK-002, HM-TASK-003 |
| NFR-AUD-01 — Truy vết thao tác và thay đổi yêu cầu | FR-ADM-06; HM-TASK-004, HM-TASK-005, HM-TASK-006 |

## 7. Đối chiếu các khoảng trống cô yêu cầu

| Rubric | Trạng thái | Việc cần dùng trong Jira |
|---|---|---|
| TC-01 — Load data nhanh | Có cache/phân trang/giới hạn; chưa có benchmark nghiệm thu | NFR-PER-01, NFR-PER-02; HM-TASK-001 |
| TC-02 — Dashboard tổng quát ≥4 loại dữ liệu | Có mobile dinh dưỡng/nước/vận động/cân nặng; admin có 4 số đếm | FR-RPT-01, FR-ADM-05; HM-TASK-006 |
| TC-03 — Danh mục CRUD, tìm, phân trang, STT, màu trạng thái, lọc loại | Có trên admin; xóa mềm/khôi phục | FR-ADM-02, FR-ADM-05; HM-TASK-003 |
| TC-04 — Xóa phải hỏi | Có các luồng xác nhận; cần UAT các điểm demo | FR-NUT-02, FR-PRO-04, FR-UI-02, FR-ADM-02; HM-TASK-002, HM-TASK-003 |
| TC-05 — Excel chứa tất cả nội dung trên danh sách | XLSX toàn bộ kết quả lọc đã tải đủ, không chỉ trang UI; mobile CSV khác luồng | FR-ADM-05, NFR-PER-02; HM-TASK-003 |
| TC-06 — Người dùng, phân quyền | Có admin/user, server Rules, khóa/mở HealthMate; không có CRUD role trong client | FR-AUTH-01, FR-ADM-01, FR-ADM-03, NFR-SEC-01; HM-TASK-002, HM-TASK-003 |
| TC-07 — Lưu trữ hình ảnh | Có assets/chụp ảnh tạm; chưa có upload/lưu/quản lý ảnh nghiệp vụ | FR-IMG-01, FR-IMG-02; HM-TASK-006 |
| TC-08 — Ít nhất 4 báo cáo | Có nền tổng hợp nhiều nguồn; cần chuẩn hóa R01–R04 và nghiệm thu | FR-REP-01, FR-REP-02, FR-REP-03, FR-REP-04; HM-TASK-006 |
| TC-09 — Pie, Bar, nhấn xem chi tiết | Có Bar/xu hướng/chi tiết ngày; Pie và drill-down đúng phần biểu đồ chưa đủ | FR-REP-05; HM-TASK-006 |
| TC-10 — Gửi mail, OTP SMS, … | Có email verify/reset; SMS chưa có, chưa coi là bắt buộc nếu dấu … là ví dụ | FR-AUTH-03, FR-AUTH-04; HM-TASK-003, HM-TASK-004 |
| TC-11 — Hai chức năng in | Chưa thấy luồng in sản phẩm hoàn chỉnh | FR-PRN-01, FR-PRN-02; HM-TASK-006 |
| TC-12 — Figma | Có link/frame/UI kit và implementation v2 trong repo; không thiếu từ đầu | FR-UI-01, NFR-USA-01; HM-TASK-002, HM-TASK-006 |
| TC-13 — Deploy | Admin có Hosting; Android có APK; tương tác production/máy thật còn chờ | NFR-OPS-01; HM-TASK-002, HM-TASK-003 |
| TC-14 — SRS, Jira | SRS/backlog được soạn lượt này; Jira thật/link/approval chưa tạo | NFR-AUD-01; HM-TASK-004, HM-TASK-005 |
| TC-15 — Unit Test | Có unit/widget/Rules/web/integration; kết quả có trong test-report, không chạy lại lượt tài liệu | NFR-TST-01; HM-TASK-006 |

## 8. Ý tưởng xem xét sau — không nằm trong cam kết hoàn thiện hiện tại

| ID ý tưởng | Nội dung | Nguồn/điều kiện | Trạng thái |
|---|---|---|---|
| HM-IDEA-01 | Duyệt món người dùng đóng góp và báo sai dinh dưỡng | Đề xuất từ trao đổi mở rộng admin; cần thiết kế hàng chờ, nguồn/duyệt và quyền công bố | Discovery, P2 |
| HM-IDEA-02 | Thư viện bài tập/video, sets/reps, lịch và chương trình | Người dùng từng muốn phần luyện tập; hiện mới có activity log và steps; cần chốt nội dung/bản quyền | Discovery, P2 |
| HM-IDEA-03 | Tiếp nhận/xử lý phản hồi, nội dung hướng dẫn và thông báo theo nhóm | Đề xuất mở rộng admin, không phải yêu cầu cô bắt buộc trong rubric đã cung cấp | Discovery, P2 |
| HM-IDEA-04 | Nhiều vai trò biên tập/hỗ trợ hoặc chuyên gia được người dùng cho quyền | Chưa có RBAC UI/consent chuyên gia; không dùng role admin để đọc health riêng | Discovery, P2 |

Không tự tạo issue triển khai/bật dịch vụ trả phí cho các ý tưởng này. Nếu được yêu cầu, cập nhật SRS và AC riêng trước khi giao thực hiện.

## 9. Chuẩn bị nhập Jira

Các field nên dùng khi chuyển từng mục:

| Field Jira | Giá trị từ tài liệu |
|---|---|
| Issue Type | Epic / Story / Task |
| Summary | Tiêu đề hiện có, kèm ID tạm khi cần đối chiếu |
| Description | User Story, FR/NFR, AC, nguồn và giới hạn |
| Priority | Mapping P0/P1/P2 theo scheme của project; không giả định tên priority mặc định |
| Epic | HM-EP-xx; thay bằng key Epic thật sau tạo |
| Labels | healthmate; srs-v0-1; baseline-14bb579; implemented-baseline / partial / proposed |
| Links | blocks/is blocked by theo dependency sau khi có key thật |
| Assignee / Estimate / Sprint | Để trống cho tới khi nhóm quyết định |
| Status | Phản ánh quy trình/bằng chứng thực tế; không đặt Done chỉ từ inventory CODE |

Sau khi người dùng cung cấp project/quyền và yêu cầu đồng bộ, lập bảng `ID tạm → issue key thật → URL`, kiểm chống trùng và giữ lịch sử. **Hiện chưa có board hoặc issue nào được tạo bởi lượt soạn tài liệu này.**

## 10. Quy tắc cập nhật backlog

1. Giữ ID ổn định; yêu cầu thay đổi cần ghi phiên bản/lý do và cập nhật SRS.
2. Baseline code mới cần review story/test/UAT tương ứng; không suy trạng thái từ file name.
3. Không dùng số test pass lịch sử để thay minh chứng của commit khác hoặc dirty tree.
4. Chỉ đóng phần đã được giao và kiểm chứng; phần Proposed/Discovery không tự triển khai.
5. Tham chiếu nguồn chính xác theo SHA. Nếu checkout hiện tại có thay đổi chưa commit, giữ riêng cho tới khi đã review và có baseline mới.

