// All money here is explicitly simulated VND, never provider-verified receipts.
export function vietnamDateKey(date) {
  return new Date(date.getTime() + 7 * 3600000).toISOString().slice(0,10);
}
export function dateBoundary(key) {
  if (typeof key !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(key)) throw Error('Chọn ngày báo cáo hợp lệ.');
  const utc = Date.parse(`${key}T00:00:00Z`);
  if (!Number.isFinite(utc) || new Date(utc).toISOString().slice(0,10) !== key) throw Error('Ngày báo cáo không tồn tại.');
  return utc - 7 * 3600000;
}
function millis(value) {
  const result = value?.toMillis?.();
  if (!Number.isSafeInteger(result)) throw Error('Giao dịch chưa có thời gian được xác nhận.');
  return result;
}
export function demoRevenue(transactions, accounts, {start, end, now = new Date()} = {}) {
  const lower = dateBoundary(start), upper = dateBoundary(end) + 86400000;
  if (upper <= lower || upper - lower > 366 * 86400000) throw Error('Chọn khoảng báo cáo từ 1 đến 366 ngày.');
  const seen = new Set(), selected = [];
  for (const row of transactions) {
    if (typeof row.id !== 'string' || seen.has(row.id) || row.mode !== 'demo' || row.status !== 'simulated_paid'
      || row.currency !== 'VND' || row.amountVnd !== 20000 || row.planId !== 'premium_demo_30d'
      || row.source !== 'demo_checkout' || typeof row.uid !== 'string' || !row.uid) {
      throw Error('Dữ liệu giao dịch demo chưa hợp lệ; chưa thể tính doanh thu.');
    }
    seen.add(row.id);
    const at = millis(row.occurredAt);
    if (at >= lower && at < upper) selected.push({...row, at});
  }
  selected.sort((a,b) => b.at - a.at || a.id.localeCompare(b.id));
  const byDay = new Map();
  for (let at=lower;at<upper;at+=86400000) byDay.set(vietnamDateKey(new Date(at)), {amountVnd:0, transactions:0});
  for (const row of selected) {
    const group = byDay.get(vietnamDateKey(new Date(row.at)));
    group.amountVnd += row.amountVnd; group.transactions++;
  }
  const users = new Set();
  for (const row of accounts) {
    if (row.mode !== 'demo' || row.planId !== 'premium_demo_30d' || users.has(row.id)) throw Error('Dữ liệu gói demo chưa hợp lệ.');
    if (millis(row.startedAt) <= now.getTime() && millis(row.expiresAt) > now.getTime()) users.add(row.id);
  }
  return {
    amountVnd: selected.reduce((sum,row) => sum + row.amountVnd,0),
    count: selected.length, buyers: new Set(selected.map(row => row.uid)).size,
    activeAccounts: users.size, transactions:selected,
    days:[...byDay].map(([day,values]) => ({day,...values})),
  };
}
export function revenueExport(report) {
  return {name:'Doanh thu mô phỏng',
    headers:['STT','Mã giao dịch demo','UID','Thời điểm (giờ Việt Nam)','Gói','Số tiền mô phỏng (VND)','Trạng thái','Môi trường'],
    rows:report.transactions.map((r,i) => [i+1,r.id,r.uid,
      new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(r.at)),
      'Premium 30 ngày',r.amountVnd,'Mua mô phỏng thành công','DEMO - KHÔNG THU TIỀN'])};
}
