$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "am", "force-stop", "com.market.alrabizi_app") "r1.log"
Start-Sleep -Seconds 1
Invoke-Adb @("shell", "am", "start", "-W", "-n", "com.market.alrabizi_app/.MainActivity") "r2.log"
Start-Sleep -Seconds 6
Invoke-Adb @("shell", "input", "tap", "140", "2185") "r3.log"
Start-Sleep -Seconds 4
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs9.png") "r4.log"
Invoke-Adb @("pull", "/sdcard/gs9.png", "gs9.png") "r5.log"
Write-Output ("gs9: " + (Get-Item "gs9.png" -ErrorAction SilentlyContinue).Length)
