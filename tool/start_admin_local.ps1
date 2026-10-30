$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$address = 'http://127.0.0.1:4173/'

function Test-AdminPage {
  try {
    $page = Invoke-WebRequest -Uri $address -UseBasicParsing -TimeoutSec 2
    return $page.StatusCode -eq 200 -and $page.Content.Contains('<h1>HealthMate Admin</h1>')
  } catch {
    return $false
  }
}

if (Test-AdminPage) {
  Write-Output "HealthMate Admin already running: $address"
  exit 0
}
if (Get-NetTCPConnection -LocalPort 4173 -State Listen -ErrorAction SilentlyContinue) {
  throw 'Port 4173 is used by a different service. Stop that service or choose the online admin launch configuration.'
}

$nodePath = (Get-Command node.exe -ErrorAction Stop).Source
$logDirectory = Join-Path $projectRoot 'build\admin-local'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$stdoutPath = Join-Path $logDirectory 'server.stdout.log'
$stderrPath = Join-Path $logDirectory 'server.stderr.log'
# Keep serving after the pre-launch task finishes. A hidden helper avoids
# opening a separate command window each time the user presses F5.
$server = Start-Process -FilePath $nodePath -ArgumentList 'admin-web/server.mjs' `
  -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
  -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$server.Id | Set-Content -LiteralPath (Join-Path $logDirectory 'server.pid')
for ($attempt = 0; $attempt -lt 30; $attempt++) {
  if (Test-AdminPage) {
    Write-Output "HealthMate Admin ready: $address"
    Write-Output 'Local login requires the Auth/Firestore emulators described in admin-web/README.md.'
    exit 0
  }
  if ($server.HasExited) {
    throw "Admin server exited. See $stderrPath"
  }
  Start-Sleep -Milliseconds 200
}
throw "Admin server did not become ready. See $stdoutPath and $stderrPath"
