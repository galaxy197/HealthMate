const {test}=require('node:test');
const assert=require('node:assert/strict');
const {randomUUID}=require('node:crypto');
// Deliberately fixed loopback/demo addresses: never run this against production.
const host='http://127.0.0.1:9099',project='demo-healthmate-auth';
async function auth(method,data) {
  const r=await fetch(`${host}/identitytoolkit.googleapis.com/v1/accounts:${method}?key=demo-key`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
  return {status:r.status,body:await r.json()};
}
test('real emulator email actions: verify link, refresh token, reset password and reject reused codes',async()=>{
  const email=`auth-flow-${randomUUID()}@example.test`,password='Fixture-password-123!',newPassword='Fixture-password-456!';
  const created=await auth('signUp',{email,password,returnSecureToken:true});assert.equal(created.status,200);
  const uid=created.body.localId,oldToken=created.body.idToken;
  const target=`http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents/users/${uid}`;
  // Minimal synthetic identity; no real user data. Owner is emulator-only.
  const seed=await fetch(target,{method:'PATCH',headers:{Authorization:'Bearer owner','Content-Type':'application/json'},body:JSON.stringify({fields:{displayName:{stringValue:'Auth fixture'},email:{stringValue:email}}})});
  assert.equal(seed.status,200);
  const read=token=>fetch(target,{headers:{Authorization:`Bearer ${token}`}});
  assert.equal((await read(oldToken)).status,403,'unverified token must not read even its own profile');
  const codes=async()=> (await (await fetch(`${host}/emulator/v1/projects/${project}/oobCodes`)).json()).oobCodes;
  const verify=await auth('sendOobCode',{requestType:'VERIFY_EMAIL',idToken:oldToken});assert.equal(verify.status,200);
  const verification=(await codes()).find(c=>c.email===email && c.requestType==='VERIFY_EMAIL');assert.ok(verification?.oobCode);
  assert.equal((await auth('update',{oobCode:verification.oobCode})).status,200);
  assert.equal((await auth('update',{oobCode:verification.oobCode})).status,400,'verification link is single use');
  assert.equal((await read(oldToken)).status,403,'cached unverified token remains denied');
  const refresh=await fetch(`${host}/securetoken.googleapis.com/v1/token?key=demo-key`,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'refresh_token',refresh_token:created.body.refreshToken})});
  assert.equal(refresh.status,200);const refreshed=await refresh.json();
  assert.equal((await read(refreshed.id_token)).status,200,'fresh verified claim grants own profile access');
  const reset=await auth('sendOobCode',{requestType:'PASSWORD_RESET',email});assert.equal(reset.status,200);
  const resetCode=(await codes()).find(c=>c.email===email && c.requestType==='PASSWORD_RESET');assert.ok(resetCode?.oobCode);
  assert.equal((await auth('resetPassword',{oobCode:'invalid-link'})).status,400);
  assert.equal((await auth('resetPassword',{oobCode:resetCode.oobCode})).status,200,'link can be checked before choosing a password');
  assert.equal((await auth('resetPassword',{oobCode:resetCode.oobCode,newPassword})).status,200);
  assert.equal((await auth('resetPassword',{oobCode:resetCode.oobCode,newPassword})).status,400,'reset link is single use');
  assert.equal((await auth('signInWithPassword',{email,password,returnSecureToken:true})).status,400,'old password no longer authenticates');
  const signedIn=await auth('signInWithPassword',{email,password:newPassword,returnSecureToken:true});assert.equal(signedIn.status,200);
  const lookup=await auth('lookup',{idToken:signedIn.body.idToken});assert.equal(lookup.body.users[0].emailVerified,true);
  await fetch(target,{method:'DELETE',headers:{Authorization:'Bearer owner'}});
  assert.equal((await auth('delete',{idToken:signedIn.body.idToken})).status,200);
});
