param(
  [string]$DeviceId = 'emulator-5554'
)

$ErrorActionPreference = 'Stop'
$tokenPath = Join-Path $env:LOCALAPPDATA 'HealthMate\app-check-debug-token.txt'
if (-not (Test-Path -LiteralPath $tokenPath)) {
  throw 'Thiếu App Check debug token cục bộ. Hãy tạo/đăng ký token trong Firebase App Check trước khi chạy AI.'
}

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) {
  $flutter = 'D:\Flutter\flutter\bin\flutter.bat'
}
$debugToken = (Get-Content -Raw -LiteralPath $tokenPath).Trim()
& $flutter run -d $DeviceId "--dart-define=HEALTHMATE_APP_CHECK_DEBUG_TOKEN=$debugToken"
