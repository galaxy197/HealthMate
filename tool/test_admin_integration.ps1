param(
  [string]$FlutterSdk = 'D:\Flutter\flutter',
  [string]$JavaHome = 'C:\Program Files\Android\Android Studio\jbr',
  [string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe',
  [switch]$InsideEmulators
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
Push-Location -LiteralPath $projectRoot
try {
  if ($InsideEmulators) {
    if ($env:FIRESTORE_EMULATOR_HOST -ne '127.0.0.1:8092' -or
        $env:FIREBASE_AUTH_EMULATOR_HOST -ne '127.0.0.1:9098') {
      throw 'Requires the local Auth/Firestore emulators; no production fallback.'
    }
    & node admin-web/seed-emulators.mjs --extended
    if ($LASTEXITCODE -ne 0) { throw 'Emulator seed failed.' }
    Push-Location -LiteralPath (Join-Path $projectRoot 'rules-tests')
    try {
      & node --test *.rules.test.cjs
      if ($LASTEXITCODE -ne 0) { throw 'Security Rules tests failed.' }
    } finally { Pop-Location }
    & node --test admin-web/test/sdk.integration.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Admin SDK tests failed.' }
    & $flutter test --no-pub --platform chrome '--dart-define-from-file=config/admin-runtime.json' '--dart-define=HEALTHMATE_ADMIN_EMULATOR_TESTS=true' test/admin_runtime_integration.dart
    if ($LASTEXITCODE -ne 0) { throw 'Flutter runtime integration failed.' }
  } else {
    $firebase = (Get-Command firebase.cmd -ErrorAction Stop).Source
    $savedPath = $env:Path
    $savedJava = $env:JAVA_HOME
    $savedChrome = $env:CHROME_EXECUTABLE
    $savedTestChrome = $env:HEALTHMATE_TEST_CHROME
    $savedTestSdk = $env:HEALTHMATE_TEST_FLUTTER_SDK
    try {
      $env:JAVA_HOME = $JavaHome
      $env:Path = "$JavaHome\bin;$env:Path"
      $env:HEALTHMATE_TEST_CHROME = $Chrome
      $env:HEALTHMATE_TEST_FLUTTER_SDK = $FlutterSdk
      $env:CHROME_EXECUTABLE = Join-Path $PSScriptRoot 'chrome_test_adapter.cmd'
      # EncodedCommand preserves OneDrive paths containing spaces through the
      # Firebase CLI's Windows shell. It contains only paths, never credentials.
      $inner = "& '" + $PSCommandPath.Replace("'", "''") + "' -InsideEmulators -FlutterSdk '" + $FlutterSdk.Replace("'", "''") + "'"
      $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
      $command = 'powershell.exe -NoProfile -OutputFormat Text -ExecutionPolicy Bypass -EncodedCommand ' + $encoded
      & $firebase emulators:exec --config firebase.admin-emulators.json --only auth,firestore --project demo-healthmate-admin $command
      if ($LASTEXITCODE -ne 0) { throw 'Local admin integration tests failed.' }
    } finally {
      $env:Path = $savedPath
      $env:JAVA_HOME = $savedJava
      $env:CHROME_EXECUTABLE = $savedChrome
      $env:HEALTHMATE_TEST_CHROME = $savedTestChrome
      $env:HEALTHMATE_TEST_FLUTTER_SDK = $savedTestSdk
    }
  }
} finally { Pop-Location }
