# Gói 7 — backend cursor pagination cho admin

Ngày: 31/10/2026. Source candidate local, không deploy production. Bảo toàn
Rules/audit/support và thay đổi Gói 1–6; không bổ sung database/backend hoặc
dependency. Không thêm denormalized role/status do client thường tự ghi.

## Hành vi trước và sau

Trước, mở danh sách gọi loader gom toàn collection theo batch 200, tối đa
5.000 rồi mới phân trang UI 25. Directory còn tải toàn controls và đọc role
từng UID. Candidate dùng `listPage(kind,{cursor,...range})`, truy vấn Firestore
server có `limit(25)`; đọc thêm role/control **chỉ** 25 UID đang xem. Không còn
API `list` gom toàn collection cho đường hiển thị.

Catalog, directory, audit và support sắp ID tăng dần; cursor lưu ID cuối,
đọc lại trang trước từ cursor lịch sử, không giữ cache các hàng private.
ID boundary vẫn dùng được khi document boundary bị xóa. Query range có
`where(documentId(), >=/<=)` và `orderBy(documentId())`.

Revenue chọn ngày theo Việt Nam (UTC+7), query `occurredAt >= đầu kỳ`,
`< đầu ngày kế kỳ`, sắp `occurredAt desc`, `documentId desc`, limit25.
Cursor giữ chính xác seconds/nanoseconds và ID (không đổi qua Date/millis
làm mất nanos). Trang giao dịch không hiển thị số tổng cả kỳ. Tổng hợp/Excel
chỉ xuất hiện sau tác vụ đọc **đủ kỳ** thành công.

## Tìm kiếm, bộ lọc và phạm vi export

- Search tiếng Việt/không dấu/alias và các filter chỉ áp dụng **trang đang
  xem**, nhãn/placeholder/empty-state ghi rõ. Không giả vờ đây là global
  full-text search. Global search còn cần index/backend thích hợp được cấp
  quyền; không có dịch vụ đó trong gói này.
- Export catalog/directory/audit chọn khoảng ID inclusive riêng. Hai đầu
  không được cùng trống; một đầu trống là open-ended có giới hạn. Không dùng
  bộ lọc trang cho export và không lặng lẽ chỉ xuất 25 hàng đang xem.
- Export/tổng hợp đọc batch200, tối đa5.000 **trong phạm vi đã chọn**. Nếu
  vượt giới hạn, throw và không tạo tệp/tổng một phần; người dùng chia nhỏ
  khoảng ID hoặc ngày. Không nâng trần collection 5.000 để né bài toán.
- Revenue chọn1–366 ngày, đọc riêng kỳ tối đa5.000; quá giới hạn chọn ngày
  nhỏ hơn. Tệp ghi rõ mô phỏng20.000đ, không phải tiền thu thật.
- Không tải toàn memberships để chỉ hiện một số đếm. Chỉ số “gói còn hạn
  toàn hệ thống” tạm không hiển thị; chưa có summary tin cậy/aggregation
  được kiểm chứng cho chỉ số đó. Không đổi nó thành số trên trang.

## Quyền, hủy và tính nhất quán

Session UID/epoch và access epoch được xác minh trước/sau từng request,
kể cả enrichment, export và các kết quả đến muộn. Role revoke/logout vẫn
xóa dữ liệu UI; dữ liệu tải muộn không hiện và không tạo file. Cancel export
đóng dialog, vô hiệu generation ngay; request Firestore đang bay không bị
thu hồi ở server nhưng dữ liệu trả về bị bỏ. Revenue có Hủy tổng hợp và
thay ngày vô hiệu kết quả cũ. Support detail/reply giữ UID/role/session guard,
idempotent message ID, retry giữ draft và audit/status hiện có.

Cursor ổn định trên fixture không đổi, **không** tạo snapshot nguyên tử qua
nhiều query khi database thay đổi. Chèn ID trước cursor cần tải lại từ đầu;
đổi `occurredAt` có thể dịch receipt giữa trang và export có thể bỏ/đọc lại
record nếu ghi đồng thời. Loader dedup theo ID và kiểm cursor loop không
biến quá trình này thành snapshot. Cần tải lại trước đối soát; báo cáo demo
không được dùng làm chứng từ. Tệp đã xuất không bị thu hồi khi logout.

## File và API

- `admin-web/dist/server-paging.mjs`: hợp đồng scope/cursor, bounded reader,
  enrichment hiện trang, `collectRange` bắt buộc phạm vi.
- `firebase.mjs`: Firestore queries thật, server-only get, guarded API.
- `app.mjs`, `support-page.mjs`, `revenue-page.mjs`: navigation/query từng
  trang, scope tìm kiếm/filter công khai, export/tổng hợp riêng và cancel.
- `revenue-model.mjs`: giữ fractional-millisecond timestamps hợp lệ.
- `test/server-paging.test.mjs`, DOM/revenue/SDK integration: hồi quy.

Không sửa Rules/schema/index trong phạm vi admin: ID-only paging dùng index
mặc định; revenue single-field occurredAt desc với __name__ desc theo cùng
chiều. Emulator không thay production index validation; lỗi index thật phải
báo không tải thay vì fallback full scan. Client đang deploy trước đây chưa
đổi, cần review source và nghiệm thu trước publish phối hợp Rules candidate.

## Bằng chứng local

- Node suite `node --test admin-web/test/*.test.mjs`: **42/42 qua**, exit0,
  khoảng7,4s; `npm --prefix admin-web run check`: exit0.
- Fixture **10.037 hàng**: trang đầu chỉ fetch25+enrich25 UID; trang sau25,
  không tải trước toàn collection. Duyệt402 query-pages mock thu đủ10.037
  ID, không lặp/mất trên dataset không đổi. Xóa boundary vẫn đi tiếp được.
- Directory một trang có1 collection query trả25 docs và tối đa25 role+
  25 control point gets, không10.037 role/control gets. Đây là đếm thao tác
  SDK/fixture, **không phải hóa đơn Firestore production**; reads/Rules
  dependent reads/empty document billing theo điều kiện dịch vụ thực tế.
- Export251 hàng qua2 batch; oversize5.000 bị từ chối sau batch phát hiện
  vượt, không tạo partial file. Mất quyền/hủy trước enrichment hoặc khi
  chờ export bị bỏ; DOM kiểm không download, không hiện dữ liệu private.
- Timestamp cursor unit giữ nanoseconds; ngày Việt Nam/biên tháng/fractional
  millis, invalid range/mixedscope và stalecursor bị kiểm tra.
- SDK emulator suite cuối **7/7 qua**, exit0, **8,45s** trong
  `build/package7-sdk-final.log`: dùng adapter Firebase của sản phẩm với
  Auth/Firestore demo admin emulator8092/9098. Fixture10.037 directory
  được ghi/xóa riêng local, trang đầu25, trang tiếp25, tail7; không tải toàn
  collection trước trang đầu. Fixture31 receipts cùng millisecond khác
  nanos trả25+6 và export đủ31 đúng thứ tự. Hồi quy archive/restore/audit,
  stale edit, suspension/config và support idempotent reply vẫn qua.
- Rules dùng cho lượt SDK này được copy tại
  `build/package7-admin-emulator.rules`, SHA256
  `D43FC4EFDFA4A1D559433103BC288D79E3BD2339AD64E209963B820F0132ABFC`.
  Hash bản copy trùng root Rules candidate cuối đã qua 119/119 Rules tests.
  Đây là kiểm chứng emulator, không phải Rules đang deploy production.

Log đang lưu `build/package7-admin-tests.log`, `package7-admin-check.log`,
`package7-sdk.log`.
Không chạy production smoke, migration production, publish hoặc xóa Auth.
