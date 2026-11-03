$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "input", "tap", "140", "2185") "q1.log"
Start-Sleep -Seconds 4
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs8.png") "q2.log"
Invoke-Adb @("pull", "/sdcard/gs8.png", "gs8.png") "q3.log"
Invoke-Adb @("shell", "uiautomator", "dump", "/sdcard/ui2.xml") "q4.log"
Invoke-Adb @("pull", "/sdcard/ui2.xml", "ui2.xml") "q5.log"
Write-Output ("gs8: " + (Get-Item "gs8.png" -ErrorAction SilentlyContinue).Length)
