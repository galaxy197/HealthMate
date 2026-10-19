param([string]$DeviceId='emulator-5580', [string]$AndroidSdk="$env:LOCALAPPDATA\Android\sdk")
$ErrorActionPreference='Stop'
$adb=Join-Path $AndroidSdk 'platform-tools\adb.exe'
if($DeviceId -ne 'emulator-5580' -or @(& $adb -s $DeviceId emu avd name)[0].Trim() -ne 'HealthMateMaintenanceQA') {throw 'Only the H7 QA AVD is allowed.'}
function Read-QABytes([string]$Arguments) {
  $start=[Diagnostics.ProcessStartInfo]::new()
  $start.FileName=$adb
  $start.Arguments="-s $DeviceId exec-out $Arguments"
  $start.UseShellExecute=$false
  $start.CreateNoWindow=$true
  $start.RedirectStandardOutput=$true
  $start.RedirectStandardError=$true
  $process=[Diagnostics.Process]::Start($start)
  $buffer=[IO.MemoryStream]::new()
  try {
    $process.StandardOutput.BaseStream.CopyTo($buffer)
    $null=$process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if($process.ExitCode -ne 0) {throw 'Could not read QA artifact bytes.'}
    return ,$buffer.ToArray()
  } finally {$buffer.Dispose();$process.Dispose()}
}
$files=@(& $adb -s $DeviceId shell ls -t '/sdcard/Download/HealthMate-*.csv')
if($LASTEXITCODE -ne 0 -or $files.Count -eq 0) {throw 'No actual exported CSV in QA Downloads.'}
$latest=$files[0].Trim()
if($latest -notmatch '^/sdcard/Download/HealthMate-[0-9-]+( \([0-9]+\))?\.csv$') {throw 'Unexpected export filename; refuse to construct a shell argument.'}
# exec-out does not parse shell quotes around a spaced path. Copy the observed,
# validated QA file to a fixed temporary QA path, then read its raw bytes.
& $adb -s $DeviceId shell "cp '$latest' /data/local/tmp/healthmate-h7-export-readback.csv"
if($LASTEXITCODE -ne 0) {throw 'Cannot stage the actual QA export for binary readback.'}
$actual=Read-QABytes 'cat /data/local/tmp/healthmate-h7-export-readback.csv'
$expected=Read-QABytes 'run-as com.example.healthmate cat cache/h7-expected.csv'
if($actual.Length -ne $expected.Length) {throw 'OS-exported file length differs from real repository CSV.'}
for($i=0;$i -lt $actual.Length;$i++) {if($actual[$i] -ne $expected[$i]) {throw 'OS-exported file bytes differ from real repository CSV.'}}
if($actual.Length -lt 4 -or $actual[0] -ne 239 -or $actual[1] -ne 187 -or $actual[2] -ne 191) {throw 'UTF-8 BOM missing.'}
$text=[Text.Encoding]::UTF8.GetString($actual)
foreach($marker in @('healthmate_journal_csv_v1','meal_item','water','activity','weight','QA Sữa','unknown','fiber_status')) {
  if(-not $text.Contains($marker)) {throw "Required CSV contract marker missing: $marker"}
}
Write-Output "H7 actual Downloads CSV verified byte-for-byte against real repository snapshot: $($actual.Length) bytes, BOM and all four record types. No contents logged."
