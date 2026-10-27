function Get-HealthMateAndroidArguments {
  param([Parameter(Mandatory=$true)][string]$ProjectRoot)

  $runtimeConfig = Join-Path $ProjectRoot 'config\admin-runtime.json'
  $chatConfig = Join-Path $ProjectRoot 'config\chat-api.json'
  $tokenPath = Join-Path $env:LOCALAPPDATA 'HealthMate\app-check-debug-token.txt'
  foreach ($required in @($runtimeConfig, $chatConfig, $tokenPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Missing Android configuration: $required"
    }
  }
  $runtime = Get-Content -Raw -LiteralPath $runtimeConfig | ConvertFrom-Json
  if ($runtime.HEALTHMATE_ENABLE_ADMIN_CONTROLS -ne $true) {
    throw 'Android app builds require HEALTHMATE_ENABLE_ADMIN_CONTROLS=true.'
  }
  $chat = Get-Content -Raw -LiteralPath $chatConfig | ConvertFrom-Json
  if ($chat.PSObject.Properties.Name -contains 'HEALTHMATE_ENABLE_ADMIN_CONTROLS') {
    throw 'Keep the admin flag in config/admin-runtime.json to avoid conflicting configuration.'
  }
  $debugToken = (Get-Content -Raw -LiteralPath $tokenPath).Trim()
  if ([string]::IsNullOrWhiteSpace($debugToken)) {
    throw 'The local App Check debug token is empty.'
  }
  @(
    "--dart-define-from-file=$chatConfig"
    "--dart-define-from-file=$runtimeConfig"
    "--dart-define=HEALTHMATE_APP_CHECK_DEBUG_TOKEN=$debugToken"
  )
}
