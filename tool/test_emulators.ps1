param(
  [string]$FlutterSdk = 'D:\Flutter\flutter',
  [string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe',
  [string]$JavaHome = 'C:\Program Files\Android\Android Studio\jbr',
  [switch]$WithoutChromeAdapter
)

$ErrorActionPreference = 'Stop'
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
$firebase = (Get-Command firebase.cmd -ErrorAction Stop).Source
foreach ($required in @($flutter, $Chrome, (Join-Path $JavaHome 'bin\java.exe'))) {
  if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
    throw "Thiếu công cụ: $required. Hãy truyền đường dẫn phù hợp vào script."
  }
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Cần Node.js 22+.' }
$savedPath = $env:Path
$savedJava = $env:JAVA_HOME
$savedChrome = $env:CHROME_EXECUTABLE
$savedTestChrome = $env:HEALTHMATE_TEST_CHROME
$savedTestSdk = $env:HEALTHMATE_TEST_FLUTTER_SDK
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
  $env:JAVA_HOME = $JavaHome
  $env:Path = "$JavaHome\bin;$env:Path"
  $env:HEALTHMATE_TEST_CHROME = $Chrome
  $env:HEALTHMATE_TEST_FLUTTER_SDK = $FlutterSdk
  $env:CHROME_EXECUTABLE = if ($WithoutChromeAdapter) { $Chrome } else {
    Join-Path $PSScriptRoot 'chrome_test_adapter.cmd'
  }
  # Both services point at a fixed demo project. Never use the active project.
  $command = 'npm test --prefix rules-tests && node tool/test_h1_catalog_import.cjs && "' + $flutter + '" test --no-pub --platform chrome --dart-define=HEALTHMATE_EMULATOR_TESTS=true test/firebase_repository_integration.dart'
  & $firebase emulators:exec --config firebase.emulators.json --only auth,firestore --project demo-healthmate-rules $command
  $result = $LASTEXITCODE
} finally {
  $env:Path = $savedPath
  $env:JAVA_HOME = $savedJava
  $env:CHROME_EXECUTABLE = $savedChrome
  $env:HEALTHMATE_TEST_CHROME = $savedTestChrome
  $env:HEALTHMATE_TEST_FLUTTER_SDK = $savedTestSdk
  Pop-Location
}
exit $result
