$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'input', 'tap', '904', '1388') 'f1.log'
Start-Sleep -Seconds 6
Invoke-Adb @('shell', 'dumpsys', 'window') 'f2.log'
Get-Content 'f2.log' | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g21.png') 'f3.log'
Invoke-Adb @('pull', '/sdcard/g21.png', 'g21.png') 'f4.log'
Write-Output ('g21: ' + (Get-Item 'g21.png' -ErrorAction SilentlyContinue).Length)
