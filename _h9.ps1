$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'input', 'tap', '540', '1354') 'c1.log'
Start-Sleep -Seconds 5
Invoke-Adb @('shell', 'dumpsys', 'window') 'c2.log'
Get-Content 'c2.log' | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g18.png') 'c3.log'
Invoke-Adb @('pull', '/sdcard/g18.png', 'g18.png') 'c4.log'
Write-Output ('g18: ' + (Get-Item 'g18.png' -ErrorAction SilentlyContinue).Length)
