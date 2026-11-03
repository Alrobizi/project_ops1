$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
    return $p.ExitCode
}
Invoke-Adb @("shell", "input", "swipe", "540", "1900", "540", "700", "250") "h1.log" | Out-Null
Start-Sleep -Milliseconds 800
Invoke-Adb @("shell", "input", "swipe", "540", "1900", "540", "700", "250") "h2.log" | Out-Null
Start-Sleep -Seconds 2
Invoke-Adb @("shell", "input", "tap", "540", "1770") "h3.log" | Out-Null
Start-Sleep -Seconds 2
Invoke-Adb @("shell", "input", "tap", "350", "1385") "h4.log" | Out-Null
Start-Sleep -Seconds 3
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs2.png") "h5.log" | Out-Null
Invoke-Adb @("pull", "/sdcard/gs2.png", "gs2.png") "h6.log" | Out-Null
Write-Output ("gs2 bytes: " + (Get-Item "gs2.png" -ErrorAction SilentlyContinue).Length)
