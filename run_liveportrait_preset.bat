@echo off
setlocal
set "DFB_LIVEPORTRAIT_SKIP_CONCAT=1"
set "ROOT=E:\DFB_AI_Studio"
set "LIVE=C:\DFB_AI_Runtime\source\LivePortrait-main"
set "PY=%LIVE%\.venv\Scripts\python.exe"
set "PRESET=%ROOT%\workflows\portrait_animation\Drew_LivePortrait_Freestyle.json"

if not exist "%PY%" (
  echo LivePortrait Python not found: "%PY%"
  pause
  exit /b 1
)

if not exist "%PRESET%" (
  echo Preset not found: "%PRESET%"
  pause
  exit /b 1
)

"%PY%" "%ROOT%\scripts\run_liveportrait_preset.py" --preset "%PRESET%" %*
if errorlevel 1 pause
