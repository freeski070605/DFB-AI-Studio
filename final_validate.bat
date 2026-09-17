@echo off
setlocal
set "ROOT=E:\DFB_AI_Studio"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\final_validate.ps1"
if errorlevel 1 (
  echo.
  echo Final validation failed. Check the log under E:\DFB_AI_Studio\logs.
  pause
  exit /b 1
)
echo.
echo Final validation completed successfully.
pause
