$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "input", "tap", "540", "1905") "v1.log"
Start-Sleep -Seconds 2
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/g12.png") "v2.log"
Invoke-Adb @("pull", "/sdcard/g12.png", "g12.png") "v3.log"
Write-Output ("g12: " + (Get-Item "g12.png" -ErrorAction SilentlyContinue).Length)
