# AGENTS.md — HealthMate

> **Vai trò của file:** Hướng dẫn làm việc cho Codex trong repository HealthMate. Đặt file này tại thư mục gốc của dự án Flutter. Codex có thể tự đọc `AGENTS.md` khi bắt đầu phiên làm việc trong repository.
>
> **Quy tắc quan trọng nhất:** Phát triển theo từng giai đoạn. Mỗi lần chỉ làm đúng giai đoạn được người dùng yêu cầu; hoàn thành, kiểm thử, báo cáo rồi dừng. Không tự động chuyển sang giai đoạn kế tiếp.

---

## 1. Bối cảnh và mục tiêu sản phẩm

**Tên:** HealthMate  
**Mô tả:** Ứng dụng di động giúp người dùng theo dõi dinh dưỡng, thể trạng và hình thành thói quen lành mạnh. Ứng dụng không phải công cụ chẩn đoán hoặc điều trị bệnh.

### Trải nghiệm khác biệt

1. **AI Food Scanner:** người dùng chụp/chọn ảnh món ăn, AI đề xuất món có khả năng xuất hiện; người dùng kiểm tra và xác nhận món/khẩu phần trước khi lưu nhật ký.
2. **Daily Health Quest:** gợi ý nhiệm vụ nhỏ trong ngày từ mục tiêu và dữ liệu đã ghi nhận; bắt đầu bằng quy tắc nghiệp vụ dễ giải thích, không cần AI để quyết định nhiệm vụ.
3. **Health Dashboard & Weekly Reflection:** tổng hợp dữ liệu thật và trình bày xu hướng theo ngày/tuần.
4. **AI Health Chatbot:** trả lời câu hỏi về thói quen và dữ liệu HealthMate khi phù hợp; phải lấy dữ liệu từ repository và không được tự bịa số liệu.

### Công nghệ đã chốt cho MVP

- Flutter + Dart, Android là nền tảng triển khai đầu tiên.
- Firebase Authentication: xác thực người dùng.
- Cloud Firestore: **database duy nhất** của MVP.
- Firebase AI Logic (`firebase_ai`) + Gemini: chatbot và phân tích ảnh, sau khi cấu hình provider/model được hỗ trợ.
- Riverpod: state management và dependency injection.
- `go_router`: điều hướng.
- `fl_chart`: biểu đồ khi cần.
- `image_picker` hoặc giải pháp camera phù hợp: chọn/chụp ảnh món ăn.
- Git/GitHub: quản lý mã nguồn.

Không thêm Supabase, PostgreSQL, BigQuery, backend riêng hoặc dịch vụ trả phí trong MVP trừ khi người dùng chủ động thay đổi quyết định. Ưu tiên gói miễn phí, nhưng không hứa mọi dịch vụ AI sẽ miễn phí vô hạn. Không thêm thư viện khi chưa cần; kiểm tra tương thích trước khi dùng.

---

## 2. Quy tắc làm việc bắt buộc

### 2.1 Trước khi sửa code

1. Đọc file này và kiểm tra repository hiện tại: `pubspec.yaml`, thư mục `lib/`, `test/`, cấu hình Android, các package đã cài và những phần đang hoạt động.
2. Không giả định dự án còn trống. Không tạo lại dự án, không ghi đè file, không xóa chức năng hiện có trước khi hiểu cấu trúc.
3. Xác định **giai đoạn đang được yêu cầu**. Chỉ thực hiện giai đoạn đó.
4. Đưa ra kế hoạch ngắn trước khi thay đổi nếu công việc có nhiều bước.
5. Nếu thiếu Firebase project/configuration hoặc cần thao tác trong Firebase Console mà agent không có quyền làm, hãy chỉ rõ người dùng cần thực hiện bước nào. Không giả vờ đã kết nối Firebase.

### 2.2 Giới hạn phạm vi

- Mỗi lượt chỉ được hoàn thành **một giai đoạn** trong mục 7.
- Không tự triển khai các giai đoạn kế tiếp, kể cả khi thấy thuận tiện.
- Không thêm tính năng ngoài phạm vi giai đoạn đang làm.
- Không refactor diện rộng chỉ để “làm sạch code” nếu không cần cho giai đoạn đó.
- Nếu phát hiện vấn đề ngoài phạm vi, ghi vào báo cáo; chỉ sửa ngay nếu nó chặn trực tiếp công việc hiện tại và sửa có rủi ro thấp.
- Nếu một quyết định có thể phá dữ liệu, thay đổi kiến trúc, phát sinh chi phí hoặc làm thay đổi luồng nghiệp vụ, hãy dừng và hỏi người dùng trước.

### 2.3 Chất lượng code

- Tổ chức theo feature, tách UI, model, repository và service.
- Widget không trực tiếp chứa truy vấn Firestore dài hoặc logic nghiệp vụ phức tạp.
- Dùng tên class/field bằng tiếng Anh theo `lowerCamelCase`/`UpperCamelCase`; nội dung giao diện ưu tiên tiếng Việt tự nhiên.
- Dùng kiểu dữ liệu rõ ràng, null safety, xử lý lỗi và validation.
- Không tạo nút giả, dữ liệu giả trong luồng sản phẩm thật, hoặc chức năng chỉ đổi giao diện mà không thực hiện hành động.
- Không tự tuyên bố test/build thành công nếu chưa chạy lệnh tương ứng.
- Không cài hàng loạt package ngay từ đầu. Thêm dependency đúng lúc cần và giải thích ngắn gọn lý do.
- Không nâng cấp toàn bộ dependencies một cách tùy tiện.

### 2.4 Firebase và an toàn dữ liệu

- Chỉ dùng Firebase làm backend/database chính trong MVP.
- Không đặt Firebase Admin SDK credential, service-account JSON, Gemini API key riêng hoặc secret vào ứng dụng Flutter/repository.
- Dùng Firebase Authentication và Firestore Security Rules; không dựa vào ẩn màn hình để bảo vệ dữ liệu.
- Mọi dữ liệu sức khỏe riêng tư phải nằm dưới đường dẫn gắn với UID hoặc có quy tắc quyền truy cập tương đương.
- Người dùng A không được đọc/sửa dữ liệu của người dùng B bằng cách thay ID.
- Dùng Firebase App Check cho các dịch vụ phù hợp, đặc biệt khi tích hợp AI; cấu hình theo hướng dẫn hiện hành và môi trường debug/production phù hợp.
- Không lưu ảnh món ăn gốc mặc định. Chỉ lưu ảnh nếu sản phẩm thật sự cần, đã có lý do và đã thiết kế quyền riêng tư.
- Không gửi toàn bộ hồ sơ sức khỏe cho AI. Chỉ cung cấp phần dữ liệu tối thiểu có liên quan đến câu hỏi.
- Không cho AI tự do truy cập Firestore, tự tạo truy vấn không kiểm soát hoặc tự ghi/xóa hồ sơ. Các thao tác ghi phải qua nghiệp vụ ứng dụng và cần xác nhận người dùng khi phù hợp.
- Không dùng AI để chẩn đoán bệnh, kê thuốc hoặc thay thế chuyên gia y tế.

### 2.5 Quy trình kiểm tra cuối mỗi giai đoạn

Thực hiện những lệnh phù hợp với cấu trúc repository, ít nhất xem xét:

```bash
dart format .
flutter analyze
flutter test
```

Chỉ chạy lệnh trong môi trường dự án Flutter hợp lệ. Nếu một lệnh không chạy được do thiếu SDK, Firebase config, emulator, network hoặc credential, hãy nêu lỗi thật và bước người dùng cần làm. Không sửa test để che giấu lỗi.

Sau mỗi giai đoạn, cập nhật `docs/implementation-progress.md` nếu có thể, gồm:
- Giai đoạn hiện tại và trạng thái.
- Các file chính đã tạo/sửa.
- Lệnh kiểm tra đã chạy và kết quả thực tế.
- Việc người dùng cần cấu hình thủ công.
- Rủi ro hoặc lỗi còn tồn tại.
- Giai đoạn tiếp theo được đề xuất, **nhưng không tự thực hiện**.

---

## 3. Kiến trúc ứng dụng đề xuất

Dùng kiến trúc **feature-first + Repository Pattern**, không cần over-engineer.

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   ├── router/
│   ├── theme/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── models/
│   │   └── presentation/
│   ├── profile/
│   ├── dashboard/
│   ├── body_metrics/
│   ├── nutrition/
│   ├── food_scanner/
│   ├── water/
│   ├── activity/
│   ├── goals/
│   ├── daily_quest/
│   ├── chatbot/
│   └── weekly_reflection/
├── shared/
│   ├── models/
│   └── providers/
test/
├── docs/
└── ...
```

Cấu trúc có thể điều chỉnh để phù hợp code hiện có. Trong từng feature, tạo các lớp khi cần, ví dụ `models/`, `data/`, `repositories/`, `presentation/`, `providers/` hoặc `view_models/`. Không tạo file rỗng chỉ để khớp sơ đồ.

### Quy ước kiến trúc

- **Presentation:** Screen, Widget, state/view model hoặc Riverpod Notifier.
- **Repository:** giao diện dữ liệu cho feature; xử lý CRUD và chuyển đổi model.
- **Service:** kết nối SDK bên ngoài, ví dụ Firebase Auth, Firestore hoặc Firebase AI Logic.
- **Model:** dữ liệu nghiệp vụ thuần, có chuyển đổi Firestore khi cần.
- **Core:** theme, router, lỗi dùng chung, tiện ích và widget dùng chung.

Không để các Screen gọi Firestore trực tiếp ở khắp nơi. Giữ logic nghiệp vụ độc lập tương đối với SDK để dễ test và chỉnh sửa về sau.

---

## 4. Thiết kế dữ liệu Firestore sơ bộ

Đây là điểm xuất phát. Trước khi tạo collection thật, hãy rà soát yêu cầu và tinh chỉnh nếu cần; mọi thay đổi phải được ghi trong `docs/database-design.md`.

```text
users/{uid}
  - displayName
  - email (chỉ nếu cần hiển thị)
  - heightCm (nullable)
  - birthDate (optional; chỉ thu thập nếu thực sự cần)
  - createdAt
  - updatedAt
  - schemaVersion

users/{uid}/body_metrics/{metricId}
  - weightKg
  - measuredAt
  - note (optional)
  - createdAt

users/{uid}/meal_logs/{mealId}
  - mealType: breakfast | lunch | dinner | snack
  - consumedAt
  - items: danh sách món có giới hạn, mỗi món là snapshot
  - totalKcal
  - totalProteinG
  - totalCarbsG
  - totalFatG
  - source: manual | ai_assisted
  - createdAt
  - updatedAt
  - schemaVersion

users/{uid}/water_logs/{logId}
  - amountMl
  - consumedAt
  - createdAt

users/{uid}/activity_logs/{activityId}
  - activityType
  - durationMinutes
  - performedAt
  - note (optional)
  - createdAt

users/{uid}/goals/{goalId}
  - goalType
  - targetValue
  - unit
  - startDate
  - endDate (optional)
  - status
  - createdAt
  - updatedAt

users/{uid}/daily_quests/{yyyy-MM-dd}
  - dateKey
  - title
  - description
  - questType
  - targetValue (if applicable)
  - unit (if applicable)
  - status: available | completed | skipped
  - createdAt
  - completedAt (optional)
  - ruleVersion

users/{uid}/chat_sessions/{sessionId}
  - title
  - createdAt
  - updatedAt
  - schemaVersion

users/{uid}/chat_sessions/{sessionId}/messages/{messageId}
  - role: user | assistant
  - text
  - createdAt
  - status (optional)

food_catalog/{foodId}
  - name
  - alternateNames (optional)
  - category
  - servingBasis: per_100g or explicit serving
  - kcalPer100g
  - proteinGPer100g
  - carbsGPer100g
  - fatGPer100g
  - sourceLabel
  - isEstimated
  - updatedAt
```

### Quy tắc dữ liệu

- `users/{uid}` là hồ sơ; không lưu mật khẩu vào Firestore.
- Nhật ký phải có timestamp nhất quán. Dùng timestamp phía server nếu phù hợp; lưu `dateKey` theo múi giờ người dùng khi cần thống kê theo ngày.
- Chuẩn hóa tên field và đơn vị đo: cân nặng kg, chiều cao cm, nước ml, thời lượng phút, dinh dưỡng g/kcal.
- Lưu snapshot thông tin dinh dưỡng trong nhật ký đã xác nhận để sửa danh mục thực phẩm sau này không làm thay đổi lịch sử cũ.
- Tránh document/array tăng không giới hạn. Danh sách món trong một bữa nên có giới hạn thực tế; nếu nhu cầu thay đổi, tách `meal_items` thành subcollection.
- Không coi tổng kcal do mô hình AI tự đưa ra là dữ liệu chuẩn. Ưu tiên tính từ danh mục có nguồn và khẩu phần do người dùng xác nhận; nếu chỉ có giá trị tham khảo, gắn nhãn ước tính.
- Không giả vờ dữ liệu minh họa là dữ liệu chính xác. Dữ liệu seed phải được đánh dấu rõ là dữ liệu mẫu/ước tính và ghi nguồn khi có nguồn.
- Mọi thao tác cần kiểm tra giá trị hợp lệ và quyền sở hữu.

### Quy tắc Security Rules

- Mặc định từ chối truy cập nếu chưa có quy tắc cho phép.
- Với đường dẫn `users/{uid}/...`, yêu cầu `request.auth != null` và `request.auth.uid == uid`.
- Hồ sơ chỉ được đọc/cập nhật bởi chủ tài khoản; chỉ cho phép các field hợp lệ được thay đổi.
- `food_catalog` có thể cho phép người dùng đã đăng nhập đọc; không cho client bất kỳ ghi vào catalog. Dữ liệu catalog chỉ được cập nhật qua quy trình quản trị/seed có kiểm soát.
- Dữ liệu hội thoại, nhật ký và mục tiêu phải riêng tư theo UID.
- Viết test rules với ít nhất hai tài khoản giả lập để kiểm tra chặn truy cập chéo. Không tuyên bố an toàn nếu chỉ nhìn rule mà chưa test.

---

## 5. Phạm vi MVP

### Trong MVP

1. Đăng ký/đăng nhập/đăng xuất và xử lý session.
2. Hồ sơ cá nhân và thiết lập cơ bản.
3. Lịch sử cân nặng và BMI tham khảo khi có dữ liệu phù hợp.
4. Danh mục thực phẩm và nhật ký bữa ăn nhập thủ công.
5. AI Food Scanner có bước người dùng xác nhận trước khi lưu.
6. Nhật ký nước uống.
7. Nhật ký vận động do người dùng nhập.
8. Mục tiêu sức khỏe do người dùng thiết lập.
9. Dashboard lấy số liệu thật.
10. Daily Health Quest chạy bằng quy tắc đơn giản và có thể kiểm thử.
11. Chatbot dùng Firebase AI Logic/Gemini, chỉ nhận ngữ cảnh cần thiết.
12. Báo cáo/Weekly Reflection cơ bản.
13. Security Rules, trạng thái loading/error/empty, test và README.

### Ngoài MVP — không tự ý làm

- Supabase, BigQuery hoặc đồng bộ hai database.
- Mạng xã hội, thử thách nhiều người, voucher hoặc tiền tệ trong game.
- Đồng bộ smartwatch/Google Fit/Health Connect.
- Tự động chẩn đoán, cảnh báo y tế hoặc kê toa.
- Huấn luyện mô hình AI riêng.
- Lưu trữ ảnh món ăn dài hạn nếu chưa có yêu cầu cụ thể.
- Push notification nền/Cloud Functions nếu chưa đánh giá nhu cầu, hạn mức và chi phí. Có thể xem thông báo local như giai đoạn tùy chọn.

---

## 6. Yêu cầu UX/UI

- Giao diện ưu tiên tiếng Việt, dễ dùng với sinh viên và người mới theo dõi sức khỏe.
- Phong cách hiện đại, thoáng, rõ phân cấp; dùng màu sắc, typography và spacing nhất quán.
- Tối ưu cho màn hình Android phổ biến, vùng bấm đủ lớn, có xử lý bàn phím và safe areas.
- Navigation có thể dùng bottom navigation cho những tab cốt lõi: Tổng quan, Nhật ký, Quest, AI/Chat, Cá nhân; điều chỉnh sau khi xem luồng UX.
- Dashboard không chỉ gồm card số liệu: ưu tiên mục tiêu hôm nay và một hành động tiếp theo hữu ích.
- Mọi màn hình dữ liệu phải có loading, empty, error và success state hợp lý.
- Không hiển thị chỉ số giả để lấp chỗ trống. Khi chưa có dữ liệu, giải thích cách bắt đầu ghi nhận.
- Không tạo score sức khỏe tổng hợp không có định nghĩa. Không dùng gamification để gây áp lực hoặc phạt người dùng nặng khi bỏ lỡ ngày.
- Có lời nhắc rõ ràng rằng thông tin chỉ hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.

---

## 7. Lộ trình triển khai theo giai đoạn

**Codex chỉ thực hiện giai đoạn được người dùng yêu cầu.** Mỗi giai đoạn phải kết thúc bằng kiểm thử và báo cáo. Không làm giai đoạn kế tiếp trong cùng lượt.

### Giai đoạn 0 — Kiểm tra hiện trạng và lập kế hoạch (KHÔNG SỬA CODE)

**Mục tiêu:** hiểu repo trước khi thay đổi.

**Yêu cầu:**
- Kiểm tra cấu trúc thư mục, `pubspec.yaml`, entry point, routing, state management, tests và cấu hình Firebase hiện có.
- Xác định phần nào đã hoạt động, phần nào thiếu.
- Kiểm tra xem đây là repo Flutter đã có hay thư mục rỗng.
- Đối chiếu với file này; phát hiện xung đột kiến trúc hoặc dependencies.
- Đề xuất kế hoạch thích nghi với code thực tế.
- Chưa chỉnh sửa mã nguồn, chưa cài package, chưa tạo Firebase project.

**Tiêu chí hoàn thành:** đưa báo cáo hiện trạng, rủi ro, việc người dùng phải tự làm trong Firebase Console và kế hoạch giai đoạn tiếp theo.

**Lệnh người dùng:** `Đọc AGENTS.md và chỉ thực hiện Giai đoạn 0. Không sửa mã nguồn.`

### Giai đoạn 1 — Nền tảng Flutter và UI system

**Mục tiêu:** có cấu trúc ứng dụng sạch và có thể chạy.

**Phạm vi:**
- Chỉ thiết lập cấu trúc dựa trên repo thực tế; không ghi đè ứng dụng hiện có.
- Tạo/hoàn thiện theme, màu, typography, spacing, shared widgets và router nếu cần.
- Thiết lập Riverpod nếu chưa có state management phù hợp.
- Tạo các trang/route khung cho Auth, Dashboard, nhật ký, Quest, Chat và Profile; các trang chưa làm nghiệp vụ phải ghi rõ đang chờ triển khai, không giả dữ liệu như dữ liệu thật.
- Đưa hướng dẫn chạy dự án vào README.

**Không làm:** kết nối Firestore hoặc triển khai logic nghiệp vụ.

**Tiêu chí:** app chạy; điều hướng hoạt động; analyze không có lỗi mới; UI dùng theme thống nhất.

**Lệnh:** `Thực hiện Giai đoạn 1 theo AGENTS.md; chỉ làm nền tảng Flutter và UI system.`

### Giai đoạn 2 — Firebase setup và Authentication

**Mục tiêu:** kết nối Firebase thực và xác thực an toàn.

**Phạm vi:**
- Kiểm tra cấu hình Firebase hiện tại.
- Nếu chưa có `firebase_options.dart`/Firebase project, hướng dẫn người dùng cài FlutterFire CLI và chạy `flutterfire configure`; không giả lập file cấu hình và không nói rằng đã kết nối.
- Thêm các package cần thiết với phiên bản tương thích qua Flutter tooling; tránh pin phiên bản lỗi thời không cần thiết.
- Khởi tạo Firebase đúng trước `runApp`.
- Đăng ký email/mật khẩu, đăng nhập, đăng xuất, theo dõi session và điều hướng theo trạng thái Auth.
- Xử lý loading, sai mật khẩu, email sai, mạng lỗi và thông báo lỗi thân thiện.
- Chưa tạo mọi nghiệp vụ sức khỏe.

**Tiêu chí:** luồng Auth hoạt động trong cấu hình thực hoặc trạng thái blocker được mô tả rõ; không có secret trong source; có test phù hợp.

**Lệnh:** `Thực hiện Giai đoạn 2 theo AGENTS.md: Firebase setup và Authentication.`

### Giai đoạn 3 — Hồ sơ và Body Metrics

**Mục tiêu:** quản lý profile và lịch sử thể trạng.

**Phạm vi:**
- Tạo hồ sơ người dùng tại `users/{uid}` sau đăng ký hoặc qua quy trình có thể chạy lại an toàn.
- Cập nhật các field profile được phép.
- Thêm/sửa/xóa lịch sử cân nặng dưới `users/{uid}/body_metrics/{metricId}`.
- BMI chỉ hiển thị khi chiều cao/cân nặng hợp lệ và phải được ghi nhãn chỉ số tham khảo; không tuyên bố chẩn đoán.
- Tạo model, repository, state management và UI.
- Viết Firestore Security Rules tối thiểu cho user/profile/metrics và test truy cập chéo nếu có emulator.

**Tiêu chí:** CRUD thật; dữ liệu được tách theo UID; validation đúng; lịch sử không bị ghi đè; có trạng thái không dữ liệu.

**Lệnh:** `Thực hiện Giai đoạn 3 theo AGENTS.md: hồ sơ và Body Metrics.`

### Giai đoạn 4 — Food Catalog và nhật ký dinh dưỡng thủ công

**Mục tiêu:** xây luồng dữ liệu dinh dưỡng trước khi có AI.

**Phạm vi:**
- Tạo danh mục thực phẩm có cấu trúc chuẩn; tên món, đơn vị/cơ sở khẩu phần, kcal, protein, carb, fat, nhãn nguồn và cờ ước tính.
- Tìm kiếm/chọn món, nhập khẩu phần, chọn loại bữa và thời điểm ăn.
- Tính dinh dưỡng bằng công thức dựa trên dữ liệu food catalog và khẩu phần; không để AI tự quyết định con số cuối cùng.
- Lưu meal log cùng snapshot giá trị dinh dưỡng tại thời điểm xác nhận.
- Cho phép xem/sửa/xóa nhật ký.
- Nếu tạo seed, đánh dấu dữ liệu mẫu và nguồn; không trình bày dữ liệu chưa xác minh là dữ liệu chính xác.

**Tiêu chí:** nhập thủ công hoàn chỉnh; đơn vị nhất quán; tổng calo/tổng dưỡng chất kiểm thử được; rules bảo vệ dữ liệu riêng tư.

**Lệnh:** `Thực hiện Giai đoạn 4 theo AGENTS.md: Food Catalog và nhật ký dinh dưỡng thủ công.`

### Giai đoạn 5 — AI Food Scanner

**Mục tiêu:** bổ sung AI vào luồng dinh dưỡng đã chạy ổn định.

**Phạm vi:**
- Dùng `image_picker` hoặc package camera đã được chấp thuận để chụp/chọn ảnh.
- Tích hợp Firebase AI Logic qua `firebase_ai` theo tài liệu Flutter hiện hành.
- Chọn model còn được hỗ trợ sau khi kiểm tra tài liệu; không hard-code một model cũ theo ví dụ không còn hiệu lực.
- Yêu cầu AI đề xuất tên món và mô tả/thành phần có thể suy ra; kết quả phải được hiển thị cho người dùng xác nhận.
- Đối chiếu kết quả với catalog nếu có; cho phép sửa món và nhập khẩu phần.
- Tính dinh dưỡng bằng dữ liệu catalog đã xác nhận; nếu thiếu dữ liệu, hiển thị rõ “ước tính/chưa có dữ liệu” và cho phép nhập thủ công.
- Xử lý ảnh quá lớn, lỗi mạng, hạn mức, AI trả kết quả không hợp lệ và người dùng hủy thao tác.
- Không lưu ảnh gốc theo mặc định.
- Cấu hình App Check phù hợp với trạng thái phát triển; không vô hiệu hóa bảo vệ trong production.

**Tiêu chí:** scanner không chặn nhập thủ công; không tự lưu bữa ăn trước xác nhận; không bịa độ chính xác; lỗi AI có đường lui rõ ràng; có test cho parsing/validation.

**Lệnh:** `Thực hiện Giai đoạn 5 theo AGENTS.md: AI Food Scanner. Kiểm tra tài liệu Firebase AI Logic hiện hành trước khi chọn API/model.`

### Giai đoạn 6 — Nước uống và hoạt động

**Mục tiêu:** hoàn tất nhật ký cơ bản hằng ngày.

**Phạm vi:**
- CRUD lượng nước uống theo thời điểm, đơn vị ml.
- CRUD hoạt động do người dùng nhập: loại hoạt động, phút, thời điểm và ghi chú tùy chọn.
- Tổng hợp theo ngày đã chọn và xử lý timezone nhất quán.
- Không giả định app tự đo bước chân nếu chưa tích hợp nguồn dữ liệu thiết bị; không tuyên bố calo tiêu hao chính xác nếu chỉ là ước tính.

**Tiêu chí:** dữ liệu thật; tổng đúng; cập nhật sau sửa/xóa; RLS tương đương theo UID; kiểm thử validation.

**Lệnh:** `Thực hiện Giai đoạn 6 theo AGENTS.md: nhật ký nước uống và hoạt động.`

### Giai đoạn 7 — Goals và Daily Health Quest

**Mục tiêu:** tạo trải nghiệm khác biệt có thể giải thích và kiểm thử.

**Phạm vi:**
- Cho phép người dùng đặt mục tiêu thực tế, có loại, giá trị, đơn vị, thời hạn và trạng thái.
- Bắt đầu bằng một rules engine đơn giản, minh bạch, không cần AI: ví dụ gợi ý ghi nhận bữa ăn nếu chưa ghi nhận, thêm nhật ký nước nếu người dùng muốn theo dõi, hoặc chọn hoạt động nhẹ theo thời gian người dùng tự chọn.
- Quest cần có ngày `dateKey` rõ ràng, ID ổn định theo người dùng/ngày để không tạo nhiều bản trùng khi mở màn hình nhiều lần.
- Người dùng có thể hoàn thành/bỏ qua nhiệm vụ; không tạo hình phạt quá nặng khi bỏ lỡ.
- Không suy đoán người dùng “không khỏe” chỉ vì chưa có nhật ký.
- Mỗi loại mục tiêu cần cách tính tiến độ riêng; không dùng một công thức cho mọi loại.

**Tiêu chí:** quest có thể tái lập an toàn trong cùng ngày; hoàn thành được lưu; chỉ số tiến độ đúng; rules engine có unit test; nhiệm vụ không đưa ra lời khuyên y tế nguy hiểm.

**Lệnh:** `Thực hiện Giai đoạn 7 theo AGENTS.md: Goals và Daily Health Quest.`

### Giai đoạn 8 — Dashboard và Weekly Reflection

**Mục tiêu:** chuyển dữ liệu thành thông tin có ích.

**Phạm vi:**
- Dashboard lấy dữ liệu thật từ repository: dinh dưỡng trong ngày, nước, vận động, cân nặng gần nhất và tiến độ mục tiêu/quest.
- Hiển thị nhãn ngày/múi giờ rõ ràng; có empty state khi chưa có dữ liệu.
- Biểu đồ theo ngày/tuần bằng `fl_chart` nếu phù hợp.
- Weekly Reflection tổng kết xu hướng đơn giản từ nhật ký thực tế; không suy diễn quan hệ nhân quả hoặc chẩn đoán.
- Chỉ thêm realtime listeners ở màn hình cần đồng bộ thực sự; hủy subscription đúng vòng đời và tránh listener trùng.
- Tránh nhiều query lặp; đo và giảm lượt đọc không cần thiết.

**Tiêu chí:** không còn số liệu demo trong dashboard chính; tổng số khớp nhật ký; biểu đồ chịu được dữ liệu trống/ít; test tính toán tổng hợp.

**Lệnh:** `Thực hiện Giai đoạn 8 theo AGENTS.md: Dashboard và Weekly Reflection.`

### Giai đoạn 9 — AI Health Chatbot

**Mục tiêu:** chatbot trả lời hữu ích và có ngữ cảnh, không chỉ là ô chat chung chung.

**Phạm vi:**
- Xây chat UI và lưu phiên/hội thoại theo UID.
- Dùng `firebase_ai`/Firebase AI Logic; kiểm tra model/provider được hỗ trợ hiện hành.
- Hỗ trợ loading, streaming nếu SDK/model phù hợp, lỗi mạng, lỗi hạn mức, thử lại và hủy thao tác nếu có thể.
- Khi người dùng hỏi “hôm nay tôi ăn bao nhiêu kcal?”, app phải lấy tổng từ repository rồi gửi số liệu cần thiết làm ngữ cảnh; không để mô hình tự đoán số liệu.
- Chỉ đưa vào prompt phần dữ liệu tối thiểu cần thiết và mô tả thời gian/đơn vị rõ ràng.
- Tách prompt hệ thống, ngữ cảnh người dùng và nội dung hội thoại; không coi nội dung người dùng là chỉ thị hệ thống.
- Không cho mô hình tự do truy cập Firestore. Nếu bổ sung tool/action, chỉ cho phép danh sách hành động hữu hạn, kiểm tra UID/quyền và xác nhận người dùng với thao tác ghi.
- Đặt giới hạn độ dài hội thoại và nội dung gửi đi để kiểm soát chi phí/token.
- Thông báo chatbot chỉ hỗ trợ thông tin chung về thói quen/dinh dưỡng, không chẩn đoán bệnh hay thay thế nhân viên y tế.
- Kiểm tra điều khoản xử lý dữ liệu của model/provider trước khi gửi dữ liệu nhạy cảm; không gửi dữ liệu không cần thiết.

**Tiêu chí:** chatbot không bịa dữ liệu cá nhân; lịch sử chat tách theo UID; có test prompt/context assembly và lỗi; không chứa API secret trong source.

**Lệnh:** `Thực hiện Giai đoạn 9 theo AGENTS.md: AI Health Chatbot có ngữ cảnh dữ liệu HealthMate.`

### Giai đoạn 10 — Security, kiểm thử tích hợp và hoàn thiện MVP

**Mục tiêu:** chuẩn bị demo đáng tin cậy.

**Phạm vi:**
- Rà soát mọi Firestore Security Rules và Cloud Storage Rules nếu có dùng Storage.
- Test truy cập chéo giữa hai UID bằng Firebase Emulator Suite nếu môi trường cho phép.
- Bổ sung unit test cho công thức, parsing, rules engine và tổng hợp báo cáo.
- Bổ sung widget test cho Auth, nhật ký, scanner states, chatbot states và dashboard ở mức phù hợp.
- Kiểm tra `dart format`, `flutter analyze`, `flutter test` và build Android nếu công cụ sẵn có.
- Rà soát secret, quyền riêng tư, error messages và trạng thái khi offline.
- Cập nhật README setup Firebase, lệnh chạy app, cấu hình App Check/AI, giới hạn gói miễn phí và hướng dẫn demo.
- Tạo `docs/test-report.md` ghi test thật đã chạy, kết quả và lỗi còn tồn tại.

**Tiêu chí:** build/test status được báo cáo chính xác; rules có test hoặc ghi blocker rõ; hướng dẫn cài đặt có thể làm theo; không còn lỗi nghiêm trọng đã biết bị che giấu.

**Lệnh:** `Thực hiện Giai đoạn 10 theo AGENTS.md: security, kiểm thử tích hợp và hoàn thiện MVP.`

### Giai đoạn tùy chọn 11 — Thông báo và polish

Chỉ làm sau khi các giai đoạn MVP ổn định và người dùng yêu cầu. Ưu tiên thông báo local nếu đủ dùng; trước khi chọn push notification, Cloud Functions hoặc dịch vụ khác phải kiểm tra yêu cầu billing, giới hạn miễn phí và thiết lập nền tảng hiện hành.

---

## 8. Quy định báo cáo cuối mỗi lượt

Khi hoàn thành một giai đoạn, phản hồi theo mẫu:

1. **Giai đoạn:** số và tên.
2. **Đã hoàn thành:** các hành vi người dùng giờ làm được.
3. **File đã tạo/sửa:** liệt kê những file chính.
4. **Kiểm thử:** lệnh đã chạy và kết quả thật.
5. **Cần người dùng làm:** ví dụ tạo Firebase project, chạy `flutterfire configure`, bật provider AI, cấu hình App Check hoặc test trên thiết bị.
6. **Vấn đề còn lại:** không giấu lỗi hoặc giả định chưa xác minh.
7. **Giai đoạn kế tiếp đề xuất:** chỉ nêu tên, không triển khai.

Nếu chưa thể hoàn thành, báo rõ phần đã xong và phần đang bị chặn. Không được chuyển tiếp giai đoạn để che một giai đoạn chưa hoàn tất.

---

## 9. Tài liệu chính thức tham khảo

Trước khi chọn API, model hoặc phiên bản package, kiểm tra tài liệu hiện hành; không lấy tên model, giới hạn miễn phí hoặc cấu hình từ ví dụ cũ làm sự thật mặc định.

- Flutter + Firebase setup: https://firebase.google.com/docs/flutter/setup
- Firebase Authentication for Flutter: https://firebase.google.com/docs/auth/flutter/start
- Cloud Firestore: https://firebase.google.com/docs/firestore/quickstart
- Firestore Security Rules: https://firebase.google.com/docs/firestore/security/get-started
- Firestore offline persistence: https://firebase.google.com/docs/firestore/manage-data/enable-offline
- Firebase AI Logic: https://firebase.google.com/docs/ai-logic
- Firebase AI Logic Flutter setup: https://firebase.google.com/docs/ai-logic/get-started?platform=flutter
- Firebase App Check: https://firebase.google.com/docs/app-check/flutter/default-providers
- Flutter testing: https://docs.flutter.dev/testing/overview
- Codex AGENTS.md / agent instructions: https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide

---

## 10. Lệnh bắt đầu khuyến nghị

Sau khi đặt file này vào thư mục gốc repository, gửi cho Codex đúng yêu cầu sau:

> **Hãy đọc toàn bộ `AGENTS.md` và chỉ thực hiện Giai đoạn 0. Kiểm tra repository HealthMate hiện tại, báo cáo hiện trạng và kế hoạch phù hợp với code thực tế. Tuyệt đối không sửa file, không cài package, không triển khai giai đoạn 1 trong lượt này.**
