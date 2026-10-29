# إزالة const من المواضع المُبلَّغ عنها في _build_err.txt
$enc = [System.Text.UTF8Encoding]::new($false)
$root = Get-Location

$errors = @()
foreach ($line in (Get-Content _build_err.txt)) {
  $m = [regex]::Match($line, '^(lib/[^:]+\.dart):(\d+):\d+: Error')
  if ($m.Success) { $errors += [pscustomobject]@{ File = $m.Groups[1].Value; Line = [int]$m.Groups[2].Value } }
}

# تجميع حسب الملف مع إزالة التكرار
$byFile = $errors | Sort-Object File, Line -Unique | Group-Object File
$totalFixed = 0
foreach ($g in $byFile) {
  $rel = $g.Name
  $full = Join-Path $root $rel
  $raw = [System.IO.File]::ReadAllText($full, $enc)
  $useCRLF = $raw.Contains("`r`n")
  $nl = if ($useCRLF) { "`r`n" } else { "`n" }
  $lines = $raw -split "`r?`n"
  if ($lines[$lines.Count-1] -eq '') { $lines = $lines[0..($lines.Count-2)] }

  foreach ($e in $g.Group) {
    $idx = $e.Line - 1
    $done = $false
    # 1) جرب السطر المُبلَّغ عنه نفسه، ثم ابحث صاعداً حتى 10 أسطر
    for ($d = 0; $d -le 10 -and -not $done; $d++) {
      $i = $idx - $d
      if ($i -lt 0) { break }
      if ($lines[$i] -match '(?<![\w])const\s') {
        $m2 = [regex]::Match($lines[$i], '(?<![\w])const\s')
        $lines[$i] = $lines[$i].Remove($m2.Index, $m2.Length)
        $done = $true
        $totalFixed++
        Write-Host "fixed $rel : line $($i+1) (reported $($e.Line))"
      }
    }
    if (-not $done) { Write-Host "NOT FOUND const near $rel : $($e.Line)" }
  }

  $out = ($lines -join $nl) + $nl
  [System.IO.File]::WriteAllText($full, $out, $enc)
}
Write-Host "TOTAL fixed: $totalFixed"
