# ============================================================
#  تشغيل تطبيق project_ops في محاكي أندرويد
#  يقوم هذا السكربت بـ:
#   1) تحديد مسار Flutter تلقائياً
#   2) التحقق من أن سيرفر Laravel يعمل على المنفذ 8009 (تنبيه فقط)
#   3) استخدام محاكي متصل، أو تشغيل أول AVD متاح وانتظار الإقلاع
#   4) تنفيذ flutter run على المحاكي
# ============================================================

$ErrorActionPreference = 'Stop'

# ضمان عرض النصوص العربية بشكل صحيح في نافذة التشغيل
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  تشغيل تطبيق project_ops في محاكي أندرويد" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------- 1) تحديد مسار Flutter ----------
$flutter = $null
$fc = Get-Command flutter -ErrorAction SilentlyContinue
if ($fc) {
    $flutter = $fc.Source
}
elseif (Test-Path "$env:USERPROFILE\Downloads\flutter\bin\flutter.bat") {
    $flutter = "$env:USERPROFILE\Downloads\flutter\bin\flutter.bat"
}
else {
    Write-Host "[خطأ] لم يتم العثور على Flutter. أضفه إلى PATH أو ثبّته في المسار الافتراضي." -ForegroundColor Red
    Read-Host "اضغط Enter للخروج"
    exit 1
}
Write-Host "[معلومات] تم العثور على Flutter:" -ForegroundColor Green
Write-Host "          $flutter" -ForegroundColor Green

# ---------- 2) تحديد أدوات Android (ADB / Emulator) ----------
$androidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
$adb = Join-Path $androidHome "platform-tools\adb.exe"
$emu = Join-Path $androidHome "emulator\emulator.exe"

if (-not (Test-Path $adb)) { $adb = "adb" }
if (-not (Test-Path $emu)) {
    Write-Host "[خطأ] لم يتم العثور على emulator.exe في: $emu" -ForegroundColor Red
    Read-Host "اضغط Enter للخروج"
    exit 1
}

# ---------- 3) التحقق من السيرفر (Laravel على المنفذ 8009) ----------
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8009/api/banners" -TimeoutSec 3 -UseBasicParsing
    if ($r.StatusCode -eq 200) {
        Write-Host "[معلومات] السيرفر يعمل على المنفذ 8009." -ForegroundColor Green
    }
    else {
        Write-Host "[تنبيه] السيرفر يستجيب برمز غير متوقع ($($r.StatusCode))." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[تنبيه] السيرفر (Laravel) غير متصل على المنفذ 8009." -ForegroundColor Yellow
    Write-Host "          شغّله أولاً:  php artisan serve --port=8009" -ForegroundColor Yellow
}

# ---------- 4) تحديد محاكي متصل، أو تشغيل واحد ----------
function Get-EmulatorDevice {
    $lines = & $adb devices 2>$null
    $lines | Select-String -Pattern '^emulator-' | ForEach-Object {
        ($_.ToString() -split '\s+')[0]
    }
}

$device = Get-EmulatorDevice | Select-Object -First 1

if ($device) {
    Write-Host "[معلومات] تم العثور على محاكي متصل: $device" -ForegroundColor Green
}
else {
    Write-Host "[معلومات] لا يوجد محاكي متصل، جاري تشغيل محاكي جديد..." -ForegroundColor Yellow
    $avds = & $emu -list-avds 2>$null | Where-Object { $_.Trim() -ne '' }
    if (-not $avds) {
        Write-Host "[خطأ] لم يتم العثور على أي AVD. أنشئ محاكياً من Android Studio." -ForegroundColor Red
        Read-Host "اضغط Enter للخروج"
        exit 1
    }
    $avd = ($avds | Select-Object -First 1).Trim()
    Write-Host "[معلومات] تشغيل المحاكي: $avd" -ForegroundColor Green
    Start-Process -FilePath $emu -ArgumentList @("-avd", $avd, "-no-snapshot-load") -WindowStyle Minimized

    Write-Host "[معلومات] انتظار اكتمال إقلاع المحاكي..." -ForegroundColor Yellow
    & $adb wait-for-device
    $booted = $false
    for ($i = 0; $i -lt 120; $i++) {
        $prop = (& $adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ($prop -eq '1') { $booted = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $booted) {
        Write-Host "[خطأ] انتهت مهلة إقلاع المحاكي (4 دقائق)." -ForegroundColor Red
        Read-Host "اضغط Enter للخروج"
        exit 1
    }
    Write-Host "[معلومات] اكتمل إقلاع المحاكي." -ForegroundColor Green
    $device = Get-EmulatorDevice | Select-Object -First 1
    if (-not $device) { $device = "emulator-5554" }
}

# ---------- 5) تشغيل التطبيق ----------
Write-Host ""
Write-Host "[معلومات] جاري بناء وتشغيل التطبيق على: $device" -ForegroundColor Cyan
Write-Host "          (اضغط q للخروج من وضع التشغيل)" -ForegroundColor Cyan
Write-Host ""
& $flutter run -d $device --no-pub

Write-Host ""
Write-Host "تم إنهاء تشغيل التطبيق." -ForegroundColor Green
Read-Host "اضغط Enter للإغلاق"
