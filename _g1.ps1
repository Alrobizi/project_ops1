$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
    return $p.ExitCode
}
Invoke-Adb @("logcat", "-c") "lclear.log" | Out-Null
Invoke-Adb @("shell", "am", "start", "-W", "-n", "com.market.alrabizi_app/.MainActivity") "g1.log" | Out-Null
Start-Sleep -Seconds 3
Invoke-Adb @("shell", "input", "tap", "75", "185") "g2.log" | Out-Null
Start-Sleep -Seconds 3
Invoke-Adb @("shell", "input", "tap", "140", "2185") "g3.log" | Out-Null
Start-Sleep -Seconds 3
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs1.png") "g4.log" | Out-Null
Invoke-Adb @("pull", "/sdcard/gs1.png", "gs1.png") "g5.log" | Out-Null
Write-Output ("gs1 bytes: " + (Get-Item "gs1.png" -ErrorAction SilentlyContinue).Length)
