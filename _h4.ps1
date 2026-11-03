$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uix.xml') 'w1.log'
Invoke-Adb @('pull', '/sdcard/uix.xml', 'uix.xml') 'w2.log'

$x = Get-Content 'uix.xml' -Raw -Encoding UTF8
Write-Output ('contains Arabic logout word: ' + ($x -like '*الخروج*'))
$pattern = 'class="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
$i = 0
foreach ($m in [regex]::Matches($x, $pattern)) {
    $cls = $m.Groups[1].Value
    $d = $m.Groups[2].Value
    $x1 = [int]$m.Groups[3].Value; $y1 = [int]$m.Groups[4].Value
    $x2 = [int]$m.Groups[5].Value; $y2 = [int]$m.Groups[6].Value
    if ($d.Length -gt 0) {
        Write-Output ("[$i] $cls | $d | [$x1,$y1][$x2,$y2]")
    }
    $i++
}
