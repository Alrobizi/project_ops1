$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

# focus email field
Invoke-Adb @('shell', 'input', 'tap', '540', '930') 'e1.log'
Start-Sleep -Seconds 2
Invoke-Adb @('shell', 'input', 'text', 's734442069@gmail.com') 'e2.log'
Start-Sleep -Seconds 2
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g20.png') 'e3.log'
Invoke-Adb @('pull', '/sdcard/g20.png', 'g20.png') 'e4.log'
Write-Output ('g20: ' + (Get-Item 'g20.png' -ErrorAction SilentlyContinue).Length)
Get-Content 'e2.log' -ErrorAction SilentlyContinue | Select-Object -First 5
