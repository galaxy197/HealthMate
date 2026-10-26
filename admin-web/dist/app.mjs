import { foodPayload, configPayload, text, validFoodId, entityVersion } from './validation.mjs';

const root = document.querySelector('#app'), dialog = document.querySelector('#editor');
const editorForm = document.querySelector('#editor-form'), fieldsHost = document.querySelector('#editor-fields');
let api, user, allowed = false, stopRole, generation = 0, pageGeneration = 0;
let currentPage = 'overview', rows = [], cursor, hasMore = false, pageNumber = 1, filter = '';
let editorAction, editorBusy = false, currentConfig = null;
const pages = {
  overview: ['Tổng quan', 'Theo dõi và vận hành HealthMate', 'Một nơi để chăm sóc dữ liệu, tài khoản và trải nghiệm trong ứng dụng.'],
  food_catalog: ['Danh mục món ăn', 'Dữ liệu tốt, lựa chọn tốt hơn', 'Quản lý nguồn dinh dưỡng dùng chung. Chỉnh danh mục không làm thay đổi nhật ký đã lưu.'],
  user_directory: ['Tài khoản', 'Quản lý quyền truy cập', 'Chỉ hiển thị thông tin tài khoản tối thiểu. Hồ sơ và nhật ký sức khỏe vẫn riêng tư.'],
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
  return h('form',{onSubmit: async event => {
    event.preventDefault(); submit.disabled = true; message.textContent = ''; submit.textContent = 'Đang xác nhận…';
    try { await api.login(email.value.trim(),password.value); password.value = ''; }
    catch(error) { message.textContent = errorMessage(error); submit.disabled = false; submit.textContent = 'Đăng nhập'; }
  }},h('label',{class:'field'},'Email quản trị',email),h('label',{class:'field'},'Mật khẩu',password),message,submit);
}
function shell() {
  const nav = h('nav',{class:'nav-group','aria-label':'Quản trị'},h('p',{},'KHÔNG GIAN LÀM VIỆC'));
  const icons = { overview:'▦',food_catalog:'♧',user_directory:'♙',app_config:'☷',admin_audit:'◷' };
  for (const [key,info] of Object.entries(pages)) nav.append(h('button',{class:`nav-button${currentPage===key?' active':''}`,'data-page':key,onClick:() => openPage(key)},h('span',{class:'nav-icon','aria-hidden':'true'},icons[key]),info[0]));
  const main = h('main',{class:'main',id:'main-content'});
  root.replaceChildren(h('div',{class:'layout'},h('aside',{class:'sidebar'},brand(),nav,h('div',{class:'sidebar-bottom'},h('strong',{},'Quản trị có trách nhiệm'),h('p',{},'Chỉ truy cập dữ liệu cần thiết. Mỗi thay đổi được ghi vào nhật ký.'))),h('div',{class:'workspace'},h('header',{class:'topbar'},h('span',{class:'breadcrumb'},'HealthMate / Quản trị'),h('div',{class:'identity'},h('span',{class:`environment${api.emulator?'':' cloud'}`},api.emulator?'LOCAL · EMULATOR':'FIREBASE · PRODUCTION'),h('span',{class:'avatar','aria-hidden':'true'},'A'),h('span',{class:'identity-name'},user.email || user.uid),button('Đăng xuất',() => api.logout()))),main)));
  return main;
}
async function openPage(key) {
  if (!allowed) return;
  currentPage = key; rows = []; cursor = null; hasMore = false; pageNumber = 1; filter = '';
  const main = shell(), info = pages[key];
  main.append(h('div',{class:'page-head'},h('div',{},h('p',{class:'page-kicker'},`QUẢN TRỊ / ${info[0].toUpperCase()}`),h('h1',{},info[1]),h('p',{class:'muted'},info[2])),key === 'food_catalog' ? button('+ Thêm món ăn',() => editFood(), '') : null));
  if (api.emulator) main.append(h('p',{class:'notice local'},'Bạn đang thao tác trên dữ liệu kiểm thử local. Các thay đổi không tác động ứng dụng production.'));
  const content = h('div',{id:'page-content'}); main.append(content);
  if (key === 'overview') return overview(content);
  if (key === 'app_config') return configPage(content);
  content.append(h('section',{class:'panel'},h('div',{class:'toolbar'},h('input',{class:'search',type:'search',placeholder:'Tìm trong 25 mục đang tải…','aria-label':'Tìm trong trang đang tải',onInput:event => { filter=event.target.value; renderRows(); }}),button('Tải lại',() => loadPage(false)))),h('div',{id:'data-content'}));
  await loadPage(false);
}
async function overview(content) {
  const g = generation, p = ++pageGeneration;
  content.replaceChildren(h('p',{class:'loading'},'Đang tải số liệu từ Firestore…'));
  try {
    const [counts,config] = await Promise.all([api.counts(),api.config()]);
    if (!safeCurrent(g) || p !== pageGeneration) return;
    const stats = h('div',{class:'stats'});
    for (const [i,label,foot,icon] of [[0,'Mục trong danh mục','Gồm món đang dùng và đã ẩn','♧'],[1,'Tài khoản đã đồng bộ','Danh sách tối thiểu, không chứa hồ sơ sức khỏe','♙'],[2,'Tài khoản đang tạm khóa','Khóa truy cập HealthMate qua Firestore','▣']]) stats.append(h('section',{class:'stat'},h('div',{class:'stat-label'},label,h('span',{class:'stat-icon'},icon)),h('div',{class:'stat-number'},String(counts[i])),h('div',{class:'stat-foot'},foot)));
    const configPanel = h('section',{class:'panel'},h('div',{class:'panel-title'},h('h2',{},'Trạng thái tính năng'),button('Điều chỉnh',() => openPage('app_config'))));
    for (const [label,sub,enabled] of [['Quét món bằng AI','Nhận diện ảnh và ước tính dinh dưỡng',config?.foodScannerEnabled ?? true],['AI Chatbot','Hỗ trợ theo dõi thói quen',config?.chatbotEnabled ?? true],['Chế độ bảo trì','Thông báo khi cần tạm dừng ứng dụng',config?.maintenanceMode ?? false]]) configPanel.append(h('div',{class:'feature-card'},h('div',{},h('strong',{},label),h('p',{},sub)),pill(enabled?'Đang bật':'Đang tắt',enabled?'':'off')));
    content.replaceChildren(stats,h('div',{class:'overview-grid'},configPanel,h('section',{class:'panel'},h('p',{class:'eyebrow'},'DỮ LIỆU & QUYỀN RIÊNG TƯ'),h('h2',{},'Đúng quyền. Đúng dữ liệu.'),h('p',{class:'muted'},'Admin quản lý dữ liệu thực phẩm dùng chung và quyền truy cập. Nhật ký bữa ăn, cân nặng và hội thoại cá nhân vẫn thuộc tài khoản người dùng.'),h('p',{class:'notice'},'Cấu hình từ xa có hiệu lực với bản app đã bật quản trị từ xa. Khóa Firestore không vô hiệu hóa tài khoản Firebase Authentication.'),button('Xem nhật ký thao tác',() => openPage('admin_audit')))));
  } catch(error) { if(safeCurrent(g) && p === pageGeneration) content.replaceChildren(h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',() => overview(content))); }
}
async function loadPage(next) {
  const host = document.querySelector('#data-content'); if (!host) return;
  const g = generation, p = ++pageGeneration;
  host.replaceChildren(h('p',{class:'loading'},'Đang tải dữ liệu…'));
  try {
    const page = await api.page(currentPage,next?cursor:null);
    if (!safeCurrent(g) || p !== pageGeneration) return;
    rows = page.rows; cursor = page.cursor; hasMore = page.hasMore; pageNumber = next?pageNumber+1:1;
    renderRows();
  } catch(error) { if(safeCurrent(g) && p === pageGeneration) host.replaceChildren(h('section',{class:'panel'},h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',() => loadPage(false)))); }
}
function renderRows() {
  const host = document.querySelector('#data-content'); if (!host) return;
  const needle = filter.trim().toLocaleLowerCase('vi');
  const filtered = rows.filter(row => JSON.stringify([row.name,row.email,row.displayName,row.entityId,row.actorUid,row.reason]).toLocaleLowerCase('vi').includes(needle));
  const table = h('table'), labels = currentPage === 'food_catalog' ? ['MÓN ĂN / NGUỒN','NHÓM','KCAL / 100 G','TRẠNG THÁI',''] : currentPage === 'user_directory' ? ['TÀI KHOẢN','TRẠNG THÁI','CẬP NHẬT',''] : ['THỜI GIAN','ĐỐI TƯỢNG / THAO TÁC','NGƯỜI THỰC HIỆN','LÝ DO'];
  table.append(h('thead',{},h('tr',{},...labels.map(label => h('th',{},label)))));
  const body = h('tbody'); table.append(body);
  for (const row of filtered) {
    if (currentPage === 'food_catalog') body.append(h('tr',{},h('td',{},h('strong',{},row.name),h('small',{},row.sourceLabel),row.isEstimated?pill('Ước tính','off'):null),h('td',{},row.category),h('td',{class:'number'},String(row.kcalPer100g??'—')),h('td',{},pill(row.isActive===false?'Đã ẩn':'Đang hiển thị',row.isActive===false?'off':'')),h('td',{},h('button',{class:'small-button',onClick:() => editFood(row)},'Chỉnh sửa'))));
    else if (currentPage === 'user_directory') body.append(h('tr',{},h('td',{},h('strong',{},row.displayName||'Chưa đặt tên'),h('small',{},row.email),h('small',{},row.id)),h('td',{},pill(row.control?.status === 'suspended'?'Tạm khóa':'Có quyền truy cập',row.control?.status === 'suspended'?'suspended':'')),h('td',{},date(row.updatedAt)),h('td',{},row.id===user.uid?h('small',{},'Tài khoản hiện tại'):h('button',{class:'small-button',onClick:() => editAccount(row)},row.control?.status==='suspended'?'Mở truy cập':'Khóa truy cập'))));
    else body.append(h('tr',{},h('td',{class:'number'},date(row.at)),h('td',{},h('strong',{},`${row.entityType} / ${row.entityId}`),h('small',{},(row.changedFields??[]).join(', '))),h('td',{},h('code',{},row.actorUid)),h('td',{},row.reason)));
  }
  const panel = h('section',{class:'panel'},h('div',{class:'table-wrap'},table));
  if (!filtered.length) panel.append(h('p',{class:'empty'},rows.length?'Chưa có kết quả trong trang này. Thử từ khóa khác hoặc tải trang tiếp theo.':currentPage==='user_directory'?'Chưa có tài khoản đồng bộ. Danh sách được cập nhật từ bản app có quản trị từ xa.':'Chưa có dữ liệu từ máy chủ.'));
  panel.append(h('div',{class:'table-foot'},h('span',{},`Trang ${pageNumber} · ${filtered.length}/${rows.length} mục đang tải`),h('div',{},button('Về trang đầu',() => loadPage(false)),document.createTextNode(' '),h('button',{class:'button secondary',disabled:!hasMore,onClick:() => loadPage(true)},'Trang tiếp theo'))));
  host.replaceChildren(panel);
}
function field(name,label,value='',{type='text',max=100,optional=false,hint='',readonly=false}={}) {
  const input = h(type==='textarea'?'textarea':'input',{name,id:`field-${name}`,value:String(value??''),required:!optional,maxLength:max,readOnly:readonly,...(type==='textarea'?{}:{type:type==='number'?'text':type}),...(type==='number'?{inputMode:'decimal'}:{})});
  return h('label',{class:'field'},label,input,hint?h('small',{},hint):null);
}
function checkbox(name,label,checked,description='') { return h('label',{class:'check-field'},h('input',{type:'checkbox',name,checked}),h('div',{},h('strong',{},label),description?h('small',{},description):null)); }
function values(form) { const data=Object.fromEntries(new FormData(form)); for (const box of form.querySelectorAll('input[type=checkbox]')) data[box.name]=box.checked; return data; }
function openEditor(title,children,action) {
  if (editorBusy || !allowed) return;
  fieldsHost.replaceChildren(...children,field('reason','Lý do thay đổi','',{type:'textarea',max:200,hint:'Lưu trong nhật ký quản trị. Với khóa/mở tài khoản, lý do sẽ hiển thị cho người dùng.'}));
  document.querySelector('#editor-title').textContent=title; document.querySelector('#editor-error').textContent=''; editorAction=action; dialog.showModal();
}
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
  event.preventDefault(); if(editorBusy||!allowed)return;
  const g=generation,submit=document.querySelector('#submit-editor'),error=document.querySelector('#editor-error');
  editorBusy=true; submit.disabled=true; submit.textContent='Đang chờ máy chủ…'; error.textContent='';
  const controls=Array.from(editorForm.elements).map(el=>({el,disabled:el.disabled}));
  try { const operation=editorAction(editorForm); for(const {el} of controls)el.disabled=true; await operation; if(!safeCurrent(g))return; dialog.close();notify('Đã lưu thay đổi và nhật ký quản trị.');await openPage(currentPage); }
  catch(e){if(safeCurrent(g))error.textContent=errorMessage(e);}
  finally{editorBusy=false;for(const {el,disabled} of controls)el.disabled=disabled;submit.disabled=false;submit.textContent='Xác nhận và lưu';}
});

try {
  const {connect}=await import('./firebase.mjs'); api=await connect(window.HEALTHMATE_ADMIN_CONFIG);
  api.authChanges(next=>{
    generation++;pageGeneration++;allowed=false;user=next;stopRole?.();stopRole=null;rows=[];filter='';dialog.close();
    if(!next){showAuth();return;}
    const g=generation;showAuth('Đang kiểm tra quyền quản trị với máy chủ…');
    stopRole=api.role(next.uid,enabled=>{
      if(g!==generation)return;
      if(!enabled){allowed=false;pageGeneration++;rows=[];dialog.close();showAuth('Tài khoản chưa được cấp quyền admin hoặc chưa xác nhận được quyền từ máy chủ.');return;}
      if(!allowed){allowed=true;openPage('overview');}
    },()=>{if(g===generation){allowed=false;pageGeneration++;rows=[];dialog.close();showAuth('Chưa xác nhận được quyền quản trị. Kiểm tra kết nối hoặc đăng nhập lại.');}});
  });
} catch(error) { root.replaceChildren(h('main',{class:'connecting'},brand(),h('h1',{},'Chưa mở được web quản trị'),h('p',{class:'error'},errorMessage(error)),h('p',{class:'muted'},'Kiểm tra cấu hình, kết nối SDK và Firebase Emulator trước khi thử lại.'),button('Tải lại',()=>location.reload()))); }
