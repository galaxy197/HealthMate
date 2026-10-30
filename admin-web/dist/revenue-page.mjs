import {demoRevenue, revenueExport, vietnamDateKey} from './revenue-model.mjs';
import {buildXlsx} from './xlsx-export.mjs';
const loads = new WeakMap();

export async function revenuePage({host, api, h, button, isCurrent}) {
  const revision = (loads.get(host) ?? 0) + 1;
  loads.set(host, revision);
  const current = () => isCurrent() && loads.get(host) === revision;
  host.replaceChildren(h('p',{class:'loading'},'Đang tải giao dịch mô phỏng…'));
  try {
    const [transactions,accounts] = await Promise.all([
      api.list('demo_premium_transactions',{isCurrent:current}),
      api.list('demo_premium_accounts',{isCurrent:current}),
    ]);
    if (!current()) return;
    const today = vietnamDateKey(new Date());
    const start = h('input',{type:'date',value:`${today.slice(0,7)}-01`,'aria-label':'Từ ngày'});
    const end = h('input',{type:'date',value:today,'aria-label':'Đến ngày'});
    const results = h('div',{id:'revenue-results'});
    function render() {
      if (!current()) return;
      try {
        const report = demoRevenue(transactions, accounts, {start:start.value,end:end.value});
        const money = n => `${n.toLocaleString('vi-VN')}đ`;
        const stats = h('div',{class:'stats'});
        for (const [label,value] of [['Doanh thu mô phỏng trong kỳ',money(report.amountVnd)],
          ['Giao dịch demo trong kỳ',String(report.count)],['Khách mua trong kỳ',String(report.buyers)],
          ['Gói demo còn hạn hiện tại',String(report.activeAccounts)]]) {
          stats.append(h('section',{class:'stat'},h('div',{class:'stat-label'},label),h('div',{class:'stat-number'},value)));
        }
        const exportButton = button('Xuất Excel mô phỏng',() => {
          if (!current()) return;
          const url = URL.createObjectURL(new Blob([buildXlsx(revenueExport(report))],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}));
          const link = h('a',{href:url,download:`healthmate-doanh-thu-demo-${start.value}-${end.value}.xlsx`});
          link.click(); setTimeout(() => URL.revokeObjectURL(url),1000);
        });
        const daily = h('table',{},h('thead',{},h('tr',{},...['Ngày (VN)','Giao dịch demo','Doanh thu mô phỏng'].map(title=>h('th',{},title)))),
          h('tbody',{},...report.days.map(day=>h('tr',{},h('td',{},day.day),h('td',{},String(day.transactions)),h('td',{},money(day.amountVnd))))));
        // Revenue totals include the complete selected period. Detail rendering
        // is bounded; export retains all rows validated by the list loader.
        const detail = h('table',{},h('thead',{},h('tr',{},...['Giao dịch','UID','Thời điểm (VN)','Mô phỏng (VND)'].map(title=>h('th',{},title)))),
          h('tbody',{},...report.transactions.slice(0,100).map(row=>h('tr',{},
            h('td',{},row.id),h('td',{},row.uid),h('td',{},new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(row.at))),h('td',{},money(row.amountVnd))))));
        results.replaceChildren(stats,h('section',{class:'panel'},exportButton,
          report.count === 0 ? h('p',{class:'muted'},'Chưa có giao dịch mô phỏng trong khoảng này.') : null,
          h('h2',{},'Tổng hợp theo ngày'),h('div',{class:'table-wrap'},daily)),
          h('section',{class:'panel'},h('h2',{},'Giao dịch demo'),
            h('p',{class:'muted'},`Hiển thị tối đa 100 giao dịch mới nhất. Tổng hợp và Excel tính đủ ${report.count} giao dịch trong kỳ.`),h('div',{class:'table-wrap'},detail)));
      } catch(error) { results.replaceChildren(h('p',{class:'error',role:'alert'},error.message)); }
    }
    const toolbar = h('div',{class:'toolbar'},h('label',{class:'field'},'Từ ngày',start),h('label',{class:'field'},'Đến ngày',end),button('Xem báo cáo',render),
      button('Tải lại',() => revenuePage({host,api,h,button,isCurrent})));
    host.replaceChildren(h('p',{class:'notice local'},'DEMO · KHÔNG THU TIỀN. Báo cáo chỉ cộng giao dịch mua mô phỏng 20.000đ/30 ngày. Không phải tiền thực nhận, lợi nhuận hoặc báo cáo quyết toán.'),
      h('section',{class:'panel'},toolbar),results);
    render();
  } catch(error) {
    if (current()) host.replaceChildren(h('p',{class:'error'},'Chưa tải đủ dữ liệu doanh thu mô phỏng. Kiểm tra quyền admin, mạng và Rules; không hiển thị tổng thiếu.'),
      button('Thử lại',() => revenuePage({host,api,h,button,isCurrent})));
  }
}
