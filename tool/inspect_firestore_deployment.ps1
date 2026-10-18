param(
  [string]$OutputDirectory = ('build/firebase-review-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
)

# Read-only production configuration inspection. Does not deploy or read user data.
$ErrorActionPreference = 'Stop'
$firebase = (Get-Command firebase.cmd -ErrorAction Stop).Source
$cliRoot = Join-Path (Split-Path -Parent $firebase) 'node_modules/firebase-tools'
if (-not (Test-Path -LiteralPath (Join-Path $cliRoot 'lib/auth.js'))) {
  throw 'Expected the npm Firebase CLI installation beside firebase.cmd. No credentials were requested.'
}
$root = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $root
try {
  & node (Join-Path $PSScriptRoot 'inspect_firestore_deployment.cjs') $cliRoot $OutputDirectory
  $result = $LASTEXITCODE
} finally { Pop-Location }
exit $result
