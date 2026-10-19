# H5 — báo cáo 30/90 ngày và mức độ ghi nhận (local)

Tiến độ giữ Tuần mặc định và tuần cũ; thêm30/90ngày, khoảng trước/sau và Tải lại.
Dinh dưỡng/nước/vận động/cân/mục tiêu/xác nhận dùng các FutureProvider riêng theo
UID+range, autoDispose, không thêm realtime listeners báo cáo. Chỉ tải nguồn cần
khi view được mở; không tạo90listener/ngày. Lỗi một nguồn không biến thành0 hoặc
che nguồn khác đã xác minh. Loading/reload bỏ giá trị cũ cho phần đang tải.

Các readRange server cũ được giới hạn1–90ngày và query.limit(2001); nếu nguồn
vượt2000doc thì báo lỗi, không tính tổng bị cắt. Meal vẫn2query dateKey + timestamp
cho bữa legacy, hợp nhấtID và bỏ timestamp nhánh códateKey; không migration.
Mục tiêu:1queryversionbase<=start +1querychanges(start,end),limit90, dùng đúng
version từng ngày. Không áp ngược targethômnay. Dayreviews1querylimit91; tổng
longviewtốiđa8query; mỗiquerylog<=2001doc, không chia90query. Số này là bound,
không phải cam kết chi phí bằng0. Quy mô lớn phải chọn khoảng ngắn hoặc thiết
kế pagination/aggregate sau, không báo tắt một phần là đầy đủ.

Collection users/{uid}/day_reviews/{dateKey}: mealsComplete(bool), mealCount,
latestMealUpdate(timestamp|null), timezoneOffsetMinutes, dateKey, createdAt,
updatedAt, schemaVersion1. Người dùng chủ động xác nhận đã ghi đủ bữa/đồ uống
có năng lượng qua nút cuốiNhậtký hoặc chi tiếtngày báo cáo. Không suy trạng thái
hoàn tất từ1bữa. Xác nhận khớp count + timestamp cập nhật mới nhất của meal; thêm,
sửa/xóa đổirevision thì phải kiểm tra lại. Chỉ trung bình những ngày cóbữa và
xác nhận còn khớp; ngày trống kể cả đãbấmxácnhận vẫnkhôngthành0kcalđãăn.
Macro thiếu vẫn —/chưađủ/≥subtotal, xác nhận đủbữa không sửa coverage nutrient.
Rules owner-only A/B/guest, allowlist/types/bounds/timestamp/createdAt/datekhông
ởtươnglai; readquery theoUID. Cleanup thêmday_reviews. Khôngindexmới cần thiết.

Biểu đồkcal đểgap khi chưa ghi, đườngtargetđúngngày; không kết luận đạt/khôngđạt
khi dữ liệu cóthể mới1phần. Cân nặng hiển thị tất cả điểm trongrange (khác default
12điểm ởProfile), vị tríx theo timestamp, số lần/ngàycócân. Chênh lệch đầu/cuối
chỉ mô tả số đo, không suy thay đổi mỡ hay nguyên nhân. Nguồn có0/1lầncân có lời
hướng dẫn riêng. Chi tiết/cách đọc thu gọn, màn hẹp/chữlớn cuộn được.

File chính: core/data/bounded_range.dart; features/reports/{models,data,providers,
presentation}; ProgressScreen; nút cuối Journal; WeightChart maxPoints tùychọn;
loadRange trong4repository và nutrition_targets; Rules/cleanup/supportfake/tests.
Không đổi giới hạn5món/6nguyênliệu, không mởAI hay sửa profile nhạy cảm.

Kiểm thử: focused53/53(19s) gồm báo cáo/weekly/progress; focusedH5+UIDcuối11/11
(13s). FullFlutter417/417(122s) trước thêm1testUIDcuối; analyze sạch39s. Rules50/50,
SDK18/18(31s): xác nhận đúnglatestrevision, sửameal làmstale, retry, A/B, history
90ngày và2.001waterlogs tổng hợp kiểm chứng bị báooverflow; xóa riêng2.001fixture
trongfinally. ImporterEmulator151creates/retry0changes. LượtSDKđầu bị từchối đúng
vì C5 còn document mục tiêu lỗi cố ý; giữ assertion từchối và dọn chínhfixture
đó sautest, SDKsau18đạt. Testdayreview đầu quên chọn ngàyfixtureJournal (đồnghồ
providerkhác), sửaharness chọnngàytườngminh; khôngsửa nghiệpvụđểlấypass.

AndroidH5 đang chạy sauđốichiếusource/config/RulessangAVDQA/demo backend. Chưa
kết luậnmáythật/production. Rawlogsbuild/h5-*.log vàD:\HealthMateMaintenanceQA\h5-android.log.
Chưa deploy Rules/indexes hoặc ghi/importproduction; clientcũkhôngbiếtdọn
collectionday_reviews, cầnnângclient/cleanup trước rolloutbackendriêng. Rollback
khôngxóaday_reviews hayđổitrạngtháixácnhậnthànhsốliệuđãđo. H6chưatriểnkhai.

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


H6 native cuối đã kiểm tra lại phần hướng dẫn rút gọn, thay ảnh period-30.png bằng ảnh chạy thành công; tổng và điều hướng30/90 vẫn khớp SDK.
