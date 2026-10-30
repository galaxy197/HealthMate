import {supportStatuses,supportTypes,supportText,filterSupport} from './support-model.mjs';
import {entityVersion} from './validation.mjs';
import {paginateRows} from './list-model.mjs';
const loads=new WeakMap();

export async function supportPage({host,api,h,button,isCurrent}) {
  const revision=(loads.get(host)??0)+1;loads.set(host,revision);
  const current=()=>isCurrent()&&loads.get(host)===revision;
  let search='',type='',status='',pageNumber=1,detailRevision=0;
  const time=t=>t?.toDate?.()?new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(t.toDate()):'—';
  host.replaceChildren(h('p',{class:'loading'},'Đang tải yêu cầu hỗ trợ…'));
  try {
    const rows=await api.list('support_tickets',{isCurrent:current});if(!current())return;
    function list(){
      if(!current())return;detailRevision++;
      const searchInput=h('input',{type:'search',class:'search',value:search,placeholder:'Tìm tiêu đề, nội dung hoặc UID…','aria-label':'Tìm yêu cầu hỗ trợ',maxLength:200,
        onInput:e=>{search=e.target.value;pageNumber=1;render();}});
      const select=(label,values,value,change)=>h('label',{class:'filter-field'},label,h('select',{'aria-label':label,value,onChange:e=>{change(e.target.value);pageNumber=1;render();}},
        h('option',{value:''},'Tất cả'),...Object.entries(values).map(([v,label])=>h('option',{value:v,selected:v===value},label))));
      const tableHost=h('div',{'aria-live':'polite'});
      function render(){
        if(!current())return;
        const filtered=filterSupport(rows,{search,type,status}),page=paginateRows(filtered,pageNumber);pageNumber=page.page;
        const body=h('tbody',{},...page.rows.map((r,i)=>h('tr',{},h('td',{},String(page.offset+i+1)),h('td',{},h('strong',{},r.title),h('small',{},r.uid)),
          h('td',{},supportTypes[r.type]??'—'),h('td',{},h('span',{class:`pill ${r.status==='resolved'?'off':''}`},supportStatuses[r.status]??'—')),
          h('td',{},time(r.updatedAt)),h('td',{},button('Xem & trả lời',()=>detail(r.id))))));
        tableHost.replaceChildren(h('div',{class:'table-wrap'},h('table',{},h('thead',{},h('tr',{},...['STT','YÊU CẦU / KHÁCH HÀNG','LOẠI','TRẠNG THÁI','CẬP NHẬT (VN)','THAO TÁC'].map(t=>h('th',{},t)))),body)),
          !filtered.length?h('p',{class:'empty'},rows.length?'Không có yêu cầu phù hợp.':'Chưa có báo lỗi hoặc góp ý từ khách hàng.'):null,
          h('div',{class:'table-foot'},h('span',{},`Trang ${page.page}/${page.pages} · ${filtered.length} yêu cầu`),h('div',{class:'pagination'},
            h('button',{type:'button',class:'button secondary',disabled:page.page===1,onClick:()=>{pageNumber--;render();}},'Trước'),
            h('button',{type:'button',class:'button secondary',disabled:page.page===page.pages,onClick:()=>{pageNumber++;render();}},'Sau'))));
      }
      host.replaceChildren(h('section',{class:'panel'},h('div',{class:'toolbar'},searchInput,
        select('Loại yêu cầu',supportTypes,type,v=>type=v),select('Trạng thái',supportStatuses,status,v=>status=v),
        button('Tải lại',()=>supportPage({host,api,h,button,isCurrent}))),tableHost));render();
    }
    async function detail(id){
      if(!current())return;const turn=++detailRevision;const active=()=>current()&&turn===detailRevision;
      host.replaceChildren(h('p',{class:'loading'},'Đang tải cuộc trao đổi…'));
      try{
        const {ticket,messages}=await api.supportThread(id);if(!active())return;
        let busy=false,messageId;
        const error=h('p',{class:'error',role:'alert'});
        const controls=h('div',{class:'toolbar'}),thread=h('div',{class:'support-thread'});
        function message(label,text,at,admin=false){return h('article',{class:`support-message${admin?' from-admin':''}`},h('small',{},`${label} · ${time(at)} (VN)`),h('p',{},text));}
        thread.append(message('Khách hàng',ticket.description,ticket.createdAt),...messages.map(m=>message(m.role==='admin'?'HealthMate hỗ trợ':'Khách hàng',m.text,m.createdAt,m.role==='admin')));
        const statusSelect=h('select',{'aria-label':'Trạng thái xử lý'},...Object.entries(supportStatuses).map(([value,label])=>h('option',{value,selected:value===ticket.status},label)));
        async function run(action){
          if(busy||!active())return;busy=true;error.textContent='';
          for(const element of host.querySelectorAll('button,textarea,select'))element.disabled=true;
          try{await action();if(active())await detail(id);}
          catch(e){if(active()){error.textContent=e.message;busy=false;for(const el of host.querySelectorAll('button,textarea,select'))el.disabled=false;}}
        }
        controls.append(button('← Danh sách',()=>supportPage({host,api,h,button,isCurrent})),h('label',{class:'filter-field'},'Trạng thái xử lý',statusSelect),
          button('Lưu trạng thái',()=>run(()=>api.supportStatus(id,statusSelect.value,entityVersion(ticket)))),button('Tải lại trao đổi',()=>detail(id)));
        const input=h('textarea',{'aria-label':'Trả lời khách hàng',maxLength:2000,rows:5,placeholder:'Nhập phản hồi cho khách hàng…'});
        const send=button('Gửi phản hồi',()=>{
          try{const text=supportText(input.value);messageId??=api.newSupportMessageId();input.readOnly=true;
            run(()=>api.supportReply(id,messageId,text));}catch(e){error.textContent=e.message;}
        },'');
        host.replaceChildren(h('section',{class:'panel'},controls,h('h2',{},ticket.title),h('p',{class:'muted'},`${supportTypes[ticket.type]} · ${supportStatuses[ticket.status]} · UID: ${ticket.uid}`),thread,error,
          ticket.messageCount>=100?h('p',{class:'notice'},'Đã đủ 100 tin nhắn. Khách hàng cần tạo yêu cầu mới để trao đổi thêm.'):
          h('div',{},h('label',{class:'field'},'Trả lời khách hàng',input),h('p',{class:'muted'},'Phản hồi được gửi tới cuộc trao đổi trong app HealthMate.'),send)));
      }catch(e){if(active())host.replaceChildren(h('p',{class:'error'},e.message),button('Tải lại',()=>detail(id)),button('Danh sách',()=>supportPage({host,api,h,button,isCurrent})));}
    }
    list();
  }catch(e){if(current())host.replaceChildren(h('p',{class:'error'},e.message),button('Tải lại',()=>supportPage({host,api,h,button,isCurrent})));}
}
