'use strict';
// Only invoked by emulators:exec. Fixed loopback/demo endpoints cannot be
// overridden to target production, and no CLI login or provider call is used.
const {spawnSync}=require('node:child_process');
const path=require('node:path');
const fs=require('node:fs');
const root=path.resolve(__dirname,'..');
function validateEnvironment(env) {
  if(env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080'
    ||env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099') {
    throw Error('Requires local Firestore8080/Auth9099 emulators.');
  }
}
function run(command,args,extraEnv={},cwd=root) {
  const result=spawnSync(command,args,{stdio:'inherit',shell:false,
    cwd,env:{...process.env,...extraEnv}});
  if(result.error||result.status!==0)throw Error(`${command} check failed (${result.status??'start error'})`);
}
async function main({env=process.env,execute=run,fetcher=fetch}={}) {
  validateEnvironment(env);
  // Rules fixtures read ../firestore.rules relative to their package directory.
  // Finish all clearing Rules fixtures before starting real SDK fixtures.
  execute(process.execPath,['--test',...fs.readdirSync(path.join(root,'rules-tests'))
    .filter(name=>name.endsWith('.rules.test.cjs')).sort()],{},path.join(root,'rules-tests'));
  const suites=[
    'test/account_deletion_repository_integration.dart',
    'test/firebase_repository_integration.dart',
    'test/plan_meal_repository_integration.dart',
    'test/query_repository_integration.dart',
    'test/support_repository_integration.dart',
  ];
  // Some legacy SDK suites reset the entire fixed demo database in setUp.
  // A separate process and fresh fixture per suite prevents cross-suite loss.
  for(const suite of suites) {
    const reset=await fetcher('http://127.0.0.1:8080/emulator/v1/projects/demo-healthmate-rules/databases/(default)/documents',{method:'DELETE'});
    if(!reset.ok)throw Error('Failed to reset the fixed local demo fixture.');
    execute(process.execPath,['tool/test_h1_catalog_import.cjs']);
    execute(env.HEALTHMATE_FLUTTER_COMMAND||'flutter',[
      'test','--no-pub','--platform','chrome','--reporter','expanded',
      '--dart-define=HEALTHMATE_EMULATOR_TESTS=true',suite,
    ]);
  }
  execute(process.execPath,['--test','tool/meal_query_migration.integration.cjs']);
  execute(process.execPath,['--test','chat-api/test/firestore.integration.mjs'],
    {HEALTHMATE_GATEWAY_EMULATOR_TESTS:'true'});
}
if(require.main===module) main().catch(error=>{console.error(error.message);process.exitCode=1;});
module.exports={validateEnvironment,main};
