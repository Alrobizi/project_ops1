$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
    return $p.ExitCode
}
Invoke-Adb @("logcat", "-c") "lc4.log" | Out-Null
Invoke-Adb @("shell", "input", "tap", "540", "1963") "m1.log" | Out-Null
Start-Sleep -Milliseconds 2500
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs4.png") "m2.log" | Out-Null
Invoke-Adb @("pull", "/sdcard/gs4.png", "gs4.png") "m3.log" | Out-Null
Start-Sleep -Seconds 3
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs5.png") "m4.log" | Out-Null
Invoke-Adb @("pull", "/sdcard/gs5.png", "gs5.png") "m5.log" | Out-Null
Write-Output ("gs4: " + (Get-Item "gs4.png" -ErrorAction SilentlyContinue).Length + "  gs5: " + (Get-Item "gs5.png" -ErrorAction SilentlyContinue).Length)
