'use strict';
const {execFileSync}=require('node:child_process');
const path=require('node:path');
if(!process.env.FIRESTORE_EMULATOR_HOST?.startsWith('127.0.0.1:')) throw new Error('Local demo emulator required');
if(process.argv.slice(2).some(a=>!['--wellness','--insights'].includes(a)) || process.argv.length>3) throw new Error('Unknown candidate option');
const wellness = process.argv.includes('--wellness');
const insights = process.argv.includes('--insights');
execFileSync(process.execPath,['--test','rules-tests/firestore.rules.test.cjs',
  ...((wellness||insights) ? ['rules-tests/wellness.rules.test.cjs'] : [])],{
  stdio:'inherit',env:{...process.env,HEALTHMATE_RULES_FILE:path.resolve(insights ? 'build/wellness-insights-production-candidate/firestore.rules' : wellness ?
    'build/wellness-production-candidate/firestore.rules' : 'build/stage10-production-candidate/firestore.rules')},
});
