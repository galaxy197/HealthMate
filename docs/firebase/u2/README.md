# U2 — bằng chứng triển khai và nghiệm thu Firebase

Ngày 18/10/2026, base `main/fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12`;
UX U1 và tooling U2 nằm trong working tree, chưa commit/push. Đích duy nhất:
`healthmate-app-20261013`, database `(default)`, `asia-southeast1`.

| Bằng chứng | Kết quả |
|---|---|
| [Metadata trước](before-metadata.json) | Backup trước deploy, hash cũ `0b7a11…`, release 13/10 |
| [Deploy chỉ Rules](deploy-rules.txt) | Exit 0; không deploy indexes |
| [Metadata sau/cuối kiểm thử](after-metadata.json) | Hash `d33e01…` khớp local, matchesLocal=true, hai indexes READY |
| [SDK production log](production-sdk.txt) | 1 scenario / 10 checkpoint, 27 giây; teardown pass |
| [Tổng hợp máy đọc](verification.json) | Scope, cleanup và giới hạn nghiệm thu |

Backup Rules đầy đủ nằm ngoài build ở
`D:\HealthMateMaintenanceQA\u2-before-20261018-193138`. Không chứa credential.
Hash LF/trim production/local đã xác minh:
`d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877`.
Ruleset `423ff6c8-79b7-4158-ba4f-2de9871a715d`, release
`2026-10-18T12:33:45.507953Z`.

## Phạm vi chạy thật

Flutter Firebase SDK trên Chrome headless, repository/model thật, backend cloud;
không mock/emulator/Admin SDK. Named Firebase apps riêng A/B/guest, Auth persistence
NONE và Firestore persistence tắt; không đụng phiên mặc định của người dùng.
Chủ sản phẩm cho phép đúng hai tài khoản QA có dữ liệu tổng hợp. Không đọc hồ sơ
sức khỏe thật, seed catalog, gọi AI hoặc thay App Check/billing.

1. Tạo/đăng nhập hai QA riêng, lưu onboarding tổng hợp 18+.
2. Mục tiêu ngày cũ/mới và cập nhật hôm nay giữ mục tiêu lịch sử.
3. CRUD món riêng/công thức và yêu thích retry không trùng.
4. Bữa từ công thức, snapshot không đổi sau sửa/xóa nguồn; scale gram và copy ngày.
5. Nước/vận động, tổng theo ngày, query server dùng composite index production.
6. Goal retry cùng ID và Quest hoàn thành không bị tạo lại/reset.
7. Logout/login, tải lại mục tiêu và nhật ký.
8. Tắt mạng 3 giây không xác nhận lưu; bật mạng, retry cùng operation ID, đúng 1 bữa.
9. 50 yêu cầu đọc/query/ghi/xóa của B/guest vào A nhận permission-denied.
10. Dọn dữ liệu Firestore QA, kiểm tra server profile và 11 collection rỗng;
    dọn A vẫn giữ profile B. Teardown kiểm tra lại cả hai.

Hai tài khoản Auth **được giữ**, không thử xóa tài khoản production. File đăng nhập
chỉ ở `D:\HealthMateMaintenanceQA\u2-production-qa-20261018194000\qa-defines.json`,
ACL giới hạn người dùng hiện tại; không đưa vào repo/log/chat. Harness và runner
không tự sinh thêm email trên retry; dùng đúng hai email QA của run đã cho phép.
Không phân phối artifact test có dart-defines; APK U1 thường không chứa QA defines.

## Chạy lại có chủ đích

Không chạy tự động cùng `flutter test`: harness cố ý không có hậu tố `_test.dart`.
Đọc script, xác nhận phạm vi production và credential QA trước khi dùng:

```powershell
.\tool\test_production_qa.ps1 -AllowProductionQa `
  -CredentialsFile 'D:\HealthMateMaintenanceQA\u2-production-qa-20261018194000\qa-defines.json' `
  -VerifiedDeploymentDirectory 'ABSOLUTE_PATH_TO_FRESH_VERIFIED_METADATA'
```

Runner kiểm tra opt-in, email QA có prefix/run cố định, credentials ngoài repo,
project và hash Rules khớp metadata. Dùng inspect tool để có metadata mới trước
khi chạy lại; không mặc định bằng chứng lịch sử vẫn đúng. Nếu App Check chặn một
môi trường mới, báo lỗi thật, không tự đổi enforcement hoặc thêm debug token.

**Giới hạn:** SDK production E2E đã đạt; UI Android dùng backend emulator đã đạt
trong U1. Chưa nghiệm thu UI Android production, máy thật, Play Integrity hoặc
release ký phát hành. Không suy ra mọi thiết bị/mạng đều đã đạt từ kịch bản này.
