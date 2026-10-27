param(
  [string]$DeviceId = 'emulator-5554'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'android_app_arguments.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$appArguments = @(Get-HealthMateAndroidArguments -ProjectRoot $projectRoot)

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) {
  $flutter = 'D:\Flutter\flutter\bin\flutter.bat'
}
Push-Location -LiteralPath $projectRoot
try {
  & $flutter run -d $DeviceId @appArguments
  $result = $LASTEXITCODE
} finally { Pop-Location }
exit $result
