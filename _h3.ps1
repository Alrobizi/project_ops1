$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uix.xml') 'w1.log'
Invoke-Adb @('pull', '/sdcard/uix.xml', 'uix.xml') 'w2.log'

$x = Get-Content 'uix.xml' -Raw -Encoding UTF8
$pattern = 'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
foreach ($m in [regex]::Matches($x, $pattern)) {
    $d = $m.Groups[1].Value
    if ($d -like '*الخروج*' -or $d -like '*Google*' -or $d -like '*الإصدار*') {
        $x1 = [int]$m.Groups[2].Value; $y1 = [int]$m.Groups[3].Value
        $x2 = [int]$m.Groups[4].Value; $y2 = [int]$m.Groups[5].Value
        $cx = [int](($x1 + $x2) / 2); $cy = [int](($y1 + $y2) / 2)
        Write-Output "$d => center($cx,$cy) [$x1,$y1][$x2,$y2]"
    }
}

Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path 'g12.png'))
Write-Output ("png size: " + $img.Width + "x" + $img.Height)
$img.Dispose()
