$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("logcat", "-c") "lc7.log"
Invoke-Adb @("shell", "input", "tap", "540", "2124") "n1.log"
Start-Sleep -Seconds 4
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs6.png") "n2.log"
Invoke-Adb @("pull", "/sdcard/gs6.png", "gs6.png") "n3.log"
Invoke-Adb @("shell", "dumpsys", "window") "win2.log"
Get-Content win2.log | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Write-Output ("gs6: " + (Get-Item "gs6.png" -ErrorAction SilentlyContinue).Length)
