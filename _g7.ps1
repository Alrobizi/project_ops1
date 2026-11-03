$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "input", "tap", "540", "1215") "p1.log"
Start-Sleep -Seconds 9
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs7.png") "p2.log"
Invoke-Adb @("pull", "/sdcard/gs7.png", "gs7.png") "p3.log"
Invoke-Adb @("shell", "dumpsys", "window") "win3.log"
Get-Content win3.log | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Write-Output ("gs7: " + (Get-Item "gs7.png" -ErrorAction SilentlyContinue).Length)
