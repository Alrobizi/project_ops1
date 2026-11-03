$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
    return $p.ExitCode
}
Invoke-Adb @("logcat", "-c") "lc2.log" | Out-Null
Invoke-Adb @("shell", "input", "tap", "540", "1963") "k1.log" | Out-Null
Start-Sleep -Seconds 7
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs3.png") "k2.log" | Out-Null
Invoke-Adb @("pull", "/sdcard/gs3.png", "gs3.png") "k3.log" | Out-Null
Invoke-Adb @("shell", "dumpsys", "window") "win.log" | Out-Null
Get-Content win.log | Select-String -Pattern 'mCurrentFocus|mFocusedApp' | Select-Object -First 4
Write-Output ("gs3 bytes: " + (Get-Item "gs3.png" -ErrorAction SilentlyContinue).Length)
