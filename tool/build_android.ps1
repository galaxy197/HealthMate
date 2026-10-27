param([string]$FlutterSdk = 'D:\Flutter\flutter')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'android_app_arguments.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter -PathType Leaf)) {
  throw "Flutter was not found: $flutter"
}
$appArguments = @(Get-HealthMateAndroidArguments -ProjectRoot $projectRoot)
Push-Location -LiteralPath $projectRoot
try {
  # Verify the exact shared admin configuration before producing an APK.
  & $flutter test --no-pub '--dart-define-from-file=config/admin-runtime.json' '--dart-define=HEALTHMATE_VERIFY_ADMIN_BUILD=true' test/admin_runtime_test.dart
  if ($LASTEXITCODE -ne 0) { throw 'Admin configuration tests failed; APK was not built.' }
  & $flutter build apk --debug --no-pub @appArguments
  if ($LASTEXITCODE -ne 0) { throw 'Android build failed; no new APK was published.' }
  $output = Join-Path $projectRoot 'build\releases'
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  $apk = Join-Path $output 'healthmate-figma-admin-debug.apk'
  Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-debug.apk' -Destination $apk
  $manifest = [ordered]@{
    apk = [System.IO.Path]::GetFileName($apk)
    builtAtUtc = [DateTime]::UtcNow.ToString('o')
    adminControlsEnabled = $true
    runtimeConfigSha256 = (Get-FileHash -LiteralPath 'config\admin-runtime.json' -Algorithm SHA256).Hash
    apkSha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
    bytes = (Get-Item -LiteralPath $apk).Length
    mode = 'debug'
  }
  $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'healthmate-figma-admin-debug.json') -Encoding UTF8
  Write-Output "APK with admin controls: $apk"
} finally { Pop-Location }
