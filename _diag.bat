@echo off
setlocal enabledelayedexpansion
set "ADB=C:\Users\MSI\AppData\Local\Android\Sdk\platform-tools\adb.exe"
"%ADB%" devices > %TEMP%\dv.txt
echo ===FINDSTR_C===
findstr /C:"emulator-" %TEMP%\dv.txt
echo ===FINDSTR_R===
findstr /r "emulator-" %TEMP%\dv.txt
echo ===FOR_C===
set "DV="
for /f "tokens=1" %%d in ('findstr /C:"emulator-" %TEMP%\dv.txt') do (set "DV=%%d" & goto f)
:f
if defined DV (echo FOUND=!DV!) else (echo NF)
del %TEMP%\dv.txt >nul 2>&1
endlocal
