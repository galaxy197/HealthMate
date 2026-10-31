import { initializeApp } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app.js';
import { getAuth, connectAuthEmulator, setPersistence, browserSessionPersistence, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut, onAuthStateChanged, sendPasswordResetEmail } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-auth.js';
import { getFirestore, connectFirestoreEmulator, doc, collection, getDocFromServer, getDocsFromServer, getCountFromServer, onSnapshot, query, where, orderBy, limit, startAfter, runTransaction, serverTimestamp, documentId, Timestamp } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-firestore.js';
import { initializeAppCheck, ReCaptchaEnterpriseProvider, getToken } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app-check.js';
import { changedFields, entityVersion } from './validation.mjs';
import {supportId,supportText,supportStatuses,validateSupportThread} from './support-model.mjs';
import {createAdminPageReader,collectRange} from './server-paging.mjs';

export async function connect(config) {
  if (!config?.firebase?.projectId) throw Error('Chưa cấu hình Firebase cho web admin.');
  const app = initializeApp(config.firebase);
  const auth = getAuth(app), db = getFirestore(app);
  if (config.emulators) {
    if (!['localhost','127.0.0.1','[::1]'].includes(location.hostname) || !config.firebase.projectId.startsWith('demo-')) throw Error('Emulator chỉ được dùng tại localhost với project demo-.');
    const emu = config.emulators;
    if (emu.auth !== 'http://127.0.0.1:9098' || emu.firestoreHost !== '127.0.0.1' || emu.firestorePort !== 8092) throw Error('Địa chỉ emulator không được hỗ trợ.');
    connectAuthEmulator(auth, emu.auth, { disableWarnings: true });
    connectFirestoreEmulator(db, emu.firestoreHost, emu.firestorePort);
  } else {
    if (location.protocol !== 'https:' && location.hostname !== 'localhost') throw Error('Web quản trị cần HTTPS.');
    if (!config.appCheckSiteKey) throw Error('Cần cấu hình reCAPTCHA Enterprise/App Check trước khi kết nối Firebase thật.');
    const appCheck = initializeAppCheck(app, { provider: new ReCaptchaEnterpriseProvider(config.appCheckSiteKey), isTokenAutoRefreshEnabled: true });
    // Do not open an admin session until this browser has a valid attestation.
    // This client gate does not change project-wide enforcement for mobile.
    let timeout;
    try {
      await Promise.race([getToken(appCheck), new Promise((_,reject) => { timeout = setTimeout(() => reject(Error('App Check timeout')),20000); })]);
    } catch {
      throw Error('Chưa xác minh được trình duyệt bằng App Check. Kiểm tra kết nối, cho phép reCAPTCHA rồi tải lại trang.');
    } finally { clearTimeout(timeout); }
  }
  await setPersistence(auth, browserSessionPersistence);
  auth.languageCode = 'vi';
  let sessionEpoch = 0, accessEpoch = 0;
  const pending = new Map();
  function session() {
    const uid = auth.currentUser?.uid, epoch = sessionEpoch, access = accessEpoch;
    if (!uid || !auth.currentUser.emailVerified) throw Error('Cần đăng nhập bằng tài khoản đã xác minh email.');
    return () => { if(auth.currentUser?.uid !== uid || sessionEpoch !== epoch || accessEpoch !== access)throw Error('Phiên đăng nhập hoặc quyền quản trị đã thay đổi.'); };
  }
  const readPage=createAdminPageReader({
    async fetchDocuments({kind,cursor,pageSize,idFrom,idTo,start,lower,upper}) {
      const clauses=start ? [where('occurredAt','>=',new Date(lower)),where('occurredAt','<',new Date(upper)),orderBy('occurredAt','desc'),orderBy(documentId(),'desc'),
        ...(cursor?[startAfter(new Timestamp(cursor.seconds,cursor.nanoseconds),cursor.id)]:[])] :
        [...(idFrom?[where(documentId(),'>=',idFrom)]:[]),...(idTo?[where(documentId(),'<=',idTo)]:[]),orderBy(documentId()),...(cursor?[startAfter(cursor.id)]:[])];
      const result=await getDocsFromServer(query(collection(db,kind),...clauses,limit(pageSize)));
      return result.docs.map(s=>({...s.data(),id:s.id}));
    },
    async enrichAccount(uid) {
      const [role,control]=await Promise.all([getDocFromServer(doc(db,'admin_roles',uid)),getDocFromServer(doc(db,'account_controls',uid))]);
      return {adminRole:role.exists()?role.data():null,control:control.exists()?control.data():null};
    },
  });
  function guarded(options={}) {
    const verify=session();
    return {...options,isCurrent:()=>{verify();return options.isCurrent?.()??true;}};
  }
  return {
    emulator: Boolean(config.emulators), projectId: config.firebase.projectId,
    authChanges: callback => onAuthStateChanged(auth, next => {sessionEpoch++;pending.clear();callback(next);}),
    login: (email, password) => signInWithEmailAndPassword(auth, email, password), logout: () => signOut(auth),
    loginGoogle: () => {
      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({prompt:'select_account'});
      return signInWithPopup(auth,provider);
    },
    resetPassword: email => sendPasswordResetEmail(auth,email.trim()),
    role: (uid, onData, onError) => {
      let last;
      return onSnapshot(doc(db,'admin_roles',uid), { includeMetadataChanges: true }, s => {
        const enabled = auth.currentUser?.emailVerified === true && s.exists() && s.data().enabled === true && !s.metadata.isFromCache;
        if(last !== enabled){accessEpoch++;last=enabled;}
        onData(enabled);
      }, error => {accessEpoch++;onError(error);});
    },
    listPage: (kind,options={})=>readPage(kind,guarded({...options,pageSize:25})),
    exportRange: (kind,options={})=>collectRange(readPage,kind,guarded(options)),
    newSupportMessageId() { return doc(collection(db,'support_tickets')).id; },
    async supportThread(id) {
      supportId(id);const check=session();
      const ticket=await getDocFromServer(doc(db,'support_tickets',id));check();
      if(!ticket.exists())throw Error('Yêu cầu không còn khả dụng.');
      const messages=await getDocsFromServer(query(collection(db,'support_tickets',id,'messages'),orderBy('sequence'),limit(101)));check();
      return validateSupportThread({id,...ticket.data()},messages.docs.map(s=>({id:s.id,...s.data()})));
    },
    async supportReply(id,messageId,input) {
      supportId(id);supportId(messageId);const text=supportText(input),check=session(),actorUid=auth.currentUser.uid;
      const ticket=doc(db,'support_tickets',id),message=doc(ticket,'messages',messageId);
      await runTransaction(db,async t=>{
        check();const [existing,parent]=await Promise.all([t.get(message),t.get(ticket)]);
        if(!parent.exists()||parent.data().deleting)throw Error('Yêu cầu không còn khả dụng.');
        if(existing.exists()){
          if(existing.data().authorUid!==actorUid||existing.data().text!==text)throw Error('Mã phản hồi đã được dùng. Tải lại cuộc trao đổi.');
          return;
        }
        if(parent.data().messageCount>=100)throw Error('Cuộc trao đổi đã đủ 100 tin nhắn.');
        const count=parent.data().messageCount+1;
        t.set(message,{authorUid:actorUid,role:'admin',text,sequence:count,createdAt:serverTimestamp()});
        t.update(ticket,{messageCount:count,lastMessageId:messageId,updatedBy:actorUid,updatedAt:serverTimestamp()});
      });check();
      const confirmed=await getDocFromServer(message);check();
      if(!confirmed.exists()||confirmed.data().authorUid!==actorUid||confirmed.data().text!==text)throw Error('Chưa xác nhận gửi phản hồi. Hãy thử lại.');
    },
    async supportStatus(id,status,expectedVersion) {
      supportId(id);if(!Object.hasOwn(supportStatuses,status))throw Error('Trạng thái không hợp lệ.');
      const check=session(),actorUid=auth.currentUser.uid,ticket=doc(db,'support_tickets',id);
      await runTransaction(db,async t=>{
        check();const current=await t.get(ticket);
        if(!current.exists()||current.data().deleting)throw Error('Yêu cầu không còn khả dụng.');
        if(current.data().status===status)return;
        if(entityVersion(current.data())!==expectedVersion)throw Error('Yêu cầu vừa thay đổi. Tải lại trước khi lưu trạng thái.');
        t.update(ticket,{status,updatedAt:serverTimestamp(),updatedBy:actorUid});
      });check();
      const confirmed=await getDocFromServer(ticket);check();
      if(!confirmed.exists()||confirmed.data().status!==status)throw Error('Trạng thái vừa thay đổi. Hãy tải lại.');
    },
    async config() { const check=session();const s = await getDocFromServer(doc(db,'app_config','runtime'));check();return s.exists() ? s.data() : null; },
    async counts() {
      const check=session();
      const requests = [collection(db,'food_catalog'),collection(db,'user_directory'),query(collection(db,'account_controls'),where('status','==','suspended')),collection(db,'admin_audit')];
      const result=await Promise.all(requests.map(async q => (await getCountFromServer(q)).data().count));check();return result;
    },
    async save(kind, id, payload, reason, expectedVersion) {
      const actorUid = auth.currentUser?.uid;
      const check = session();
      if(!['food_catalog','account_controls','app_config'].includes(kind) || typeof id!=='string'||id.includes('/'))throw Error('Đối tượng thao tác không hợp lệ.');
      const key = JSON.stringify([actorUid,kind,id,payload,reason,expectedVersion]);
      const audit = pending.get(key) ?? doc(collection(db,'admin_audit'));
      if (pending.size > 100) pending.clear();
      pending.set(key,audit);
      const target = doc(db,kind,id);
      await runTransaction(db,async t => {
        check();
        const current = await t.get(target), before = current.exists() ? current.data() : null;
        if (before?.lastAdminOperationId === audit.id) return;
        const actualVersion = entityVersion(before);
        if (actualVersion !== expectedVersion) throw Error('Dữ liệu đã được thay đổi. Đóng form, tải lại rồi kiểm tra bản mới trước khi lưu.');
        const metadata = { updatedAt: serverTimestamp(), updatedBy: actorUid, lastAdminOperationId: audit.id };
        const after = { ...before, ...payload, ...metadata };
        const changes = changedFields(before,after,kind);
        // Timestamp sentinels are not the same as the previous server timestamp.
        for (const field of ['updatedAt','lastAdminOperationId']) if (!changes.includes(field)) changes.push(field);
        t.set(target,after);
        t.set(audit,{ actorUid, entityType: kind, entityId: id, at: serverTimestamp(), changedFields: changes, reason });
      });
      check();
      const confirmed = await getDocFromServer(target);
      check();
      if (confirmed.metadata.isFromCache || confirmed.metadata.hasPendingWrites || confirmed.data()?.lastAdminOperationId !== audit.id) throw Error('Chưa xác nhận được thay đổi trên máy chủ. Bản nháp được giữ để thử lại.');
      pending.delete(key);
    }
  };
}
