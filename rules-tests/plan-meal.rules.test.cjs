const {test,before,beforeEach,after}=require('node:test');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,Timestamp}=require('firebase/firestore');
let env;
const day='2026-10-30', id=day+'-breakfast', planPath='users/alice/meal_plans/'+id,
  mealPath='users/alice/meal_logs/plan-'+id;
const client=uid=>env.authenticatedContext(uid,{email_verified:true}).firestore();
const row=()=>({foodId:'fixture',name:'Fixture',quantity:100,quantityUnit:'g',kcal:120,
  proteinG:6,carbsG:15,fatG:4,fiberG:0,sourceLabel:'Synthetic fixture',isEstimated:true,
  nutrientVectorV1:'[0,1,120,150,50,1.2,3,4]'});
const plan=()=>({dateKey:day,mealType:'breakfast',items:Array.from({length:5},row),
  schemaVersion:2,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
const meal=()=>({mealType:'breakfast',consumedAt:Timestamp.fromDate(new Date(day+'T08:00:00Z')),
  dateKey:day,timezoneOffsetMinutes:0,items:Array.from({length:5},row),totalKcal:600,
  totalProteinG:30,totalCarbsG:75,totalFatG:20,source:'manual',schemaVersion:5,
  createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
async function record(a) {
  const b=writeBatch(a);b.set(doc(a,mealPath),meal());
  b.update(doc(a,planPath),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()});
  return b.commit();
}
before(async()=>{const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8080').split(':');
  env=await initializeTestEnvironment({projectId:'demo-healthmate-plan-meal',
    firestore:{host,port:Number(port),rules:fs.readFileSync(process.env.HEALTHMATE_RULES_FILE||'../firestore.rules','utf8')}});});
beforeEach(()=>env.clearFirestore());after(()=>env?.cleanup());
test('five-row plan and meal record/delete/re-record atomically within Rules budget',async()=>{
  const a=client('alice');await setDoc(doc(a,planPath),plan());await assertSucceeds(record(a));
  const b=writeBatch(a);b.delete(doc(a,mealPath));
  b.update(doc(a,planPath),{loggedMealId:null,updatedAt:serverTimestamp()});
  await assertSucceeds(b.commit());
  await assertSucceeds(record(a));
  if(!(await getDoc(doc(a,mealPath))).exists())throw Error('Missing re-recorded meal');
});
test('reject split creation, split deletion and unlink while recorded meal still exists',async()=>{
  const a=client('alice');await setDoc(doc(a,planPath),plan());
  await assertFails(setDoc(doc(a,mealPath),meal()));
  await assertFails(updateDoc(doc(a,planPath),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()}));
  await record(a);
  await assertFails(deleteDoc(doc(a,mealPath)));
  await assertFails(updateDoc(doc(a,planPath),{loggedMealId:null,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(a,planPath),{items:[row()],updatedAt:serverTimestamp()}));
});
test('deleting a plan keeps journal editable and deletable; recreated plan cannot replace history',async()=>{
  const a=client('alice');await setDoc(doc(a,planPath),plan());await record(a);
  await assertSucceeds(deleteDoc(doc(a,planPath)));
  await assertSucceeds(updateDoc(doc(a,mealPath),{updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(a,planPath),plan()));
  await assertSucceeds(deleteDoc(doc(a,mealPath)));
  await assertSucceeds(setDoc(doc(a,planPath),plan()));
});
test('legacy dangling marker can be cleared and edited only while linked meal is absent',async()=>{
  await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),planPath),{
    ...plan(),loggedMealId:'plan-'+id});});
  const a=client('alice');
  await assertFails(updateDoc(doc(client('bob'),planPath),{loggedMealId:null,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(a,planPath),{loggedMealId:null,items:[row()],updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(a,planPath),{loggedMealId:'plan-unrelated',updatedAt:serverTimestamp()}));
});
test('another UID, guest and unverified owner cannot write or remove either side',async()=>{
  const a=client('alice');await setDoc(doc(a,planPath),plan());await record(a);
  for(const other of [client('bob'),env.unauthenticatedContext().firestore(),
    env.authenticatedContext('alice',{email_verified:false}).firestore()]) {
    await assertFails(getDoc(doc(other,mealPath)));
    await assertFails(deleteDoc(doc(other,planPath)));
    await assertFails(record(other));
  }
});

for (const state of ['partitioned','complete']) {
  test(`certified ${state} five distinct enriched rows record atomically within Rules budget`,async()=>{
    const rows=Array.from({length:5},(_,index)=>({...row(),foodId:`fixture-${index}`,
      name:`Fixture ${index}`,fiberG:index+1,
      nutrientVectorV1:`[${index+1},${index+2},120,150,50,1.2,3,4]`}));
    await env.withSecurityRulesDisabled(async context=>{
      await setDoc(doc(context.firestore(),'users/alice/data_migrations/meal_date_key_v1'),{
        schemaVersion:1,state,verifiedAt:Timestamp.now()});
    });
    const a=client('alice');
    await assertSucceeds(setDoc(doc(a,planPath),{...plan(),items:rows}));
    const batch=writeBatch(a);
    batch.set(doc(a,mealPath),{...meal(),items:rows,queryPartition:'current'});
    batch.update(doc(a,planPath),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()});
    await assertSucceeds(batch.commit());
    const saved=(await getDoc(doc(a,mealPath))).data();
    if(saved.queryPartition!=='current'||new Set(saved.items.map(item=>item.foodId)).size!==5)
      throw Error('Certified five-row meal was not preserved');
    await assertFails(updateDoc(doc(a,mealPath),{items:rows.map((item,index)=>
      index===4?{...item,fiberG:-1}:item),updatedAt:serverTimestamp()}));
    await assertFails(updateDoc(doc(a,mealPath),{items:rows.map((item,index)=>
      index===4?{...item,nutrientVectorV1:'[1,2,3]'}:item),updatedAt:serverTimestamp()}));
  });

  test(`certified ${state} five incomplete-fiber rows allow confirmed portions different from plan`,async()=>{
    const rows=Array.from({length:5},(_,index)=>({...row(),foodId:`incomplete-${index}`,
      name:`Incomplete fixture ${index}`,fiberG:index+1,fiberIncomplete:true,
      nutrientVectorV1:`[${index+1},${index+2},120,150,50,1.2,3,4]`}));
    const confirmed=rows.map(item=>({...item,quantity:200,kcal:240,proteinG:12,
      carbsG:30,fatG:8,fiberG:item.fiberG*2,
      nutrientVectorV1:'[2,4,240,300,100,2.4,6,8]'}));
    await env.withSecurityRulesDisabled(async context=>{
      await setDoc(doc(context.firestore(),'users/alice/data_migrations/meal_date_key_v1'),{
        schemaVersion:1,state,verifiedAt:Timestamp.now()});
    });
    const a=client('alice');
    await assertSucceeds(setDoc(doc(a,planPath),{...plan(),items:rows}));
    const batch=writeBatch(a);
    batch.set(doc(a,mealPath),{...meal(),items:confirmed,queryPartition:'current',
      totalKcal:1200,totalProteinG:60,totalCarbsG:150,totalFatG:40});
    batch.update(doc(a,planPath),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()});
    await assertSucceeds(batch.commit());
    const saved=(await getDoc(doc(a,mealPath))).data();
    if(saved.items.some(item=>item.quantity!==200||item.fiberIncomplete!==true))
      throw Error('Confirmed portions or incomplete-fiber metadata were changed');
  });
}

test('enriched list shape and optional fiber metadata fail closed for both plans and meals',async()=>{
  const a=client('alice');
  const malformed=[{},'not a list',[],[{...row(),fiberIncomplete:false}],
    [{...row(),fiberIncomplete:'true'}],[{...row(),unknownField:true}]];
  for(const items of malformed) {
    await assertFails(setDoc(doc(a,planPath),{...plan(),items}));
    await assertFails(setDoc(doc(a,'users/alice/meal_logs/shape-fixture'),{
      ...meal(),items,queryPartition:'current'}));
  }
});
