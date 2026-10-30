import { foodPayload, configPayload, text, validFoodId, entityVersion } from './validation.mjs';
import { filterRows, paginateRows, canControlAccount, exportRows } from './list-model.mjs';
import { buildXlsx } from './xlsx-export.mjs';
import { revenuePage } from './revenue-page.mjs';
import { supportPage } from './support-page.mjs';

const root = document.querySelector('#app'), dialog = document.querySelector('#editor');
const editorForm = document.querySelector('#editor-form'), fieldsHost = document.querySelector('#editor-fields');
let api, user, allowed = false, stopRole, generation = 0, pageGeneration = 0;
let currentPage = 'overview', rows = [], pageNumber = 1, filter = '', rowsReady = false;
let categoryFilter = '', statusFilter = '', roleFilter = '';
let editorAction, editorBusy = false, currentConfig = null;
const pages = {
  revenue: ['Doanh thu demo', 'Premium và giao dịch mô phỏng', 'Báo cáo Premium demo 20.000đ / 30 ngày. Không có khoản tiền thật nào được thu.'],
  overview: ['Tổng quan', 'Theo dõi và vận hành HealthMate', 'Một nơi để chăm sóc dữ liệu, tài khoản và trải nghiệm trong ứng dụng.'],
  food_catalog: ['Danh mục món ăn', 'Dữ liệu tốt, lựa chọn tốt hơn', 'Quản lý nguồn dinh dưỡng dùng chung. Chỉnh danh mục không làm thay đổi nhật ký đã lưu.'],
  user_directory: ['Tài khoản', 'Quản lý quyền truy cập', 'Chỉ hiển thị thông tin tài khoản tối thiểu. Hồ sơ và nhật ký sức khỏe vẫn riêng tư.'],
  support: ['Hỗ trợ khách hàng', 'Báo lỗi và góp ý', 'Tiếp nhận, phản hồi và theo dõi yêu cầu từ khách hàng.'],
  app_config: ['Cấu hình ứng dụng', 'Điều chỉnh trải nghiệm HealthMate', 'Cấu hình áp dụng cho bản ứng dụng đã bật chức năng quản trị từ xa.'],
  admin_audit: ['Nhật ký quản trị', 'Mọi thay đổi đều có dấu vết', 'Lịch sử thao tác được ghi cùng thay đổi dữ liệu và không thể sửa hoặc xóa trên web.']
};
function h(tag, props = {}, ...children) {
  const el = document.createElement(tag);
  for (const [key,value] of Object.entries(props)) {
    if (key.startsWith('on')) el.addEventListener(key.slice(2).toLowerCase(),value);
    else if (key === 'class') el.className = value;
    else if (key in el) el[key] = value;
    else el.setAttribute(key,value);
  }
  el.append(...children.filter(c => c !== null && c !== undefined).map(c => typeof c === 'string' ? document.createTextNode(c) : c));
  return el;
}
function brand() { return h('div',{class:'brand'},h('span',{class:'brand-mark'},'H',h('span',{},'+')),h('div',{},'HealthMate',h('small',{},'KHÔNG GIAN QUẢN TRỊ'))); }
function errorMessage(error) {
  const code = error?.code ?? '';
  if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') return 'Bạn đã hủy đăng nhập Google. Có thể thử lại khi sẵn sàng.';
  if (code === 'auth/popup-blocked') return 'Trình duyệt đang chặn cửa sổ đăng nhập. Hãy cho phép cửa sổ bật lên cho HealthMate rồi thử lại.';
  if (code.includes('permission-denied')) return 'Không có quyền thực hiện. Kiểm tra vai trò admin, tài khoản được bảo vệ và Rules đã cấu hình.';
  if (code.startsWith('auth/')) return 'Không đăng nhập được. Kiểm tra email, mật khẩu và kết nối Firebase.';
  if (/unavailable|deadline|network/.test(code)) return 'Chưa kết nối được máy chủ. Dữ liệu chưa được xác nhận; hãy thử lại.';
  return error?.message ?? 'Thao tác chưa hoàn tất. Hãy thử lại.';
}
function notify(message, bad = false) {
  const el = document.querySelector('#notification');
  el.textContent = message; el.className = `notification${bad?' bad':''}`; el.hidden = false;
  clearTimeout(notify.timer); notify.timer = setTimeout(() => { el.hidden = true; },7000);
}
function date(value) { const d = value?.toDate?.(); return d ? new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(d) : '—'; }
function version(data) { return entityVersion(data); }
function pill(label, style = '') { return h('span',{class:`pill ${style}`},label); }
function button(label, click, style = 'secondary') { return h('button',{type:'button',class:`button ${style}`,onClick:click},label); }
function safeCurrent(g) { return allowed && user && generation === g; }

function showAuth(message = '') {
  root.replaceChildren(h('main',{class:'auth-shell'},
    h('aside',{class:'auth-story'},brand(),h('div',{},h('p',{class:'eyebrow'},'HEALTHMATE CONTROL CENTER'),h('h1',{},'Một nơi quản lý.\nNhiều thói quen tốt.'),h('p',{},'Chăm sóc dữ liệu thực phẩm, vận hành tài khoản và giữ trải nghiệm HealthMate nhất quán.'),h('div',{class:'auth-lines'},h('span'),h('span'),h('span'))),h('p',{},'Quyền quản trị được kiểm tra bằng Firebase Security Rules.')),
    h('div',{class:'auth-form'},h('section',{},h('p',{class:'page-kicker'},'CHÀO MỪNG TRỞ LẠI'),h('h2',{},user ? 'Quyền quản trị chưa sẵn sàng' : 'Đăng nhập quản trị'),h('p',{class:'muted'},message || 'Sử dụng tài khoản đã được cấp quyền HealthMate Admin.'),
      api?.emulator ? h('p',{class:'notice local'},'Môi trường kiểm thử local · Firebase Emulator. Dữ liệu tại đây không phải dữ liệu production.') : null,
      user ? button('Đăng xuất',() => api.logout()) : loginForm(),
      h('p',{class:'auth-note'},'Không tự đăng ký hoặc cấp quyền admin tại đây. Chủ dự án cấp quyền qua bước thiết lập Firebase riêng.')))));
}
function loginForm() {
  const email = h('input',{id:'login-email',type:'email',autocomplete:'username',required:true,maxLength:254});
  const password = h('input',{id:'login-password',type:'password',autocomplete:'current-password',required:true,maxLength:128});
  const message = h('p',{class:'error',role:'alert'}), submit = h('button',{class:'button',type:'submit'},'Đăng nhập');
  const form = h('form',{onSubmit: async event => {
    event.preventDefault(); submit.disabled = true; message.textContent = ''; submit.textContent = 'Đang xác nhận…';
    try { await api.login(email.value.trim(),password.value); password.value = ''; }
    catch(error) { message.textContent = errorMessage(error); submit.disabled = false; submit.textContent = 'Đăng nhập'; }
  }},h('label',{class:'field'},'Email quản trị',email),h('label',{class:'field'},'Mật khẩu',password),message,submit);
  form.append(h('button',{type:'button',id:'google-login',class:'button secondary',onClick:async event=>{
    const google=event.currentTarget;
    google.disabled=true;submit.disabled=true;message.textContent='';google.textContent='Đang mở Google…';
    try { await api.loginGoogle(); }
    catch(error) { message.textContent=errorMessage(error); }
    finally { google.disabled=false;submit.disabled=false;google.textContent='Tiếp tục với Google'; }
  }},'Tiếp tục với Google'));
  let resetAt = 0;
  form.append(button('Quên mật khẩu',async () => {
    if(!email.checkValidity()||!email.value.trim()){email.reportValidity();return;}
    if(Date.now()<resetAt){message.textContent='Vui lòng chờ trước khi gửi lại email.';return;}
    resetAt=Date.now()+60000;
    try{await api.resetPassword(email.value.trim());message.textContent='Đã gửi yêu cầu đặt lại mật khẩu. Nếu email đủ điều kiện, hãy kiểm tra hộp thư và thư rác.';}
    catch(error){message.textContent=errorMessage(error);}
  }));
  return form;
}
function shell() {
  const nav = h('nav',{class:'nav-group','aria-label':'Quản trị'},h('p',{},'KHÔNG GIAN LÀM VIỆC'));
  const icons = { overview:'▦',food_catalog:'♧',user_directory:'♙',app_config:'☷',admin_audit:'◷',revenue:'₫',support:'✉' };
  for (const [key,info] of Object.entries(pages)) nav.append(h('button',{class:`nav-button${currentPage===key?' active':''}`,'data-page':key,onClick:() => openPage(key)},h('span',{class:'nav-icon','aria-hidden':'true'},icons[key]),info[0]));
  const main = h('main',{class:'main',id:'main-content'});
  root.replaceChildren(h('div',{class:'layout'},h('aside',{class:'sidebar'},brand(),nav,h('div',{class:'sidebar-bottom'},h('strong',{},'Quản trị có trách nhiệm'),h('p',{},'Chỉ truy cập dữ liệu cần thiết. Mỗi thay đổi được ghi vào nhật ký.'))),h('div',{class:'workspace'},h('header',{class:'topbar'},h('span',{class:'breadcrumb'},'HealthMate / Quản trị'),h('div',{class:'identity'},h('span',{class:`environment${api.emulator?'':' cloud'}`},api.emulator?'LOCAL · EMULATOR':'FIREBASE · PRODUCTION'),h('span',{class:'avatar','aria-hidden':'true'},'A'),h('span',{class:'identity-name'},user.email || user.uid),button('Đăng xuất',() => api.logout()))),main)));
  return main;
}
async function openPage(key) {
  if (!allowed) return;
  pageGeneration++;
  currentPage = key; rows = []; rowsReady = false; pageNumber = 1; filter = '';
  categoryFilter = '';statusFilter = '';roleFilter = '';
  const main = shell(), info = pages[key];
  main.append(h('div',{class:'page-head'},h('div',{},h('p',{class:'page-kicker'},`QUẢN TRỊ / ${info[0].toUpperCase()}`),h('h1',{},info[1]),h('p',{class:'muted'},info[2])),key === 'food_catalog' ? button('+ Thêm món ăn',() => editFood(), '') : null));
  if (api.emulator) main.append(h('p',{class:'notice local'},'Bạn đang thao tác trên dữ liệu kiểm thử local. Các thay đổi không tác động ứng dụng production.'));
  const content = h('div',{id:'page-content'}); main.append(content);
  if (key === 'overview') return overview(content);
  if (key === 'app_config') return configPage(content);
  if (key === 'support') {
    const g = generation, p = pageGeneration;
    return supportPage({host:content,api,h,button,isCurrent:() => safeCurrent(g) && pageGeneration === p});
  }
  if (key === 'revenue') {
    const g = generation, p = pageGeneration;
    return revenuePage({host:content,api,h,button,isCurrent:() => safeCurrent(g) && pageGeneration === p});
  }
  const toolbar = h('div',{class:'toolbar'},h('input',{class:'search',type:'search',id:'list-search',placeholder:'Tìm toàn bộ danh sách, có hoặc không dấu…','aria-label':'Tìm toàn bộ danh sách',maxLength:200,onInput:event => { filter=event.target.value;pageNumber=1;renderRows(); }}));
  function select(id,label,values,change) {
    return h('label',{class:'filter-field'},label,h('select',{id,'aria-label':label,onChange:event=>{change(event.target.value);pageNumber=1;renderRows();}},...values.map(([value,title])=>h('option',{value},title))));
  }
  if(key==='food_catalog') {
    toolbar.append(select('category-filter','Nhóm món',[['','Tất cả nhóm']],v=>categoryFilter=v),
      select('status-filter','Trạng thái',[['','Tất cả trạng thái'],['active','Đang hiển thị'],['archived','Đã xóa khỏi danh mục']],v=>statusFilter=v));
  } else if(key==='user_directory') {
    toolbar.append(select('status-filter','Trạng thái',[['','Tất cả trạng thái'],['active','Hoạt động'],['suspended','Tạm khóa']],v=>statusFilter=v),
      select('role-filter','Vai trò',[['','Tất cả vai trò'],['admin','Admin'],['user','Người dùng']],v=>roleFilter=v));
  } else toolbar.append(select('category-filter','Đối tượng',[['','Tất cả đối tượng'],['food_catalog','Danh mục món ăn'],['account_controls','Tài khoản'],['app_config','Cấu hình']],v=>categoryFilter=v));
  toolbar.append(button('Tải lại',() => loadPage()),h('button',{type:'button',class:'button secondary',id:'export-list',disabled:true,onClick:exportList},'Xuất Excel (.xlsx)'));
  content.append(h('section',{class:'panel'},toolbar,h('p',{class:'muted',id:'list-status','aria-live':'polite'},'Chưa tải dữ liệu.')),h('div',{id:'data-content'}));
  await loadPage();
}
async function overview(content) {
  const g = generation, p = ++pageGeneration;
  content.replaceChildren(h('p',{class:'loading'},'Đang tải số liệu từ Firestore…'));
  try {
    const [counts,config] = await Promise.all([api.counts(),api.config()]);
    if (!safeCurrent(g) || p !== pageGeneration) return;
    const stats = h('div',{class:'stats'});
    for (const [i,label,foot,icon] of [[0,'Mục trong danh mục','Gồm món đang dùng và đã ẩn','♧'],[1,'Tài khoản đã đồng bộ','Danh sách tối thiểu, không chứa hồ sơ sức khỏe','♙'],[2,'Tài khoản đang tạm khóa','Khóa truy cập HealthMate qua Firestore','▣'],[3,'Thao tác quản trị','Thay đổi có nhật ký xác nhận','◷']]) stats.append(h('section',{class:'stat'},h('div',{class:'stat-label'},label,h('span',{class:'stat-icon'},icon)),h('div',{class:'stat-number'},String(counts[i])),h('div',{class:'stat-foot'},foot)));
    const configPanel = h('section',{class:'panel'},h('div',{class:'panel-title'},h('h2',{},'Trạng thái tính năng'),button('Điều chỉnh',() => openPage('app_config'))));
    for (const [label,sub,enabled] of [['Quét món bằng AI','Nhận diện ảnh và ước tính dinh dưỡng',config?.foodScannerEnabled ?? true],['AI Chatbot','Hỗ trợ theo dõi thói quen',config?.chatbotEnabled ?? true],['Chế độ bảo trì','Thông báo khi cần tạm dừng ứng dụng',config?.maintenanceMode ?? false]]) configPanel.append(h('div',{class:'feature-card'},h('div',{},h('strong',{},label),h('p',{},sub)),pill(enabled?'Đang bật':'Đang tắt',enabled?'':'off')));
    content.replaceChildren(stats,h('div',{class:'overview-grid'},configPanel,h('section',{class:'panel'},h('p',{class:'eyebrow'},'DỮ LIỆU & QUYỀN RIÊNG TƯ'),h('h2',{},'Đúng quyền. Đúng dữ liệu.'),h('p',{class:'muted'},'Admin quản lý dữ liệu thực phẩm dùng chung và quyền truy cập. Nhật ký bữa ăn, cân nặng và hội thoại cá nhân vẫn thuộc tài khoản người dùng.'),h('p',{class:'notice'},'Cấu hình từ xa có hiệu lực với bản app đã bật quản trị từ xa. Khóa Firestore không vô hiệu hóa tài khoản Firebase Authentication.'),button('Xem nhật ký thao tác',() => openPage('admin_audit')))));
  } catch(error) { if(safeCurrent(g) && p === pageGeneration) content.replaceChildren(h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',() => overview(content))); }
}
async function loadPage() {
  const host = document.querySelector('#data-content'); if (!host) return;
  const g = generation, p = ++pageGeneration;
  rowsReady=false;rows=[];
  const isCurrent=()=>safeCurrent(g)&&p===pageGeneration;
  document.querySelector('#export-list').disabled=true;
  host.replaceChildren(h('p',{class:'loading'},'Đang tải dữ liệu…'));
  try {
    const loaded = await api.list(currentPage,{isCurrent,onProgress:count=>{
      if(isCurrent())document.querySelector('#list-status').textContent=`Đã đọc ${count} mục; đang kiểm tra đủ danh sách…`;
    }});
    if (!isCurrent()) return;
    rows=loaded;rowsReady=true;pageNumber=1;
    const categories=document.querySelector('#category-filter');
    if(currentPage==='food_catalog'&&categories){
      categories.replaceChildren(h('option',{value:''},'Tất cả nhóm'),...[...new Set(rows.map(r=>r.category).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'vi')).map(value=>h('option',{value},value)));
      categories.value=categoryFilter;
      if(categories.value!==categoryFilter)categoryFilter='';
    }
    document.querySelector('#list-status').textContent=`Đã tải đủ ${rows.length} mục từ máy chủ. Tìm kiếm và Excel áp dụng cho toàn bộ kết quả lọc, không chỉ trang đang xem.`;
    document.querySelector('#export-list').disabled=false;
    renderRows();
  } catch(error) { if(isCurrent()) {
    document.querySelector('#list-status').textContent='Chưa tải đủ dữ liệu; chưa thể tìm kiếm hoặc xuất toàn danh sách.';
    host.replaceChildren(h('section',{class:'panel'},h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',() => loadPage())));
  } }
}
function renderRows() {
  const host = document.querySelector('#data-content'); if (!host) return;
  if(!rowsReady)return;
  const filtered = currentRows(), page=paginateRows(filtered,pageNumber);pageNumber=page.page;
  const table = h('table'), labels = currentPage === 'food_catalog' ? ['STT','MÓN ĂN / NGUỒN','NHÓM','KCAL / 100 G','TRẠNG THÁI','THAO TÁC'] : currentPage === 'user_directory' ? ['STT','TÀI KHOẢN','VAI TRÒ','TRẠNG THÁI','CẬP NHẬT','THAO TÁC'] : ['STT','THỜI GIAN','ĐỐI TƯỢNG / THAO TÁC','NGƯỜI THỰC HIỆN','LÝ DO'];
  table.append(h('thead',{},h('tr',{},...labels.map(label => h('th',{},label)))));
  const body = h('tbody'); table.append(body);
  for (const [index,row] of page.rows.entries()) {
    const stt=h('td',{class:'number'},String(page.offset+index+1));
    if (currentPage === 'food_catalog') body.append(h('tr',{},stt,h('td',{},h('strong',{},row.name),h('small',{},row.sourceLabel),row.isEstimated?pill('Ước tính','off'):null),h('td',{},row.category),h('td',{class:'number'},String(row.kcalPer100g??'—')),h('td',{},pill(row.isActive===false?'Đã xóa khỏi danh mục':'Đang hiển thị',row.isActive===false?'off':'')),h('td',{class:'row-actions'},h('button',{class:'small-button',onClick:()=>viewFood(row)},'Chi tiết'),h('button',{class:'small-button',onClick:() => editFood(row)},'Sửa'),h('button',{class:'small-button',onClick:()=>archiveFood(row)},row.isActive===false?'Khôi phục':'Xóa khỏi danh mục'))));
    else if (currentPage === 'user_directory') body.append(h('tr',{},stt,h('td',{},h('strong',{},row.displayName||'Chưa đặt tên'),h('small',{},row.email),h('small',{},row.id)),h('td',{},pill(row.adminRole?.enabled?'Admin':'Người dùng',row.adminRole?.enabled?'':'off')),h('td',{},pill(row.control?.status === 'suspended'?'Tạm khóa':'Hoạt động',row.control?.status === 'suspended'?'suspended':'')),h('td',{},date(row.updatedAt)),h('td',{class:'row-actions'},h('button',{class:'small-button',onClick:()=>viewAccount(row)},'Chi tiết'),!canControlAccount(row,user.uid)?h('small',{},row.id===user.uid?'Tài khoản hiện tại':'Tài khoản được bảo vệ'):h('button',{class:'small-button',onClick:() => editAccount(row)},row.control?.status==='suspended'?'Mở truy cập':'Khóa truy cập'))));
    else body.append(h('tr',{},stt,h('td',{class:'number'},date(row.at)),h('td',{},h('strong',{},`${row.entityType} / ${row.entityId}`),h('small',{},(row.changedFields??[]).join(', '))),h('td',{},h('code',{},row.actorUid)),h('td',{},row.reason)));
  }
  const panel = h('section',{class:'panel'},h('div',{class:'table-wrap'},table));
  if (!filtered.length) panel.append(h('p',{class:'empty'},rows.length?'Không có kết quả phù hợp trên toàn danh sách. Thử đổi từ khóa hoặc bộ lọc.':currentPage==='user_directory'?'Chưa có tài khoản đồng bộ. Tài khoản xuất hiện sau khi dùng bản app hỗ trợ quản trị từ xa.':'Chưa có dữ liệu từ máy chủ.'));
  const go=n=>{pageNumber=n;renderRows();};
  panel.append(h('div',{class:'table-foot'},h('span',{},`Trang ${page.page}/${page.pages} · ${filtered.length} kết quả / ${rows.length} tổng mục`),h('div',{class:'pagination'},h('button',{type:'button',class:'button secondary',disabled:page.page===1,onClick:()=>go(1)},'Đầu'),h('button',{type:'button',class:'button secondary',disabled:page.page===1,onClick:()=>go(page.page-1)},'Trước'),h('button',{type:'button',class:'button secondary',disabled:page.page===page.pages,onClick:()=>go(page.page+1)},'Sau'),h('button',{type:'button',class:'button secondary',disabled:page.page===page.pages,onClick:()=>go(page.pages)},'Cuối'))));
  host.replaceChildren(panel);
}
function currentRows(){return filterRows(rows,currentPage,{search:filter,category:categoryFilter,status:statusFilter,role:roleFilter});}
function exportList(){
  if(!rowsReady||editorBusy)return;
  const kind=currentPage,selected=currentRows();
  openEditor('Xuất toàn bộ danh sách đã lọc',[
    h('p',{},`${selected.length} dòng, gồm mọi trang của kết quả lọc hiện tại.`),
    h('p',{class:'notice'},kind==='user_directory'?'Tệp có email và UID. Chỉ lưu vào nơi bạn quản lý; tệp tải về không tự bị xóa khi đăng xuất.':'Tệp Excel có số liệu nguồn và trạng thái hiện tại. Không gồm nhật ký sức khỏe cá nhân.'),
  ],async()=>{
    const g=generation;
    const bytes=buildXlsx(exportRows(kind,selected));
    if(!safeCurrent(g))throw Error('Phiên xuất đã thay đổi.');
    const url=URL.createObjectURL(new Blob([bytes],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}));
    const a=h('a',{href:url,download:`HealthMate-${kind}-${new Date().toISOString().slice(0,10)}.xlsx`});
    document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  },{reason:false,success:'Đã tạo tệp Excel và yêu cầu trình duyệt tải xuống.'});
}
function field(name,label,value='',{type='text',max=100,optional=false,hint='',readonly=false}={}) {
  const input = h(type==='textarea'?'textarea':'input',{name,id:`field-${name}`,value:String(value??''),required:!optional,maxLength:max,readOnly:readonly,...(type==='textarea'?{}:{type:type==='number'?'text':type}),...(type==='number'?{inputMode:'decimal'}:{})});
  return h('label',{class:'field'},label,input,hint?h('small',{},hint):null);
}
function checkbox(name,label,checked,description='') { return h('label',{class:'check-field'},h('input',{type:'checkbox',name,checked}),h('div',{},h('strong',{},label),description?h('small',{},description):null)); }
function values(form) { const data=Object.fromEntries(new FormData(form)); for (const box of form.querySelectorAll('input[type=checkbox]')) data[box.name]=box.checked; return data; }
let editorSuccess = '';
function openEditor(title,children,action=null,{reason=true,success='Đã lưu thay đổi và nhật ký quản trị.'}={}) {
  if (editorBusy || !allowed) return;
  fieldsHost.replaceChildren(...children,...(reason&&action?[field('reason','Lý do thay đổi','',{type:'textarea',max:200,hint:'Lưu trong nhật ký quản trị. Với khóa/mở tài khoản, lý do sẽ hiển thị cho người dùng.'})]:[]));
  editorSuccess=success;document.querySelector('#submit-editor').hidden=!action;
  document.querySelector('#editor-title').textContent=title; document.querySelector('#editor-error').textContent=''; editorAction=action; dialog.showModal();
}
function viewFood(row){openEditor('Chi tiết món ăn',[
  h('h3',{},row.name),h('p',{},`${row.id} · ${row.category}`),
  pill(row.isActive===false?'Đã xóa khỏi danh mục':'Đang hiển thị',row.isActive===false?'off':''),
  h('p',{},`Trên 100 g: ${row.kcalPer100g} kcal · Đạm ${row.proteinGPer100g} g · Carb ${row.carbsGPer100g} g · Béo ${row.fatGPer100g} g · Xơ ${row.fiberGPer100g??'Chưa có dữ liệu'}`),
  h('p',{},`Nguồn: ${row.sourceLabel}`),h('p',{},row.sourceUrl),h('p',{},`Tên tương đương: ${(row.alternateNames??[]).join(', ')||'—'}`),
  h('p',{},`Cập nhật: ${date(row.updatedAt)}`),
]);}
function viewAccount(row){openEditor('Chi tiết tài khoản',[
  h('h3',{},row.displayName||'Chưa đặt tên'),h('p',{},row.email),h('p',{},`UID: ${row.id}`),
  h('p',{},`Vai trò: ${row.adminRole?.enabled?'Admin':'Người dùng'}${row.adminRole?' · được bảo vệ khỏi khóa trên web':''}`),
  h('p',{},`Trạng thái truy cập: ${row.control?.status==='suspended'?'Tạm khóa':'Hoạt động'}`),
  h('p',{},`Lý do gần nhất: ${row.control?.reason||'—'}`),
  h('p',{class:'notice'},'Đây là danh bạ tài khoản đồng bộ từ HealthMate; không phải toàn bộ Firebase Authentication. Admin không được xem nhật ký sức khỏe, đổi mật khẩu hoặc xóa tài khoản Auth tại đây.'),
]);}
function archiveFood(row){const restore=row.isActive===false;openEditor(restore?'Khôi phục món ăn?':'Xóa món khỏi danh mục?',[
  h('h3',{},row.name),h('p',{class:'notice'},restore?'Món sẽ hiển thị lại trong danh mục của app sau khi đồng bộ.':'Món được ẩn khỏi danh mục đang dùng. Snapshot bữa ăn cũ và thông tin nguồn vẫn được giữ; có thể khôi phục sau.'),
],async form=>api.save('food_catalog',row.id,{isActive:restore},text(values(form).reason,'Lý do',200),version(row)));}
function editFood(row=null) {
  const data=row??{isActive:true,isEstimated:true};
  openEditor(row?'Chỉnh sửa món ăn':'Thêm món ăn',[
    field('id','Mã món',row?.id??'',{readonly:Boolean(row),hint:'Chữ thường, số và dấu gạch ngang. Mã không đổi sau khi tạo.'}),
    field('name','Tên món',data.name),
    h('div',{class:'field-row'},field('category','Nhóm món',data.category),field('alternateNames','Tên tương đương',(data.alternateNames??[]).join('\n'),{type:'textarea',max:808,optional:true,hint:'Mỗi tên một dòng, tối đa 8 tên.'})),
    h('p',{class:'notice'},'Mọi giá trị dinh dưỡng bên dưới tính trên 100 g. Để trống chất xơ khi chưa có dữ liệu; không tự thay bằng 0.'),
    h('div',{class:'field-row nutrients'},...['kcalPer100g','proteinGPer100g','carbsGPer100g','fatGPer100g','fiberGPer100g'].map((key,i)=>field(key,['Năng lượng (kcal)','Đạm (g)','Carbohydrate (g)','Chất béo (g)','Chất xơ (g)'][i],data[key],{type:'number',optional:key==='fiberGPer100g'}))),
    field('sourceLabel','Tên nguồn dinh dưỡng',data.sourceLabel,{max:160}),field('sourceUrl','Đường dẫn nguồn (HTTPS)',data.sourceUrl,{max:500}),
    h('div',{class:'field-row'},field('servingLabel','Tên khẩu phần',data.servingLabel,{max:60,optional:true}),field('servingGrams','Gram / khẩu phần',data.servingGrams,{type:'number',optional:true})),
    checkbox('isEstimated','Dữ liệu ước tính',data.isEstimated!==false),checkbox('isActive','Hiển thị trong danh mục app',data.isActive!==false,'Ẩn món không xóa hoặc thay đổi snapshot trong nhật ký đã ghi.')
  ],async form => { const input=values(form); await api.save('food_catalog',validFoodId(input.id),foodPayload(input),text(input.reason,'Lý do',200),version(row)); });
}
function editAccount(row) {
  const suspended=row.control?.status !== 'suspended';
  openEditor(suspended?'Tạm khóa truy cập':'Mở lại truy cập',[
    h('p',{},`${row.displayName||'Tài khoản'} · ${row.email}`),h('p',{class:'notice'},suspended?'Tài khoản sẽ bị chặn truy cập dữ liệu HealthMate qua Firestore Rules. Không xóa nhật ký hoặc vô hiệu hóa Firebase Auth.':'Khôi phục quyền truy cập HealthMate. Dữ liệu cá nhân được giữ nguyên.'),
    field('uid','UID',row.id,{readonly:true,max:128})
  ],async form => { const reason=text(values(form).reason,'Lý do',200); await api.save('account_controls',row.id,{status:suspended?'suspended':'active',reason},reason,version(row.control)); });
}
async function configPage(content) {
  const g=generation,p=++pageGeneration; content.replaceChildren(h('p',{class:'loading'},'Đang tải cấu hình…'));
  try {
    currentConfig=await api.config(); if(!safeCurrent(g)||p!==pageGeneration)return;
    const c=currentConfig??{};
    const form=h('form',{class:'config-form',onSubmit:event => {
      event.preventDefault();
      try { const payload=configPayload(values(form)); openEditor('Xác nhận thay đổi cấu hình',[h('p',{class:'notice'},'Thay đổi sẽ áp dụng cho các bản HealthMate bật quản trị từ xa. Kiểm tra các lựa chọn trước khi lưu.'),h('p',{},`Chatbot: ${payload.chatbotEnabled?'bật':'tắt'} · Quét món: ${payload.foodScannerEnabled?'bật':'tắt'} · Bảo trì: ${payload.maintenanceMode?'bật':'tắt'}`)],async review => api.save('app_config','runtime',payload,text(values(review).reason,'Lý do',200),version(currentConfig))); }
      catch(error){ notify(errorMessage(error),true); }
    }},
    checkbox('foodScannerEnabled','Quét món bằng AI',c.foodScannerEnabled!==false,'Cho phép sử dụng tính năng nhận diện ảnh. Cờ tắt trong bản build vẫn được ưu tiên.'),
    checkbox('chatbotEnabled','AI Chatbot',c.chatbotEnabled!==false,'Bật/tắt lối vào và điều kiện gọi AI trong bản app hỗ trợ.'),
    h('div',{class:'divider'}),checkbox('maintenanceMode','Chế độ bảo trì',c.maintenanceMode===true,'Hiển thị thông báo thay cho nội dung app với người dùng đang đăng nhập.'),
    field('maintenanceMessage','Thông báo bảo trì',c.maintenanceMessage,{type:'textarea',max:300,optional:true,hint:'Bắt buộc khi bật bảo trì. Tối đa 300 ký tự.'}),
    h('p',{class:'muted'},`Cập nhật gần nhất: ${date(c.updatedAt)}`),h('button',{type:'submit',class:'button'},'Kiểm tra và lưu cấu hình'));
    content.replaceChildren(h('section',{class:'panel config-wrap'},h('p',{class:'notice'},'Không cấu hình API key, secret hoặc tên model AI tại đây. Các giới hạn gói dịch vụ không thay đổi khi bật/tắt tính năng.'),form));
  } catch(error){if(safeCurrent(g)&&p===pageGeneration)content.replaceChildren(h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',()=>configPage(content)));}
}
function closeEditor() { if(!editorBusy)dialog.close(); }
document.querySelector('#close-editor').addEventListener('click',closeEditor);
document.querySelector('#cancel-editor').addEventListener('click',closeEditor);
dialog.addEventListener('cancel',event=>{if(editorBusy)event.preventDefault();});
editorForm.addEventListener('submit',async event=>{
  event.preventDefault(); if(editorBusy||!allowed||!editorAction)return;
  const g=generation,submit=document.querySelector('#submit-editor'),error=document.querySelector('#editor-error');
  editorBusy=true; submit.disabled=true; submit.textContent='Đang chờ máy chủ…'; error.textContent='';
  const controls=Array.from(editorForm.elements).map(el=>({el,disabled:el.disabled}));
  try { const operation=editorAction(editorForm); for(const {el} of controls)el.disabled=true; await operation; if(!safeCurrent(g))return; dialog.close();notify(editorSuccess);if(editorSuccess==='Đã lưu thay đổi và nhật ký quản trị.')await openPage(currentPage); }
  catch(e){if(safeCurrent(g))error.textContent=errorMessage(e);}
  finally{editorBusy=false;for(const {el,disabled} of controls)el.disabled=disabled;submit.disabled=false;submit.textContent='Xác nhận và lưu';}
});

try {
  const {connect}=await import('./firebase.mjs'); api=await connect(window.HEALTHMATE_ADMIN_CONFIG);
  api.authChanges(next=>{
    generation++;pageGeneration++;allowed=false;user=next;stopRole?.();stopRole=null;rows=[];rowsReady=false;filter='';dialog.close();
    if(!next){showAuth();return;}
    const g=generation;showAuth('Đang kiểm tra quyền quản trị với máy chủ…');
    stopRole=api.role(next.uid,enabled=>{
      if(g!==generation)return;
      if(!enabled){allowed=false;pageGeneration++;rows=[];dialog.close();showAuth('Tài khoản chưa được cấp quyền admin hoặc chưa xác nhận được quyền từ máy chủ.');return;}
      if(!allowed){allowed=true;openPage('overview');}
    },()=>{if(g===generation){allowed=false;pageGeneration++;rows=[];dialog.close();showAuth('Chưa xác nhận được quyền quản trị. Kiểm tra kết nối hoặc đăng nhập lại.');}});
  });
} catch(error) { root.replaceChildren(h('main',{class:'connecting'},brand(),h('h1',{},'Chưa mở được web quản trị'),h('p',{class:'error'},errorMessage(error)),h('p',{class:'muted'},'Kiểm tra kết nối, cấu hình Firebase và App Check trước khi thử lại.'),button('Tải lại',()=>location.reload()))); }
