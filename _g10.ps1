$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "input", "tap", "75", "170") "s1.log"
Start-Sleep -Seconds 5
Invoke-Adb @("shell", "input", "tap", "140", "2185") "s2.log"
Start-Sleep -Seconds 4
Invoke-Adb @("shell", "screencap", "-p", "/sdcard/gs10.png") "s3.log"
Invoke-Adb @("pull", "/sdcard/gs10.png", "gs10.png") "s4.log"
Write-Output ("gs10: " + (Get-Item "gs10.png" -ErrorAction SilentlyContinue).Length)
