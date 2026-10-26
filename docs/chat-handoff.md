# Bàn giao sang chat mới — HealthMate

## Yêu cầu mới nhất 26/10 — Đưa code lên GitHub và đề xuất giao diện

Người dùng đã yêu cầu commit/push toàn bộ code hiện có lên GitHub. Yêu cầu này
thay thế các chỉ dẫn lịch sử “không commit/push” bên dưới cho đợt xuất bản này.
Giữ toàn bộ thay đổi; loại trừ secret, thư mục dependency, log và APK khỏi Git.
Không triển khai Firebase/Cloudflare hoặc cài điện thoại trong đợt này.

Đề xuất avatar hồ sơ góc trái trên; năm mục Hôm nay, Dinh dưỡng, Tập luyện,
Tiến độ, Trợ lý và nút thêm riêng. Chưa sửa UI hoặc triển khai bài tập có hướng dẫn.
Chi tiết ở [ui-navigation-proposal.md](ui-navigation-proposal.md).
Bản chụp Rules MVP đã xác minh được lưu ở `deploy/`, không bật lại admin.
Kết quả test sản phẩm bên dưới thuộc đợt trước; đợt push chỉ kiểm tra nguồn và Git.
Không lặp lại shutdown từ yêu cầu cũ.

## Ưu tiên mới nhất26/10 — mục2/3/4 đã viết, test và deployRules, chưa cài phone

User yêu cầu “bây h làm2 3 4đi”: estimate bước/calo, progressgiảm cân, sleepstats/
goal/reminder. Không phải tự khởi động lại step service. Cả3đã triển khai cùng đợt,
không quaylạiadmin hoặc shutdown. Defaultnoenergycredit; calibrationstride người
dùngtựđo, weight≤90ngày, baseline bước đãtính tronggoal; xácnhậncreditchỉhômnay.
Target/food/macro gốc khôngđổi. Activitynhậptayhoặcgoalđổithìcreditkhôngápdụng.
Dashboard/Journal/chat dùngcùngDailyEnergyBudget. Sleep7/30daysmergeoverlap,
daywake/unknown/circularbedtime/goalselfset; nativebedtimenotifUIDprivate.
Progress7/30/90daysweighttrend+weeklyavg/mealcov/budget vàstephistorymax30.

Fullcuối608/608,82s; analyze cuối0issues,49,2s;SDK73Rules+23testqua;
candidate64/64,nativefinal51s+teardownqua. Native6000stepfixturekhôngphảisensor
(AVDkhôngcósensorvàbáođúng). Headerselectedtabdeeplinkđãtựcuộnvisible.
Ruleschỉthêm2privatecollectionswellness_preferences/energy_adjustments,đãdeploy
projecthealthmate-app-20261013,readbackhash6a1762dd899ebdac732a9d55e4c4444a27e06a584c1fad982e36088f7108c374,
rulesete0057d3e-f72e-405c-b50c-cd5063e25c6c,releaseUTC2026-10-26T09:55:44.532520Z.
Before/predeploy/after ởbuild/wellness-insights-*-20261026;candidate riêngbuild/
wellness-insights-production-candidate. Không đổiadmin/index/model/billing/data.
Logsbuild/wellness-234-*,native/ảnhbuild/wellness-insights-android.
APK mớibuild/releases/healthmate-wellness-insights-debug.apk,khôngphảiintegration.
236693862bytes,SHA256231C2BF1E4529185B3273AF38F3C6D1D2F67866FEE4B4DB93715F66E2B3429CD.
Format34file0thayđổi;diffcheckqua;sourceaudit438file0patternfindings.
Userđãchọnkếtnốisau;chưaADBinstall/chưatestphoneproduction/sensor/calorieaccuracy.
Tiếptheo chỉcàiđè giữdata vànghiệmthuphonekhikếtnối, khôngtựlàmtiếpfeature.
[Báo cáo đầy đủ](wellness-insights.md). Giữtoànbộdirtytree;khôngpush/commit/reset.

## Ưu tiên mới nhất26/10 — user đã yêu cầu rollout mục1, Firebase đã xong

User nói “làm mục1 đi” (deployRulesMVP + cài/QAphone), rồi chọn “Tôi sẽ kết nối sau”.
Đã đọc baseline mới, hash873887eb… vẫn khớp; backup tại
build/wellness-rollout-before-20261026. Chạy lạicandidate61/61,19,7s,exit0.
Deploy chỉfirestore:rules từbuild/wellness-production-candidate/firebase.json,
không deploywholelocal/admin/index/billing/data. Compilerqua,1warningunusedknownNumber.
Đọc lại serverhash2bb6a4a230da4d516cb757c564944782924e875ff9cc1f3b7397951773d59f62
khớp candidate; ruleset8add3549-ea41-4a5d-9f5c-22d1b62808cc,
releaseUTC2026-10-26T08:53:38.991581Z. Afterbackup tạibuild/wellness-rollout-after-20261026.
APKgiữ nguyênhash0B3A90… ởbuild/releases/healthmate-wellness-debug.apk; manifestđúng
package/MainActivity/quyền sensor+notification/healthFGS. Không sửaDart/Kotlin,
khôngbuildlạihoặc nhận597/70/22 làtestvừachạylại. Không cài vì không códevice.

Chờ userkết nối lại rồiadb install -rgiữdata, test30–50bước/cảm biếnquyền/thaytab,
ngủ/dậy/sửagiờ/lưu/mởlại, thựcđơn/notification. Chưa testappFirebaseproduction
hoặc bước thật; không nói toàn bộmục1hoàn tất. Không triển khai mục2(kcal),
không commit/push/resetdirty/admin, không lặp lại shutdownyêucầucũ.
[Báo cáo rollout và checklist](wellness-rollout.md).

## Lịch sử trước rollout26/10 — đợt mở rộng 6 tính năng, đã lưu source/APK và kiểm thử

User yêu cầu làm nhắc bữa → cải thiện món Việt/khẩu phần → mở rộng dưỡng chất
→ lập thực đơn, thêm bước chân và giờ ngủ. Đây là yêu cầu mở rộng chủ động,
không dừng ở riêng nhắc bữa. User đã chọn ngủ/dậy thủ công, sửa giờ/lịch sử.
Sau đó user yêu cầu khi hoàn tất thì tự tắt laptop; đã xác nhận sẽ làm sau
khi code/test/báo cáo hoàn tất. Lệnh shutdown thường sẽ được gửi cuối lượt sau
khi mọi file đã lưu; không force đóng app. Không tự lặp lại shutdown ở phiên sau.
Source đã qua analyze0, Flutter597, Rules70, SDK22, catalog10, candidateMVP61;
native Android25giây+teardown qua notification/cache/ngủ/thực đơn/dưỡng chất/UID.
Fix thật: catalog autoDispose khiến editor chờ mãi và async* Ref đã dispose khi
đổi UID; native round3 qua. Đã tạo APK thường cóchat/debugAppCheck cục bộ tại
build/releases/healthmate-wellness-debug.apk,236630807bytes,SHA256
0B3A90A09D48F1ED6D76AC0926DB034656E953E0D609D3C4B9545616EDFCF84F.
Không cài điện thoại. Log/5ảnh native ởbuild/wellness-android, báo cáo đủ tại
[wellness-expansion.md](wellness-expansion.md).

Production Rules chưa deploy: 4collection mới và nutrient snapshots chỉ đã thử
Emulator. Candidate không admin ởbuild/wellness-production-candidate, hash
2bb6a4a230da4d516cb757c564944782924e875ff9cc1f3b7397951773d59f62,61ca qua.
Không ghi đè build/stage10-production-candidate (baseline cũ đã kiểm thử52ca).
Tiếp theo cần duyệt rolloutMVP/đọc lại baseline rồi nghiệm thu trên điện thoại.
Không reset dirty tree, không push/commit, không bật lại admin/billing.
Không tuyên bố bước chân chính xác hoặc permissionAndroid13+ đã thử: AVDAPI30
không có sensor, app báo không hỗ trợ. Kế hoạch gợi ý chưa cá nhân hóa.

## Mới nhất 25–26/10/2026 — Giai đoạn 10 theo yêu cầu

Ưu tiên phần này và [báo cáo bảo mật](stage10-security-review.md) hơn lịch sử.
Đã kiểm thử/sửa parser USDA nested nutrients, unknown/zero, cache SQLite public
v2, tránh log query/exception, admin role local phải verified. Không bật admin,
không đổi provider/model/quota/billing, không thêm package, không commit/push.
Bảo toàn các thay đổi auth/scanner/admin/chat đang có trước đợt này.

Full Flutter584/584, analyze0issues; localRules52MVP+9admin, SDK19/19, AuthOOB1/1;
MVPcandidate52/52, Worker21/21/check/audit0 và Rules deps audit0. Native core
đã cập nhật thao tác disclosure/tab/date; runner C6/H7 truyền explicit false cho
AI và guard từ chối nếu thiếu cờ. Kết quả cuối native xem báo cáo, không nhận
các lượt lỗi fixture là đã qua. Không thử AI trên backend thật ở đợt này.

Native cuối: C6 round7 qua cacheSQLite+10checkpoint,4phút13giây,exit0. H7 hai pha
qua17giây/44giây vớiforce-stop thật, durable encrypted draft, offline/retry,
AndroidSAF CSV/readback, UIDswitch export rejection và dọn dữ liệu đúngUID.
Log ởD:/HealthMateMaintenanceQA/stage10-android-round7.log vàstage10-h7-android-final.log,
có bản sao trongbuild/stage10-android. QAAVD được dừng sau kiểm thử, giữ artifact.
Format11file scopequa; fullformatcheck271file có12file ngoài scope lệchformat,
--output=none không sửa; diffcheckqua. Sourceaudit406file,0patternfindings.

APK mới `build/releases/healthmate-stage10-debug.apk`,236.547.388bytes,SHA256
`7EC5FCD80B9CD67FF042F475BFAA70D9210A59E808D8E40E828A375DB5A61205`.
User đã chọn cài/thử sau; không hỏi nối USB lại. Chưa signed release: thiếu
key.properties, applicationId vẫncom.example.healthmate.

Chưa deploy production: đọc lại Rules thấy vẫn hash873887eb… (chat50 từ lượt
trước), thiếu verified email gate/schema dinh dưỡng mới. Đã chuẩn bị riêng
`build/stage10-production-candidate`, hash6ee24c538f6673bd45ab9d2803f63383ec6877ec75cd3cabf1d5e63c0bbf4bef,
loại admin hoàn toàn và qua52test. Script tool/prepare_stage10_rules.cjs không
deploy; khi được duyệt phải đọc lại baseline, deploy đúngcandidate và verifyhash.
Backup/rollback ởbuild/stage10-production-review. Không deploy wholelocalRules.
AppCheckAI ENFORCED; FirestoreHTTP200 nhưng thiếuenforcementMode, chưa tựbật.

Giai đoạn10 source/QA và các giới hạn chi tiết trong docs/test-report.md và
stage10-security-review.md. Rollout email gate cần duyệt theoAGENTS2.2 do chặn
tài khoản chưa xác minh. Không chuyểnstage11 hoặc quaylạiadmin tự động.

## Mới nhất25/10 — 50 lượt và khôi phục hội thoại, ưu tiên phần này

Người dùng đồng ý nâng50lượt/cuộc, sửa mất nội dung khi quay lại tab và tối ưu
AI, rồi chọn cài/thử điện thoại sau. Đã hoàn tất code/build, chưa cài bản mới.
APK: build/releases/healthmate-chat-50-debug.apk,236.539.039bytes,SHA256
214FFD9EA23869A50DFEA7A4B6320B44C31134F6E806CEC21E32C24603459BB2.

chat_resume_provider giữ con trỏ theo UID/revision, không giữ messages; init
controller tự mở đã chọn/latest, newSession explicitnull giữ trống qua tab;
late save không ghi đè chọn mới/UID khác. AutoDispose vẫn hủy stream dở.
50lượt=100messages app/repository/Rules; không migrate. Quick chips dùng local
repositories không gọi AI; body AI bỏ bảng tham chiếu lặp, giữ3lượt history.
Không tăng API rate/quota/đổi model/billing. Cloudflare Worker vẫn version
b886ff1f-270d-458c-b508-fc443655651e,URL config/chat-api.json như trước.

Đã deploy chỉ chat limit trên production snapshot, giữ các Rules production
khác, không deploy filelocaldirty. Ruleset mới4d084994-cde1-4c8f-b8bd-dbfb52611baa,
hash873887eb91e67a19caaa063e4c8f0a8b0f36d5a08d81c7c124f61914e2f7590c,
đọc lại khớp. Backup/candidate/rollback config dưới build/chat-limits-production-*.

Focusedchat62/62,fullFlutter578/578,analyze18info cũ0warning/error,Ruleslocal52/52
vàcandidate4/4,APK42,2s qua. Rulesfull đầu51/52 assertiononboarding,baseline riêng
vàfullrerunqua nên ghi nhận timingflake chưachốt nguyênnhân, không sửa test.
Chi tiết docs/chatbot-capacity-update.md. Người dùng sẽ cài/thử sau; không tự
test50lượt bằng model thật hay tạo Firebase test user. Không commit/push,
không mở admin/scanner/stage10. Bảo toàn toàn bộ dirty tree.

## Kết nối thật25/10 — ưu tiên hơn các trạng thái lịch sử bên dưới

Đã OAuth Wrangler thành công trên account adfd92f2dcd7fd6171ef7c67120444fb,
triển khai https://healthmate-chat-api.healthmate-chat-api.workers.dev/v1/chat.
Version cuối b886ff1f-270d-458c-b508-fc443655651e. Không bật billing/Paid/thêm DB.
Qwen làm planner, Llama3.3 70B làm answer (hai model cố định cùng Cloudflare),
do benchmark Qwen-only có lỗi diễn giải, Llama-only có JSON lỗi. Benchmark cuối
20/20routing/ngày/hoàn tất,1,258–5,494s,median1,892s,fixture tổng hợp qua REST;
không phải native E2E và không chứng minh AI luôn đúng.21Worker tests qua.
Endpoint thật thiếu/saiJWT401,GET405,unknown404. Chi tiết docs/chatbot-live-qa.md.

APK debug đã build45,9s với config/chat-api.json publicURL và debug token đọc
filelocal (không in token). tool/run_android.ps1 tự đọc config. Full569tests và
analyze18info là kết quả trước khi sửa SSE ở lượt native bên dưới.
Không sửa Firestore Rules/schema/scanner/admin. Bảo toàn dirty tree, chưa commit/push.
Người dùng vừa kết nối điện thoại AAK_AN00 qua USB; adb install -r trả Success,
app đã mở, giữ dữ liệu, lastUpdateTime25/10/2026 02:54:03. Người dùng thử
"Protein có vai trò gì trong bữa ăn?" và báo "Phản hồi AI vượt giới hạn".
Đã sửa SSE wire budget32KB bị cộng envelope: capture thật45.817byte/95events
chỉ844chữ; Dart replay mới qua. Wire2MiB/event16k/raw16k, text3.800giữ nguyên.
55focusedtests qua,APK sửa17,1s qua,analyze3file sạch; full analyze cuối8,9s
18info có sẵn/0warning/error. Cài đè lần hai Success,
lastUpdateTime25/10/2026 02:59:04; người dùng xác nhận "Đã trả lời đầy đủ".
Người dùng thử "Hôm nay còn bao nhiêu kcal so với mục tiêu?" rồi "Còn đạm thì
sao?", xác nhận "Khớp số liệu hoặc báo thiếu dữ liệu đúng". Kết nối và luồng
cốt lõi đã nghiệm thu trên máy; native mất mạng/quota/đổi UID/lịch sử mở lại
chưa thử thủ công. Chi tiết docs/chatbot-live-qa.md. Dừng ở scope stage9 hiện tại,
chờ yêu cầu tiếp; không tự mở stage10/admin/Rules hoặc push.

## Lịch sử trước kết nối25/10 — chatbot API Cloudflare

Người dùng yêu cầu linh hoạt như MyFitnessPal, giữ miễn phí, làm rõ muốn gọi
API cloud rồi yêu cầu thực hiện phương án Cloudflare. Đã triển khai code Worker
và Flutter. Người dùng nói chưa có tài khoản Cloudflare và sẽ tạo Free;
`npm run whoami` trong chat-api báo chưa đăng nhập. **Chưa deploy/URL thật/call
Qwen live**, chưa đo tiếng Việt/latency, không coi giai đoạn 9 rollout hoàn tất.

Đọc chat-api/README.md cho bước kết nối còn lại. Worker xác thực Firebase JWT
verified + App Check đúng project/Android app, public keys/jose, rate bindings;
không có key dịch vụ AI trong app, không đọc Firestore. Plan JSON giới hạn → app
repositories tính dữ liệu → answer SSE. 3 nguồn/lượt, phạm vi7ngày, cân gần nhất
90ngày, 5 món catalog, 3 lượt history; không dùng nhánh USDA parser đang lỗi.
Consent trước gửi, mode tra cứu không gọi AI, UID/cancel/retry cùngID, partial
không lưu. Cấu hình `HEALTHMATE_CHAT_API_URL` URL thật mới mở chat tự do. Hiện APK
không có URL nên giữ tra cứu/10 chủ đề cũ, hiển thị rõ chưa kết nối.

Full Flutter569/569qua56s, Worker18/18qua, npm audit0, dry-run48,14KiB. Analyze
18info cũ/0warning/error exit1, APK cuối10,9s qua; logs build/chat-api-*.log.
4 snapshot fake font thật docs/ux/chatbot-api, 360px 100–200%, đã xem. Không ADB
device; chưa cài APK. Code, scope/risks và QA đầy đủ trong implementation-progress,
test-report, chatbot.md và chat-api/README.md. Không đổi Firestore schema/Rules,
Firebase billing/scanner/admin; bảo toàn toàn bộ dirty tree, chưa commit/push.

Chờ chủ dự án tạo xong Free và đăng nhập/cấp quyền CLI, xác nhận đúng account;
sau đó triển khai API thật, build URL và kiểm thử model/native trong cùng stage.
Không tự tạo tài khoản/chấp nhận điều khoản, dùng temporary account hoặc nâng
Paid. Không yêu cầu dán API token/OTP/mật khẩu vào chat. Không resume admin hoặc
triển khai Rules còn treo ngoài scope.

## Cập nhật25/10/2026 — chatbot, ưu tiên trạng thái này

Người dùng yêu cầu xây chatbot và đồng ý làm sau giải thích API Gemini qua
Firebase AI Logic. Giữ free tier; không gửi nhật ký/hồ sơ/UID/raw text/history
tới Gemini. Không billing/backend mới, không sửa scanner/USDA/admin hoặc deploy.
Bảo toàn mọi thay đổi chưa commit từ các lượt trước.

Đã mở rộng chat: plan cục bộ tiếng Việt có/không dấu, ngày cụ thể,
hôm nay/hôm qua/hôm kia, tuần này/tuần trước/7ngày; totals kèm dữ liệu thiếu,
còn/vượt kcal và macro so mục tiêu theo từng ngày, cân nặng có ngày đo,
followup trong phiên. Mục tiêu ngoài dinh dưỡng dẫn về Mục tiêu, không trả nhầm
ngân sách calo. Giao diện mới, Gemini10chủ đề enum chuẩn hóa sau disclosure.
Model gemini-3.5-flash-lite/thinking minimal đối chiếu docs25/10. Chưa có chat
LLM tự do phân tích dữ liệu cá nhân hoặc gợi ý thực đơn cá nhân.

File mới chat_request.dart, personal_chat_context.dart, chatbot_personal_test.dart
(14case mới); models/service/UI/controller chat cập nhật. Giữ schema chat,
retry cùng turnID, UID guards, streaming/stop/history. Mạch câu hỏi xóa khi mở
lịch sử/phiên mới/chọn lịch/đổi UID hoặc đổi sang kiến thức/trợ giúp.
docs/chatbot.md có phạm vi và checklist, docs/ux/chatbot là snapshot fake font thật.

Full cuối548/548qua73s; chat32/32qua11s; analyze18info cũ,0warning/error,
exit1; APK cuối build25,7s. Log accepted-tests/accepted-analyze/build-final
trong build/, chi tiết docs/test-report.md và implementation-progress.md. APK ở
build/app/outputs/flutter-apk/app-debug.apk. Không có ADB device; chưa cài APK
hoặc nghiệm thu API Gemini live trong lượt này. Không coi tests fake là E2E cloud.
Lỗi USDA/Rules schema mới trong audit24/10 vẫn còn, chưa sửa ngoài phạm vi.

## Tiếp nối 24/10 — người dùng yêu cầu bật Google

Đã được người dùng xác nhận email hỗ trợ và lưu Google provider thành công.
Console Google Enabled, API200 enabled=true có client ID. Đã đăng ký SHA-1 debug
qua CLI, đọc lại đủ SHA-1/SHA-256 đúng Android app; cập nhật google-services.json
có OAuth client_type1 đúng SHA-1 và client_type3 đúng project/package/app ID.
Không có ADB device; chưa nghiệm thu Google OAuth trên điện thoại hoặc thư inbox.
Trạng thái này thay thế thông tin Google IDP404/OAuth rỗng bên dưới.
APK debug build qua11,1s (`build/google-enabled-android-build.log`), resource
default_web_client_id khớp JSON. Chưa cài APK vì không có thiết bị kết nối.
Không deploy Rules/hosting/admin. Giữ mọi thay đổi chưa commit.

## Cập nhật 24/10/2026 — auth mobile (ưu tiên trạng thái này)

Người dùng yêu cầu hoàn thiện đăng nhập/đăng ký/quên mật khẩu, thêm Google;
đã hủy yêu cầu Facebook và tạm gác web admin. Mã auth đã có Google SDK native,
email verification gate, resend/cooldown và password reset qua Firebase; Rules
local yêu cầu verified claim. Không sao chép/xóa dữ liệu hoặc đổi UID cũ.
Full Flutter **534/534**, auth cuối **35/35**, Rules **60/60**, email Emulator
E2E **1/1** qua. APK debug cuối build10,8s; analyze18 info cũ. Không có ADB device.

Google production còn bị chặn cấu hình: Email/Password đã bật, Google IDP404,
danh sách IDP rỗng, `google-services.json` không OAuth client. Cần chủ dự án bật
Google, đăng ký SHA và tải lại JSON; xem `docs/authentication-flow.md` (có SHA
debug thực). Chưa chứng minh email tới inbox hoặc Google OAuth thật, chưa cài APK.
Không push/commit/deploy Rules hoặc thay provider/billing production. Mọi thay
đổi trước đó và phần admin local vẫn được giữ; không resume admin tự động.
Tiến độ/test-report có kết quả và giới hạn mới, không dùng số490 bên dưới làm
trạng thái hiện tại. Chờ yêu cầu kế tiếp sau khi bàn giao kết quả lượt auth.

Cập nhật: 20/10/2026 (Asia/Saigon). Đây là bối cảnh tiếp tục dự án, không phải yêu
cầu triển khai thêm tính năng. Đọc AGENTS.md và kiểm tra code/Git hiện tại trước
khi sửa; nếu trạng thái đã đổi, ưu tiên dữ liệu thực tế.

**Cập nhật Git ngày 23/10/2026:** người dùng đã yêu cầu commit và push đầy đủ
các thay đổi UI/test/tài liệu lên GitHub. Mô tả “chưa commit” và HEAD bên dưới là
ảnh chụp ngày 20/10, trước đợt đồng bộ này; chat mới phải đọc `git status`,
`git log` và đối chiếu origin/main để xác định trạng thái mới nhất.

## Dự án và Git

- Thư mục: `C:\Users\LEGION\OneDrive - Ho Chi Minh City University of Foreign Languages and Information Technology - HUFLIT\Documents\ChatGPT\HealthMate 2`.
- Flutter/Dart, Riverpod, go_router, Firebase Auth/Firestore/AI Logic; Android trước.
- Nhánh đang làm: main. HEAD khi bàn giao: `ba0557d` — `feat: Add MyFitnessPal-style UI components`.
- Có nhiều file sửa và file mới **chưa commit/push** của các lượt UI gần đây.
  Phải đọc git status và diff; không reset, clean, ghi đè hoặc pull đè thay đổi.
- Không commit/push/deploy Firebase nếu chưa có yêu cầu mới. Không thực hiện lại
  yêu cầu tắt laptop cũ: yêu cầu đó thuộc công việc trước, hiện người dùng đang chạy app.

## Trạng thái gần nhất

1. UI được sửa theo ảnh MyFitnessPal người dùng gửi: giao diện tối xanh đen,
   điểm nhấn xanh dương, thẻ lớn, số liệu thật. Giữ theme sáng và font Be Vietnam Pro
   đóng gói sẵn. Không dùng ảnh/số liệu của MyFitnessPal làm dữ liệu ứng dụng.
2. Thanh dưới có đúng **5 ô Hôm nay / Nhật ký / + / Tiến độ / Thêm**, + ở giữa.
   Nhật ký, Quest, Chat, Cá nhân và Tiến độ giữ route/branch có sẵn.
3. **+ → Quét món** mở FoodScannerDialog. Scanner/Chat hiển thị mặc định qua
   bool.fromEnvironment(defaultValue: true) trong appFeatureFlagsProvider.
   Constructor AppFeatureFlags vẫn mặc định false cho cấu hình tường minh/test;
   test helper mặc định core-only. Build có hai define=false vẫn tắt được AI.
   Không bỏ kiểm tra hồ sơ 18+, consent, UID hoặc Firebase App Check.
4. **Thêm** đưa Mục tiêu/Nhiệm vụ và Chat lên đầu; + cũng có hai lối tắt này.
   Quest/Chat được ánh xạ trạng thái chọn về Thêm trên thanh dưới.
5. Quét mã vạch đã chuyển ra phần chung MealFormDialog để xuất hiện cả trong
   luồng thật có sourcesBuilder/MealFoodSources. Chặn mở lúc lưu/bỏ nháp hoặc đủ
   5 món. Chưa nghiệm thu camera/API sản phẩm thật trong lượt sửa UI này.
6. Hôm nay dùng ngày chọn, bữa ngày trước cho sao chép, các nguồn nước/vận động/
   cân nặng thật. Form dùng chung journal_meal_entry.dart giữ UID guards, nháp,
   operation ID và xác nhận lưu. Tìm món đã sửa debounce/response đến trễ và
   duyệt catalog khi chưa nhập chữ; test dùng fake API.
7. Yêu cầu mới nhất đã hoàn thành: **giảm thông tin chen chúc**. Hôm nay giữ số
   liệu/bữa/ghi nhanh; mục tiêu dinh dưỡng, Goal/Quest và WeeklyReflection nằm
   trong “Mục tiêu và tổng kết” mặc định đóng, nội dung chỉ dựng khi mở.
   Bỏ nút tiến độ trùng tab, UTC chuyển vào tooltip ngày, giảm nhãn lặp và chiều
   cao thẻ phụ. Nút ⓘ mở giải thích dinh dưỡng/nước/vận động/khẩu phần. Nước dùng
   ml, không lặp lít. Không ẩn lỗi cần xử lý, nhãn ước tính, consent hoặc xác nhận.
   Dấu — vẫn phân biệt với 0. Cá nhân bỏ email bị lặp.

## Báo cáo tuần/tháng: câu hỏi đã trả lời, chưa có yêu cầu sửa

- Tiến độ có Tuần (chọn tuần trước), 30 ngày và 90 ngày, số liệu/biểu đồ thực.
- “30 ngày” là khoảng lùi 30 ngày đến hôm nay, **chưa phải tháng lịch**.
- Có xuất nhật ký CSV theo khoảng ngày. Người dùng mới hỏi đã có báo cáo chưa;
  không tự thêm tháng lịch nếu chưa được yêu cầu.

## Kiểm thử đã chạy thực tế

- Dart format 20 file của đợt rút gọn: qua, kiểm tra lại 0 thay đổi.
- `flutter --no-version-check test --no-pub --reporter expanded`: **490/490 qua**,
  65 giây. Log `build/compact-full-final.log`.
- `flutter --no-version-check analyze --no-pub`: **21 info, 0 warning/error**,
  exit 1, 21,7 giây. Log `build/compact-analyze.log`. Không gọi analyze sạch.
  Info có sẵn: withOpacity cũ, print trong search, http đang ở dev_dependencies
  nhưng được import trong lib.
- `flutter --no-version-check build apk --debug --no-pub`: qua, assembleDebug
  49,1 giây; vẫn có cảnh báo Kotlin plugin. Log `build/compact-build.log`.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Git diff whitespace check có cấu hình cr-at-eol: qua.
- Chưa QA trực tiếp điện thoại/camera/AI/API mã vạch trong lượt UI này. Chưa chạy
  lại security emulator vì không đổi Rules. Không đổi schema/index/package,
  không deploy hoặc ghi dữ liệu production trong các lượt này.
- Test/ảnh dùng dữ liệu tổng hợp. Không bỏ test hay assertion tính toán để né lỗi;
  một số test cũ được cập nhật thao tác mở chi tiết hoặc nhãn rút gọn.

## Tài liệu và file cần đọc

- AGENTS.md; docs/implementation-progress.md; docs/test-report.md.
- docs/mfp-ui-redesign.md; docs/compact-ui.md; docs/ux/mfp/README.md.
- lib/core/widgets/app_shell.dart, details_disclosure.dart, information_button.dart.
- lib/features/dashboard/presentation/dashboard_screen.dart và widgets/mfp_*.
- lib/features/journal/presentation/journal_meal_entry.dart, journal_screen.dart.
- lib/features/nutrition/presentation/meal_form_dialog.dart.
- lib/features/progress/presentation/progress_screen.dart, progress_overview.dart.
- lib/features/reports/presentation/period_report_panel.dart.
- test/compact_ui_test.dart, navigation_features_test.dart, mfp_ui_test.dart,
  mfp_search_test.dart và các fake trong test/support.

## Môi trường chạy

- Flutter: `D:\Flutter\flutter\bin\flutter.bat`.
- Dart: `D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe`.
- Java: `C:\Program Files\Android\Android Studio\jbr` (JAVA_HOME).
- TEMP/TMP dùng khi kiểm thử: `D:\HealthMateMaintenanceQA\tmp`.
- VS Code: `D:\VS Code\Microsoft VS Code\bin\code.cmd`; đã mở đúng dự án và
  lib/main.dart ở cuối chat trước. Dừng debug cũ rồi F5 để áp dụng cờ compile-time.

Tiếp tục bằng việc xác nhận yêu cầu tiếp theo của người dùng; không tự chuyển
giai đoạn, push code hoặc triển khai Firebase.
