param(
  [string]$DeviceId='emulator-5580',
  [string]$FlutterSdk='D:\Flutter\flutter',
  [string]$AndroidSdk="$env:LOCALAPPDATA\Android\sdk",
  [switch]$RunInner
)
$ErrorActionPreference='Stop'
$adb=Join-Path $AndroidSdk 'platform-tools\adb.exe'
$flutter=Join-Path $FlutterSdk 'bin\flutter.bat'
if($DeviceId -ne 'emulator-5580' -or @(& $adb -s $DeviceId emu avd name)[0].Trim() -ne 'HealthMateMaintenanceQA') {
  throw 'H7 only permits the dedicated synthetic QA AVD.'
}
if((& $adb -s $DeviceId shell getprop sys.boot_completed).Trim() -ne '1') {throw 'QA AVD has not booted.'}
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$exitCode=1
function Read-LiveLog([string]$Path) {
  $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
  $reader=[IO.StreamReader]::new($stream)
  try {return $reader.ReadToEnd()} finally {$reader.Dispose()}
}
try {
  if(-not $RunInner) {
    $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
    $env:Path="$env:JAVA_HOME\bin;$env:Path"
    $props=Join-Path (Get-Location).Path 'android\gradle.properties'
    $saved=[IO.File]::ReadAllBytes($props)
    try {
      [IO.File]::AppendAllText($props,"`nkotlin.incremental=false`n",[Text.UTF8Encoding]::new($false))
      $command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File tool/test_h7_android.ps1 -RunInner -DeviceId emulator-5580'
      & firebase.cmd emulators:exec --config firebase.emulators.json --only auth,firestore --project demo-healthmate-rules $command
      $exitCode=$LASTEXITCODE
    } finally {[IO.File]::WriteAllBytes($props,$saved)}
  } else {
    $output=Join-Path (Get-Location).Path 'build\h7-android'
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    # A failed prior test can leave its system picker above a removed activity.
    # Cancel that observed QA picker; never clear/uninstall app data.
    $activities=(& $adb -s $DeviceId shell dumpsys activity activities) -join "`n"
    if($activities -match 'mResumedActivity:.*documentsui' -and $activities -match 'mCallingPackage=com.example.healthmate') {
      $null=& $adb -s $DeviceId shell input keyevent 4
    }
    $null=& $adb -s $DeviceId shell am force-stop com.example.healthmate
    foreach($phase in @(1,2)) {
      $stdout=Join-Path $output "phase-$phase.log"
      $stderr=Join-Path $output "phase-$phase-error.log"
      $arguments=@('drive','--no-pub','-d',$DeviceId,'--keep-app-running',
        '--driver=test_driver/core_acceptance_driver.dart','--target=integration_test/h7_private_data_test.dart',
        '--dart-define=HEALTHMATE_CORE_EMULATOR_TESTS=true',"--dart-define=HEALTHMATE_H7_PHASE=$phase",
        '--dart-define=HEALTHMATE_ENABLE_CHATBOT=false','--dart-define=HEALTHMATE_ENABLE_FOOD_SCANNER=false')
      $process=Start-Process -FilePath $flutter -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
      # Cache the OS handle while alive; Windows PowerShell 5 otherwise may lose
      # ExitCode when HasExited is polled on a Start-Process wrapper for .bat.
      $null=$process.Handle
      $handled=@{}
      $deadline=[DateTime]::UtcNow.AddMinutes(14)
      while(-not $process.HasExited) {
        if([DateTime]::UtcNow -gt $deadline) {throw 'H7 drive timed out; inspect the retained QA process/logs.'}
        if($phase -eq 2 -and (Test-Path -LiteralPath $stdout)) {
          $log=Read-LiveLog $stdout
          foreach($marker in @('H7_EXPORT_PICKER_READY','H7_EXPORT_SWITCH_PICKER_READY')) {
            if(-not $handled.ContainsKey($marker) -and $log.Contains($marker)) {
              # Read the real Android accessibility tree; select only the observed Save action.
              $null=& $adb -s $DeviceId shell uiautomator dump /sdcard/hm-h7-picker.xml 2>&1
              $xmlText=(& $adb -s $DeviceId shell cat /sdcard/hm-h7-picker.xml 2>$null) -join "`n"
              if($xmlText -match 'com\.(google\.android|android)\.documentsui') {
                [xml]$tree=$xmlText
                $save=@($tree.SelectNodes('//node') | Where-Object {
                  $_.'resource-id' -match ':id/(button1|button_create)$' -and $_.enabled -eq 'true' -and $_.text -match '^(SAVE|Save|LƯU|Lưu)$'
                })
                if($save.Count -eq 1 -and $save[0].bounds -match '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
                  $x=[int](([int]$Matches[1]+[int]$Matches[3])/2)
                  $y=[int](([int]$Matches[2]+[int]$Matches[4])/2)
                  $null=& $adb -s $DeviceId shell input tap $x $y
                  $handled[$marker]=$true
                  Write-Output "H7 native picker Save selected: $marker"
                }
              }
            }
          }
        }
        Start-Sleep -Seconds 1
        $process.Refresh()
      }
      $process.WaitForExit()
      Get-Content -LiteralPath $stdout -Tail 35
      Get-Content -LiteralPath $stderr -Tail 15
      if($process.ExitCode -ne 0) {throw "H7 phase $phase failed: $($process.ExitCode)"}
      if($phase -eq 1) {
        if(-not ([IO.File]::ReadAllText($stdout)).Contains('H7_PHASE1_DRAFT_DURABLE_NO_SERVER_WRITE')) {throw 'Phase 1 checkpoint missing.'}
        $null=& $adb -s $DeviceId shell am force-stop com.example.healthmate
        if($LASTEXITCODE -ne 0) {throw 'Could not stop the QA process.'}
        Write-Output 'H7 PROCESS DEATH: am force-stop; app data retained, no uninstall/clear-data.'
      } else {
        if($handled.Count -ne 2) {throw 'Both native picker paths must be exercised.'}
      }
    }
    $exitCode=0
  }
} finally {Pop-Location}
exit $exitCode
