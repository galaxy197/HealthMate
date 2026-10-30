# HealthMate

## Cập nhật nguồn thực phẩm — 27/10/2026

Danh mục đóng gói hiện có **11.169 mục**, thêm **308 USDA Foundation Foods**
từ bản tải chính thức **04/2026** và **3.255 USDA FNDDS 2021–2023** phát hành
**10/2024**. Các nguồn USDA mới được ưu tiên trước SR Legacy khi mức khớp tìm
kiếm bằng nhau; giữ nguyên ID, giá trị cũ và snapshot nhật ký. Bản phát hành
2026 không có nghĩa tất cả thực phẩm được đo năm 2026. Xem nguồn, số mục đã
loại và cách tái tạo tại [báo cáo cập nhật dữ liệu](docs/current-food-data-2026-10-27.md).

## Lần mở rộng trước: 7.606 mục và bộ lọc chế độ ăn — 27/10/2026

Tăng từ 162 lên **7.606 mục thực phẩm/món/biến thể**, có **7.169 mục kèm khẩu
phần quy đổi**. Bổ sung USDA SR Legacy 2018 offline, giữ món Việt hiện có và
tìm bằng từ khóa Việt/Anh. Quy mô vẫn nhỏ hơn MyFitnessPal và Calz công bố.
Nhật ký và gợi ý thực đơn đọc lựa chọn chay/thuần chay trong hồ sơ; mục tiêu
tăng/giảm cân tiếp tục dùng chỉ tiêu kcal và khẩu phần. Mục thực phẩm cần tránh
trong hồ sơ nay tự lọc món trùng và món chưa rõ thành phần khi tìm/gợi ý.
Thực đơn điều chỉnh gram theo mục tiêu kcal từng ngày, tính cả bữa đã lên kế
hoạch; xem trước tổng và báo khi chưa khớp trong ±5%. Tên USDA đã có tên Việt
rút gọn, giữ mô tả gốc để tra cứu và đối chiếu; thương hiệu/tên giống hiếm được giữ.
Web admin vẫn quản lý catalog Firestore, không hiện toàn bộ asset mới.
[Nguồn, cách dùng, tái tạo và giới hạn](docs/catalog-expansion-and-diets.md).
APK mới: `build/releases/healthmate-personalized-food-debug.apk` (giữ cấu hình
admin). **678 Flutter tests qua, analyze sạch**. Sàng lọc theo thành phần tham
khảo/từ khóa không chứng nhận an toàn dị ứng và không xác minh nhiễm chéo.
Chưa nghiệm thu bản này trên thiết bị thật.

## Android nhận điều khiển admin — 27/10/2026

Chạy `powershell -ExecutionPolicy Bypass -File tool/run_android.ps1 -DeviceId emulator-5554`
hoặc đóng gói bằng `powershell -ExecutionPolicy Bypass -File tool/build_android.ps1`.
Hai lệnh dùng chung `config/admin-runtime.json`, cấu hình chatbot và App Check debug
cục bộ; APK nằm ở `build/releases/healthmate-figma-admin-debug.apk`.
Script build kiểm thử cờ admin trước khi đóng gói và ghi SHA256 bên cạnh APK.
[Quy trình kiểm tra tích hợp](docs/admin-runtime-integration.md).

## Bộ 20 câu cá nhân hóa

Người mới trả lời theo các phần ngắn và xác nhận mục tiêu trước khi lưu.
Người cũ có thể bổ sung tại **Thêm → Cá nhân hóa · 20 câu hỏi**.
Câu bổ sung có thể để sau; dữ liệu riêng theo UID, không gửi bộ khảo sát cho AI.
Xem [thiết kế, nguồn và giới hạn](docs/personalization-questionnaire.md).


## Web admin đã triển khai — 27/10/2026

Danh mục, tài khoản, cấu hình và audit có tìm toàn bộ danh sách, lọc, phân trang,
STT và xuất Excel `.xlsx`. Dashboard có bốn số liệu. Mở
**https://healthmate-app-20261013.web.app**, chọn **Tiếp tục với Google** bằng
`luuxuantung285600@gmail.com`. App Check web/role/Rules/Hosting đã cấu hình;
17 kiểm tra quyền server thật qua, người dùng chọn thử giao diện sau.
Thanh toán vẫn tắt. APK nhận cấu hình admin đã build, chưa cài điện thoại.
[Chạy local](admin-web/README.md) · [Triển khai, kiểm thử và giới hạn](docs/admin-production.md).
Các ghi chú “tạm gác admin” bên dưới là lịch sử, được thay bằng yêu cầu mới này.

## Báo cáo năm và khoảng tùy chọn — 27/10/2026

Trong **Tiến độ**, chọn **Theo năm** hoặc **Tùy chọn** để xem từ ngày–đến ngày hay
nhập số ngày cụ thể (1–366 mỗi lượt). Có tổng hợp theo tháng và chi tiết ngày.
Xuất CSV Android nhận sẵn khoảng đang xem và hỗ trợ đến 366 ngày. Các mốc này là
khoảng xem/xuất, không phải thời hạn tự xóa nhật ký. Năm cũ vẫn chọn lại được.
[Cách dùng, giới hạn và kiểm thử](docs/year-and-custom-reports.md).

## Cá nhân hóa kcal mỗi ngày — 26/10/2026

Thiết lập ban đầu có thêm bước đề xuất kcal và đạm/carb/béo từ hồ sơ, mức hoạt
động và mục tiêu. Người đã dùng bấm **Hoàn thiện kế hoạch kcal** ở Hôm nay khi
chưa có mục tiêu, hoặc **Thêm → Mục tiêu dinh dưỡng → Cá nhân hóa/Tính lại kế hoạch**.
Phải xem lại và xác nhận trước lưu; mục tiêu cũ không tự đổi. Có nhập tay/thiết lập
sau. Không thêm API trả phí hoặc cần thay Rules Firebase.
[Cách tính, nguồn, giới hạn và kiểm thử](docs/personalized-nutrition.md).

## Mã nguồn và đề xuất giao diện — 26/10/2026

Mã Flutter, Worker chatbot và web admin thử nghiệm được lưu chung trong repo.
Web admin vẫn tạm gác. [Đề xuất điều hướng](docs/ui-navigation-proposal.md):
avatar hồ sơ góc trái trên, năm mục Hôm nay/Dinh dưỡng/Tập luyện/Tiến độ/Trợ lý.
Đây là đề xuất, chưa thay đổi giao diện hoặc bổ sung buổi tập có hướng dẫn.

[Bản chụp Rules MVP đã xác minh](deploy/README.md) được lưu để clone lại có thể
đối chiếu; Rules ở gốc còn phần thử nghiệm admin, không deploy mặc định vào production.
Các mục cũ bên dưới là lịch sử; trạng thái mới nhất được ghi ở đầu tài liệu.

## Mới nhất26/10 — Năng lượng, tiến độ cân nặng và giấc ngủ

**Thêm → Thói quen & kế hoạch**: tab Bước chân có ước tính calo và lựa chọn xác nhận
cộng ngân sách hôm nay; tab Tiến độ nối ngân sách với cân nặng/mục tiêu; Giấc ngủ
có biểu đồ7/30ngày, mục tiêu tự đặt và lời nhắc local. Mặc định không tự cộng calo
từ bước hoặc giờ ngủ. Phần cộng sau xác nhận thống nhất ở Tổng quan, Nhật ký và chat.
Rules2collectionmới đã deploy/đọc lại xác nhận.608Flutter/73Rules/23SDK/nativeQAqua.
APK: `build/releases/healthmate-wellness-insights-debug.apk`; chưa cài điện thoại
theo lựa chọn kết nối sau. [Hướng dẫn và giới hạn](docs/wellness-insights.md).

## Mở rộng thói quen và kế hoạch — 26/10/2026

Trong APK mới, mở **Thêm → Thói quen & kế hoạch**: nhắc bữa local, thực đơn7 ngày,
bước chân opt-in, giờ ngủ thủ công có sửa/lịch sử và8 dưỡng chất mở rộng. Tìm món
có asset offline162 thực phẩm/công thức có nguồn và khẩu phần tham khảo điều chỉnh được.
Không thêm dịch vụ trả phí. Bản debug: `build/releases/healthmate-wellness-debug.apk`.

Source đã qua analyze,597 Flutter tests,70 Rules,22 SDK và Android QA. **Rules MVP
đã deploy và đọc lại xác nhận đúng bản vào 26/10/2026**, sau lượt kiểm thử lại61/61.
Ngủ/thực đơn/đồng bộ bước và snapshot schema mới đã có Rules trên Firebase thật.
Admin tiếp tục tạm gác. Người dùng chọn kết nối điện thoại sau, nên chưa cài APK
và chưa nghiệm thu cảm biến/lưu dữ liệu trên máy thật.
[Trạng thái rollout và bước thử điện thoại](docs/wellness-rollout.md).
[Hướng dẫn, kiểm thử, giới hạn và hash APK](docs/wellness-expansion.md).

## Kiểm thử và bảo mật — 25–26/10/2026

Giai đoạn 10 đã sửa parser USDA/cache công khai và kiểm tra Flutter, Firebase
Emulator, Worker cùng Android QA. Bản debug mới nằm trong
`build/releases/healthmate-stage10-debug.apk`; chưa cài lên điện thoại.
Rules production còn thiếu email gate và schema dinh dưỡng mới; candidate MVP
đã chuẩn bị, chưa triển khai. Xem [kết quả và giới hạn](docs/stage10-security-review.md).
Web admin tiếp tục tạm gác; không tự chuyển sang Giai đoạn 11.

## Hoàn thiện auth điện thoại — 24/10/2026

Đăng nhập email hoặc **Tiếp tục với Google**, đăng ký/xác minh email trước khi
mở dữ liệu, quên mật khẩu qua liên kết Firebase và gửi lại có thời gian chờ.
Google đã bật trên Firebase thật, đăng ký SHA debug và cập nhật
`google-services.json` có OAuth client. Cần cài APK mới và thử trên điện thoại;
Rules mới chưa deploy. Facebook đã bỏ theo yêu cầu, web admin tạm gác.
[Luồng, cấu hình và nghiệm thu](docs/authentication-flow.md).

## Web quản trị — 23/10/2026

Mã nguồn web nằm trong `admin-web`, có thể mở cùng dự án trong VS Code.
HTML/CSS/JavaScript + Firebase Web SDK: danh mục, khóa/mở truy cập tài khoản,
cấu hình app và nhật ký quản trị. Admin đã triển khai; bản local dùng Firebase
Emulator. [Hướng dẫn chạy và thiết lập](admin-web/README.md).
Mobile nhận cấu hình/quyền từ xa khi dùng script chạy/build ở đầu tài liệu;
`config/admin-runtime.json` bật `HEALTHMATE_ENABLE_ADMIN_CONTROLS=true`.

## Màn hình thêm bữa ăn hợp nhất — 23/10/2026

Thêm bữa ăn và Quét món dùng chung một màn hình với **Nhập tay · Ảnh · Yêu thích**.
Tab Ảnh có camera xem trước, chụp/chọn ảnh và lối vào quét mã vạch; các món được
thêm vào cùng bản nháp, kiểm tra rồi mới lưu nhật ký. [Cách dùng và giới hạn](docs/unified-meal-entry.md).

## Cập nhật quét món — 23/10/2026

Quét ảnh hiển thị tên/thành phần, kcal, đạm, carbohydrate, chất béo, chất xơ trên
100 g và theo khẩu phần; ưu tiên catalog, số AI ghi rõ ước tính. Bấm **Kiểm tra
và lưu vào Món của tôi** để xác nhận/lưu món chưa có vào thư viện riêng; lưu bữa
ăn vẫn là bước riêng. Mã vạch giữ đúng gram đã chỉnh và quy đổi dinh dưỡng theo
khẩu phần. [Luồng sử dụng, nguồn dữ liệu và giới hạn](docs/scanner-update.md).

Đã sửa việc ghép cả đĩa nhiều thành phần vào một nguyên liệu: scanner chỉ tự
chọn một món trùng đầy đủ tên/tên tương đương duy nhất. Khớp từ “cơm” không còn
lấy dinh dưỡng cơm trắng cho cả đĩa cơm tấm. Khi chưa khớp, giữ nguồn AI ước tính
cho cả món để kiểm tra/lưu; có thể chuyển từ danh mục về ước tính AI.

Đã kiểm tra chọn ảnh và phân tích AI trên điện thoại thật: một lượt thành công
trong 6,77 giây, người dùng xác nhận đã thấy kết quả. Chưa nghiệm thu riêng thao
tác chụp camera. Lưu với schema/chất xơ mở rộng còn phụ thuộc Rules production;
xem trạng thái Rules H0–H7 bên dưới.

Ứng dụng Flutter giúp người từ **18 tuổi** theo dõi thói quen lành mạnh.
Android là nền tảng chính;
web phục vụ xem và kiểm tra giao diện trong quá trình phát triển.

## Thay đổi local H0–H7 — 19/10/2026

[Tiến độ và kết quả từng mốc](docs/h-improvements.md): ổn định E2E/release guard,
catalog/khẩu phần/tìm kiếm, recent/bữa mẫu, nhập nhãn và ghi nhanh kcal với macro
chưa biết. [Schema H3 và kiểm thử](docs/h3-quick-add.md).
**Rules/schema mới chưa deploy; catalog mới chưa import production.** Backend U2
bên dưới là trạng thái lịch sử, chưa bảo đảm lưu bữa mẫu/schema3 trên production.
Cần phối hợp nâng client/cleanup và review triển khai riêng; không dùng APK test
target Emulator làm APK phát hành. H4 đã có hướng dẫn mục tiêu tùy chọn; H5 có báo
cáo 30/90 ngày và trạng thái xác nhận; [H6](docs/h6-fiber.md) bổ sung chất xơ có nguồn.
H0–H7 đã kiểm thử local/Emulator. [H7](docs/h7-private-data.md): nháp bữa ăn mã hóa
theo UID trên Android, phục hồi sau process death, retry cùng mã thao tác; xuất
nhật ký CSV 1–90 ngày qua hộp chọn nơi lưu của Android. Flutter454/454; analyze
sạch; Android H7 hai phase12s/32s, file1554byte trong Downloads khớp snapshot
repository. Web/desktop chưa hỗ trợ nháp bền vững hoặc xuất file.
[Checkpoint H7 cũ](docs/h7-checkpoint.md) ghi lần dừng lúc hạn mức còn4%; đã tiếp
tục và hoàn thành sau khi cửa sổ hạn mức reset. Không commit/push/deploy trong đợt này.

## Phạm vi hiện tại — Core C6, UX U1 và Firebase U2

U1 thu gọn Nhật ký thành một overview kcal/macros + mục tiêu đúng ngày; nút thêm
theo bữa hiện trong viewport đầu390×844/chữ100%. Tiến độ đưa tổng/biểu đồ lên đầu,
chi tiết ngày và cách đọc mở khi cần. Giữ form, snapshot, ngày, retry và nghiệp vụ.
[Ảnh trước/sau và phép đo](docs/ux/u1/README.md),
[kế hoạch Firebase có thể review](docs/firebase-deployment-plan.md).
U1 local:370Flutter tests,47Rules,14SDK,7catalog; Android E2E đủ10chặng và các
kiểm tra viewport/dùng lại món mới. APK debug ARM64:
`D:\HealthMateMaintenanceQA\HealthMate-U1-debug-arm64.apk`.
**U2 đã hoàn tất ngày 18/10/2026:** deploy chỉ Firestore Rules, xác minh hash
production khớp bản đã review và hai index hiện có READY. Firebase SDK production
đạt một kịch bản gồm 10 chặng, có 50 yêu cầu guest/truy cập chéo bị từ chối.
Đã tạo đúng hai tài khoản QA theo cho phép, dọn và xác minh dữ liệu Firestore QA;
giữ hai tài khoản Auth. [Bằng chứng U2](docs/firebase/u2/README.md).
Không đổi App Check/billing/indexes, không migration hoặc tác động dữ liệu thật.
Điện thoại thật, Android production UI và bản release ký phát hành vẫn chưa nghiệm thu.

Bản mặc định hiển thị Chatbot và Food Scanner. Thanh dưới có 5 ô:
**Hôm nay · Nhật ký · + · Tiến độ · Thêm**. Bấm **+ → Quét món** để mở scanner;
**Thêm** có lối vào Mục tiêu/Nhiệm vụ và Chat. Trong form thêm bữa, bấm
**Quét mã vạch** để mở camera mã vạch. AI vẫn kiểm tra hồ sơ 18+, sự đồng ý và
cấu hình Firebase/App Check; chỉ mở menu không tự gửi dữ liệu đến AI.

Muốn chạy bản chỉ có tính năng cơ bản, truyền cả hai cờ cục bộ:
`--dart-define=HEALTHMATE_ENABLE_CHATBOT=false`
`--dart-define=HEALTHMATE_ENABLE_FOOD_SCANNER=false`.
Các mô tả AI bên dưới là luồng đã bảo toàn cho bản bật cờ, không phải tính năng
đang mở trong bản core. Bật lại AI cần yêu cầu riêng và không bỏ qua kiểm tra tuổi,
consent, App Check hoặc điều kiện backend.

Phạm vi, gap, schema dự kiến, kiểm thử và kế hoạch C2–C6:
[`docs/core-scope.md`](docs/core-scope.md). C2 bổ sung mục tiêu kcal/macros do bạn
tự nhập, có ngày hiệu lực, mở từ Tổng quan/Cá nhân. Nhật ký so sánh mục tiêu đúng
ngày đang chọn; không tự tính BMR/TDEE hoặc viết lại mục tiêu ngày trước.
C3 chia nhật ký thành Sáng/Trưa/Tối/Phụ, có tổng và nút thêm từng bữa. Form có
Tìm món/Gần đây/Yêu thích; yêu thích catalog lưu riêng theo tài khoản. Sao chép mở
bản nháp sửa ngày/giờ/bữa/gram, giữ snapshot và dùng cùng ID khi retry để tránh trùng.
Vẫn tối đa 5 món/bản ghi và giữ nhập món ngoài danh mục một lần.
C4 thêm Thư viện món ở Cá nhân, hai nguồn Món của tôi/Công thức trong form bữa ăn,
CRUD riêng theo UID và yêu thích cả ba nguồn. Công thức có tối đa 6 nguyên liệu
catalog/món cá nhân, snapshot độc lập, khối lượng thành phẩm và số phần tùy chọn;
nhập gram hoặc phần có quy đổi rõ ràng. Không tự thay nhật ký khi sửa/xóa nguồn.
Lưu món ngoài catalog vào thư viện là lựa chọn chủ động; bữa vẫn cần xác nhận riêng.
C5 bổ sung tab **Tiến độ**: chọn tuần từ Thứ Hai, tổng kcal/macros, số ngày có ghi,
trung bình chỉ trên ngày ghi bữa, nước/phút vận động và cân nặng theo ngày đo.
Mục tiêu từng ngày lấy theo phiên bản hiệu lực; đổi mục tiêu mới không áp ngược
về ngày cũ. Chưa ghi khác với ghi 0 và ngày tương lai; dưới 2 lần cân chưa mô tả
thay đổi. Tải báo cáo từ máy chủ khi mở/đổi tuần, có giờ tải và nút tải lại sau
khi sửa nhật ký. Lỗi mục tiêu không che tổng nhật ký đã tải thành công.
Rules cho nutrition_targets/favorite_foods/custom_foods/recipes đã kiểm thử local
và triển khai, xác minh trong U2 (trước U2 production còn thiếu các match này).
C6 đã nghiệm thu local: 349 Flutter tests, 47 Rules tests, 14 Firebase
SDK tests, 10/10 chặng E2E Android API30 trên AVD QA/backend emulator và APK debug
ARM64 từ lib/main.dart. U2 bổ sung kiểm thử SDK production; điện thoại thật chưa
nghiệm thu và chưa có bản release ký phát hành. Báo cáo theo từng đợt tại
docs/test-report.md; các trạng thái C6/U1 bên dưới là lịch sử tại thời điểm chạy.
C6 sửa vòng đời subscription khi đổi UID, chặn thao tác Auth trễ nhắm nhầm tài
khoản, giữ draft hồ sơ/cân nặng khi lưu lỗi và giữ đúng thời điểm lần cân mới.

- Material 3, màu sắc, typography, spacing và widget dùng chung.
- Giao diện tiếng Việt, chế độ sáng/tối/theo thiết bị.
- Thanh điều hướng hiển thị Tổng quan, Nhật ký, Tiến độ và Cá nhân; route Quest/Chat
  vẫn được giữ. Mục tiêu/nhiệm vụ mở từ Cá nhân. Khi cờ Chat tắt, menu Chat ẩn
  và `/chat` chuyển về Tổng quan sau Auth/onboarding. Nút `+` có bữa ăn, nước,
  vận động và cân nặng; Quét món chỉ xuất hiện ở bản bật cờ Scanner. Thêm cân nặng
  mặc định ngày hôm nay, cho chọn ngày đo cũ và giữ form nếu chưa lưu được.
- Điều hướng bằng `go_router`, giữ trạng thái từng tab; Riverpod quản lý router
  và lựa chọn theme. Lựa chọn theme được lưu trên thiết bị.
- Thanh điều hướng dưới trên điện thoại, thanh bên khi rộng từ 840 logical pixels.
- Firebase được khởi tạo trước `runApp` bằng cấu hình Android/web do FlutterFire
  sinh cho project `healthmate-app-20261013`.
- Đăng ký, đăng nhập và đăng xuất bằng email/mật khẩu thật; session được theo dõi
  để bảo vệ route riêng tư và đưa người dùng về đúng trang họ định mở.
- Form có validation, trạng thái đang xử lý, chống gửi lặp, ẩn/hiện mật khẩu và
  thông báo tiếng Việt cho lỗi thông tin đăng nhập, email, mạng hoặc giới hạn thử.
- Hồ sơ được tạo an toàn theo session tại `users/{uid}`; người dùng sửa tên hiển
  thị và chiều cao, còn email được đồng bộ từ tài khoản Auth.
- Lịch sử cân nặng có thêm/sửa/xóa thật tại
  `users/{uid}/body_metrics/{metricId}`, sắp xếp theo ngày đo và có trạng thái
  không dữ liệu.
- BMI chỉ xuất hiện khi chiều cao và cân nặng hợp lệ, được ghi rõ là chỉ số tham
  khảo và không phải chẩn đoán.
- Firestore Security Rules giới hạn dữ liệu theo UID, schema, kiểu dữ liệu,
  khoảng giá trị và ngày theo timestamp/UTC offset; rules mới đã test trên emulator nhưng
  chưa deploy production.
- Danh mục **158 mục**: 10 mục USDA cũ, 101 thực phẩm Việt theo Viện Dinh dưỡng
  2007 và 47 món chế biến theo công thức tham khảo. Dùng `100 g`, có macro,
  nguồn và nhãn ước tính; client chỉ đọc khi đã đăng nhập. Tìm được không dấu,
  có **Xem thêm món**. Chi tiết nguồn, giới hạn và cách nạp:
  [`docs/food-catalog.md`](docs/food-catalog.md).
- Nhật ký bữa ăn hỗ trợ tìm món, chọn khẩu phần, loại bữa/thời điểm, xem tổng
  kcal/protein/carb/fat, thêm/sửa/xóa và lưu snapshot dưới UID.
- AI Food Scanner trên Android cho phép chụp/chọn ảnh, dùng Firebase AI Logic với
  Gemini Developer API và model `gemini-3.5-flash-lite` để giảm độ trễ. Người dùng
  kiểm tra món/khẩu phần; số AI chỉ là ước tính, catalog được chọn là nguồn ưu tiên.
  Có thể cấu hình riêng qua `HEALTHMATE_FOOD_SCANNER_MODEL`; cờ cũ
  `HEALTHMATE_AI_MODEL` vẫn được hỗ trợ nhưng có thể ghi đè model nhanh mặc định.
- App Check dùng debug provider trong debug và Play Integrity trong release.
  Trạng thái enforcement hiện tại cần kiểm tra trong Console trước khi demo.
  Ảnh được mã hóa lại từ pixel để bỏ metadata gốc rồi chỉ gửi sau xác nhận;
  HealthMate không tải ảnh lên Storage hoặc lưu ảnh trong Firestore. Camera/picker
  có thể tạo file tạm trên thiết bị; nhà cung cấp AI xử lý ảnh theo điều khoản riêng.
- Nhật ký nước uống hỗ trợ chọn ngày, nhập lượng ml và thời điểm, xem tổng theo
  ngày, sửa/xóa dữ liệu thật dưới UID.
- Nhật ký vận động hỗ trợ loại hoạt động, số phút, thời điểm và ghi chú tùy chọn;
  tổng thời lượng theo ngày cập nhật sau mọi thao tác.
- Ngày nhật ký dùng `dateKey` theo lịch địa phương và lưu độ lệch múi giờ tại
  thời điểm ghi. Ứng dụng không nhận là tự đo bước chân hay tính calories tiêu hao.

HealthMate hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.

## Yêu cầu môi trường

Môi trường đã dùng: Flutter 3.44.1 stable, Dart 3.12.1. `pubspec.yaml` yêu cầu
Dart `^3.12.1`; các phiên bản dependency được ghi trong `pubspec.lock`.
Cần Flutter SDK, Android SDK, kết nối mạng và thiết bị Android hoặc emulator để
chạy Android. Firebase project đã được cấu hình; Email/Password provider đang bật.

Trên máy hiện tại Flutter nằm tại `D:\Flutter\flutter`, chưa có trên PATH.
Trong PowerShell có thể thêm PATH cho **phiên terminal hiện tại**:

```powershell
$env:Path = 'D:\Flutter\flutter\bin;' + $env:Path
flutter --version
flutter doctor -v
```

Trên máy khác, dùng đường dẫn Flutter SDK thực tế của bạn. Nếu muốn dùng lâu dài,
thêm thư mục `flutter\bin` vào PATH qua Windows Environment Variables.

## Chạy ứng dụng

Mở terminal tại thư mục chứa `pubspec.yaml`:

```powershell
flutter pub get
flutter devices
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <android-device-id>
```

Trên máy phát triển đã cấu hình HealthMate, chạy Android qua script sau để nạp
App Check debug token từ file cục bộ ngoài repository:

```powershell
.\tool\run_android.ps1 -DeviceId <android-device-id>
```

Build release không dùng debug token; code chuyển sang Play Integrity. Khi tạo
release keystore hoặc bật Play App Signing, phải đăng ký SHA-256 release tương
ứng trong Firebase trước khi phát hành.

Nếu `flutter doctor` báo giấy phép Android chưa được chấp nhận, người dùng cần
tự đọc và chấp nhận giấy phép thích hợp bằng `flutter doctor --android-licenses`.

Để xem UI trong Chrome mà không cần emulator:

```powershell
flutter run -d chrome
```

## Kiểm tra và build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

Widget tests kiểm tra các tab hiện và route ẩn, Auth/quay lại, phục hồi đường dẫn không
tồn tại, đổi theme, màn hình nhỏ với cỡ chữ lớn và layout rộng. Bộ test Auth còn
kiểm tra validation, session routing, loading, lỗi mạng, đăng xuất và retry. Test
Profile bao phủ bootstrap sau đăng nhập, validation/BMI và CRUD Body Metrics.
Test Nutrition bao phủ công thức khẩu phần, parser Gemini và luồng thêm bữa.
Test Daily Logs bao phủ date key, validation, tổng hợp và luồng CRUD nước/vận động.
Scanner có test chọn ảnh/hủy/lỗi/timeout/consent/xác nhận; Chat có test nguồn dữ
liệu, streaming, retry, đổi UID và không gửi nhật ký tới AI. Integration test
Android gọi Firebase AI Logic thật là kiểm tra tùy chọn cho đợt AI riêng khi có
thiết bị và App Check; **không chạy trong bản core đã tắt AI**. Test hồi quy AI
trong suite dùng fake và bật cờ riêng; không coi việc có file test là bằng chứng
đã chạy dịch vụ thật.
Kết quả thực tế và giới hạn môi trường được ghi tại
[`docs/implementation-progress.md`](docs/implementation-progress.md).
Kết quả kiểm tra Giai đoạn 10 và giới hạn: [`docs/test-report.md`](docs/test-report.md).

Kiểm thử Auth + Firestore SDK thật và Rules trên emulator (không gọi production):

```powershell
# Sau khi đã có Node.js 22+, Firebase CLI, Java 21 và dependencies rules-tests:
.\tool\test_emulators.ps1
# Máy khác có thể truyền -FlutterSdk, -Chrome, -JavaHome.
```

Script dùng cố định `demo-healthmate-rules`, Auth 9099/Firestore 8080. Test SDK
ở `test/firebase_repository_integration.dart` được chạy riêng, không được phát
hiện trong `flutter test` mặc định vì không mang hậu tố `_test.dart`. Mặc định
trên Windows script bật adapter phục vụ CanvasKit từ cache cho lỗi slash của
Flutter web test runner hiện tại; không sửa SDK. Có thể dùng
`-WithoutChromeAdapter` khi SDK đã sửa lỗi. Chỉ trình duyệt test headless bị tác động.

Security Rules có bộ test Node riêng. Trên máy hiện tại cần Java 21 từ Android
Studio vì Java mặc định còn là Java 8:

```powershell
npm install --prefix rules-tests
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --only firestore --project demo-healthmate-rules "npm test --prefix rules-tests"
```

Chỉ sau khi chủ project review và chủ động yêu cầu triển khai Rules:

```powershell
firebase deploy --only firestore:rules --project healthmate-app-20261013
```

## Cấu trúc

```text
lib/
  main.dart                      # Khởi tạo Firebase trước ProviderScope/runApp
  app.dart                       # MaterialApp.router, locale và theme
  firebase_options.dart          # Client config do FlutterFire sinh
  core/
    config/                      # Firebase bootstrap
    router/                      # Đường dẫn, router và vòng đời
    theme/                       # Theme sáng/tối và spacing
    widgets/                     # Shell thích ứng, trang khung, trạng thái chờ
  features/
    auth/                        # Model, repository, provider và UI Auth
    dashboard/presentation/
    journal/presentation/        # Điểm vào nhật ký tổng hợp
    nutrition/                   # Catalog, meal log, repository, provider và UI
    food_scanner/                # Firebase AI service và luồng xác nhận ảnh
    water/                       # Nhật ký nước theo UID/ngày
    activity/                    # Nhật ký vận động theo UID/ngày
    daily_quest/presentation/
    chatbot/presentation/
    profile/                     # Model, repository, provider và UI profile/metrics
  shared/providers/              # Theme preference lưu trên thiết bị
test/                            # Widget/unit tests và fake repositories
integration_test/                # Smoke test Firebase AI Logic trên Android
tool/run_android.ps1             # Chạy debug với token App Check ở ngoài repo
rules-tests/                     # Security Rules tests trên Firestore Emulator
firestore.rules
firestore.indexes.json
android/
web/
```

`journal` là điểm vào tổng hợp; nutrition, food scanner, water và activity được
tách theo feature.

## Firebase và bảo mật cấu hình

Android application ID hiện là `com.example.healthmate`; cần chốt namespace
thương hiệu trước khi phát hành. `firebase_options.dart` và
`android/app/google-services.json` chỉ chứa client configuration mà Firebase SDK
cần để kết nối. Không đưa service-account JSON, Admin SDK credential hoặc secret
server vào repository. Build release yêu cầu cấu hình ký riêng trong
`android/key.properties` (ngoài Git); Gradle dừng nếu thiếu cấu hình, không dùng
debug signing thay thế. Hiện chưa có khóa phát hành trên máy này.

Cloud Firestore mặc định dùng Native mode tại `asia-southeast1` (Singapore).
Schema và quyền truy cập được mô tả tại
[`docs/database-design.md`](docs/database-design.md). Tài khoản chỉ có thể đọc và
ghi document nằm dưới UID của chính nó; validation được thực hiện cả ở Flutter
và Security Rules.

## Các bước tiếp theo

Giai đoạn tùy chọn 11: thông báo và polish, chỉ khi người dùng yêu cầu sau khi
đã kiểm tra MVP trên Android thật. Chưa triển khai.

Tuân theo `AGENTS.md`: mỗi lượt chỉ thực hiện giai đoạn được yêu cầu.

## Thiết lập Firebase trên máy mới

1. Chạy `flutter pub get`, cài Firebase CLI và FlutterFire CLI theo
   [hướng dẫn Flutter chính thức](https://firebase.google.com/docs/flutter/setup).
   Đăng nhập tài khoản được cấp quyền vào project. Các file cấu hình client đã
   có trong repo; chỉ chạy `flutterfire configure --project=<project-id>` nếu
   chủ động đổi project/platform, không tự ghi đè cấu hình hiện tại.
2. Trong Authentication bật **Email/Password**. Dùng Firestore Native mode và
   review Rules hiện có; không bật test mode công khai để vượt lỗi permission.
   Production đã có các collection MVP và trần chat 50 lượt; Rules local còn
   các thay đổi chưa triển khai. Đợt kiểm tra 25–26/10 phát hiện production thiếu
   kiểm tra email đã xác minh và định dạng dinh dưỡng mới. Xem
   [bản rà soát Giai đoạn 10](docs/stage10-security-review.md) trước khi deploy;
   không deploy cả file local vì còn chứa phần admin đang tạm gác.
3. Trước khi thử AI trên Android, kiểm tra Firebase AI Logic đã cấu hình
   **Gemini Developer API**, model còn được hỗ trợ và quota trong project.
   Không bật billing hoặc thêm API key Gemini riêng vào Flutter để vượt hạn mức.
   Free tier có hạn mức và điều khoản xử lý dữ liệu; không bảo đảm miễn phí vô hạn.
4. Đăng ký Android App Check debug token trong Console theo
   [hướng dẫn debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider).
   Lưu token tại `%LOCALAPPDATA%\HealthMate\app-check-debug-token.txt` trên máy
   phát triển để chạy `tool/run_android.ps1`; giữ ngoài Git, không chia sẻ log
   chứa token. Bản release dùng Play Integrity và SHA-256 ký phát hành, cần
   cấu hình/kiểm tra riêng. Không tắt enforcement production để sửa lỗi debug.

Không dùng Storage hoặc Cloud Functions. Theo lựa chọn mới của người dùng,
chatbot gọi Cloudflare Worker đã triển khai; chỉ gửi ngữ cảnh cần thiết sau khi
đồng ý dùng Chat AI. Chế độ tra cứu nhật ký tại app không gửi AI. Các giới hạn
và cấu hình nằm ở [tài liệu chatbot](docs/chatbot.md).
Scanner dùng Firebase AI Logic/Gemini, yêu cầu đồng ý **cho từng ảnh**; chỉ chọn
ảnh món ăn không có khuôn mặt, giấy tờ hay nội dung cá nhân. Re-encode ảnh bỏ
EXIF/GPS gốc, nhưng không loại được thông tin cá nhân xuất hiện trong pixel.
[Điều khoản Gemini](https://ai.google.dev/gemini-api/terms) áp dụng cho payload gửi đi.

## Kịch bản demo và kiểm tra trên Android thật

Với bản core C1, thực hiện các bước Auth/hồ sơ, nhật ký, cân nặng, mục tiêu và
tổng hợp tuần bên dưới; bỏ qua thao tác Chat/Scanner. Không bật hai cờ chỉ để
hoàn tất kịch bản AI cũ. Nghiệm thu Android core đầy đủ thuộc C6.

1. Dùng tài khoản kiểm thử của người từ 18 tuổi; thử đăng ký, hoàn tất thiết lập,
   đóng/mở lại app, đăng xuất/đăng nhập. Người dùng cũ thiếu thông tin được yêu
   cầu bổ sung; dữ liệu cũ được giữ nguyên. Ngày sinh là thông tin tự khai,
   không phải xác minh danh tính. Tài khoản không đủ điều kiện không được gọi AI.
2. Ghi một bữa thủ công, nước và vận động; đổi ngày sang ngày trống rồi quay lại.
   Sửa/xóa và đối chiếu tổng kcal/macro/ml/phút trên Tổng quan và Nhật ký.
   Mở Nhìn lại tuần, tải lại sau khi sửa dữ liệu; không dùng số liệu demo giả.
3. Tạo mục tiêu và hoàn thành/bỏ qua nhiệm vụ; mở lại để kiểm tra trạng thái
   được lưu. Chat thử câu hỏi số liệu theo ngày và tải lại lịch sử; chỉ thử
   chủ đề AI chung sau khi đọc disclosure và xác nhận App Check hoạt động.
4. Scanner thử hủy camera, từ chối quyền, ảnh hỏng/lớn, ảnh món không trong
   catalog, mất mạng và đóng khi đang phân tích. Phải đồng ý xử lý ảnh trước
   khi phân tích, xác nhận món/khẩu phần trước lưu. Hủy chờ không bảo đảm hủy
   xử lý phía AI hoặc hoàn quota; vẫn luôn có lối nhập thủ công.
5. Thử mất mạng khi thêm nước: app báo đang chờ máy chủ, khóa gửi lặp; kết nối
   lại rồi kiểm tra chỉ có một bản ghi. Báo cáo tuần/tra cứu Chat cần mạng để
   lấy dữ liệu mới, không coi cache cũ là số liệu vừa được server xác nhận.
6. Kiểm tra sáng/tối, chữ lớn, bàn phím và back gesture. Với tài khoản **dùng
   riêng để kiểm thử**, thử quên/đổi mật khẩu và xóa tài khoản. Xác thực lại
   trước thao tác nhạy cảm; xóa dữ liệu trước Auth, xử lý lỗi giữa chừng bằng
   thông báo/thử lại. Không thử xóa trên tài khoản có dữ liệu cần giữ.

Firebase native có cache cục bộ; đăng xuất không bảo đảm xóa byte cache khỏi
thiết bị. Chỉ xóa dữ liệu ứng dụng qua Android sau khi đã đồng bộ các ghi đang
chờ. Cấu hình Android loại dữ liệu app khỏi backup đám mây/chuyển thiết bị;
chưa kiểm thử chuyển máy trên OEM thực và không tuyên bố xóa dữ liệu an toàn.

Giai đoạn 10 đã build APK **debug**, chưa xác minh Gemini/App Check/camera trên
Android thật trong lượt này. Trước phát hành công khai cần chốt application ID,
icon, release keystore/App Signing, SHA-256 và Play Integrity, kiểm tra Rules
production theo quy trình được phê duyệt. Cấu hình ký release chưa được cung cấp;
bản debug hiện tại phục vụ phát triển/demo, chưa sẵn sàng phát hành công khai.

## Trò chuyện HealthMate (Giai đoạn 9)

**Cập nhật 25/10: API chatbot Cloudflare đã triển khai, APK debug đã gắn URL.**
Qwen lập kế hoạch đọc dữ liệu, Llama 3.3 70B trả lời tiếng Việt trong cùng dịch vụ.
Đã benchmark model thật với dữ liệu tổng hợp; native E2E xem
[báo cáo live](docs/chatbot-live-qa.md). API có Firebase JWT/App Check, kế hoạch tra
cứu giới hạn, streaming, hội thoại nhiều lượt và số liệu do app tính. Không thêm
database, không bật billing. Xem [setup API](chat-api/README.md) để đăng nhập,
triển khai lại Worker; chạy/build app với `--dart-define-from-file=config/chat-api.json`.
Không có URL thì giao diện báo chưa kết nối và giữ luồng hiện có bên dưới.
Có chế độ **Tra cứu nhật ký · không gửi AI**, không tự chuyển nhật ký sang Gemini
miễn phí khi Cloudflare lỗi/hết quota. Kết quả benchmark không đảm bảo model luôn đúng.

### Luồng hiện có khi chưa cấu hình API Cloudflare

Mở **Thêm → Trò chuyện cùng HealthMate**. Hỏi kcal/macro, nước, vận động,
cân nặng, tóm tắt ngày/tuần hoặc lượng còn lại theo mục tiêu dinh dưỡng. Hỗ trợ
ngày cụ thể, hôm nay/hôm qua, tuần này/tuần trước/7ngày; câu nối tiếp giữ cùng
phạm vi. Số liệu lấy mới từ repository, tính tại app; không coi thiếu bản ghi là0.

Theo lựa chọn giữ Gemini Developer API free tier của người dùng: AI chỉ nhận
**10 chủ đề kiến thức chung**, mỗi yêu cầu độc lập. Có thể nhập “Protein là gì?”
để app nhận diện chủ đề rồi xin đồng ý trước gửi prompt chung. Không gửi nội dung
tự nhập, dữ liệu nhật ký, hồ sơ hoặc lịch sử hội thoại tới model. Đây là phạm vi
đã điều chỉnh sau khi kiểm tra [điều khoản dịch vụ miễn phí](https://ai.google.dev/gemini-api/terms#unpaid-services);
không bật chế độ AI phân tích dữ liệu sức khỏe cá nhân. Thông báo xử lý dữ liệu
xuất hiện trước khi gửi chủ đề AI lần đầu trong mỗi lần vào Chat.

Firebase AI Logic dùng `gemini-3.5-flash-lite`, kiểm tra trong
[danh sách model chính thức](https://firebase.google.com/docs/ai-logic/models)
ngày 25/10/2026. Có thể đổi qua `--dart-define=HEALTHMATE_CHAT_MODEL=<model-được-hỗ-trợ>`;
cần kiểm tra lại model/quota khi đổi. Flash-Lite dùng thinking minimal, tối đa 2048
output tokens và 6000 ký tự. Không thêm API key riêng hay package mới.

- AI chạy trên Android có App Check hiện có; web/desktop chỉ tra cứu nhật ký.
- Có streaming, dừng nhận, lỗi mạng/hạn mức, thử lại. Dừng không bảo đảm server
  hủy xử lý hoặc hoàn lại quota. Bản AI chưa hoàn chỉnh không được lưu.
- Lưu cặp tin nhắn nguyên tử theo UID, tối đa 50 lượt/phiên; lịch sử hiển thị 20
  phiên gần nhất. Thử lại sau lỗi lưu dùng cùng ID và đáp án, không gọi AI lại.
- Khi lỗi lưu, đáp án hoàn chỉnh hiển thị nhãn chưa lưu. Rời màn hình có thể mất
  bản chưa lưu; chỉ lịch sử đã được Firestore xác nhận tồn tại khi mở lại.
- Không có listener lịch sử thường trực; tải lại bằng menu lịch sử khi cần.
- Production đã có Rules chat từ18/10 (metadata audit24/10). Rules local mới
  cho verified claim/schema dinh dưỡng/admin chưa deploy. Không đổi schema chat.
  **Lượt mở rộng không deploy Rules/indexes, không bật billing.**

Chi tiết schema, giới hạn, cách kiểm tra trên máy thật:
[`docs/chatbot.md`](docs/chatbot.md).

## Mục tiêu và nhiệm vụ hằng ngày (Giai đoạn 7)

Mở **Cá nhân → Mục tiêu và nhiệm vụ hằng ngày**. Tạo mục tiêu số bữa đã ghi,
lượng nước, phút vận động mỗi ngày hoặc cân nặng theo thời hạn. Mức do bạn tự
chọn; sửa được giá trị, thời hạn và trạng thái theo dõi. Mục tiêu định lượng
được lưu riêng với định hướng sức khỏe trong hồ sơ.

Mỗi ngày có một nhiệm vụ từ quy tắc có lý do hiển thị. Chỉ gợi ý nước/vận động
khi bạn đã chọn theo dõi nội dung đó. Hoàn thành/bỏ qua được lưu theo UID/ngày;
không có điểm phạt và không tự tạo dữ liệu nhật ký. Nhiệm vụ giữ nguyên trong
ngày kể cả khi bạn sửa mục tiêu. Tạo/cập nhật nhiệm vụ cần kết nối mạng.

Rules mới đã có trong source để kiểm thử. **Chưa deploy production**: cần
review và deploy `firestore.rules` trước khi tạo mục tiêu/nhiệm vụ trên Firebase
thật. Không cần tạo index mới, package mới hoặc dịch vụ trả phí.

## Tổng quan và Nhìn lại tuần (Giai đoạn 8)

Tổng quan hiển thị dinh dưỡng hôm nay, nước, phút vận động, số bữa, lần cân gần
nhất và tiến độ mục tiêu/nhiệm vụ đã lưu. Lỗi hoặc dữ liệu đang tải dùng dấu `—`;
ngày/múi giờ được hiển thị và đồng hồ cập nhật khi qua ngày hoặc app trở lại
foreground. Lối vào nhiệm vụ mở màn Goals/Quest hiện có.

Mở **Nhìn lại tuần** ở cuối Tổng quan để xem tuần từ Thứ Hai đến Chủ nhật, đổi
tuần trước và biểu đồ kcal/nước/phút vận động. Tổng macro, số ngày có ghi nhận,
trung bình kcal trên ngày có ghi bữa và thay đổi giữa các lần cân đều lấy từ
nhật ký thật. Biểu đồ cân nặng hiển thị tối đa 12 lần cân gần nhất trong tuần.
Ngày trống không có nghĩa là không ăn/uống/vận động; một lần cân chưa đủ để
mô tả thay đổi. Không chẩn đoán hoặc suy diễn nguyên nhân.

Báo cáo tuần là lượt đọc một lần từ server, có giờ tải và nút **Tải lại báo cáo**.
Cần mạng khi mở/làm mới; nếu một nguồn lỗi thì không hiển thị tổng thiếu. Sau
khi sửa nhật ký, mở lại hoặc tải lại báo cáo. Khi phần báo cáo đóng thì không
truy vấn tuần. Không thêm package, collection, index hoặc Rules mới.

## Nghiệm thu Android core bằng backend local (C6)

`integration_test/core_acceptance_test.dart` mở UI thật với Firebase repositories
thật, dùng named Firebase app `healthmate-core-c6-qa` và project cố định
`demo-healthmate-rules`. Không gọi main/bootstrap production, không dùng tài khoản
thật và không gọi AI. Có driver lưu PNG tại `build/c6-android` và checkpoint log.
Script chỉ chấp nhận AVD riêng tên **HealthMateMaintenanceQA**, từ chối điện thoại
và AVD khác. Auth/Firestore Emulator dùng cổng9099/8080, Android truy cập10.0.2.2.

```powershell
# Khởi động AVD QA riêng đã cài SDK/image; lấy serial từ flutter devices.
$env:TEMP = 'D:\HealthMateMaintenanceQA\tmp'
$env:TMP = $env:TEMP
.\tool\test_android_core.ps1 -DeviceId emulator-5560
```

Nếu project và pub cache ở hai ổ Windows khác nhau, thêm `-CrossDriveBuild`.
Script tạm đặt `kotlin.incremental=false` trong phiên build và khôi phục bytes
của gradle.properties cùng biến môi trường khi kết thúc, không sửa setting toàn
máy. Cần Flutter, Android SDK/AVD, Java21 và Firebase CLI đã có; không cần billing
hoặc Firebase production để chạy bài này. Debug manifest chỉ cho HTTP trên
10.0.2.2/127.0.0.1/localhost; release không có cấu hình debug này.

Trên máy hiện tại C ít dung lượng nên bản sao QA/build ở
`D:\HealthMateMaintenanceQA\c6-workspace`; source chính vẫn ở repository gốc.
Khi dùng bản sao phải đồng bộ thay đổi và đối chiếu hash source trước nghiệm thu;
không lấy một bản checkout cũ thiếu working tree C1–C5. Không copy build/.git/cache
hoặc xóa app có dữ liệu thật để thử nghiệm. APK integration test dùng riêng cho
AVD, không dùng nó làm APK bàn giao; build bình thường với `--target lib/main.dart`.

Luồng E2E: đăng ký/onboarding → mục tiêu và ngày cũ → bữa/gram/copy ngày khác →
nước/vận động/cân nặng → tuần → món riêng/công thức/khẩu phần → sửa/xóa nguồn,
MealLog vẫn giữ snapshot → offline/draft/retry → sáng/tối/chữ lớn → logout/UID B.
Rules/SDK và cleanup A/B chạy riêng bằng `tool/test_emulators.ps1`; không chạy
hai script cùng lúc vì cùng dùng project/cổng emulator. Chi tiết kết quả thực tế,
ảnh, APK, giới hạn production và thiết bị trong docs/test-report.md phần C6.

## Tài liệu đã đối chiếu

### Báo lỗi, góp ý và hỗ trợ khách hàng (30/10/2026)

Trong app: **Cá nhân → Báo lỗi & Góp ý**, gửi yêu cầu mới rồi mở lại để xem
phản hồi hoặc bổ sung thông tin. Trên [web admin](https://healthmate-admin-vn.web.app):
**Hỗ trợ khách hàng → Xem & trả lời**, lọc loại/trạng thái và cập nhật xử lý.
Phản hồi hiển thị trong app; chưa có email/push hay ảnh đính kèm. Khách chỉ xem
yêu cầu của mình; yêu cầu/tin nhắn hỗ trợ được xóa khi xóa tài khoản trong app.

APK mới: `build/releases/healthmate-support-debug.apk` (giữ Premium demo).
Chi tiết dữ liệu, giới hạn và kiểm thử:
[customer-support-2026-10-30.md](docs/customer-support-2026-10-30.md).

### Premium demo và báo cáo doanh thu (30/10/2026)

Web quản trị online: **https://healthmate-admin-vn.web.app**. Mở trực tiếp trên
trình duyệt, không cần VS Code/server local. Đăng nhập bằng tài khoản admin đã
cấp; link cũ vẫn hoạt động, dữ liệu dùng chung trong Firebase project hiện có.

Gói mô phỏng **20.000đ/30 ngày**, không thu tiền/không tự gia hạn. Miễn phí:
3 lượt quét ảnh và 5 câu hỏi AI/ngày; Premium demo: 20 và 50 lượt. Đặt lại
lúc 00:00 giờ Việt Nam. Nhật ký và tra cứu local không dùng lượt AI.
Vào **Cá nhân → Premium** trên APK có bật demo; admin có mục **Doanh thu**,
lọc ngày, tổng hợp ngày và Excel đều ghi rõ doanh thu mô phỏng.

Build riêng: `.\tool\build_android.ps1 -PremiumDemo`, tạo
`build/releases/healthmate-premium-demo-debug.apk` và manifest JSON.
Cờ `HEALTHMATE_ENABLE_PREMIUM_DEMO` mặc định false. Đã triển khai Rules và
trang Doanh thu ngày 30/10/2026 lên Firebase hiện có; cài APK demo mới để dùng.
Giới hạn này không nâng quota nhà cung cấp AI và chưa chống client bị sửa.
Quy trình, dữ liệu, lưu giữ sau xóa tài khoản và trạng thái triển khai:
[docs/premium-demo-2026-10-30.md](docs/premium-demo-2026-10-30.md).

- [Firestore range queries](https://firebase.google.com/docs/firestore/query-data/queries)
- [fl_chart BarChartData](https://pub.dev/documentation/fl_chart/latest/fl_chart/BarChartData-class.html)

- [Flutter internationalization](https://docs.flutter.dev/ui/internationalization)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- [go_router](https://pub.dev/packages/go_router)
- [Cupertino icon font](https://pub.dev/packages/cupertino_icons)
- [Add Firebase to Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication for Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore for Flutter](https://firebase.google.com/docs/firestore/quickstart)
- [Firestore Security Rules fields](https://firebase.google.com/docs/firestore/security/rules-fields)
- [Test Firestore Security Rules](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Firebase AI Logic for Flutter](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter)
- [Firebase AI Logic supported models](https://firebase.google.com/docs/ai-logic/models?api=dev)
- [Firebase App Check for Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [USDA FoodData Central](https://fdc.nal.usda.gov/)
