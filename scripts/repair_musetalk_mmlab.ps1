param(
    [string]$Root = "E:\DFB_AI_Runtime\source\MuseTalk"
)

$ErrorActionPreference = "Stop"

$Py = Join-Path $Root ".venv\Scripts\python.exe"
$Mim = Join-Path $Root ".venv\Scripts\mim.exe"
$TempRoot = "E:\DFB_AI_Runtime\temp\musetalk_mmlab"
$PipCache = "E:\DFB_AI_Runtime\pip_cache"

New-Item -ItemType Directory -Force $TempRoot, $PipCache | Out-Null
$env:TEMP = $TempRoot
$env:TMP = $TempRoot
$env:PIP_CACHE_DIR = $PipCache

if (-not (Test-Path $Py)) {
    throw "MuseTalk Python not found: $Py"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "DFB MuseTalk MMLab Repair"
Write-Host "============================================================"
Write-Host ""

Write-Host "MuseTalk Python:"
& $Py --version
if ($LASTEXITCODE -ne 0) { throw "MuseTalk Python could not start." }

# Ensure openmim exists in this exact MuseTalk environment.
& $Py -m pip install --no-cache-dir -U openmim
if ($LASTEXITCODE -ne 0) { throw "Failed to install openmim." }

if (-not (Test-Path $Mim)) {
    throw "mim.exe was not created at $Mim"
}

function Invoke-MimInstall {
    param([string]$Package)

    Write-Host ""
    Write-Host "Installing/verifying $Package ..."
    & $Mim install $Package
    if ($LASTEXITCODE -ne 0) {
        throw "MIM failed while installing $Package"
    }
}

Invoke-MimInstall "mmengine"
Invoke-MimInstall "mmcv==2.0.1"
Invoke-MimInstall "mmdet==3.1.0"
Invoke-MimInstall "mmpose==1.1.0"

Write-Host ""
Write-Host "Verifying MuseTalk MMLab imports..."

$Verify = @'
import sys
mods = ["mmengine", "mmcv", "mmdet", "mmpose"]
for name in mods:
    mod = __import__(name)
    print(f"{name}: {getattr(mod, '__version__', 'installed')}")
from mmpose.apis import inference_topdown, init_model
print("mmpose.apis: OK")
print("MMLAB_STACK_OK")
'@

& $Py -c $Verify
if ($LASTEXITCODE -ne 0) {
    throw "MMLab packages installed, but the final Python import check failed."
}

Write-Host ""
Write-Host "============================================================"
Write-Host "MuseTalk MMLab stack repaired and verified."
Write-Host "============================================================"
