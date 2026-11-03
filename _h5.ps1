$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'input', 'tap', '540', '1828') 'y1.log'
Start-Sleep -Seconds 2
Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uiy.xml') 'y2.log'
Invoke-Adb @('pull', '/sdcard/uiy.xml', 'uiy.xml') 'y3.log'
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g13.png') 'y4.log'
Invoke-Adb @('pull', '/sdcard/g13.png', 'g13.png') 'y5.log'

$x = Get-Content 'uiy.xml' -Raw -Encoding UTF8
$pattern = 'class="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
foreach ($m in [regex]::Matches($x, $pattern)) {
    $d = $m.Groups[2].Value
    if ($d.Length -gt 0) {
        $x1 = [int]$m.Groups[3].Value; $y1 = [int]$m.Groups[4].Value
        $x2 = [int]$m.Groups[5].Value; $y2 = [int]$m.Groups[6].Value
        Write-Output ("$($m.Groups[1].Value) | $d | [$x1,$y1][$x2,$y2]")
    }
}
Write-Output ('g13: ' + (Get-Item 'g13.png' -ErrorAction SilentlyContinue).Length)
