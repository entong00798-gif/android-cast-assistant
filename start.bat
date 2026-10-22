@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AndroidCast.ps1"
if errorlevel 1 (
  echo.
  echo Android Cast failed to start. See the error above.
  pause
)

