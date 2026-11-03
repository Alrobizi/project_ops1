$ErrorActionPreference = 'Continue'
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
function Invoke-Adb($a, $out) {
    Start-Process -FilePath $adb -ArgumentList $a -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError "$out.err" | Out-Null
}

Invoke-Adb @('shell', 'input', 'tap', '540', '2124') 'b1.log'
Start-Sleep -Seconds 5
Invoke-Adb @('shell', 'dumpsys', 'window') 'b2.log'
Get-Content 'b2.log' | Select-String -Pattern 'mCurrentFocus' | Select-Object -First 2
Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/uip.xml') 'b3.log'
Invoke-Adb @('pull', '/sdcard/uip.xml', 'uip.xml') 'b4.log'
Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/g17.png') 'b5.log'
Invoke-Adb @('pull', '/sdcard/g17.png', 'g17.png') 'b6.log'

$x = Get-Content 'uip.xml' -Raw -Encoding UTF8
$pattern = 'class="([^"]*)"[^>]*content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
foreach ($m in [regex]::Matches($x, $pattern)) {
    $d = $m.Groups[2].Value
    if ($d.Length -gt 0) {
        $x1 = [int]$m.Groups[3].Value; $y1 = [int]$m.Groups[4].Value
        $x2 = [int]$m.Groups[5].Value; $y2 = [int]$m.Groups[6].Value
        Write-Output ("$($m.Groups[1].Value) | $d | [$x1,$y1][$x2,$y2]")
    }
}
$txt = [regex]::Matches($x, 'text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
foreach ($m in $txt) {
    $d = $m.Groups[1].Value
    if ($d.Length -gt 0) {
        Write-Output ("TEXT: $d | [$($m.Groups[2].Value),$($m.Groups[3].Value)][$($m.Groups[4].Value),$($m.Groups[5].Value)]")
    }
}
