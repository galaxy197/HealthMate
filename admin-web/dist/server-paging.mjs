import {adminLists, adminPageSize, collectAdminRows} from './list-model.mjs';
import {dateBoundary} from './revenue-model.mjs';

export function pageScope(kind, {idFrom = '', idTo = '', start = '', end = ''} = {}) {
  if (!adminLists.includes(kind)) throw Error('Danh sách không được hỗ trợ.');
  for (const id of [idFrom,idTo]) if (typeof id !== 'string' || id.length > 1500 || id.includes('/')) throw Error('Khoảng mã không hợp lệ.');
  if (idFrom && idTo && idFrom > idTo) throw Error('Mã bắt đầu phải đứng trước mã kết thúc.');
  if (Boolean(start) !== Boolean(end) || ((start || end) && kind !== 'demo_premium_transactions')) throw Error('Phạm vi ngày không hợp lệ.');
  if(start&&(idFrom||idTo))throw Error('Chọn phạm vi ngày hoặc mã, không kết hợp hai loại.');
  let lower,upper;
  if (start && end) {
    lower=dateBoundary(start);upper=dateBoundary(end)+86400000;
    if(upper<=lower||upper-lower>366*86400000)throw Error('Chọn khoảng báo cáo từ 1 đến 366 ngày.');
  }
  return {kind,idFrom,idTo,start,end,lower,upper,key:JSON.stringify([kind,idFrom,idTo,start,end])};
}

// All display paths read one server page. No row cache or private persistence.
// Cursor ordering is stable for an unchanged data set, not a snapshot spanning
// concurrent writes. ID cursors continue to work when the boundary row is deleted.
export function createAdminPageReader({fetchDocuments,enrichAccount}) {
  return async function readPage(kind,{cursor=null,pageSize=adminPageSize,isCurrent=()=>true,...range}={}) {
    const scope=pageScope(kind,range);
    if(!Number.isInteger(pageSize)||pageSize<1||pageSize>200)throw Error('Kích thước trang không hợp lệ.');
    if(cursor && (cursor.scope!==scope.key || typeof cursor.id!=='string' || !cursor.id || cursor.id.includes('/') ||
      (scope.start && (!Number.isSafeInteger(cursor.seconds)||!Number.isInteger(cursor.nanoseconds)||cursor.nanoseconds<0||cursor.nanoseconds>999999999))))throw Error('Con trỏ không thuộc phạm vi đang xem.');
    const check=()=>{if(!isCurrent())throw Error('Phiên tải đã kết thúc.');};
    check();const result=await fetchDocuments({...scope,cursor,pageSize});check();
    if(!Array.isArray(result)||result.length>pageSize)throw Error('Trang dữ liệu không hợp lệ.');
    const ids=new Set();
    for(const row of result){
      if(typeof row.id!=='string'||!row.id||ids.has(row.id))throw Error('Trang có mã trùng hoặc không hợp lệ.');
      ids.add(row.id);
    }
    const rows=kind==='user_directory'?await Promise.all(result.map(async row=>{
      check();const extra=await enrichAccount(row.id);check();return {...row,...extra};
    })):result;
    check();const last=rows.at(-1);
    const nextCursor=last?{scope:scope.key,id:last.id,...(scope.start?{seconds:last.occurredAt?.seconds,nanoseconds:last.occurredAt?.nanoseconds}: {})}:null;
    if(scope.start&&last&&(!Number.isSafeInteger(nextCursor.seconds)||!Number.isInteger(nextCursor.nanoseconds)||nextCursor.nanoseconds<0||nextCursor.nanoseconds>999999999))throw Error('Giao dịch chưa có thời điểm hợp lệ.');
    return {rows,cursor:nextCursor,hasMore:rows.length===pageSize};
  };
}

export async function collectRange(readPage,kind,{isCurrent=()=>true,onProgress=()=>{},...range}={}) {
  // The caller must choose an explicit range. A blank endpoint is an open side,
  // but both blank must never turn an export into an unbounded collection scan.
  if(!(range.idFrom||range.idTo||(range.start&&range.end)))throw Error('Chọn khoảng mã hoặc ngày trước khi xuất/tổng hợp.');
  return collectAdminRows(cursor=>readPage(kind,{...range,cursor,pageSize:200,isCurrent}),{isCurrent,onProgress});
}
