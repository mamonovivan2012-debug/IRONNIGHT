@echo off
cd /d "%~dp0"
if not exist "IRON_NIGHT.exe" (echo IRON_NIGHT.exe not found.& pause & exit /b 1)
if not exist "IRON_NIGHT.pck" (echo IRON_NIGHT.pck not found. Keep it beside the EXE.& pause & exit /b 1)
start "" "%~dp0IRON_NIGHT.exe"
