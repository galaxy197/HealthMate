param([string]$Destination='D:\HealthMateMaintenanceQA\c6-workspace')
$ErrorActionPreference='Stop'
$repo=(Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$target=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
if(-not $target.StartsWith('D:\HealthMateMaintenanceQA\',[StringComparison]::OrdinalIgnoreCase) -or $target -eq $repo) {
  throw 'Only a separate task QA workspace under D:\HealthMateMaintenanceQA is allowed.'
}
Push-Location -LiteralPath $repo
try {
  $paths=@('lib','assets','test','test_driver','integration_test','tool','data','rules-tests','android',
    'pubspec.yaml','pubspec.lock','analysis_options.yaml','firestore.rules','firestore.indexes.json','firebase.emulators.json','.metadata')
  $files=@(@(git -c core.quotepath=false ls-files -- $paths)+@(git -c core.quotepath=false ls-files --others --exclude-standard -- $paths) | Sort-Object -Unique)
  if($LASTEXITCODE -ne 0 -or $files.Count -lt 100) {throw 'Cannot enumerate repository source.'}
  foreach($relative in $files) {
    if($relative -match '(^|/)(node_modules|build|\.git)/|key\.properties$|\.jks$|\.keystore$|qa-defines\.json$') {throw 'Private/generated file in source inventory.'}
    $source=Join-Path $repo $relative
    $copy=Join-Path $target $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $copy) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $copy
    if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) {throw "QA source mismatch: $relative"}
  }
  Write-Output "QA sync verified: $($files.Count) source/config/assets, including root Rules. No ignored data copied/deleted."
} finally {Pop-Location}
