@echo off
setlocal
chcp 65001 >nul
title Run project_ops in Android Emulator
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1"
endlocal