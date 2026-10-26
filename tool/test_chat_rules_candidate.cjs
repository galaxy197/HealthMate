'use strict';
const { execFileSync } = require('node:child_process');
const path = require('node:path');
if (!process.env.FIRESTORE_EMULATOR_HOST?.startsWith('127.0.0.1:')) throw new Error('Local Firestore emulator required');
execFileSync(process.execPath, ['--test', '--test-name-pattern=^chat ', 'rules-tests/firestore.rules.test.cjs'], {
  stdio: 'inherit', env: { ...process.env, HEALTHMATE_RULES_FILE: path.resolve('build/chat-limits-production-candidate/firestore.rules') },
});
