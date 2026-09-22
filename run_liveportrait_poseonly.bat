@echo off
setlocal
set "ROOT=E:\DFB_AI_Studio"
set "LIVE=C:\DFB_AI_Runtime\source\LivePortrait-main"
set "PY=%LIVE%\.venv\Scripts\python.exe"
set "PRESET=%ROOT%\workflows\portrait_animation\Drew_LivePortrait_PoseOnly.json"
set "DFB_LIVEPORTRAIT_SKIP_CONCAT=1"

if not exist "%PY%" (
  echo ERROR: LivePortrait Python not found:
  echo %PY%
  pause
  exit /b 1
)

if exist "%ROOT%\scripts\patch_liveportrait_longform.py" (
  "%PY%" "%ROOT%\scripts\patch_liveportrait_longform.py"
  if errorlevel 1 (
    echo ERROR: Failed to install/verify the long-form concat bypass.
    pause
    exit /b 1
  )
)

if not exist "%ROOT%\outputs\portrait_pose_only" mkdir "%ROOT%\outputs\portrait_pose_only"

echo.
echo DFB Stage 1: LivePortrait POSE ONLY
echo Eyes and mouth are intentionally not driven by LivePortrait.
echo.

"%PY%" "%ROOT%\scripts\run_liveportrait_preset.py" --preset "%PRESET%" %*
if errorlevel 1 pause
