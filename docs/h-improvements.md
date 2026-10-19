# Cải thiện H0–H7 — nhật ký thực hiện

Yêu cầu trực tiếp ngày 19/10/2026: thực hiện tuần tự H0 tới H7 theo file
`C:\Users\LEGION\Downloads\cải thiện`. Yêu cầu này chọn cả chuỗi, thay cho mẫu
“mỗi lượt một giai đoạn” trong file; vẫn kiểm thử và ghi mốc riêng, không tự deploy,
import production, commit/push hoặc đổi cấu hình Firebase.

Base main/1c258b37366d47ef562eed65f326e490efabae99, working tree sạch khi bắt đầu.
Không tìm thấy báo cáo HealthMate-vs-MyFitnessPal trong workspace/Downloads;
đã dùng baseline trong file và kiểm tra code thật. AI vẫn tắt.

Hạn mức 5 giờ còn 80% lúc bắt đầu, 76% sau kiểm tra H0; sẽ kiểm tra ở các mốc.
Nếu còn dưới 5%, hoàn tất điểm đang sửa đến trạng thái an toàn, lưu tiến độ và
tắt laptop theo yêu cầu; không tuyên bố các phần chưa làm là hoàn thành.

## H0 — đạt local/Android emulator

- Selector bản ghi mới loại sourceId và recipeMeal.id, giữ singleWhere; assert
  đủ 3 ID độc lập, breakfast/ngày/200g/260kcal. Fixture chọn recipe breakfast qua
  UI nên luôn tồn tại ít nhất hai breakfast, không phụ thuộc giờ hệ điều hành.
- Release bỏ fallback debug signing; private android/key.properties (ignore),
  task release thiếu cấu hình báo lỗi, debug vẫn build. Chưa tạo key/đổi package.
- Format 1 file 0 thay đổi; analyze sạch 33,8 giây; Flutter 370/370, 56 giây.
- `tool/test_android_core.ps1 -DeviceId emulator-5580 -CrossDriveBuild` trên QA
  copy D, AVD HealthMateMaintenanceQA/API30, Auth/Firestore demo-healthmate-rules:
  đủ 10 checkpoint và viewport/Gần đây, pass 159 giây; debug assemble 42,7 giây.
- `gradlew :app:assembleRelease --dry-run --offline`: bị chặn đúng thông báo
  thiếu signing (kết quả mong đợi), không có release build/signed APK.
- Log D:\HealthMateMaintenanceQA\h0-android.log và h0-release-guard.log;
  unit/analyze ở build/h0-*.log. Ảnh native ở QA copy build/c6-android.
- KGP và SwiftShader/Impeller warnings còn; không suy ra mọi GPU/máy thật đạt.
  [Rủi ro phát hành và cấu hình cần chủ sở hữu](release-readiness.md).

Tiếp theo: H1. H2–H7 chưa thực hiện tại mốc này.

## H1 — 19/10/2026: khẩu phần catalog, tìm kiếm và dữ liệu có nguồn

Hoàn thành code/data review, chưa import production. Reader khẩu phần tương thích
cũ, fallback gram khi metadata hỏng, không dùng basis/unit không hỗ trợ. Đổi đơn vị
giữ lượng, phần phân số preview/snapshot đúng. Tìm exact/alias/token trước substring;
giữ tìm dấu/không dấu/NFD. Ba dòng TH yogurt100g có nguồn nhà sản xuất;47 công thức
đề xuất phần tham khảo theo yield, không coi tô=100g. docs/h1-catalog-review.md.
Node9/9; Flutter379/379 (42s), focused51/51, H1 cuối9/9; analyze sạch9,6s.
Rules47/47 + SDK15/15 (21s); import emulator151create, retry0create/update/conflict.
Fixture import ban đầu bỏ pagination và fail; diagnostic xác định vn2007-9007,
sửa đọc nextPageToken rồi đạt. Benchmark tool đầu5lint imports/braces đã sửa.
Android QA emulator-5580/API30/demo-healthmate-rules đủ10checkpoint pass154s;
phần0,75 ×200g lưu150g/195kcal qua repository thật. Ảnh docs/ux/h1/catalog-fractional-portion.png
đã xem; benchmark19truy vấn có nhóm held-out/brand/missing,15positive+4rỗng có chủ đích,
19đúng first/empty, giữ và báo kết quả nhiễu. Dataset branch151 khác production158.
Dry-run production: existing158/create3/skip148/proposedMetadataUpdates47/conflict0;
manifest/benchmark ở docs/ux/h1. Tool --apply chỉcreate, metadataupdates cần review/
maintenance riêng. Không đổi Rules/index/schema nhật ký hoặc deploy/AI/billing.
Chưa máy thật/release ký. Hạn mức5h còn60%; chuyển H2 theo yêu cầu chuỗi.

## H2 — 19/10/2026: ghi quen nhanh và bữa mẫu, đạt local/emulator

Recent ưu tiên khi có lịch sử, tài khoản mới về Tìm món; dùng trực tiếp lượng
hiển thị vào bản nháp, Hoàn tác/Sửa riêng, Lưu mới ghi server. Hay dùng đếm theo
20 bản ghi gần nhất/tối đa8 món, không tải toàn lịch sử. Cùng fixture/điểm bắt
đầu đo3tap/0scroll/0gõ/0xác nhận lượng thay cho5tap; đúng ngày/bữa/gram/snapshot.
Bữa mẫu thuộc UID, CRUD tên+1–5snapshot, tạo từ bữa cũ/món đang chọn, dùng bản sao
vào ngày/bữa chọn và sửa từng món. Không gộp thành recipe, nguồn mất vẫn giữ lịch
sử. Cleanup client mới thêm meal_templates; cần nâng client trước enable backend
để client cũ không bỏ sót collection mới khi xóa tài khoản.
Format20file0đổi; analyze sạch11,4s; Flutter385/385 pass52s; targeted6/6 (UID+
pending/retry/bounds/widget100/150/200%). Rules48/48 + SDK16/16 pass25s; test A/B,
guest,5món/overflow/timestamps, offline/retry snapshot và cleanup A giữ B.
Rules đầu vượt1000expressions khi5món; dùng regex/let/sum bounded giữ đủ validation
rồi focused/full pass. UI test đầu chưa prewarm Auth làm dialog đóng, sau đó
x2 chữ dài đẩy ô tên khỏi lazy viewport: sửa harness auth và đưa tên lên trước
hướng dẫn ngắn; cuối6pass. UID test cần giữ subscription Auth trước await.future;
đã sửa và full385pass. Không bỏ assertion hoặc nới Rules lấy pass.
Android final: emulator-5580/HealthMateMaintenanceQA/API30/demo-healthmate-rules,
10checkpoint +H1portion/H2recent vàtemplate UI pass176s. Tạo mẫu2món từ draft,
hủy không log; dùng/chỉnh100g +20grecipe nguồn đã xóa =180kcal đúng ngày/Bữa tối;
xóa mẫu không đổi meal; logoutBriêng tư. Ảnh/flow ở docs/ux/h2.
Lượt Android đầu cần reveal trường lazy sau bố cục mới; lượt sau dùng Rules cũ
trong QA copy nên lưu bị từ chối. Thêm tool/sync_qa_workspace.ps1 đối chiếu241
source/config/asset gồm root Rules rồi final pass. Không deploy production để
sửa lỗi QA copy. Raw logs D:\HealthMateMaintenanceQA\h2-android*.log.
Schema/Rules/rollback và client compatibility trong h2-templates-deployment.md;
local Rules mới chưa deploy, catalog H1 mới chưa import. Không commit/push/AI/billing.
H3–H7 chưa triển khai tại mốc H2; tiếp tục tuần tự theo yêu cầu, còn40% hạn mức5h
ở lần kiểm tra trước Android final.

## H3 checkpoint 19/10/2026 — code/Rules/SDK đạt, Android đang chạy

Chi tiết hành vi, file, schema/rollout, log và các vòng lỗi/sửa trong
[H3 Quick Add](h3-quick-add.md). Ghi100g/100ml/khẩu phần/tổng, kcal-only/macro
optional, unknown khác0; nhật ký/copy/template/history dùng snapshot.
Format32file; analyze sạch9.8s; fullFlutter397/397(52s),focusedcuối13/13(4s);
Rules49/49(13.2s),SDK17/17(23s), importerEmulator151/0retrychanges.
Android H3 đang chạyQA AVDemulator-5580/demo-healthmate-rules, chưa kết luận đạt.
Production chưa ghi/import/deploy, Git chưacommit/push. H4–H7 chưa triển khai.
Hạn mức5h còn7% lần kiểm tra gần nhất; sẽ theo yêu cầu dừng/lưu/tắt máy khi<5%.

### H3 cập nhật kiểm chứng cuối

FullFlutter398/398(56s), analyze sạch10.2s sau fix UI, focused13/13(3s),
Rules49/49(13.5s), SDK17/17(23s). AndroidH3đủ10checkpoint pass206s; hiện chạy
lần cuối sau cải thiện spacing/helper/snackbar từ ảnh kiểm tra. Chi tiết cả lần
lỗi và sửa trong h3-quick-add.md. Hạn mức5h đã<5%(còn4%); chốtH3/dừngH4–H7,
lưu tiến độ và tắt laptop theo yêu cầu. Không commit/push/deploy/importproduction.

### H3 đạt; tiếp tục theo yêu cầu mới sau khi hạn mức reset

Android visual-final đạt200s, đủ10checkpoint/H2templates/H3QuickAdd. Đã xem ảnh
volume-preview mới: khoảng cách/hướng dẫn rõ và không còn snackbar cũ che form.
Nguồn243fileQAđối chiếu. H3 hoàn tất local/Emulator; chưa nghiệm thu production.
Người dùng gửi “tiếp tục đi” sau khoảng nghỉ; kiểm tra mới: hạn mức5h used0%,
còn100%. Chưa có lệnh shutdown nào được thực thi/lập lịch. Tiếp tục H4–H7 theo
lệnh mới, vẫn theo dõi điều kiện<5% và tắt máy ở cuối chuỗi hoặc tại ngưỡng đó.
Các mục “Android đang chạy” ở trên là checkpoint lịch sử, đã có kết quả cuối này.

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

## H5 — đạt local/Emulator

Báo cáo30/90, giữtuầncũ; mụctiêuđúnghiệulực; trạngtháixácnhậnđủbữa theoUID+
ngày+revision, không tự coi1bữa làđủ. Ngàytrống khônglà0kcalđãăn; macrothiếu giữ
coverage. Range2001sentinel/chặn>2000doc mỗiquery,1–90ngày; lỗi nguồn riêng,
refresh rõ, không thêmrealtime. Cân hiển thịđiểmthật/khoảngcáchthời gian/sốmẫu.
File/schema/rollout và lỗi đãsửa trongh5-period-reports.md. Cleanupday_reviews,
Rulesmớiđãtestnhưngchưadeploy, khôngindexmới/migration/AI/importproduction.
Focused53/53(19s); H5+UID11/11(13s), full417/417(122s) trước thêmtestUIDcuối;
analyze sạch39s. Rules50/50 vàSDK18/18(31s), kểcả2.001waterfixturebịbáooverflow,
xáoriêngfixturetrongfinally. NativeAndroid227s/10checkpoint+H1–H5đạttrênAVDQA/
demo-healthmate-rules: UIxácnhậnngày,30/90tổngkhớpSDK,1ngàyxácnhận, khoảngcũ
trống/next/trởvềvàBriêngtư. Ảnhdocs/ux/h5/period-30.png. Khôngcommit/push/deploy.
Tiếp theoH6; H7chưatriểnkhai. Hạnmức5h lần gầnnhất còn66%, tiếptụctheodõi.


## H6 — đạt local/Emulator, chưa triển khai production

Thêm chất xơ có nguồn, phân biệt 0 thật/thiếu/tổng biết một phần; giữ coverage khi
nhân khẩu phần, recipe yield, snapshot, sửa/copy/bữa mẫu và báo cáo. Nguồn 4 ID
USDA có sẵn; branch 155 mục, production dry-run 158 đang có/3 create/51 metadata/
0 conflict/152 skip, không apply. Hợp đồng meal4, custom/recipe2, template3,
chống hạ phiên bản và rollout/rollback xem h6-fiber.md và database-design.md.
File chính: nutrition_models/catalog_food_reader, firebase_nutrition_repository,
food_library models/forms/text/repository, quick_add_dialog, meal_templates,
journal/weekly summary, firestore.rules, legacy_usda.json, importer và tests.
Format 59 file/0 đổi ở kiểm tra cuối; analyze sạch (62.1s); Flutter423/423(67s);
unit H6 mới nhất5/5 sau thêm assert round-trip. Rules51/51, importer Emulator155
create/retry0change, Firebase Flutter Web SDK19/19(43s), gồm thiếu nguồn, retry,
A/B, cleanup và H5 overflow2.001rows. Android QA API30/emulator-5580 +
demo-healthmate-rules: 10checkpoint và H1–H6 đạt239s; 250ml/100ml ->3g, nguồn
recipe đã xóa nhưng bữa cũ vẫn0.5g, B riêng tư. Lượt native đầu221s thất bại do
assert nhầm recipe một nguyên liệu biết chất xơ thành thiếu; sửa kỳ vọng và đọc
lại bản ghi thật rồi chạy lại. Các lỗi Rules/codec phát triển ghi ở h6-fiber.md.
Ảnh h6/fiber-volume.png và ảnh H5 mới đã xem: nút xác nhận rõ, preview3g,
macro thiếu không thành0, nội dung báo cáo có thể cuộn. Còn cảnh báo KGP/
SwiftShader/Impeller cũ; cần xem thêm máy thật. Không commit/push/deploy/index/
import production/AI. H6 hoàn thành; tiếp H7 theo yêu cầu, theo dõi ngưỡng5%.


## H7 — checkpoint chưa hoàn thành, dừng do hạn mức còn 4%

Đã chốt lõi CSV thuần journal_csv.dart + test/h7_csv_test.dart:4/4 qua; định dạng
UTF-8 BOM/CRLF/quote, chặn formula injection, range1–90 ngày, dateKey/UTC/offset/
schema và missing/0/partial. Chưa nối UI/controller/file picker hoặc quyền UID
cho export; chưa lưu/phục hồi draft bền vững. Không gọi đây là H7 hoàn chỉnh.
Format2file; analyze lượt đầu1lint thiếu ngoặc, đã sửa; lượt cuối xem log và
h7-checkpoint.md. Không chạy lại toàn bộ suite sau4test mới; fullH6 trước đó423/423,
Rules51/51, SDK19/19, Android239s/10checkpoint+H1–H6 đã đạt. H7 chưa testAndroid.
Không có package/collection/Rules/index/localstorage mới cho H7, không production
write/commit/push. Còn lại và hướng nối tiếp ghi rõ h7-checkpoint.md. Theo chỉ thị
người dùng, lưu checkpoint và tắt máy bình thường sau khi chốt phần CSV này.


Chốt checkpoint H7: analyze cuối sạch (11.5s), format2file; CSV4/4. Bản sao323file nguồn/tài liệu và log nằm ở D:/HealthMateMaintenanceQA/h0-h6-h7-checkpoint-20261019; patchtracked riêng h0-h6-h7-working-tree.patch. H7 còn thiếu đúng như danh sách trên, không công bố hoàn tất.

## H7 — hoàn thành local/Android Emulator sau khi tiếp tục

Tiếp tục từ checkpoint 4% sau khi cửa sổ 5 giờ reset; H0–H6 và toàn bộ thay đổi
chưa commit được giữ. H7 hoàn thành, không tự chuyển mốc khác. Hạn mức được đọc
ở các mốc; không cần dùng lý do hạn mức để bỏ phần nghiệm thu còn lại.

- Android giữ nháp mã hóa AES-256/GCM, khóa AndroidKeyStore và AtomicFile trong
  noBackupFilesDir. UID/ngày/bữa, snapshot nguồn, unit, missing/0/partial, UTC,
  offset, operationId và minimum schema giữ xuyên restart. Tối đa20nháp/512KiB,
  TTL7ngày, dọn khi mở kho; khôi phục/bỏ nháp do người dùng chọn, không tự submit.
- Mọi entry point MealFormDialog nối cùng kho. Lưu operationId+payload local
  trước gửi Firestore; chỉ dọn sau ack. Gián đoạn có thể vẫn commit; retry giữ
  ID cũ, không mặc định lỗi Future đồng nghĩa chưa có bản ghi máy chủ.
- Cá nhân có Xuất nhật ký CSV, ngày1–90, bốn nguồn nhật ký/cân nặng, query giới
  hạn H5; không export profile/chat/goals/draft và không gọi đây là toàn bộ account.
  CSV BOM/CRLF/quote/chặn công thức, schema/đơn vị/timezone/basis và nutrient status.
  Consent riêng tư, Android document picker, kiểm tra UID trực tiếp SDK và phiên
  trước ghi bytes, native đọc lại khớp mới báo thành công. Không email/upload tự động.
- Xóa tài khoản dọn nháp đúng UID sau Firestore/trước Auth; lỗi giữa chừng giữ Auth
  cho retry, chặn callback trễ ghi lại. Không xóa B hoặc CSV người dùng đã xuất.
- Sửa hai guard ref.mounted ở userProfileProvider/bodyMetricsProvider: lỗi cũ được
  native H7 phát hiện khi đổi UID lúc bootstrap, trực tiếp chặn nghiệm thu A/B.
  Không refactor toàn bộ profile; regression có completer theo sự kiện thực.

File chính: core/data/private_local_data.dart; Android PrivateLocalData.kt và
MainActivity.kt; meal_drafts/data/meal_draft_store.dart, presentation/draft_picker.dart;
MealFormDialog, JournalScreen, MealDraft; data_export/models/journal_csv.dart,
data/journal_export_service.dart, presentation/journal_export_dialog.dart;
ProfileScreen, auth repository/currentUid và controller cleanup; profile_providers;
test/h7_csv_test.dart, h7_private_data_test.dart; integration_test/h7_private_data_test.dart;
tool/test_h7_android.ps1 và verify_h7_export.ps1. Đường dẫn/contract đầy đủ:
[h7-private-data.md](h7-private-data.md), ảnh và chứng cứ [ux/h7](ux/h7/README.md).

Kiểm tra cuối (19/10/2026):
- flutter test --no-pub: **454/454 qua, 43s**, build/h7-flutter-final-6.log.
- flutter analyze --no-pub: **No issues found, 17.4s**, build/h7-analyze-final-5.log.
- Native QA: **phase1 12s + phase2 32s, exit0**; D:/HealthMateMaintenanceQA/h7-android-final.log
  và c6-workspace/build/h7-android/phase-1.log, phase-2.log. Process death/restore,
  offline/uncertain commit/retry, OS picker/file readback, UID switch và A/B cleanup đều qua.
- tool/verify_h7_export.ps1: **file Downloads1554byte khớp từng byte** với CSV từ
  repository thật; BOM và đủ bốn loại dữ liệu. build/h7-export-final.log.
- H7 không sửa Rules/indexes. Bộ Rules51/51, Web SDK19/19 và native H0–H6 trước đó
  vẫn là kết quả lịch sử đã ghi, không giả là vừa chạy lại các suite đó trong H7.

Các lượt phát triển thất bại được giữ log: lỗi dùng navigator context của màn
thay dialog; thêm nút export làm test vị trí metric cần sửa layout; lỗi provider
đã disposed (đã thêm guard); runner Windows ExitCode/file sharing và chờ frame
khi OS picker mở (sửa harness). Một kỳ vọng offline=0 sau reconnect không đúng
hợp đồng acknowledgement; giữ assert chưa tự gửi trước Lưu, sau retry đúng một
ID trên server. Bài regression đầu có chờ theo thời gian bị flaky; đổi sang
completer/sự kiện bootstrap, full suite452qua. Script đọc CSV ban đầu quote sai
đường dẫn có khoảng trắng qua exec-out; đã sửa và đối chiếu byte thật, không bỏ assert.

Không thêm package, collection, Rules/index hoặc migration H7. Không commit/push,
không deploy Firebase/import production, không bật AI/billing hoặc sửa package ID.
Production vẫn cần review/ủy quyền rollout Rules/schema H2–H6 và catalog manifest
riêng; APK E2E trỏ demo không phải APK phát hành. Web/desktop chưa có nháp bền vững
hoặc lưu CSV; local không đồng bộ nhiều thiết bị, không xóa được bản sao offline
trên thiết bị khác, file CSV do người dùng quản lý. Cần QA điện thoại thật và cấu
hình release/signing còn thiếu như release-readiness.md. Đề xuất tiếp theo: review
rollout và kiểm tra máy thật; **không triển khai** trong lượt này.

Đóng kiểm tra: dart format --output=none --set-exit-if-changed trên toàn bộ76file
Dart thay đổi: 0file cần format, exit0. git diff --check với cr-at-eol phù hợp
Windows: exit0; không thay line ending hàng loạt. HEAD vẫn
1c258b37366d47ef562eed65f326e490efabae99, không stage/commit/push. Ảnh export đã xem
và lưu docs/ux/h7/export-android.png. Chỉ định tiếp theo là review/máy thật, không
chạy thêm giai đoạn hoặc deploy. Sau khi sao lưu, tắt máy bình thường theo chỉ thị
người dùng; không dùng /f để ép mất tài liệu đang mở.

Bổ sung chốt hồi quy H7 trên bố cục cuối:
- Android core H0–H6: 221s, đủ10checkpoint và H1–H6, exit0;
  D:/HealthMateMaintenanceQA/h7-core-regression-3.log. Recent vẫn3tap; U1 kiểm tra
  vùng bấm thêm bữa trong viewport đầu thật. Hai thao tác hủy hẳn trong fixture
  dùng Bỏ bản nháp để phù hợp UX H7, không bỏ các assert dữ liệu/ngày/snapshot.
- Lượt core đầu phát hiện nút nháp riêng đẩy nút thêm bữa xuống: chuyển thành icon
  cạnh Bữa ăn. Lượt sau cho thấy nút bỏ nháp trong body khó truy cập khi cuộn:
  đưa lên AppBar, chống bấm lặp. Test360/chữ2/tối phát hiện dropdown bữa tràn1.2px;
  isExpanded xử lý đúng, không giảm cỡ chữ/ẩn lỗi. Test xóa nháp lỗi rồi retry và
  xóa account lỗi server/local giữ Auth, giữ UID B đã bổ sung; full cuối454/454.
- H7 native chạy lại trên bố cục cuối:12s/32s, exit0. Đọc lại file Downloads thật
  sau lượt cuối vẫn1554byte khớp từng byte. Không dùng ảnh cũ để kết luận UI mới;
  ảnh journal-android.png lấy từ core lượt đã qua, đã kiểm tra bằng mắt.

Bản sao cuối gồm nguồn/tài liệu chưa commit và log kiểm chứng: D:\HealthMateMaintenanceQA\h0-h7-complete-20261019-191713. Hạn mức được kiểm tra trước tắt máy; không đợi xuống dưới5% vì công việc đã hoàn tất.
