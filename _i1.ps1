$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Start-Sleep -Seconds 8
Invoke-Adb @('shell', 'dumpsys', 'window') 'd1.log'
Get-Content 'd1.log' | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uiq.xml') 'd2.log'
Invoke-Adb @('pull', '/sdcard/uiq.xml', 'uiq.xml') 'd3.log'
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g19.png') 'd4.log'
Invoke-Adb @('pull', '/sdcard/g19.png', 'g19.png') 'd5.log'

$x = Get-Content 'uiq.xml' -Raw -Encoding UTF8
$txt = [regex]::Matches($x, '(?:text|content-desc)="([^"]+)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
foreach ($m in $txt) {
    Write-Output ("$($m.Groups[1].Value) | [$($m.Groups[2].Value),$($m.Groups[3].Value)][$($m.Groups[4].Value),$($m.Groups[5].Value)]")
}
