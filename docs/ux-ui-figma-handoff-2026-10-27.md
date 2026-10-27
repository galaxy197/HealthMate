# HealthMate — Bàn giao dự án và hiện trạng UX/UI để làm Figma

Ngày bàn giao: **27/10/2026** · Ngôn ngữ sản phẩm: **tiếng Việt** · Nền tảng ưu tiên: **Android / Flutter**.

Tài liệu này dành cho người dùng, designer và agent ở chat tiếp theo. Nội dung được tổng hợp từ mã nguồn và tài liệu dự án hiện tại. Phần “hiện trạng” mô tả chức năng đã có trong source; phần “đề xuất” chưa phải giao diện đã triển khai hoặc thiết kế đã được duyệt.

## 1. Yêu cầu hiện tại và điểm bắt đầu cho chat mới

Người dùng muốn chuyển sang chat khác để **làm UX/UI thông qua Figma**. Lượt bàn giao này chỉ xuất tài liệu, không sửa giao diện, không thêm nghiệp vụ, không triển khai dịch vụ và không tự push tiếp.

- Repository: **https://github.com/luuxuantung285600/HealthMate**.
- Branch hiện tại: **main**.
- Commit mã nguồn gần nhất đã push và kiểm tra remote: **56e1b31e8ccc91c5050301f596fdb58d70f0cdda**.
- Commit message: `feat: add 20-question personalization and publish admin/report updates`.
- Working tree sạch khi bắt đầu lượt xuất tài liệu; file bàn giao này được tạo sau commit trên.
- Thư mục dự án trên máy:

```text
C:\Users\LEGION\OneDrive - Ho Chi Minh City University of Foreign Languages and Information Technology - HUFLIT\Documents\ChatGPT\HealthMate 2
```

**Chưa có file/link Figma được tạo và xác minh trong công việc đã ghi nhận.** Các ảnh tham khảo người dùng gửi là nguồn cảm hứng, không phải bản thiết kế HealthMate đã hoàn thiện. Nếu chat mới không có lại ảnh tham khảo, dùng tài liệu này để hiểu nghiệp vụ và xin lại ảnh khi cần đối chiếu hình thức.

Agent tiếp theo cần đọc `AGENTS.md`, tài liệu này và các phần liên quan trong source. `docs/chat-handoff.md` là nhật ký dài theo thời gian: những câu như “chưa push”, “tạm gác admin”, yêu cầu tắt máy ở các thời điểm cũ không mô tả trạng thái mới nhất. Không tự thực hiện lại các yêu cầu lịch sử đó.

## 2. Sản phẩm và những phần đã làm

HealthMate giúp theo dõi dinh dưỡng, thể trạng và thói quen. App không phải công cụ chẩn đoán hoặc điều trị bệnh. Dữ liệu thật được tách theo tài khoản Firebase; không dùng số liệu mẫu để lấp dashboard.

| Nhóm | Khả năng đã có trong mã nguồn | Giới hạn cần hiểu đúng |
|---|---|---|
| Tài khoản | Đăng ký/đăng nhập email và mật khẩu, tiếp tục với Google, xác minh email, gửi email đặt lại mật khẩu, đổi mật khẩu, đăng xuất, xóa tài khoản | Người dùng đã bỏ yêu cầu Facebook; không thêm lại. Email reset do Firebase Auth gửi tới hộp thư của người dùng; việc nhận thư thực tế cần kiểm tra trên tài khoản thật |
| Cá nhân hóa | Onboarding, bộ 20 câu có rẽ nhánh, 5 mục tiêu, đề xuất kcal và macro, xem lại và xác nhận | Không phải thang đo sức khỏe được kiểm định; không tự chẩn đoán hoặc đảm bảo giảm cân |
| Hồ sơ/thể trạng | Chỉnh thông tin, thêm/sửa/xóa cân nặng, lịch sử, BMI tham khảo | Có đủ dữ liệu mới hiển thị chỉ số; không ghi đè lịch sử cũ khi sửa khảo sát |
| Nhật ký dinh dưỡng | Chọn món, khẩu phần, loại bữa, ngày giờ, tính kcal/macro, sửa/xóa bữa | Nhật ký lưu snapshot dinh dưỡng; sửa món gốc không sửa lại lịch sử đã ghi |
| Quét ảnh | Chụp/chọn ảnh, đồng ý gửi AI, nhận diện thành phần/khẩu phần, xem lại trước ghi bữa | Kết quả ước tính; không lấy toàn bộ đĩa cơm sườn thành dinh dưỡng của riêng cơm trắng. Ảnh không mặc định lưu dài hạn |
| Mã vạch | Quét mã, tra thông tin sản phẩm, xem dữ liệu và xác nhận khẩu phần | Không phải mọi mã vạch đều có dữ liệu; dưỡng chất thiếu không được hiển thị như bằng 0 |
| Thư viện món | Món cá nhân, công thức, yêu thích và luồng chọn lại món/bữa đã chuẩn bị | Danh mục dùng chung và thư viện cá nhân khác phạm vi quyền; sửa nguồn không làm đổi bữa cũ |
| Nước/vận động | CRUD nhật ký theo ngày, thêm nhanh nước, ghi hoạt động và thời lượng | Ghi vận động chưa phải hệ thống hướng dẫn bài tập hoàn chỉnh |
| Nhắc bữa/thực đơn | Nhắc local theo lựa chọn; kế hoạch ăn nhiều ngày, chỉnh và xác nhận | Món trong kế hoạch chưa có nghĩa đã ăn; cần ghi nhận riêng |
| Bước chân | Đếm bằng cảm biến Android sau khi bật/cấp quyền, dịch vụ nền và lịch sử | Chưa bật/quyền bị từ chối/thiết bị thiếu cảm biến thì không thể hứa tự đo đầy đủ cả ngày |
| Giấc ngủ | Bấm ngủ/dậy, kiểm tra và sửa giờ, nhập thủ công, lịch sử và tổng hợp | Tự ghi nhận; chưa tự phát hiện ngủ, chưa có giai đoạn ngủ sâu/REM |
| Dưỡng chất | Macro, chất xơ và các trường mở rộng khi nguồn có dữ liệu | Không suy ra đầy đủ vitamin/khoáng chất đáng tin cậy chỉ từ một tấm ảnh |
| Mục tiêu/Quest | Mục tiêu, tiến độ, nhiệm vụ ngày theo quy tắc, hoàn thành/bỏ qua | Không chấm điểm bệnh, không phạt người dùng vì thiếu nhật ký |
| Chat AI | Hỏi tự do, ngữ cảnh lấy từ dữ liệu app, lịch sử theo UID, khôi phục cuộc trò chuyện | Có giới hạn mỗi cuộc và rate limit; miễn phí không có nghĩa không giới hạn |
| Báo cáo | Tổng hợp, biểu đồ, xem chi tiết ngày, tuần/30/90 ngày/theo năm/tùy chọn, xuất CSV trên mobile | Phạm vi xem không phải thời hạn lưu dữ liệu; không tự xóa lịch sử sau 7/30 ngày |
| Web admin | Danh mục, tài khoản/quyền truy cập app, cấu hình, audit, dashboard, Excel | Đã deploy; nghiệm thu đăng nhập/trực quan bằng trình duyệt của người dùng còn chờ |

## 3. Cấu trúc điều hướng đang có — cần giữ rõ khi làm Figma

### 3.1 Thanh dưới hiện tại

```text
┌────────────┬────────────┬──────────┬────────────┬──────────┐
│  Hôm nay   │  Nhật ký   │    +     │  Tiến độ   │   Thêm   │
│ Dashboard  │  Journal   │ Ghi nhanh│  Reports   │ Profile  │
└────────────┴────────────┴──────────┴────────────┴──────────┘
```

Đây là **5 vị trí hiển thị, gồm 4 trang đích và 1 nút hành động “+”**. Không được diễn giải thành 5 tab dữ liệu độc lập.

- **Hôm nay:** tổng quan dữ liệu của ngày đang xem.
- **Nhật ký:** quản lý bữa ăn, nước, vận động của ngày được chọn.
- **“+”:** mở bottom sheet thêm ghi nhận; không chuyển tới một tab riêng.
- **Tiến độ:** báo cáo, biểu đồ và xem theo khoảng thời gian.
- **Thêm:** mở màn `ProfileScreen`, tiêu đề **Không gian cá nhân**, chứa hồ sơ, tài khoản, cài đặt và các lối vào phụ.

Quest và Chat có route/nhánh riêng nhưng **không có nút riêng trên thanh dưới hiện tại**; mở từ Thêm hoặc “+”. Router giữ trạng thái các nhánh bằng `StatefulShellRoute.indexedStack`; Quest/Chat được tính trong nhóm Thêm khi chọn điều hướng. Với màn hình rộng từ 840 logical px, shell dùng `NavigationRail`.

**Hồ sơ chưa chuyển lên avatar góc trên trái.** Đây là mong muốn của người dùng từ trước, chưa phải hiện trạng.

### 3.2 Sơ đồ thông tin hiện tại

```text
Mở app
├─ Chưa đăng nhập → Đăng nhập / Đăng ký / Google / Quên mật khẩu
├─ Chưa xác minh email → Xác minh / Gửi lại / Kiểm tra lại
├─ Chưa hoàn tất hồ sơ → Onboarding + cá nhân hóa → Xem lại → Xác nhận
└─ Đã đủ điều kiện → Shell chính
   ├─ Hôm nay
   │  ├─ Chọn ngày / tuần
   │  ├─ Kcal, macro, bữa ăn, nước, vận động, cân nặng
   │  └─ Mục tiêu và tổng kết
   ├─ Nhật ký
   │  ├─ Chọn ngày
   │  ├─ Bữa sáng / trưa / tối / phụ
   │  ├─ Nước uống
   │  └─ Vận động
   ├─ + → Thêm ghi nhận
   │  ├─ Quét món / Thêm bữa ăn
   │  ├─ Thêm nước / vận động / cân nặng
   │  └─ Mục tiêu, nhiệm vụ / Chat
   ├─ Tiến độ
   │  ├─ Tổng quan / Năng lượng / Dưỡng chất / Macro
   │  ├─ Tuần / 30 ngày / 90 ngày / Theo năm / Tùy chọn
   │  └─ Biểu đồ / Chi tiết từng ngày / Xuất dữ liệu
   └─ Thêm — Không gian cá nhân
      ├─ Thói quen & kế hoạch
      │  └─ Nhắc bữa | Thực đơn | Bước chân | Giấc ngủ | Dưỡng chất | Tiến độ
      ├─ Mục tiêu và nhiệm vụ hằng ngày
      ├─ Trò chuyện cùng HealthMate
      ├─ Tài khoản
      ├─ Cá nhân hóa · 20 câu hỏi
      ├─ Hồ sơ / BMI / Lịch sử cân nặng / Mục tiêu dinh dưỡng
      ├─ Thư viện món của tôi
      ├─ Xuất nhật ký CSV
      └─ Giao diện / Giới thiệu / Quyền riêng tư / Lưu ý sức khỏe
```

Các lối vào AI có thể ẩn/khóa theo cấu hình tính năng, trạng thái tài khoản và bảo trì. Thiết kế cần có trạng thái này.

## 4. Bố cục từng màn hình đang có

### 4.1 Khung dùng chung

Phần lớn trang dùng `FeaturePage`: vùng cuộn dọc, nội dung căn giữa, rộng tối đa 960, padding thông thường 24 và 16 với biến thể gọn. Header thường là icon + chữ HealthMate, tiêu đề và mô tả; cuối nội dung có lưu ý sức khỏe dùng chung. Đây **chưa phải** header avatar + lời chào như ảnh tham khảo của người dùng.

Thành phần chính là card, list tile, choice chip, biểu đồ, form/dialog và bottom sheet. Tôn trọng safe area, bàn phím và chiều cao màn hình; không thiết kế một trang dài mà các nút cuối không cuộn tới được.

### 4.2 Hôm nay — thứ tự từ trên xuống

1. Header, ngày đang xem, lịch/chuyển ngày, dãy ngày trong tuần và lối vào nhật ký.
2. Trạng thái lỗi/tải lại nếu có.
3. Card năng lượng: đã ăn, mục tiêu/ngân sách, phần còn lại; có đường vào đề xuất mục tiêu dinh dưỡng.
4. Card macro: carbohydrate, chất béo, protein.
5. Hướng dẫn bắt đầu nếu chưa có nhật ký.
6. Các card **Sáng / Trưa / Tối / Phụ**, hiển thị món đã ghi, kcal và thao tác thêm.
7. Nhóm **Ghi nhận khác**: nước (có thêm nhanh 250 ml), vận động, số bữa, cân nặng mới nhất.
8. Nhóm mở rộng **Mục tiêu và tổng kết**: mục tiêu dinh dưỡng, các mục tiêu khác và tổng kết tuần.

Không mặc định có ảnh món đẹp cho mọi bữa; nguồn dữ liệu hiện tại không cung cấp đủ ảnh để designer coi đó là trường bắt buộc. Không có số bước/giấc ngủ nổi bật ngay trên trang này trong bố cục hiện tại.

### 4.3 Nhật ký

Thứ tự: **chọn ngày → tổng quan dinh dưỡng → các bữa ăn → nước → vận động → xác nhận độ đầy đủ của nhật ký bữa**. Có nút **Xác nhận đủ bữa** để báo cáo phân biệt ngày ghi đầy đủ với ngày có thể thiếu dữ liệu.

- Thêm/sửa/xóa ghi nhận; xóa phải có xác nhận.
- Thêm từ ngày lịch sử trong Nhật ký phải giữ ngày đó.
- Thêm nhanh từ “+” đặt ngày Nhật ký về **hôm nay**. Đây là khác biệt nghiệp vụ cần giữ hoặc chủ động xin thay đổi, không vô tình đổi khi thiết kế.
- Chưa ghi dữ liệu khác với đã ghi 0 kcal và khác với lỗi tải dữ liệu.

### 4.4 Bottom sheet của nút “+”

Sheet có drag handle, cuộn và safe area; tiêu đề **Thêm ghi nhận**, mô tả cho ngày hôm nay. Thứ tự hiện tại:

1. Quét món, nếu tính năng được bật.
2. Thêm bữa ăn.
3. Thêm nước.
4. Thêm vận động.
5. Thêm cân nặng.
6. Đường phân cách, Mục tiêu và nhiệm vụ.
7. Trò chuyện cùng HealthMate, nếu được bật.

Bước chân/giấc ngủ hiện chưa có lối vào trực tiếp trong sheet này.

### 4.5 Thêm bữa ăn — đã tích hợp nhập tay và quét món

Luồng chính nằm trong `meal_form_dialog.dart`, với ba chế độ **Nhập tay / Ảnh / Yêu thích**. Đây là form/dialog tích hợp, không phải một tab riêng của thanh dưới.

- **Nhập tay:** tìm và chọn món từ catalog/thư viện, chọn loại bữa, thời gian, lượng ăn; xem kcal/macro; xác nhận lưu.
- **Ảnh:** camera/chọn ảnh thư viện, lối vào mã vạch, thông tin quyền riêng tư, đồng ý gửi AI rồi phân tích.
- **Kết quả ảnh:** tên/mô tả món, thành phần có thể xuất hiện, lượng từng phần và dinh dưỡng; người dùng xem/sửa trước khi ghi. Cho lưu món cá nhân khi cần, không tự ghi bữa ngay sau nhận diện.
- **Yêu thích:** chọn lại món đã đánh dấu để giảm thao tác nhập.
- **Mã vạch:** mở màn scanner và bảng chi tiết sản phẩm; trường thiếu phải biểu thị thiếu dữ liệu, không gán 0.
- Các nguồn catalog, sản phẩm mã vạch và AI ước tính phải phân biệt rõ. Không đổi nhãn “ước tính” thành “chính xác” để giao diện ngắn hơn.

Người dùng từng gửi giao diện camera Calz với khung ngắm lớn, nút chụp ở giữa, thư viện góc dưới và lựa chọn chế độ. Source đã có luồng tích hợp; ảnh đó không có nghĩa toàn bộ bố cục Calz đã được sao chép giống hệt hoặc Figma đã có sẵn.

### 4.6 Thư viện món

Lối vào **Thêm → Thư viện món của tôi**, route `/food-library`. Màn có AppBar **Thư viện món**, ghi chú dữ liệu riêng tư và hai chip **Món của tôi / Công thức**. Có tạo/sửa/xóa, chọn đưa vào bữa, phân trang/tải thêm. Yêu thích là chức năng chọn món liên quan, không phải chip thứ ba của màn thư viện này.

### 4.7 Tiến độ — tab dưới

- Các mục hiển thị: **Tổng quan / Năng lượng / Dưỡng chất / Macro**.
- Bộ chọn khoảng: **Tuần / 30 ngày / 90 ngày / Theo năm / Tùy chọn**.
- Có chuyển tuần/ngày, xem biểu đồ và **Chi tiết từng ngày / Mục tiêu**; có nút trở về biểu đồ.
- Chọn năm: năm hiện tại tính từ 1/1 tới hôm nay, năm cũ theo năm lịch; khoảng tùy chọn hoặc số ngày có giới hạn 366 ngày mỗi lần.
- Dữ liệu được đọc theo phạm vi/chia đợt, không tải toàn bộ lịch sử không giới hạn vào một lần mở trang.
- Lối vào **Tiến độ cân nặng và ngân sách ăn** dẫn tới `/wellness?tab=5`.
- Có xuất dữ liệu nhật ký CSV. Xuất Excel XLSX của admin là luồng khác.

**Lưu ý tên trùng:** tab dưới “Tiến độ” là báo cáo tổng thể; chip “Tiến độ” trong Thói quen & kế hoạch thiên về cân nặng/ngân sách ăn. Đây là điểm nên làm rõ hơn trong IA mới.

### 4.8 Thêm — Không gian cá nhân

Thứ tự nội dung chính trong source:

1. Card lối vào Thói quen & kế hoạch, Mục tiêu và nhiệm vụ, Chat.
2. Trạng thái tải/lỗi hồ sơ nếu có.
3. Card tài khoản: email, đổi mật khẩu nếu tài khoản có mật khẩu, đăng xuất, xóa tài khoản.
4. Card **Cá nhân hóa · 20 câu hỏi**, subtitle tóm tắt đặc điểm đã chọn.
5. Card hồ sơ, chỉnh sửa.
6. BMI tham khảo khi đủ chiều cao và cân nặng.
7. Lịch sử cân nặng, thêm/sửa/xóa và biểu đồ.
8. Mục tiêu dinh dưỡng.
9. Thư viện món của tôi.
10. Xuất nhật ký CSV.
11. Giao diện: **Thiết bị / Sáng / Tối**, lưu lựa chọn trên thiết bị.
12. Giới thiệu, Quyền riêng tư, Lưu ý sức khỏe.

Card tài khoản được giữ trước card khảo sát để các thao tác tài khoản không bị đẩy quá sâu. Khi thiết kế lại cần kiểm tra cả màn nhỏ và cỡ chữ lớn.

### 4.9 Thói quen & kế hoạch

Route `/wellness`, AppBar có nút quay lại. Dưới AppBar là **hàng chip cuộn ngang**, không phải sáu tab dưới cùng:

```text
0 Nhắc bữa | 1 Thực đơn | 2 Bước chân | 3 Giấc ngủ | 4 Dưỡng chất | 5 Tiến độ
```

Route `?tab=N` chọn mục mở ban đầu. Vì hàng cuộn ngang, một số người dùng chưa nhìn thấy Bước chân/Giấc ngủ; đây là vấn đề khả năng tìm thấy chức năng, không đồng nghĩa source chưa có.

- **Nhắc bữa:** bật/tắt và chọn giờ nhắc local, giải thích quyền thông báo.
- **Thực đơn:** lập/chỉnh kế hoạch 7 ngày, xem trước gợi ý rồi xác nhận. Tách rõ “đã lên kế hoạch” và “đã ăn”.
- **Bước chân:** nút bật đếm, quyền hoạt động thể chất/thông báo, trạng thái cảm biến/dịch vụ nền, số bước và lịch sử. Android dùng `TYPE_STEP_COUNTER`; không phải GPS. Sau opt-in có thể ghi nền trong điều kiện hệ thống cho phép; không thể hứa ghi trước khi bật hoặc khi bị chặn quyền.
- **Giấc ngủ:** Bắt đầu ngủ, Đã thức dậy/kiểm tra giờ, thêm giờ ngủ thủ công, sửa/xóa lịch sử, tổng hợp 7/30 ngày và nhắc ngủ theo lựa chọn. Không tự đo chất lượng giấc ngủ hoặc giai đoạn REM.
- **Dưỡng chất:** theo dõi các trường có nguồn; phần thiếu và độ phủ dữ liệu cần rõ. Trường mở rộng gồm đường, béo bão hòa, natri, kali, canxi, sắt, vitamin C, cholesterol.
- **Tiến độ:** xu hướng cân nặng và ngân sách ăn. Ước tính năng lượng vận động tách khỏi mục tiêu nền; không tự cộng thêm kcal ăn chỉ vì ghi bước/ngủ.

### 4.10 Mục tiêu, nhiệm vụ và Chat

**Mục tiêu/Quest:** quản lý mục tiêu; nhiệm vụ hằng ngày có trạng thái hoàn thành/bỏ qua; tạo bằng quy tắc có thể giải thích, ID ổn định theo ngày. Không đặt hình phạt hoặc suy luận người dùng không khỏe vì chưa nhập dữ liệu.

**Chat:** đồng ý dùng AI trước khi gửi, lịch sử cuộc trò chuyện, chọn/tạo cuộc mới, vùng tin nhắn, ô soạn và trạng thái trả lời/thử lại. Rời tab và quay lại tải lại đúng cuộc đã chọn; mở lần đầu có thể lấy cuộc gần nhất. Lịch sử riêng theo UID.

- Tối đa **50 lượt hỏi–đáp mỗi cuộc** (100 messages), không phải 50 cuộc/ngày hay AI miễn phí vô hạn.
- Rate binding đang cấu hình 8 API requests/phút/UID và 60/phút theo location; một lượt tự do thường dùng hai requests.
- AI nhận tối đa ba lượt hội thoại gần nhất theo giới hạn app; không gửi toàn bộ lịch sử/hồ sơ.
- Rời tab trong khi AI trả lời sẽ hủy stream/bỏ phần chưa hoàn tất. Không thiết kế giao diện hứa tác vụ tiếp tục ngầm nếu chưa đổi implementation.
- Nút tra cứu nhanh có thể dùng số liệu repository trong app và không gọi AI. Câu hỏi tự do dùng dịch vụ AI sau consent.

### 4.11 Đăng nhập, đăng ký và lần đầu dùng

```text
Chưa có session
 → Đăng nhập email/mật khẩu hoặc Google
 → Hoặc đăng ký, xác nhận mật khẩu
 → Xác minh email khi cần, gửi lại và kiểm tra lại
 → Tải/tạo hồ sơ
 → Onboarding nếu chưa hoàn tất
 → Xem đề xuất mục tiêu, xem lại và xác nhận
 → Hôm nay
```

Quên mật khẩu là luồng gửi email reset đến địa chỉ nhập hợp lệ qua Firebase Auth. Tài khoản đã hoàn tất onboarding đi vào app bình thường; không bắt làm lại 20 câu sau mỗi lần đăng nhập. Người dùng có thể chủ động sửa từ Thêm.

## 5. Bộ 20 câu cá nhân hóa mới nhất

Đã làm, commit và push trong `56e1b31`. Cấu trúc **8 màn ngắn**: thông tin cơ thể → mục tiêu → đích/nhịp/phạm vi đề xuất → hoạt động → ăn uống → ngủ/khó khăn/ưu tiên → đề xuất dinh dưỡng → xem lại/xác nhận. Tên hiển thị là field hành chính ngoài 20 câu.

| # | Nội dung | Vai trò/rẽ nhánh |
|---|---|---|
| 1 | Ngày sinh | Tuổi, kiểm tra phạm vi người trưởng thành |
| 2 | Hệ số nam/nữ dùng cho công thức | Có thể không trả lời; thiếu thì không đoán hệ số |
| 3 | Chiều cao | Tính mục tiêu và BMI tham khảo |
| 4 | Cân nặng hiện tại | Tính mục tiêu và lưu lịch sử số đo |
| 5 | Mục tiêu chính | Giảm cân / duy trì / tăng cân / tăng cơ / cải thiện thói quen |
| 6 | Cân nặng đích | Chỉ hiện cho giảm/tăng cân |
| 7 | Nhịp điều chỉnh nhẹ/vừa | Chỉ hiện cho giảm/tăng cân |
| 8 | Điều kiện nhận đề xuất hay cần hướng dẫn riêng | Không đủ xác nhận thì không tự đề xuất kcal |
| 9 | Hoạt động thường ngày | Hệ số hoạt động, đã tính tập thường lệ |
| 10 | Số ngày tập mỗi tuần | Mô tả thói quen; không cộng tiêu hao lần hai |
| 11 | Thời lượng một buổi | Bỏ qua khi không tập thường xuyên |
| 12 | Loại hình/cường độ tập | Bỏ qua khi không tập thường xuyên |
| 13 | Chế độ ăn | Ăn đa dạng / chay có trứng sữa / thuần chay / khác |
| 14 | Dị ứng hoặc thực phẩm tránh | Ghi chú tự khai, tối đa 200 ký tự |
| 15 | Tần suất rau/trái cây | Đặc điểm thói quen; không tự suy ra gram dưỡng chất |
| 16 | Tần suất đồ uống thêm đường | Đặc điểm thói quen |
| 17 | Giờ ngủ trung bình trong 24 giờ | Tự khai; không tạo nhật ký ngủ, không đổi kcal |
| 18 | Lịch ngủ | Đều / không đều / làm theo ca |
| 19 | Khó khăn chính | Thời gian / chi phí / chọn món / động lực / không có |
| 20 | Ưu tiên | Dinh dưỡng / vận động / ngủ, hướng dẫn hành động đầu tiên |

- Có 20 câu trong bộ; sau rẽ nhánh thường **16–20 câu phù hợp**. Câu bổ sung được để sau, không ép chọn sai để đi tiếp.
- Giá trị chưa trả lời khác với 0 hoặc “không có”.
- Dùng bộ tính cá nhân hóa hiện có, dựa trên Mifflin–St Jeor và lựa chọn người dùng; hiển thị kcal, protein, carb, fat để xem lại.
- Không tự thay mục tiêu cũ nếu chưa xác nhận. Thay mục tiêu có hiệu lực theo ngày, không ghi đè lịch sử.
- “Tăng cơ” dùng mức duy trì làm điểm bắt đầu; chưa tự lập chương trình tập hoặc tính thặng dư chuyên biệt.
- Phân nhóm là mục tiêu + đặc điểm tự khai (hoạt động, ăn uống, ngủ, khó khăn, ưu tiên), không phải chẩn đoán hay một health score.
- Dị ứng/chế độ ăn mới chỉ lưu và xem lại: **chưa có bộ lọc thực đơn tự động bảo đảm an toàn dị ứng**.
- Dữ liệu nằm ở hồ sơ riêng `users/{uid}.personalization`; không gửi cho AI hoặc directory admin.

Nguồn và giới hạn đã ghi ở `docs/personalization-questionnaire.md`: tham khảo [WHO STEPS](https://www.who.int/publications/m/item/standard-steps-instrument), [WHO GPAQ](https://www.who.int/teams/noncommunicable-diseases/surveillance/systems-tools/physical-activity-surveillance), [NIH/NCI DSQ](https://epi.grants.cancer.gov/nhanes/dietscreen/), [CDC về giấc ngủ](https://www.cdc.gov/sleep/data-research/facts-stats/adults-sleep-facts-and-stats.html), [NIDDK](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner). Đây là bộ câu hỏi rút gọn cho sản phẩm, **không phải bản WHO/GPAQ/DSQ đã kiểm định**; không áp điểm chuẩn của các thang đầy đủ vào bộ rút gọn.

## 6. Design system hiện có để dựng lại trong Figma

Các giá trị dưới đây lấy từ hằng số thực tế; một số comment trong file theme còn mô tả bảng màu cũ, nên không dùng comment để xác định mã màu.

| Token | Light | Dark |
|---|---|---|
| Canvas | `#F8FAFC` | `#171824` |
| Surface/card | `#FFFFFF` | `#252832` |
| Primary | `#2459A3` | `#91BAFF` |
| On primary | `#FFFFFF` | `#10233F` |
| Text chính | `#1C1F2E` | `#F8FAFC` |
| Text phụ | `#4A5068` | `#94A3B8` |
| Outline | `#E2E8F0` | `#363A4D` |

- Font bundle: **BeVietnamPro**, hỗ trợ tiếng Việt offline; weight 400/500/600/700.
- Spacing có thang 4/8/12/16/20/24/32/40/48…; card radius thực tế **24**, control/input **16**, pill bo tròn.
- Macro: carb `#06B6D4`, fat `#A855F7`, protein `#F97316`.
- Nhóm chỉ số: nước cyan, bữa ăn cam, vận động emerald `#10B981`, cân nặng tím `#8B5CF6`.
- Typography dựa trên Material 3 và cấu hình `app_theme.dart`; không giả định mọi tiêu đề cùng một size cố định.
- Nội dung rộng tối đa 960; breakpoint rail 840.

Đây là điểm xuất phát để hiểu code, không phải yêu cầu cấm đổi phong cách. Nếu đề xuất đổi màu, font hoặc độ bo, cần có bảng ánh xạ token mới và kiểm tra tương phản/tiếng Việt/light-dark.

## 7. Các mong muốn UX/UI chưa hoàn thành — trọng tâm chat Figma

Người dùng đã nêu:

1. **Chuyển hồ sơ/người dùng lên góc trái trên cùng**, dạng avatar/lối vào hồ sơ.
2. Xem lại các mục ở **thanh dưới**, có tính đến phần bài tập luyện.
3. Đưa giao diện thêm bữa ăn thủ công và quét món về một luồng thống nhất; source đã có phần tích hợp nhưng cần hoàn thiện trải nghiệm/visual.
4. Thích bố cục thoáng, card dinh dưỡng/bữa ăn rõ như ảnh tham khảo; thích cách camera quét món dễ thao tác.
5. Muốn nhìn thấy **đi bộ và giấc ngủ** dễ hơn.

**Chưa chốt thứ tự/nội dung 5 mục dưới cùng sau khi chuyển hồ sơ lên avatar.** Designer cần phân biệt lựa chọn “5 tab thật” và “4 tab + nút thêm ở giữa”. Không tự ghi rằng người dùng đã duyệt một phương án cụ thể.

### Định hướng để nghiên cứu trong Figma, chưa được phê duyệt

- Thử IA gom các thao tác hằng ngày và giảm việc phải vào Thêm rồi vuốt chip để tìm bước/ngủ.
- Header avatar + lời chào + ngày, nhưng không tự thêm trường ảnh đại diện bắt buộc hoặc hứa đã có upload ảnh.
- Thể hiện kcal/macro gọn, hành động kế tiếp rõ, bữa ăn có trạng thái, bước/ngủ có đường vào dễ thấy.
- Tránh hai khu vực cùng tên “Tiến độ” nhưng mục đích khác nhau.
- Dành luồng cho bài tập, nhưng gắn nhãn **đề xuất/chưa triển khai** đối với chương trình tập, video, sets/reps, timer, lịch luyện tập hoặc coaching.

**Phần luyện tập hiện tại:** có ghi vận động, thời lượng, theo dõi bước và lựa chọn thói quen tập. Chưa có hệ thống chương trình tập hoàn chỉnh để designer coi là chức năng đang hoạt động. Nếu muốn triển khai nghiệp vụ tập mới, đó là phạm vi tiếp theo cần yêu cầu riêng.

## 8. Checklist bàn giao thiết kế Figma

Đề xuất cấu trúc pages trong Figma:

| Page | Nội dung |
|---|---|
| 00 — Brief & IA | Mục tiêu, inventory hiện có, sitemap, user flows, điểm chưa chốt |
| 01 — Foundations | Màu, typography tiếng Việt, spacing, radius, icon, light/dark |
| 02 — Components | Header/avatar, navigation, nút thêm, cards, chip, input, dialog/sheet, chart, feedback |
| 03 — Auth & Onboarding | Login/register/reset/verify và 8 màn của bộ 20 câu, xem lại |
| 04 — Today & Diary | Dashboard, chọn ngày, nhật ký, CRUD và trạng thái trống |
| 05 — Add Meal & Scanner | Nhập tay/ảnh/yêu thích, camera, barcode, kết quả/thành phần/khẩu phần/lưu món |
| 06 — Habits & Activity | Nhắc bữa, thực đơn, bước chân, giấc ngủ; tách ý tưởng workout tương lai |
| 07 — Reports & Goals | Khoảng ngày/năm/tùy chọn, chart/detail, mục tiêu/quest |
| 08 — Chat & Personal | Chat/history/consent, hồ sơ, thư viện, tài khoản, cài đặt |
| 09 — Prototype & Handoff | Luồng tương tác, trạng thái, responsive, component specs và ánh xạ Flutter |

Đây chỉ là cách tổ chức file đề xuất. Không cần dựng web admin trong cùng phạm vi nếu người dùng chỉ yêu cầu UX/UI mobile.

Mỗi luồng quan trọng cần có:

- Loading, empty, lỗi và thử lại; phân biệt dữ liệu chưa nhập với mạng lỗi.
- Keyboard, focus, validation, disabled/busy, hủy và quay lại không mất ngữ cảnh ngoài ý muốn.
- Xác nhận trước xóa, lưu bữa, thay mục tiêu hoặc ghi dữ liệu ảnh.
- Quyền camera/ảnh/hoạt động/thông báo: chưa hỏi, từ chối, cần mở cài đặt, thiết bị không hỗ trợ.
- AI consent, đang phân tích, timeout/quota, không nhận diện được, thiếu thành phần và sửa kết quả.
- Chưa xác minh email, cần đăng nhập lại, tài khoản bị khóa quyền app/bảo trì.
- Trạng thái có/không có mục tiêu, dữ liệu thiếu dưỡng chất, chưa xác nhận nhật ký đầy đủ.
- Riêng sleep: đang ngủ, đã thức nhưng chưa xác nhận giờ, nhập thủ công, lịch sử trống.
- Riêng step: chưa bật, đang đếm, quyền bị thu hồi, không có cảm biến.

Thiết kế Android ở 360/390/412 logical px, kiểm tra mép 320, chữ 150–200%, light/dark, safe area, bàn phím. Đề xuất vùng bấm tối thiểu 48 logical px. Chuỗi tiếng Việt dài cần wrap thay vì chỉ cắt mất thông tin quan trọng; có màn xem lại đầy đủ.

Trình tự hợp lý: **inventory → sitemap/luồng → phương án điều hướng → wireframe → chốt với người dùng → high fidelity/components → prototype → handoff**. Không tự chuyển từ thiết kế sang sửa Flutter/deploy nếu chưa được yêu cầu.

## 9. Kiến trúc và bảng ánh xạ màn hình sang code

Kiến trúc feature-first, Riverpod, Repository Pattern; router `go_router`. Flutter mobile hiện tại không phải React website. Figma cần bàn giao được cho Flutter, tránh tạo UI đòi kiến trúc web mới chỉ để tái hiện hình thức.

| Khu vực | File/thư mục chính, tính từ root repo |
|---|---|
| App shell, thanh dưới, nút + | `lib/core/widgets/app_shell.dart` |
| Routes/redirect | `lib/core/router/app_routes.dart`, `app_router.dart`, `auth_redirect.dart` |
| Khung trang dùng chung | `lib/core/widgets/feature_page.dart` |
| Theme/tokens | `lib/core/theme/app_theme.dart`, `app_colors.dart`, `design_tokens.dart`, `app_spacing.dart` |
| Hôm nay | `lib/features/dashboard/presentation/dashboard_screen.dart` |
| Cards kcal/macro/bữa | `lib/features/dashboard/presentation/widgets/mfp_calories_card.dart`, `mfp_macros_card.dart`, `mfp_meal_card.dart` |
| Nhật ký | `lib/features/journal/presentation/journal_screen.dart` |
| Thêm bữa tích hợp | `lib/features/nutrition/presentation/meal_form_dialog.dart` |
| Camera/kết quả ảnh | `lib/features/food_scanner/presentation/food_camera_view.dart`, `food_scanner_dialog.dart` |
| Barcode | `lib/features/food_scanner/presentation/barcode_scanner_screen.dart`, `barcode_product_detail_sheet.dart` |
| Thư viện món | `lib/features/food_library/presentation/food_library_screen.dart` |
| Báo cáo | `lib/features/progress/presentation/progress_screen.dart` |
| Thêm/Hồ sơ | `lib/features/profile/presentation/profile_screen.dart` |
| Onboarding/20 câu | `lib/features/profile/presentation/onboarding_screen.dart`, `personalization_questions.dart` |
| Model khảo sát | `lib/features/profile/models/personalization_answers.dart` |
| Đề xuất dinh dưỡng | `lib/features/nutrition_targets/presentation/personal_nutrition_planner.dart` |
| Thói quen & kế hoạch | `lib/features/wellness/presentation/wellness_screen.dart` và các panel cùng feature |
| Quest | `lib/features/daily_quest/presentation/quest_screen.dart` |
| Chat | `lib/features/chatbot/presentation/chat_screen.dart`, `chat-api/` |
| Auth | `lib/features/auth/` |
| Rules/database | `firestore.rules`, `docs/database-design.md` |
| Admin riêng | `admin-web/dist/`, `admin-web/test/`, `admin-web/tool/` |

Các route hiện có: `/dashboard`, `/journal`, `/quest`, `/chat`, `/progress`, `/profile`, `/wellness`, `/food-library`, `/personalization`, `/onboarding`, `/auth`, `/verify-email`, `/session`, `/about`, `/privacy`, `/disclaimer`.

## 10. Công nghệ/API thực tế và ràng buộc cần giữ

- **Flutter/Dart**, Android ưu tiên; Riverpod, go_router, fl_chart, font bundle.
- **Firebase Authentication**, **Cloud Firestore** là database chính, Security Rules và App Check.
- **Quét ảnh:** Firebase AI Logic qua `firebase_ai`, Gemini. `FoodScannerConfig` nằm trong `firebase_food_scanner_service.dart`; default source đang là `gemini-3.5-flash-lite`, có thể override bằng build define. Đây là giá trị source tại bàn giao, không phải cam kết model còn hỗ trợ mãi; kiểm tra tài liệu hiện hành trước khi đổi API/model.
- **Barcode:** `mobile_scanner`; tra sản phẩm qua **Open Food Facts** trong `barcode_product_service.dart`.
- **Chat thực tế:** **Cloudflare Workers + Workers AI**, xác thực gắn Firebase ID token/App Check. Không nhầm với Gemini của scanner. Lựa chọn này đã được người dùng cho làm ở các công việc trước; không tự thay lại kiến trúc vì AGENTS ban đầu ghi chatbot Gemini.
- Bước chân dùng bridge Android/cảm biến và foreground service; sleep là nhập/bấm ngủ dậy; reminder dùng local notification.
- Catalog/cache cục bộ hỗ trợ trải nghiệm; Firestore giữ dữ liệu người dùng và nghiệp vụ đồng bộ. Không thêm database cloud thứ hai.
- Không đưa secret, service account, App Check debug token vào Figma/chat/source. Không gửi toàn bộ hồ sơ sức khỏe cho AI.
- Không mặc định lưu ảnh món gốc dài hạn. Chưa có luồng upload ảnh/Storage hoàn chỉnh để designer coi là dịch vụ sẵn có.
- Không hứa chi phí AI miễn phí vô hạn; không nâng billing hoặc thêm backend trả phí khi chỉ làm UX/UI.

## 11. Web admin đã hoàn thiện tới đâu

URL: **https://healthmate-app-20261013.web.app**. Tài khoản admin đầu tiên được người dùng chỉ định: **luuxuantung285600@gmail.com**, đăng nhập Google. Không có mật khẩu/credential trong tài liệu này.

- Source web: JavaScript ES modules/CSS và Firebase Web SDK; tách khỏi app Flutter.
- Có dashboard ít nhất bốn số liệu, catalog CRUD/ẩn-khôi phục, tìm/lọc, trạng thái, số thứ tự/phân trang, Excel XLSX theo toàn bộ kết quả lọc, kiểm soát xung đột và audit.
- Tài khoản: directory người dùng app, khóa/mở quyền truy cập HealthMate bằng Firestore; **không phải disable tài khoản Firebase Auth**.
- Cấu hình app: scanner/chat và bảo trì; app cần build có `HEALTHMATE_ENABLE_ADMIN_CONTROLS=true` để nhận các kiểm soát runtime tương ứng.
- Admin không được quyền đọc hồ sơ sức khỏe, nội dung chat và khảo sát cá nhân chỉ vì có role admin.
- Directory không tự liệt kê toàn bộ Firebase Auth; phụ thuộc luồng app đồng bộ được bật.
- App Check web đã cấu hình; role/Rules/Hosting đã deploy. Người dùng chọn **thử trình duyệt sau**, nên không coi nghiệm thu tương tác production đã hoàn tất.
- `admin-web/dist/config.js` đang dành cho Emulator local; gói production được chuẩn bị riêng trong `build/`. Không lấy local config ghi đè web đang chạy.

Các yêu cầu môn học như đủ bốn loại báo cáo theo tiêu chí cô, pie/bar có drill-down, hai luồng in, Figma/SRS/Jira phải nghiệm thu riêng. Không tuyên bố toàn bộ checklist môn học hoàn tất chỉ vì admin đã deploy.

## 12. Kiểm thử, deploy và bản cài gần nhất

Các kết quả sau thuộc công việc triển khai gần nhất đã được ghi nhận trong repo, **không phải chạy lại toàn bộ trong lượt xuất Markdown**:

| Kiểm tra | Kết quả |
|---|---|
| Format phần thay đổi | Không còn lệch format |
| `flutter analyze --no-pub` cuối | 0 issues |
| Flutter test toàn bộ | 646/646 qua |
| Sau sửa cuối phần nhãn/subtitle khảo sát | Analyze 0 issues; 7/7 test khảo sát qua |
| Hồi quy Auth/account/widget/khảo sát | 39/39 qua |
| Firestore Rules Emulator | 77/77 qua, có owner/UID chéo/anonymous/admin và validation khảo sát |
| Web admin | 20/20 qua |
| Admin SDK adapter trên Emulator | 4/4 qua |
| Android debug build | Thành công, 30,1 giây |

Đã xem ảnh render font thật 360×800, chữ 150% của khảo sát; không overflow. Một số lựa chọn dài dùng dấu “…”, nội dung đầy đủ có ở xem lại. **Không thay thế nghiệm thu trên điện thoại.** Build còn warning Kotlin plugin cũ; Rules có warning helper unused đã ghi nhận.

Rules production mới nhất đã deploy riêng `firestore:rules` và readback khớp source; không đồng thời thay Hosting/indexes/billing. Ruleset: `04f3777e-84c5-42a2-b242-56c1640a0bbe`. AI App Check enforcement giữ nguyên; không tự bật enforcement Firestore/Auth cho toàn bộ app cũ trong lượt đó.

APK debug mới nhất:

```text
build/releases/healthmate-questionnaire-20-debug.apk
236777378 bytes
SHA256: 3afab0533edc044304ec1105a5b09d02e8c1063273ec332a3d02a1b32f20e984
```

**Chưa cài/nghiệm thu APK khảo sát 20 câu mới nhất trên điện thoại.** Không suy ra app đang cài đã là commit mới nhất. Đây là bản debug với cấu hình debug cục bộ, không public APK/debug token. Cài cập nhật thì giữ dữ liệu, không gỡ/xóa app để thử cho tiện.

## 13. Những điểm còn lại cần bảo toàn hoặc nghiệm thu

1. Thử luồng 20 câu trên điện thoại: người mới/người cũ, bỏ câu, quay lại, hủy, thay mục tiêu và cân nặng.
2. Thử admin production bằng Google đúng email; người dùng đã chọn làm sau.
3. Đưa bước/ngủ ra vị trí dễ tìm trong thiết kế; không hứa tính năng tự đo giấc ngủ chưa tồn tại.
4. Lên UX bài tập tương lai tách khỏi vận động đang có; chưa tự xây chương trình tập.
5. Không tự nối câu dị ứng sang bộ lọc “an toàn tuyệt đối”; chưa có implementation và dữ liệu để bảo đảm.
6. Giữ review khẩu phần/thành phần sau scanner, nguồn dinh dưỡng và các nhãn ước tính/thiếu dữ liệu.
7. Giữ ngày đang xem, lịch sử snapshot, dữ liệu tách UID, xác nhận xóa và xác nhận ghi/thay mục tiêu.
8. Bảo toàn thay đổi chưa commit nếu chat mới phát hiện; không reset/clean để đồng bộ GitHub.
9. Không triển khai lại/push/transfer repository hoặc tắt laptop từ các câu lịch sử. Chỉ làm phạm vi mới được yêu cầu.

## 14. Tài liệu đọc tiếp và lệnh mở chat mới

Các file trong repo chứa chi tiết:

- `AGENTS.md`: nguyên tắc và phạm vi từng giai đoạn.
- `docs/chat-handoff.md`: nhật ký bàn giao theo thời gian, đọc ưu tiên mục mới nhất.
- `docs/implementation-progress.md`, `docs/test-report.md`: tiến độ và kiểm thử thật.
- `docs/database-design.md`: dữ liệu/quyền truy cập.
- `docs/personalization-questionnaire.md`, `docs/personalized-nutrition.md`: khảo sát và mục tiêu.
- `docs/unified-meal-entry.md`, `docs/scanner-update.md`: nhập bữa/quét món.
- `docs/wellness-expansion.md`, `docs/wellness-insights.md`, `docs/wellness-rollout.md`: nhắc bữa, thực đơn, bước/ngủ và giới hạn.
- `docs/year-and-custom-reports.md`: báo cáo năm/tùy chọn.
- `docs/chatbot-capacity-update.md`, `docs/chatbot-live-qa.md`: lịch sử chat, 50 lượt và nghiệm thu trước đây.
- `docs/admin-completion.md`, `docs/admin-production.md`: admin và production.
- `docs/ui-navigation-proposal.md`, `docs/mfp-ui-redesign.md`, `docs/compact-ui.md`: các phương án UI trước; đối chiếu source để biết phần nào thực sự đang chạy.

Có thể đính kèm file này và dùng lời nhắn sau cho chat mới:

> Tiếp tục dự án HealthMate từ file bàn giao này. Đọc toàn bộ AGENTS.md, file bàn giao và kiểm tra git status/diff trước. Tôi muốn làm một giai đoạn thiết kế UX/UI mobile bằng Figma; chưa sửa code, chưa push/deploy. Xác minh source và phân biệt giao diện đang có với đề xuất. Ưu tiên avatar/hồ sơ góc trên trái, chốt lại thanh điều hướng dưới, làm bước chân/giấc ngủ dễ tìm, thống nhất thêm bữa/quét món và xem xét khu vực bài tập. Giữ bộ 20 câu cá nhân hóa và nghiệp vụ đang hoạt động. Trước hết lập sitemap, user flows và wireframe để tôi duyệt, sau đó mới làm high fidelity/prototype. Kiểm tra khả năng truy cập file Figma thật; không tuyên bố đã tạo Figma nếu chỉ có ảnh hoặc code mô phỏng. Bảo toàn dữ liệu/thay đổi hiện có, không thêm dịch vụ trả phí hoặc tự thực hiện yêu cầu lịch sử ngoài phạm vi.
