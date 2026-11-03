$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "input", "swipe", "540", "1900", "540", "700", "250") "t1.log"
Start-Sleep -Milliseconds 700
Invoke-Adb @("shell", "input", "swipe", "540", "1900", "540", "700", "250") "t2.log"
Start-Sleep -Seconds 2
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/g11.png") "t3.log"
Invoke-Adb @("pull", "/sdcard/g11.png", "g11.png") "t4.log"
Write-Output ("g11: " + (Get-Item "g11.png" -ErrorAction SilentlyContinue).Length)
