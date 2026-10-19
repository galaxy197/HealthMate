# Release readiness — H0, 19/10/2026

Package/namespace vẫn `com.example.healthmate`, version `1.0.0+1`.
Firebase Android app và App Check đang gắn package/certificate hiện có. Chưa được
giao package ID chính thức hoặc upload key; chưa sẵn sàng phát hành Play Store.

Trước H0, release âm thầm dùng debug signing. H0 bỏ fallback đó: task release
thiếu signing dừng với thông báo cụ thể; debug dùng workflow cũ. Không tạo hoặc
ghi đè keystore, không thay application ID/Firebase/App Check.

Chủ sở hữu cung cấp `android/key.properties` ở máy build (Git ignore), gồm
`storeFile` (đường dẫn tuyệt đối, Windows dùng `/` hoặc `\\`), `storePassword`,
`keyAlias`, `keyPassword`. Keystore để ngoài repository, giữ backup/ACL riêng;
không gửi mật khẩu vào chat hoặc commit. Không có giá trị thật trong tài liệu.
CI tạo file tạm từ secret store được chủ sở hữu cấu hình rồi xóa file sau build.

Trước phát hành: chốt package ID, đăng ký đúng Android app Firebase và cấu hình
Google services cho ID đó; đăng ký SHA certificate ký/app signing và kiểm tra
Play Integrity/App Check trên bản ký thật; kiểm tra release manifest/network,
quyền riêng tư, versionCode, Play signing và upload bằng tài khoản chủ sở hữu.
Đổi package có thể thành ứng dụng cài riêng và không giữ session local của bản cũ;
không tự thực hiện chuyển đổi này hoặc sửa production để vượt kiểm tra.

Nguồn đối chiếu: [Flutter Android signing](https://docs.flutter.dev/deployment/android#sign-the-app).
Kết quả debug/Android và phép thử release thiếu khóa ghi trong test-report H0.
