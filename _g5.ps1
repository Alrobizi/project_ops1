$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    $p = Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err"
}
Invoke-Adb @("shell", "uiautomator", "dump", "/sdcard/ui.xml") "u1.log"
Invoke-Adb @("pull", "/sdcard/ui.xml", "ui.xml") "u2.log"
Get-Content u1.log
