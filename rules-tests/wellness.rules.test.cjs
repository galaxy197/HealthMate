const {test,before,after,beforeEach}=require('node:test');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,updateDoc,deleteDoc,serverTimestamp,Timestamp}=require('firebase/firestore');
let env;
const time=()=>Timestamp.now();
const date=()=>new Date().toISOString().slice(0,10);
const db=(uid,verified=true)=>env.authenticatedContext(uid,{email_verified:verified}).firestore();
const extras={sugar:0,saturatedFat:1,sodium:120,potassium:150,calcium:50,iron:1.2,vitaminC:3,cholesterol:4};
const wire=n=>'['+['sugar','saturatedFat','sodium','potassium','calcium','iron','vitaminC','cholesterol'].map(k=>n[k]===undefined?'null':typeof n[k]==='number'&&Number.isFinite(n[k])?n[k].toFixed(6):JSON.stringify(n[k])).join(',')+']';
const item=()=>({foodId:'fixture',name:'Fixture',grams:100,kcal:120,proteinG:6,carbsG:15,fatG:4,
  sourceLabel:'Synthetic test',isEstimated:true,nutrientVectorV1:wire(extras)});
const compact=i=>({...Object.fromEntries(Object.entries(i).filter(([k,v])=>k!=='grams')),quantity:i.grams??i.quantity,quantityUnit:i.grams==null?i.quantityUnit:'g'});
const meal=items=>({mealType:'breakfast',consumedAt:time(),dateKey:date(),timezoneOffsetMinutes:0,items:items.map(compact),
  totalKcal:120*items.length,totalProteinG:6*items.length,totalCarbsG:15*items.length,totalFatG:4*items.length,
  source:'manual',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:5});
const sleep=()=>({startedAt:Timestamp.fromMillis(Date.now()-8*3600000),endedAt:time(),
  source:'manual_entry',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:1});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-healthmate-wellness',
  firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(process.env.HEALTHMATE_RULES_FILE||'../firestore.rules','utf8')}});});
beforeEach(()=>env.clearFirestore());
after(()=>env?.cleanup());

test('sleep timer belongs to verified owner, cannot replace an active start',async()=>{
  const a=db('alice'),path='users/alice/wellness_state/sleep',r=doc(a,path);
  const data={startedAt:serverTimestamp(),schemaVersion:1};
  await assertSucceeds(setDoc(r,data));
  await assertFails(updateDoc(r,{startedAt:serverTimestamp()}));
  for(const other of [db('bob'),db('alice',false),env.unauthenticatedContext().firestore()]){
    await assertFails(getDoc(doc(other,path)));
    await assertFails(deleteDoc(doc(other,path)));
  }
  await assertFails(setDoc(doc(a,'users/alice/wellness_state/arbitrary'),data));
  await assertSucceeds(deleteDoc(r));
});
test('sleep logs validate duration, future timestamps, shape and cross-UID edits',async()=>{
  const a=db('alice'),r=doc(a,'users/alice/sleep_logs/sleep');
  await assertSucceeds(setDoc(r,sleep()));
  await assertSucceeds(updateDoc(r,{endedAt:time(),updatedAt:serverTimestamp()}));
  await assertFails(getDoc(doc(db('bob'),r.path)));
  await assertFails(setDoc(doc(db('alice',false),'users/alice/sleep_logs/unverified'),sleep()));
  for(const patch of [{endedAt:Timestamp.fromMillis(Date.now()+3600000)},
    {startedAt:Timestamp.fromMillis(Date.now()-25*3600000)},{startedAt:time(),endedAt:Timestamp.fromMillis(0)},
    {source:'automatic_eeg'},{extraPrivateField:'no'},{schemaVersion:2}]) {
    await assertFails(setDoc(doc(a,'users/alice/sleep_logs/bad'),{...sleep(),...patch}));
  }
});
test('step history validates bounded integers, local date and owner',async()=>{
  const a=db('alice'),path='users/alice/step_logs/'+date();
  const data={dateKey:date(),steps:345,trackingStartedAt:Timestamp.fromMillis(Date.now()-1000),
    measuredAt:time(),timezoneOffsetMinutes:0,updatedAt:serverTimestamp(),schemaVersion:1,source:'device_step_counter'};
  await assertSucceeds(setDoc(doc(a,path),data));
  for(const other of [db('bob'),db('alice',false)]){
    await assertFails(getDoc(doc(other,path)));await assertFails(setDoc(doc(other,path),data));
  }
  for(const patch of [{steps:-1},{steps:150001},{steps:1.5},{dateKey:'2026-02-31'},
    {timezoneOffsetMinutes:999},{source:'guessed'},{measuredAt:Timestamp.fromMillis(Date.now()+3600000)}]){
    await assertFails(setDoc(doc(a,path),{...data,...patch}));
  }
});
test('planned meals remain private; cannot claim journal conversion without the journal entry',async()=>{
  const a=db('alice'),id=date()+'-breakfast',path='users/alice/meal_plans/'+id;
  const data={dateKey:date(),mealType:'breakfast',items:[compact(item())],schemaVersion:2,
    createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(a,path),data));
  const maximumItems=Array(5).fill(compact({...item(),fiberG:0,proteinG:null}));
  await assertSucceeds(updateDoc(doc(a,path),{items:maximumItems,updatedAt:serverTimestamp()}));
  await assertFails(getDoc(doc(db('bob'),path)));
  await assertFails(updateDoc(doc(a,path),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(a,'users/alice/meal_logs/plan-'+id),meal([item()])));
  await assertSucceeds(updateDoc(doc(a,path),{loggedMealId:'plan-'+id,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(a,path),{loggedMealId:null,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(a,path),{items:[{...item(),kcal:999}],updatedAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(doc(a,path)));
  await assertSucceeds(getDoc(doc(a,'users/alice/meal_logs/plan-'+id)));
});
test('planned meals reject impossible dates, wrong ID, too many rows and invalid nutrients',async()=>{
  const a=db('alice'),data={dateKey:date(),mealType:'lunch',items:[compact(item())],schemaVersion:2,
    createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  for(const [id,patch] of [
    ['wrong-id',{}],[date()+'-lunch',{dateKey:'2026-02-31'}],
    [date()+'-lunch',{items:Array(6).fill(compact(item()))}],
    [date()+'-lunch',{items:[compact({...item(),nutrientVectorV1:wire({sodium:-1})})]}],
  ]) await assertFails(setDoc(doc(a,'users/alice/meal_plans/'+id),{...data,...patch}));
});
test('five meal rows retain all eight nutrients within the Rules expression budget',async()=>{
  const a=db('alice');
  await assertSucceeds(setDoc(doc(a,'users/alice/meal_logs/extras-five'),meal(Array(5).fill(item()))));
  const partial={...item(),grams:null,quantity:250,quantityUnit:'ml',proteinG:null,fiberG:0};
  await assertSucceeds(setDoc(doc(a,'users/alice/meal_logs/extras-partial'),{
    ...meal(Array(5).fill(partial)),totalProteinG:null}));
  for(const bad of [{sodium:-1},{sodium:'100'},{sugar:'Infinity'},{iron:10001},
    {sodium:100001},{calcium:'NaN'},{saturatedFat:2001}]){
    await assertFails(setDoc(doc(a,'users/alice/meal_logs/bad'),meal([{...item(),nutrientVectorV1:wire(bad)}])));
  }
});
test('six recipe ingredients preserve extras within the Rules budget',async()=>{
  const a=db('alice');
  const recipe={name:'Recipe fixture',ingredients:Array(6).fill({...item(),fiberG:2,fiberIncomplete:true}).map(({nutrientVectorV1,...i})=>i),nutrientVectorsV1:Array(6).fill(wire(extras)).join('|'),yieldGrams:600,servingsCount:2,
    sourceLabel:'Synthetic',isEstimated:true,schemaVersion:3,createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(a,'users/alice/recipes/extras'),recipe));
  await assertFails(setDoc(doc(a,'users/alice/recipes/bad'),{...recipe,
    ingredients:[{...item(),nutrientVectorV1:wire({sodium:-1})}]}));
});
test('personal food permits optional sourced nutrient fields, not arbitrary attributes',async()=>{
  const a=db('alice'),food={name:'Custom fixture',alternateNames:[],servingBasis:'per_100g',kcalPer100g:100,
    proteinGPer100g:4,carbsGPer100g:10,fatGPer100g:5,extraNutrientsPer100g:extras,defaultServingGrams:100,
    servingLabel:null,servingGrams:null,sourceLabel:'Label',isEstimated:true,schemaVersion:3,
    createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(a,'users/alice/custom_foods/custom'),food));
  await assertFails(setDoc(doc(a,'users/alice/custom_foods/bad'),{...food,
    extraNutrientsPer100g:{sodium:'salt'}}));
});

test('five enriched template rows keep fiber, partial macros, all nutrient values and budget',async()=>{
const a=db('alice'),i=compact({...item(),proteinG:null}),base=Object.fromEntries(Object.entries(i).filter(([k,v])=>k!=='nutrientVectorV1'&&!(v==null&&['proteinG','carbsG','fatG'].includes(k)))),data={name:'Enriched template',items:Array(5).fill(base),fiberValues:Array(5).fill(0),nutrientVectorsV1:Array(5).fill(wire(extras)).join('|'),schemaVersion:4,createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
await assertSucceeds(setDoc(doc(a,'users/alice/meal_templates/enriched'),data));
await assertSucceeds(updateDoc(doc(a,'users/alice/meal_templates/enriched'),{name:'Changed title',updatedAt:serverTimestamp()}));
await assertFails(setDoc(doc(a,'users/alice/meal_templates/bad-enriched'),{...data,items:[{...i,nutrientVectorV1:'[NaN]'}]}));
});

test('wellness preferences are private, nullable and validate calibration and sleep goal',async()=>{
  const a=db('alice'),path='users/alice/wellness_preferences/main',data={stepLengthCm:75,baselineSteps:4000,sleepGoalMinutes:480,schemaVersion:1,updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(a,path),data));
  await assertSucceeds(updateDoc(doc(a,path),{sleepGoalMinutes:null,updatedAt:serverTimestamp()}));
  for(const other of [db('bob'),db('alice',false),env.unauthenticatedContext().firestore()]){
    await assertFails(getDoc(doc(other,path)));await assertFails(setDoc(doc(other,path),data));await assertFails(deleteDoc(doc(other,path)));
  }
  for(const patch of [{stepLengthCm:NaN},{stepLengthCm:19},{stepLengthCm:201},{baselineSteps:-1},{baselineSteps:1.5},{sleepGoalMinutes:59},{sleepGoalMinutes:1441},{schemaVersion:2},{secret:'x'}])await assertFails(setDoc(doc(a,path),{...data,...patch}));
  await assertFails(setDoc(doc(a,'users/alice/wellness_preferences/other'),data));
});

async function prepareEnergy(){
  const a=db('alice'),day=date();
  await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),'users/alice/nutrition_targets/'+day),{
    effectiveFromDateKey:day,kcalTarget:1800,proteinGTarget:null,carbsGTarget:null,fatGTarget:null,source:'user_manual',schemaVersion:1,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});});
  return {a,path:'users/alice/energy_adjustments/'+day,data:{dateKey:day,timezoneOffsetMinutes:0,steps:6000,baselineSteps:4000,stepLengthCm:75,weightKg:70,weightMeasuredAt:Timestamp.fromMillis(Date.now()-86400000),targetFromDateKey:day,baseKcalTarget:1800,kcal:50,source:'walking_net_v1',schemaVersion:1,confirmedAt:serverTimestamp()}};
}
test('confirmed energy adjustment belongs to owner, does not modify base target and can be removed',async()=>{
  const {a,path,data}=await prepareEnergy();
  await assertSucceeds(setDoc(doc(a,path),data));
  for(const other of [db('bob'),db('alice',false),env.unauthenticatedContext().firestore()]){
    await assertFails(getDoc(doc(other,path)));await assertFails(setDoc(doc(other,path),data));await assertFails(deleteDoc(doc(other,path)));
  }
  if((await getDoc(doc(a,'users/alice/nutrition_targets/'+date()))).data().kcalTarget!==1800)throw Error('Base target changed');
  await assertSucceeds(updateDoc(doc(a,path),{kcal:40,confirmedAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(doc(a,path)));
});
test('energy adjustment rejects excess credit, unknown models, stale weight, false target and wrong date',async()=>{
  const {a,path,data}=await prepareEnergy();
  for(const patch of [{kcal:53},{kcal:0},{kcal:5001},{kcal:NaN},{steps:1.5},{steps:150001},{steps:3000},
    {stepLengthCm:Infinity},{weightKg:0},{weightMeasuredAt:Timestamp.fromMillis(Date.now()-91*86400000)},
    {baseKcalTarget:2000},{targetFromDateKey:'2000-01-01'},{source:'sleep_calories'},{dateKey:'2000-01-01'},{timezoneOffsetMinutes:999},{extra:'no'}])await assertFails(setDoc(doc(a,path),{...data,...patch}));
  await assertFails(setDoc(doc(a,'users/alice/energy_adjustments/wrong-id'),data));
});
