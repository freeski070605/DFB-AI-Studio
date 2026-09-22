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

# MMPose depends on chumpy==0.70. Chumpy's legacy setup.py imports pip
# during the build, which fails inside modern PEP 517 build isolation.
# Install it first in the real MuseTalk environment with build isolation disabled.
Write-Host ""
Write-Host "Preparing legacy chumpy dependency for MMPose..."
& $Py -m pip install --no-cache-dir "setuptools<82" wheel
if ($LASTEXITCODE -ne 0) { throw "Failed to prepare setuptools/wheel for chumpy." }

& $Py -m pip install --no-cache-dir --no-build-isolation "chumpy==0.70"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to install chumpy==0.70 without build isolation."
}

& $Py -c "import importlib.metadata as m; print('chumpy:', m.version('chumpy'))"
if ($LASTEXITCODE -ne 0) { throw "chumpy metadata verification failed." }

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

& $Py -c "import mmengine, mmcv, mmdet, mmpose; print('Core MMLab imports: OK')"
if ($LASTEXITCODE -ne 0) {
    throw "Core MMLab package import check failed."
}

& $Py -c "from mmpose.apis import inference_topdown, init_model; print('mmpose.apis: OK'); print('MMLAB_STACK_OK')"
if ($LASTEXITCODE -ne 0) {
    throw "MMPose API import check failed."
}

Write-Host ""
Write-Host "============================================================"
Write-Host "MuseTalk MMLab stack repaired and verified."
Write-Host "============================================================"
