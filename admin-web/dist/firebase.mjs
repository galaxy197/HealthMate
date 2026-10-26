import { initializeApp } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app.js';
import { getAuth, connectAuthEmulator, setPersistence, browserSessionPersistence, signInWithEmailAndPassword, signOut, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-auth.js';
import { getFirestore, connectFirestoreEmulator, doc, collection, getDoc, getDocs, getCountFromServer, onSnapshot, query, where, orderBy, limit, startAfter, runTransaction, serverTimestamp } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-firestore.js';
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from 'https://www.gstatic.com/firebasejs/13.0.0/firebase-app-check.js';
import { changedFields, entityVersion } from './validation.mjs';

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
    initializeAppCheck(app, { provider: new ReCaptchaEnterpriseProvider(config.appCheckSiteKey), isTokenAutoRefreshEnabled: true });
  }
  await setPersistence(auth, browserSessionPersistence);
  const pending = new Map();
  return {
    emulator: Boolean(config.emulators), projectId: config.firebase.projectId,
    authChanges: callback => onAuthStateChanged(auth, callback),
    login: (email, password) => signInWithEmailAndPassword(auth, email, password), logout: () => signOut(auth),
    role: (uid, onData, onError) => onSnapshot(doc(db,'admin_roles',uid), { includeMetadataChanges: true }, s => onData(s.exists() && s.data().enabled === true && !s.metadata.isFromCache), onError),
    async page(kind, cursor) {
      const sort = kind === 'food_catalog' ? 'name' : kind === 'user_directory' ? 'email' : 'at';
      const q = query(collection(db,kind), orderBy(sort,kind === 'admin_audit' ? 'desc' : 'asc'), ...(cursor ? [startAfter(cursor)] : []), limit(25));
      const snapshot = await getDocs(q);
      const rows = await Promise.all(snapshot.docs.map(async s => ({ id: s.id, ...s.data(), ...(kind === 'user_directory' ? { control: (await getDoc(doc(db,'account_controls',s.id))).data() ?? null } : {}) })));
      return { rows, cursor: snapshot.docs.at(-1), hasMore: rows.length === 25 };
    },
    async config() { const s = await getDoc(doc(db,'app_config','runtime')); return s.exists() ? s.data() : null; },
    async counts() {
      const requests = [collection(db,'food_catalog'),collection(db,'user_directory'),query(collection(db,'account_controls'),where('status','==','suspended'))];
      return Promise.all(requests.map(async q => (await getCountFromServer(q)).data().count));
    },
    async save(kind, id, payload, reason, expectedVersion) {
      const actorUid = auth.currentUser?.uid;
      if (!actorUid) throw Error('Phiên đăng nhập đã kết thúc.');
      const key = JSON.stringify([actorUid,kind,id,payload,reason,expectedVersion]);
      const audit = pending.get(key) ?? doc(collection(db,'admin_audit'));
      if (pending.size > 100) pending.clear();
      pending.set(key,audit);
      const target = doc(db,kind,id);
      await runTransaction(db,async t => {
        if (auth.currentUser?.uid !== actorUid) throw Error('Phiên đăng nhập đã thay đổi.');
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
      pending.delete(key);
    }
  };
}
