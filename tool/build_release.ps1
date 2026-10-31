param(
  [string]$FlutterSdk='D:\Flutter\flutter',
  [string]$Node='node',
  [string]$ReleaseConfig,
  [string]$AndroidBuildToolsVersion='36.0.0'
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
if(-not $ReleaseConfig){$ReleaseConfig=Join-Path $projectRoot 'config\release-candidate.json'}
$flutter=Join-Path $FlutterSdk 'bin\flutter.bat'
if(-not (Test-Path -LiteralPath $flutter -PathType Leaf)){throw 'Flutter SDK not found.'}
Push-Location -LiteralPath $projectRoot
try {
  # Separate from android_app_arguments.ps1: never reads the local debug token.
  & $Node tool/release_preflight.cjs --config $ReleaseConfig
  if($LASTEXITCODE -ne 0){throw 'Release preflight failed; no APK was built.'}
  $sdkRoot=if($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
  $apksigner=Join-Path $sdkRoot "build-tools\$AndroidBuildToolsVersion\apksigner.bat"
  if(-not (Test-Path -LiteralPath $apksigner -PathType Leaf)){throw 'apksigner not found; supply the installed Android build-tools version.'}
  & $flutter build apk --release --no-pub "--dart-define-from-file=$ReleaseConfig"
  if($LASTEXITCODE -ne 0){throw 'Release build failed; no artifact was promoted.'}
  $apk=Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
  $certificate=@(& $apksigner verify --verbose --print-certs $apk 2>&1)
  if($LASTEXITCODE -ne 0 -or ($certificate -join "`n") -match '(?i)CN=Android Debug|androiddebugkey'){
    throw 'Release signature verification failed or a debug certificate was detected; artifact was not promoted.'
  }
  $output=Join-Path $projectRoot 'build\releases'
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  $target=Join-Path $output 'healthmate-demo-signed-release.apk'
  Copy-Item -LiteralPath $apk -Destination $target
  $manifest=[ordered]@{builtAtUtc=[DateTime]::UtcNow.ToString('o');mode='release';applicationId='com.example.healthmate';version='1.0.0+1';
    clientCommit=(& git rev-parse HEAD);workingTreeDirty=[bool](& git status --porcelain);configSha256=(Get-FileHash -LiteralPath $ReleaseConfig -Algorithm SHA256).Hash;
    rulesSha256=(Get-FileHash -LiteralPath 'firestore.rules' -Algorithm SHA256).Hash;indexesSha256=(Get-FileHash -LiteralPath 'firestore.indexes.json' -Algorithm SHA256).Hash;
    apkSha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash;signatureVerified=$true;nativeAcceptance=$false;productionAccepted=$false}
  $manifest | ConvertTo-Json | Set-Content -LiteralPath ([IO.Path]::ChangeExtension($target,'.json')) -Encoding utf8
  Write-Output "Signed candidate saved: $target. Native and production acceptance remain required."
} finally {Pop-Location}
