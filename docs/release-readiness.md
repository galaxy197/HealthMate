# Release readiness — Gói 10 (31/10/2026)

**Trạng thái: code preflight sẵn sàng; signed release và nghiệm thu Android bị chặn.**
Chủ sở hữu chốt bản demo `com.example.healthmate`, version `1.0.0+1`.
Đây chưa phải quyết định định danh/phát hành Play Store. Chưa có signing key hoặc
thiết bị; lượt này không build APK, không chạy native acceptance, không deploy.

## Cấu hình và guard

`config/release-candidate.json` bắt buộc cấu hình rõ admin controls bật, premium
demo tắt, chatbot tắt và gateway URL rỗng. Scanner entry bật để giữ luồng barcode;
điều đó không xác nhận AI scanner/gateway production đã an toàn. Không gọi AI thật
trong kiểm tra release. Gói 5 vẫn chặn do gateway disabled/IAM/direct old-client
bypass chưa được nghiệm thu; R1 vẫn thiếu job xóa server đặc quyền bền vững.
Không được ghi trạng thái release accepted chỉ vì preflight pass.

`tool/release_preflight.cjs` chỉ đọc source/config/signing metadata cục bộ, in mã
lỗi và SHA-256 source; không in token, mật khẩu hoặc đường dẫn khóa. Chỉ cho phép
danh sách define đã biết; cấm define debug/emulator, flag sai kiểu, premium demo,
AI chưa kiểm chứng. URL gateway phải rỗng trong cấu hình hiện tại. Preflight
không kiểm tra mật khẩu/certificate, App Check backend, IAM, migration hoặc
native behavior. `signingConfigured` chỉ có nghĩa metadata/file hợp lệ sơ bộ.

Guard ở resolved Gradle task graph kiểm tra cả task alias (`assemble`), chặn
release thiếu private signing và define debug/emulator, kể cả Firebase. Gọi
Flutter/Gradle trực tiếp vẫn phải cung cấp feature config rõ; không fallback sang
debug signing. Firebase bootstrap dùng Play Integrity ngoài debug mode.

Chủ sở hữu cung cấp `android/key.properties` trên máy build (Git ignore):
`storeFile` tuyệt đối (Windows dùng `/` hoặc `\\`), `storePassword`, `keyAlias`,
`keyPassword`. Keystore để ngoài repository; giữ backup/ACL riêng. Không gửi khóa
hoặc mật khẩu vào chat/commit. CI dùng secret store và dọn file tạm sau build.
Cấu hình certificate SHA đúng Firebase Android app và App Check/Play Integrity
phải do chủ sở hữu xác nhận trước khi nghiệm thu.

## Lệnh và bằng chứng hiện có

```powershell
& 'D:\Database\node.exe' --test tool/release_preflight.test.cjs
& 'D:\Database\node.exe' tool/release_preflight.cjs
```

31/10/2026: **6/6 Node tests pass**. Lệnh preflight thực trả exit 1 với blocker
`release-signing-missing`; identity/config hợp lệ, `releaseAccepted=false`,
`apkSha256=null`. Test Gradle là source contract, chưa compile Gradle/Kotlin.
Không có bằng chứng APK, certificate thật hoặc test thiết bị trong lượt này.
Root tổng hợp riêng analyze/Flutter/emulator tests trong `docs/test-report.md`.

Sau khi chủ sở hữu có key và tự quyết định build, helper đã chuẩn bị:

```powershell
./tool/build_release.ps1 -Node 'D:\Database\node.exe'
```

Helper preflight trước build, chỉ build release với file config rõ; kiểm tra
`apksigner`, từ chối certificate Android Debug rồi ghi APK và manifest vào
`build/releases/`. Manifest ghi identity/config/rules/indexes/APK hashes, commit,
working-tree dirty và `nativeAcceptance=false`, `productionAccepted=false`.
Manifest phản ánh source local; không chứng minh rules/indexes đã deploy.
Không chạy helper trong lượt này. Không ký hoặc tạo key tự động.

## Bảng nghiệm thu thiết bị — chủ sở hữu thực hiện

| Hạng mục | Bằng chứng cần ghi | Trạng thái |
| --- | --- | --- |
| Signed APK đúng identity/version | APK SHA-256, certificate SHA-256, manifest | Pending — chưa có key/APK |
| Cài mới và nâng cấp | Model Android/API, dữ liệu trước/sau, log đã loại PII | Pending — chưa có thiết bị |
| Auth, email verify, session/đăng xuất | Luồng thành công/lỗi mạng/thử lại | Pending |
| App Check Play Integrity | Certificate đã đăng ký, request được chấp nhận/từ chối | Pending |
| CRUD nhật ký, offline/reconnect | Tổng sau sửa/xóa, không ghi trùng | Pending |
| Camera/barcode/photo permissions | Allow/deny/cancel, thiết bị thật | Pending |
| Private cache theo UID và sign-out | Tài khoản A/B, reboot, không lộ dữ liệu | Pending |
| Account deletion pending/resume | Fail-closed và job server thực hoàn tất | Blocked — R1 server job chưa có |
| AI policy/quota/direct route | IAM, old-client bypass, limits, retention | Blocked — Gói 5 chưa nghiệm thu |
| Accessibility/keyboard/safe area | Màn hình nhỏ, font lớn, back navigation | Pending |

## Rollout, rollback và chi phí — kế hoạch chưa thực thi

1. Giữ production dừng cho đến khi R1/Gói 5, migration/index readiness và bảng
   thiết bị có bằng chứng đạt. Chốt một source revision và lưu manifest hashes;
   dirty tree phải được review trước khi dùng làm candidate chính thức.
2. Chủ sở hữu duyệt riêng deploy rules/indexes/config và chuyển đổi dữ liệu nếu
   cần. Không chạy migration, đổi IAM/billing hoặc seed production từ preflight.
3. Demo nội bộ ít người trước; quan sát auth denial, permission errors, retry,
   duplicate writes, latency và crash qua log đã loại PII. Có lỗi riêng tư hoặc
   mất dữ liệu thì ngừng phân phối ngay. Không đặt SLA từ kết quả emulator.
4. Rollback client về artifact đã được nghiệm thu trước đó; giữ AI/gateway tắt
   và pause rollout. Không tự hạ versionCode của bản đã phát hành, không xóa dữ
   liệu/migration reverse. Rules cũ chỉ được phục hồi sau khi kiểm tra tương thích
   schema và chặn truy cập chéo; rules rollback có thể mở lại lỗ hổng đã sửa.
5. Theo dõi Firestore reads/writes, auth errors và AI request/token/quota từ
   dịch vụ đo thật. Giá và hạn mức phải kiểm tra theo project/provider tại thời
   điểm phát hành. Emulator không đo billing, IAM, quota thực hoặc chi phí tiền.
   Chỉ có phép đo latency local giới hạn ở phần dưới; chưa đo chi phí/reads,
   quota hoặc load capacity production.
   Ngưỡng cảnh báo/giới hạn cần chủ sở hữu đặt và duyệt riêng, không bật billing.

Nguồn signing: [Flutter Android signing](https://docs.flutter.dev/deployment/android#sign-the-app).

## Load probe local có giới hạn

`tool/emulator_load_probe.cjs` chỉ chạy với opt-in dưới đây và Firestore Emulator
đã được root khởi động. Không nhận endpoint/project/request-size override, không
start/reset emulator; không kết nối production hoặc AI.

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
$env:HEALTHMATE_LOCAL_LOAD_PROBE='true'
& 'D:\Database\node.exe' --test tool/emulator_load_probe.test.cjs
& 'D:\Database\node.exe' tool/emulator_load_probe.cjs
```

Probe dùng project cố định `demo-healthmate-rules`, collection
`load_probe_catalog_<UUID>` mới cho từng lượt. Seed 100 catalog-shaped synthetic
documents (1 commit request), chạy 10 workers x 10 cursor-page queries, mỗi trang
10 docs và đối chiếu ID/thứ tự. Sau đó 1 commit chỉ xóa 100 đường dẫn fixture của
chính lượt đó; không dùng DELETE toàn database, không đụng fixture khác.
Giới hạn mỗi HTTP request 10 giây, từ chối redirect.

JSON ghi requested/completed/successful query count, returned document count,
error count/code, p50/p95/max latency và cleanup status. Query latency gồm HTTP,
parse JSON, kiểm tra trang; không gồm seed/cleanup. Total elapsed có cả setup và
cleanup. 100 query thành công dự kiến trả tổng 1.000 documents, đây là số response
thực quan sát, **không phải billing reads** (trường `billingReads=null`).

31/10/2026: 4/4 pure harness tests pass, gồm input guard trước network, percentiles,
10 concurrent workers/100 trang, fixture cleanup và lỗi setup/query. Đây là test
mock logic harness; kết quả emulator thực được ghi riêng dưới đây.
Không suy diễn từ mock sang latency thực. Admin REST `Bearer owner` bypass rules:
phép đo không nghiệm thu Auth/Rules/App Check, native, AI, quota, billing hoặc số
người dùng production chịu tải. Quota production chưa được đo.

### Kết quả chạy emulator thực — 31/10/2026

Đã đọc artifact `build/improvement-packages8-10/load-probe.json`: concurrency
**10**, **100/100 queries thành công**, **1.000 documents trả về**, **0 lỗi**.
Query latency **p50 17.604 ms**, **p95 58.452 ms**, **max 66.382 ms**;
tổng lượt chạy **296.778 ms** gồm setup/cleanup. Seed 100 fixtures bằng 1 commit,
cleanup bằng 1 commit thành công, chỉ xóa đúng 100 đường dẫn riêng của lượt chạy.
Đây là một lần đo synthetic admin REST trên emulator local, không đại diện tải
production hoặc số người dùng chịu được. `billingReads=null`,
`productionQuotaMeasured=false`; chưa có phép đo signed release/device/production.

Preflight cuối do root chạy vẫn exit 1 vì `release-signing-missing`; kết quả
được lưu cùng thư mục artifact trên. Không có APK hoặc native acceptance mới.
