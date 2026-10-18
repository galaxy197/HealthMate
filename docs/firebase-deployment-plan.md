# Firestore Rules — chuẩn bị U1 và kết quả triển khai U2

## Trạng thái mới nhất — U2 hoàn tất 18/10/2026

Chủ sản phẩm đã giao hoàn tất file, đồng thời cho phép tạo đúng hai tài khoản
QA tổng hợp và chỉ dọn dữ liệu QA sau kiểm thử. Không commit/push source U1/U2.
Base `main/fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12`; Rules/index local không đổi.

- Backup ngay trước deploy: `D:\HealthMateMaintenanceQA\u2-before-20261018-193138`,
  đủ source Rules, metadata và config rollback; đã đối chiếu bản copy.
- Chạy lại 47/47 Rules và 14/14 Firebase SDK emulator tests, exit 0.
- Đã chạy đúng `firebase deploy --only firestore:rules --project healthmate-app-20261013`,
  exit 0; không deploy indexes hoặc dịch vụ khác.
- Release cập nhật `2026-10-18T12:33:45.507953Z` (19:33:45 UTC+07), ruleset
  `423ff6c8-79b7-4158-ba4f-2de9871a715d`.
- Hash production/local LF-trim cùng
  `d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877`;
  GET sau deploy và cuối kiểm thử đều `matchesLocal=true`; hai index READY.
- SDK production: 1 kịch bản, 10 checkpoint, 27 giây, pass cả teardown; 50
  yêu cầu guest/B truy cập A bị chặn. Dữ liệu Firestore của hai QA đã dọn và
  xác minh server; A cleanup không ảnh hưởng B. Giữ hai tài khoản Auth, không
  thử xóa Auth production. Credentials nằm riêng ngoài repo với ACL người dùng.

**Local đạt / Rules đã triển khai đúng / SDK E2E production đã kiểm chứng.**
Chưa kiểm chứng Android UI trên production, máy thật, Play Integrity hoặc release.
Không đổi App Check/billing, seed catalog, migration, AI hoặc dữ liệu người thật.
[Metadata trước/sau, deploy log và SDK log](firebase/u2/README.md).

Lệnh phục hồi chính xác nếu sau này cần và được giao:

```powershell
firebase deploy --only firestore:rules --project healthmate-app-20261013 --config "D:\HealthMateMaintenanceQA\u2-before-20261018-193138\firebase.rollback.json"
```

Chưa chạy rollback. Các phần tiếp theo là **kế hoạch và snapshot U1 trước deploy**;
các câu “chưa deploy” trong đó mô tả thời điểm U1, không phải trạng thái hiện tại.

## Hồ sơ chuẩn bị U1 (giữ làm lịch sử)

**U1 không deploy.** Tài liệu này là kế hoạch có thể thực hiện sau khi chủ sản phẩm
giao U2 rõ ràng. Không bật billing, đổi App Check, seed/migrate, tạo tài khoản
production hoặc thử xóa hồ sơ thật. UX U1 còn trong working tree để review;
Rules/index không thay đổi so với commit `fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12`.

GET kiểm tra lại **19:12:59 UTC+07,18/10/2026** tại build/u1-firebase-final:
release/hash/source và index vẫn giống snapshot18:14 bên dưới, matchesLocal=false.
Không có deploy hoặc thay đổi cấu hình production trong hai lần kiểm tra này.

## Đích và bằng chứng mới nhất

Đối chiếu `.firebaserc`, `firebase.json`, `lib/firebase_options.dart`, Android
`google-services.json` và `firebase use --json`: cùng project
**healthmate-app-20261013**. GET cấu hình chỉ đọc lúc **18:14:37 UTC+07,
18/10/2026**, Firebase CLI15.22.4:

- Database `projects/healthmate-app-20261013/databases/(default)`,
  `FIRESTORE_NATIVE`, vùng `asia-southeast1`.
- Release `projects/healthmate-app-20261013/releases/cloud.firestore`, cập nhật
  `2026-10-13T06:25:21.345792Z`.
- Ruleset đang chạy `projects/healthmate-app-20261013/rulesets/b83d6f60-1e9a-49b3-a3e7-239ccf0d3ee0`.
- SHA256 chuẩn hóa LF/trim của production:
  `0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
- SHA256 chuẩn hóa của Rules local đã review/test:
  `d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877`.
- `matchesLocal=false`. Vấn đề hiện tại là **bộ Rules core đã có nhưng chưa được
  deploy**, không phải U1 cần nới quyền hoặc tạo diff Rules mới.

Backup và diff local (ignored, không có credential/dữ liệu sức khỏe):
`build/u1-firebase-review/{firestore.rules,metadata.json,firebase.rollback.json,rules.diff}`.
So production với local:252dòng thêm/7dòng bỏ. Trước U2 phải GET và sao lưu lại;
không mặc định snapshot ngày18/10 vẫn là bản đang chạy. Giữ backup ngoài thư mục
build trước deploy để tránh mất khi chạy flutter clean.

## Nội dung cần review

| Đường dẫn | Quyền/validation trong Rules local |
|---|---|
| users/{uid}, body_metrics, meal_logs, water_logs, activity_logs | Owner theo UID; allowlist/type/range; server timestamps; createdAt bất biến; ngày/offset, snapshot tối đa5món |
| nutrition_targets | Owner CRUD; ID=ngày hiệu lực hợp lệ; kcal>0; đủ3macro hoặc cả3null; macro0 hợp lệ; source user_manual; schema/timestamps |
| favorite_foods | Owner CRUD; sourceKind/sourceId/ID nhất quán; kiểm tra nguồn khi create; immutable createdAt/source; schema/timestamps |
| custom_foods | Owner CRUD; dinh dưỡng/gram bounded; tối đa5bí danh; serving basis/optional serving; field/type/source/schema/timestamps |
| recipes | Owner CRUD;1–6nguyên liệu snapshot có nguồn; không lồng recipe; yield/servings bounded; isEstimated; field/schema/timestamps |
| goals, daily_quests | Owner; loại/đơn vị/phạm vi/ngày/status hợp lệ; createdAt bất biến; hạn chế field cập nhật và chuyển trạng thái quest |
| chat_sessions/messages | Bộ Rules đã có, owner/bounded/atomic turn/schema; U1 không phát triển hay bật AI/chat/scanner |
| food_catalog | Người đăng nhập đọc; client không ghi |
| wildcard private | Chỉ owner read/delete phục vụ cleanup; không cấp create/update cho collection chưa định nghĩa |

Production chưa có create/update cho7nhóm targets/favorites/custom/recipes/goals/
quests/chat nêu trên. Có wildcard owner read/delete không có nghĩa tạo mới chạy
được. U1 đã review và chạy lại47Rules tests +14Firebase SDK tests trên project
**demo-healthmate-rules**, gồm owner CRUD, guest/B bị chặn read/query/write, dữ liệu
sai/field lạ/createdAt/updatedAt, snapshots và cleanup collection/subcollection
của A giữ nguyên B, data trước Auth sau. Chi tiết kết quả mới trong test-report U1.
Không bỏ validation để giảm lỗi production; không suy ra production pass từ emulator.

## Index thực sự cần

| Query | Index |
|---|---|
| water_logs where dateKey==D orderBy consumedAt DESC | Composite dateKey ASC + consumedAt DESC; production READY |
| activity_logs where dateKey==D orderBy performedAt DESC | Composite dateKey ASC + performedAt DESC; production READY |
| meal dateKey; legacy consumedAt range/order; recent consumedAt DESC | Single-field hiện có; U1 không thay query |
| targets effectiveFromDateKey range/order; weight measuredAt; library/favorites createdAt; catalog name | Single-field; query bounded như core hiện có |

`firestore.indexes.json` vẫn chỉ2composite trên, production metadata GET khớp cả
queryScope COLLECTION; __name__ DESC được thêm tự động. Không có index mới cần
deploy trong U1/U2 dự kiến. Không chạy deploy indexes hoặc xóa index đang dùng.
Nếu sau này phát sinh missing-index thật, review query/index và xin phạm vi riêng.

## Lệnh U2 dự kiến — chưa chạy trong U1

Chạy ở REPO_ROOT sau yêu cầu U2. Trước hết kiểm tra revision/working tree và hash
Rules (nếu khác hash đã review thì phải review/test lại):

```powershell
git status --short
git rev-parse HEAD
git diff fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12 -- firestore.rules firestore.indexes.json
firebase use --json
$text = [IO.File]::ReadAllText((Resolve-Path firestore.rules).Path).Replace("`r`n", "`n").Trim()
$algorithm = [Security.Cryptography.SHA256]::Create()
try {
  $hash = [BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-', '').ToLowerInvariant()
} finally { $algorithm.Dispose() }
if ($hash -ne 'd33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877') { throw 'Rules khác bản review; dừng để review/test lại.' }

$backupDirectory = 'build/u2-before-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
.\tool\inspect_firestore_deployment.ps1 -OutputDirectory $backupDirectory
# Kiểm tra metadata/project/database, giữ bản rules+metadata ở nơi an toàn ngoài build.
.\tool\test_emulators.ps1
# Chỉ khi các kiểm tra trên đạt và U2 đã được giao:
firebase deploy --only firestore:rules --project healthmate-app-20261013

$afterDirectory = 'build/u2-after-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
.\tool\inspect_firestore_deployment.ps1 -OutputDirectory $afterDirectory
```

Kiểm tra metadata mới có matchesLocal=true và deployedSha256 đúng hash local đã
review, release updateTime mới và index vẫn READY. CLI exit0 chưa chứng minh app
hoạt động. Có thể phải chờ propagation rồi GET lại; không nới Rules vì retry sớm.
Tool inspect chỉ GET cấu hình Rules/database/index và lưu backup; không đọc user
documents hoặc deploy. Tool dùng auth helper nội bộ của npm Firebase CLI đã thử
ở15.22.4; nếu CLI đổi API/quyền hết hạn, nó fail closed với mã lỗi an toàn. Người
dùng đăng nhập lại qua Firebase CLI/Console nếu cần; không gửi mật khẩu/token vào chat.

## Phục hồi khi deploy có vấn đề

Không overwrite source Rules đã review. Dùng **đúng backup lấy ngay trước U2**
(biến backupDirectory ở trên) và config rollback chỉ chứa Rules:

```powershell
firebase deploy --only firestore:rules --project healthmate-app-20261013 --config "$backupDirectory/firebase.rollback.json"
.\tool\inspect_firestore_deployment.ps1 -OutputDirectory ('build/u2-rollback-check-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
```

Sau rollback, deployedSha256 phải bằng hash trong metadata backup. Release/time
có thể mới vì đây là deploy lại cùng nội dung cũ. Rules cũ sẽ chặn lại thao tác
core mới; ghi rõ hệ quả này. Không xóa dữ liệu đã tạo, không rollback bằng cách
mở allow read/write, không seed/migrate hoặc triển khai dịch vụ khác. Nếu không
có backup, dùng lịch sử Rules trong Firebase Console theo release đã ghi và
review lại; không đoán bản cũ từ file source hiện tại.

## Nghiệm thu production sau deploy

Cần tài khoản QA A/B được chủ sản phẩm cấp rõ ràng; U1 chưa dùng/tạo tài khoản QA
production hoặc thao tác hồ sơ thật. Sau U2, bằng dữ liệu tổng hợp có nhãn QA,
kiểm tra target ngày cũ/mới, favorite/custom/recipe, bữa từ công thức, sửa/xóa nguồn
không đổi MealLog, Goals/Quest, logout/login, offline/retry và B bị chặn dữ liệu A.
Không tự thử xóa tài khoản production. Nếu thiếu tài khoản/device thì báo riêng:
**local đạt / Rules đã triển khai đúng / E2E production còn chờ**.

Tài liệu chính thức đã đối chiếu18/10/2026:
[quản lý/deploy Rules](https://firebase.google.com/docs/rules/manage-deploy),
[Firebase CLI và --config](https://firebase.google.com/docs/cli#the_firebasejson_file).
Lệnh chỉ Firestore Rules tuân theo phạm vi deploy riêng của Firebase CLI; không
dùng firebase deploy toàn bộ project.
