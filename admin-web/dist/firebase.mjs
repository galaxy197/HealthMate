import { initializeApp } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app.js';
import { getAuth, connectAuthEmulator, setPersistence, browserSessionPersistence, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut, onAuthStateChanged, sendPasswordResetEmail } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-auth.js';
import { getFirestore, connectFirestoreEmulator, doc, collection, getDocFromServer, getDocsFromServer, getCountFromServer, onSnapshot, query, where, orderBy, limit, startAfter, runTransaction, serverTimestamp, documentId } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-firestore.js';
import { initializeAppCheck, ReCaptchaEnterpriseProvider, getToken } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app-check.js';
import { changedFields, entityVersion } from './validation.mjs';
import { adminLists, collectAdminRows } from './list-model.mjs';

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
  async function all(kind, check, onProgress) {
    if(![...adminLists,'account_controls'].includes(kind))throw Error('Danh sách không được hỗ trợ.');
    return collectAdminRows(async cursor => {
      check();
      const q = query(collection(db,kind), orderBy(documentId()), ...(cursor ? [startAfter(cursor)] : []), limit(200));
      const result = await getDocsFromServer(q);
      check();
      return {rows:result.docs.map(s => ({...s.data(),id:s.id})), cursor:result.docs.at(-1), hasMore:result.size === 200};
    }, {isCurrent: () => {check();return true;},onProgress});
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
    async list(kind, {isCurrent = () => true, onProgress} = {}) {
      const verify = session();
      const check = () => {verify();if(!isCurrent())throw Error('Đã chuyển trang; phiên tải cũ đã hủy.');};
      const data = await all(kind,check,onProgress);
      if (kind === 'user_directory') {
        const controls = new Map((await all('account_controls',check)).map(r => [r.id,r]));
        // Only check roles for known directory IDs; no role listing or granting.
        for(let at=0;at<data.length;at+=20) {
          check();
          await Promise.all(data.slice(at,at+20).map(async row => {
            const role = await getDocFromServer(doc(db,'admin_roles',row.id));
            check();row.adminRole = role.exists() ? role.data() : null;row.control = controls.get(row.id) ?? null;
          }));
        }
      }
      check();
      return data.sort(kind === 'admin_audit' ? (a,b)=>(b.at?.toMillis?.()??0)-(a.at?.toMillis?.()??0)||a.id.localeCompare(b.id) :
        (a,b)=>String(a.name??a.displayName??a.email??a.id).localeCompare(String(b.name??b.displayName??b.email??b.id),'vi')||a.id.localeCompare(b.id));
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
