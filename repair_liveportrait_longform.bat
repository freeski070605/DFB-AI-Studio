@echo off
setlocal
set "ROOT=E:\DFB_AI_Studio"
set "LIVE=C:\DFB_AI_Runtime\source\LivePortrait-main"
set "PY=%LIVE%\.venv\Scripts\python.exe"
set "PATCH=%ROOT%\scripts\patch_liveportrait_longform.py"
set "TARGET=%LIVE%\src\live_portrait_pipeline.py"
set "DFB_LIVEPORTRAIT_SKIP_CONCAT=1"

echo.
echo ============================================================
echo DFB LivePortrait Long-Form Repair
echo ============================================================
echo.

if not exist "%PY%" (
  echo ERROR: LivePortrait Python not found:
  echo %PY%
  pause
  exit /b 1
)

if not exist "%PATCH%" (
  echo ERROR: Patch script not found:
  echo %PATCH%
  pause
  exit /b 1
)

"%PY%" "%PATCH%"
if errorlevel 1 (
  echo.
  echo ERROR: Patch failed.
  pause
  exit /b 1
)

echo.
findstr /C:"DFB_LIVEPORTRAIT_SKIP_CONCAT" "%TARGET%" >nul
if errorlevel 1 (
  echo ERROR: Patch marker was not found in:
  echo %TARGET%
  pause
  exit /b 1
)

echo VERIFIED: long-form concat bypass is installed.
echo.
echo The stock 3-panel concat preview will be skipped for long renders.
echo You can now start LivePortrait using:
echo %ROOT%\start_liveportrait.bat
echo.
pause
