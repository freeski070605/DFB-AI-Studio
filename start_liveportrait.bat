@echo off
setlocal
set "ROOT=E:\DFB_AI_Studio"
set "LIVE=C:\DFB_AI_Runtime\source\LivePortrait-main"
set "PY=%LIVE%\.venv\Scripts\python.exe"
set "GRADIO_ALLOWED_PATHS=%ROOT%\outputs\portrait_animation"
set "GRADIO_TEMP_DIR=E:\DFB_AI_Runtime\temp\gradio"
set "DFB_LIVEPORTRAIT_SKIP_CONCAT=1"

if not exist "%PY%" (
  echo LivePortrait environment not found at "%PY%".
  echo See README.md for installation status or manual steps.
  pause
  exit /b 1
)

if exist "%ROOT%\scripts\patch_liveportrait_longform.py" (
  "%PY%" "%ROOT%\scripts\patch_liveportrait_longform.py"
  if errorlevel 1 (
    echo Failed to verify/install DFB long-form patch.
    pause
    exit /b 1
  )
)

if not exist "%GRADIO_TEMP_DIR%" mkdir "%GRADIO_TEMP_DIR%"
if not exist "%ROOT%\outputs\portrait_animation" mkdir "%ROOT%\outputs\portrait_animation"

cd /d "%LIVE%"
echo DFB long-form mode: concat preview disabled.
"%PY%" app.py --output-dir "%ROOT%\outputs\portrait_animation" --server-name 127.0.0.1 --server-port 8890
if errorlevel 1 pause
