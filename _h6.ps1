$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

# confirm logout
Invoke-Adb @('shell', 'input', 'tap', '358', '1338') 'z1.log'
Start-Sleep -Seconds 3
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g14.png') 'z2.log'
Invoke-Adb @('pull', '/sdcard/g14.png', 'g14.png') 'z3.log'

# tap Google button on login screen
Invoke-Adb @('shell', 'input', 'tap', '540', '2124') 'z4.log'
Start-Sleep -Seconds 4
Invoke-Adb @('shell', 'dumpsys', 'window') 'z5.log'
Get-Content 'z5.log' | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g15.png') 'z6.log'
Invoke-Adb @('pull', '/sdcard/g15.png', 'g15.png') 'z7.log'
Write-Output ('g14: ' + (Get-Item 'g14.png' -ErrorAction SilentlyContinue).Length + '  g15: ' + (Get-Item 'g15.png' -ErrorAction SilentlyContinue).Length)
