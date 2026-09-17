@echo off
setlocal
set "ROOT=E:\DFB_AI_Studio"
set "PY=C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe"
set "MAIN=C:\DFB_AI_Runtime\source\ComfyUI-master\main.py"
if not exist "%PY%" (
  echo ComfyUI runtime not found at "%PY%".
  echo See README.md for installation status.
  pause
  exit /b 1
)
"%PY%" "%MAIN%" --enable-manager --lowvram --reserve-vram 1.5 --input-directory "%ROOT%\inputs" --output-directory "%ROOT%\outputs" --temp-directory "C:\DFB_AI_Runtime\temp" --auto-launch
if errorlevel 1 pause
