// Synthetic fixtures only; every URL/project is fixed to the local demo.
import { readFile } from 'node:fs/promises';
const project='demo-healthmate-admin', auth='http://127.0.0.1:9098';
const store=`http://127.0.0.1:8092/v1/projects/${project}/databases/(default)/documents`;
async function call(url,body,method='POST',headers={}) {
  const r=await fetch(url,{method,headers:{'Content-Type':'application/json',...headers},body:JSON.stringify(body)});
  const data=await r.json(); if(!r.ok)throw Error(`Local emulator request failed (${r.status}).`);return data;
}
async function signup(email) {
  const body={email,password:'LocalHealthMate!2026',returnSecureToken:true};
  let result=await fetch(`${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const account=result.ok ? await result.json() : await call(`${auth}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key`,body);
  const lookup=await call(`${auth}/identitytoolkit.googleapis.com/v1/accounts:lookup?key=demo-key`,{idToken:account.idToken});
  if(!lookup.users?.[0]?.emailVerified) {
    // Exercise the email-verification flow inside Auth Emulator only. No real email is sent.
    await call(`${auth}/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=demo-key`,{requestType:'VERIFY_EMAIL',idToken:account.idToken});
    const response=await fetch(`${auth}/emulator/v1/projects/${project}/oobCodes`);
    if(!response.ok)throw Error('Cannot read local emulator verification codes.');
    const codes=await response.json();
    const verification=codes.oobCodes?.findLast(code=>code.email===email && code.requestType==='VERIFY_EMAIL');
    if(!verification?.oobCode)throw Error('Local verification code was not created.');
    await call(`${auth}/identitytoolkit.googleapis.com/v1/accounts:update?key=demo-key`,{oobCode:verification.oobCode});
  }
  return account.localId;
}
function value(v) {
  if(v===null)return {nullValue:null};if(typeof v==='boolean')return{booleanValue:v};if(typeof v==='number')return{doubleValue:v};
  if(v instanceof Date)return{timestampValue:v.toISOString()};if(Array.isArray(v))return{arrayValue:{values:v.map(value)}};
  return{stringValue:String(v)};
}
async function set(path,data) {return call(`${store}/${path}`,{fields:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,value(v)]))},'PATCH',{Authorization:'Bearer owner'});}
const admin=await signup('admin@healthmate.local'),member=await signup('member@healthmate.local');
const now=new Date();
await set(`admin_roles/${admin}`,{enabled:true});
for(const [uid,email,name] of [[admin,'admin@healthmate.local','Quản trị kiểm thử'],[member,'member@healthmate.local','Người dùng kiểm thử']]) {
  await set(`user_directory/${uid}`,{displayName:name,email,createdAt:now,updatedAt:now});
  await set(`users/${uid}`,{displayName:name,email});
}
const legacy=JSON.parse(await readFile(new URL('../data/food_catalog/legacy_usda.json',import.meta.url),'utf8'));
const foods=Array.isArray(legacy)?legacy:legacy.foods;
for(const food of foods.slice(0,4))await set(`food_catalog/${food.id}`,{...Object.fromEntries(Object.entries(food).filter(([k,v])=>!['id','sourceDetails'].includes(k)&&typeof v!=='object')),alternateNames:food.alternateNames??[],isActive:true,updatedAt:now});
if (process.argv.includes('--extended')) {
  for(let i=1;i<=61;i++)await set(`food_catalog/qa-item-${String(i).padStart(3,'0')}`,{
    name:i===57?'QA Phở bò ngoài trang đầu':`QA Món kiểm thử ${String(i).padStart(3,'0')}`,
    alternateNames:i===57?['Noodle soup test']:[],category:i%2?'Món chính':'Trái cây',
    servingBasis:'per_100g',unit:'g',kcalPer100g:130,proteinGPer100g:2.69,carbsGPer100g:28.17,fatGPer100g:.28,fiberGPer100g:null,
    sourceLabel:'Dữ liệu kiểm thử, không phải món thật',sourceUrl:'https://example.com/qa',
    isEstimated:true,isActive:i%3!==0,servingLabel:null,servingGrams:null,updatedAt:now,
  });
}
await set('app_config/runtime',{chatbotEnabled:true,foodScannerEnabled:true,maintenanceMode:false,maintenanceMessage:'',updatedAt:now});
process.stdout.write('Đã tạo dữ liệu kiểm thử trên demo-healthmate-admin tại localhost.\nEmail admin: admin@healthmate.local\nMật khẩu local: LocalHealthMate!2026\nKhông thay đổi Firebase production.\n');
