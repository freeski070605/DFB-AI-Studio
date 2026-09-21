@echo off
set "GRADIO_ALLOWED_PATHS=E:\DFB_AI_Studio\outputs\portrait_animation"
setlocal
set "ROOT=E:\DFB_AI_Studio"
set "LIVE=C:\DFB_AI_Runtime\source\LivePortrait-main"
set "PY=%LIVE%\.venv\Scripts\python.exe"
if not exist "%PY%" (
  echo LivePortrait environment not found at "%PY%".
  echo See README.md for installation status or manual steps.
  pause
  exit /b 1
)
cd /d "%LIVE%"
set "GRADIO_TEMP_DIR=E:\DFB_AI_Runtime\temp\gradio"
"%PY%" app.py --output-dir "%ROOT%\outputs\portrait_animation" --server-name 127.0.0.1 --server-port 8890
if errorlevel 1 pause
