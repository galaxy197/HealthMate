'use strict';
// Git paths remain argv, never shell source. Only selected existing Dart files
// are checked; unrelated legacy formatting is outside this maintenance scope.
const {spawnSync}=require('node:child_process');
const fs=require('node:fs');
function git(args, optional=false) {
  const r=spawnSync('git',args,{encoding:'utf8'});
  if(r.status!==0) {if(optional)return null;throw Error(`git failed (${r.status})`);}
  return r.stdout;
}
function filesToCheck(base=process.env.HEALTHMATE_FORMAT_BASE) {
  const validBase=base&&/^[a-f0-9]{40}$/i.test(base)&&!/^0+$/.test(base)
    &&git(['cat-file','-e',`${base}^{commit}`],true)!==null;
  const previous=validBase?base:git(['rev-parse','--verify','HEAD^'],true)?.trim();
  const committed=previous
    ?git(['diff','--name-only','--diff-filter=ACMR','-z',`${previous}...HEAD`,'--','*.dart'])
    :git(['ls-files','-z','--','*.dart']);
  const local=git(['diff','--name-only','--diff-filter=ACMR','-z','HEAD','--','*.dart']);
  const untracked=git(['ls-files','--others','--exclude-standard','-z','--','*.dart']);
  return [...new Set((committed+'\0'+local+'\0'+untracked).split('\0').filter(Boolean))]
    .filter(path=>fs.existsSync(path)).sort();
}
if(require.main===module) {
  try {
    const paths=filesToCheck();
    if(process.argv.includes('--list')) console.log(JSON.stringify(paths));
    else if(!paths.length) console.log('No changed Dart files.');
    else {
      const result=spawnSync(process.env.HEALTHMATE_DART_COMMAND||'dart',
        ['format','--output=none','--set-exit-if-changed',...paths.map(path=>'./'+path)],
        {stdio:'inherit',shell:false});
      if(result.error)throw Error('Dart executable unavailable; set HEALTHMATE_DART_COMMAND to its absolute path.');
      process.exitCode=result.status??1;
    }
  }catch(error){console.error(error.message);process.exitCode=1;}
}
module.exports={filesToCheck};
