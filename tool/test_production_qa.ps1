param(
  [Parameter(Mandatory = $true)][string]$CredentialsFile,
  [Parameter(Mandatory = $true)][string]$VerifiedDeploymentDirectory,
  [switch]$AllowProductionQa,
  [string]$FlutterSdk = 'D:\Flutter\flutter',
  [string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Stop'
if (-not $AllowProductionQa) {
  throw 'Production QA requires explicit authorization and -AllowProductionQa.'
}
$root = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$privateFile = (Resolve-Path -LiteralPath $CredentialsFile).Path
if ($privateFile.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'QA credentials must be stored outside the repository.'
}
$defines = Get-Content -LiteralPath $privateFile -Raw | ConvertFrom-Json
$run = [string]$defines.HEALTHMATE_QA_RUN
if ($run -notmatch '^\d{13,20}$' -or
    [string]$defines.HEALTHMATE_PRODUCTION_QA_TESTS -ne 'true' -or
    $defines.HEALTHMATE_QA_EMAIL_A -ne "healthmate.qa.u2.$run.a@example.com" -or
    $defines.HEALTHMATE_QA_EMAIL_B -ne "healthmate.qa.u2.$run.b@example.com" -or
    ([string]$defines.HEALTHMATE_QA_PASSWORD).Length -lt 24) {
  throw 'Invalid QA-only credential file. Never provide a real account.'
}
$metadata = Get-Content -LiteralPath (Join-Path $VerifiedDeploymentDirectory 'metadata.json') -Raw | ConvertFrom-Json
$source = [IO.File]::ReadAllText((Join-Path $root 'firestore.rules')).Replace("`r`n", "`n").Trim()
$sha = [Security.Cryptography.SHA256]::Create()
try {
  $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($source)))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }
if ($metadata.project -ne 'healthmate-app-20261013' -or -not $metadata.matchesLocal -or
    $metadata.deployedSha256 -ne $hash -or $metadata.localSha256 -ne $hash) {
  throw 'Verified deployment metadata must match the current Rules and project.'
}
$savedChrome = $env:CHROME_EXECUTABLE
$savedTestChrome = $env:HEALTHMATE_TEST_CHROME
$savedTestSdk = $env:HEALTHMATE_TEST_FLUTTER_SDK
Push-Location -LiteralPath $root
try {
  $env:HEALTHMATE_TEST_CHROME = $Chrome
  $env:HEALTHMATE_TEST_FLUTTER_SDK = $FlutterSdk
  $env:CHROME_EXECUTABLE = Join-Path $PSScriptRoot 'chrome_test_adapter.cmd'
  # Credentials are never printed or placed on the command line individually.
  # This opt-in harness is NOT an application build to distribute.
  & (Join-Path $FlutterSdk 'bin\flutter.bat') test --no-pub --platform chrome "--dart-define-from-file=$privateFile" test/firebase_production_qa.dart
  $result = $LASTEXITCODE
} finally {
  $env:CHROME_EXECUTABLE = $savedChrome
  $env:HEALTHMATE_TEST_CHROME = $savedTestChrome
  $env:HEALTHMATE_TEST_FLUTTER_SDK = $savedTestSdk
  Pop-Location
}
exit $result
