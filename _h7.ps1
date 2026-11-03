$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'input', 'swipe', '540', '700', '540', '2000', '250') 'a1.log'
Start-Sleep -Milliseconds 700
Invoke-Adb @('shell', 'input', 'swipe', '540', '700', '540', '2000', '250') 'a2.log'
Start-Sleep -Seconds 2
Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uiz.xml') 'a3.log'
Invoke-Adb @('pull', '/sdcard/uiz.xml', 'uiz.xml') 'a4.log'
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g16.png') 'a5.log'
Invoke-Adb @('pull', '/sdcard/g16.png', 'g16.png') 'a6.log'

$x = Get-Content 'uiz.xml' -Raw -Encoding UTF8
$pattern = 'class="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
foreach ($m in [regex]::Matches($x, $pattern)) {
    $d = $m.Groups[2].Value
    if ($d.Length -gt 0) {
        $x1 = [int]$m.Groups[3].Value; $y1 = [int]$m.Groups[4].Value
        $x2 = [int]$m.Groups[5].Value; $y2 = [int]$m.Groups[6].Value
        Write-Output ("$($m.Groups[1].Value) | $d | [$x1,$y1][$x2,$y2]")
    }
}
