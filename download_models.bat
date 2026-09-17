@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\DFB_AI_Studio\scripts\download_models.ps1"
if errorlevel 1 pause
