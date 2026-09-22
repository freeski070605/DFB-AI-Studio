param(
    [string]$Root = "E:\DFB_AI_Runtime\source\MuseTalk"
)

$ErrorActionPreference = "Stop"

$Venv = Join-Path $Root ".venv"
$Py = Join-Path $Venv "Scripts\python.exe"
$TempRoot = "E:\DFB_AI_Runtime\temp\musetalk_install"
$PipCache = "E:\DFB_AI_Runtime\pip_cache"
$HfHome = "E:\DFB_AI_Runtime\hf_cache"

New-Item -ItemType Directory -Force $TempRoot, $PipCache, $HfHome | Out-Null
$env:TEMP = $TempRoot
$env:TMP = $TempRoot
$env:PIP_CACHE_DIR = $PipCache
$env:HF_HOME = $HfHome
$env:HUGGINGFACE_HUB_CACHE = Join-Path $HfHome "hub"

Write-Host ""
Write-Host "DFB MuseTalk 1.5 Installer"
Write-Host "Runtime: $Root"
Write-Host "Large temp/cache files stay on E:"
Write-Host ""

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git was not found in PATH." }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { throw "ffmpeg was not found in PATH." }

if (-not (Test-Path (Join-Path $Root ".git"))) {
    New-Item -ItemType Directory -Force (Split-Path $Root) | Out-Null
    git clone https://github.com/TMElyralab/MuseTalk.git $Root
} else {
    git -C $Root pull --ff-only
}

if (-not (Test-Path $Py)) {
    # Remove an incomplete venv left by a previous failed install.
    if (Test-Path $Venv) {
        Write-Host "Removing incomplete MuseTalk virtual environment..."
        Remove-Item $Venv -Recurse -Force
    }

    $Created = $false
    $LivePortraitPy = "C:\DFB_AI_Runtime\source\LivePortrait-main\.venv\Scripts\python.exe"

    # DFB first choice: reuse the already-working Python 3.10 interpreter
    # from LivePortrait to create a completely separate MuseTalk venv.
    if (Test-Path $LivePortraitPy) {
        try {
            $Version = (& $LivePortraitPy -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')").Trim()
        }
        catch {
            $Version = ""
        }

        if ($Version -eq "3.10") {
            Write-Host "Using the existing LivePortrait Python 3.10 interpreter..."
            Write-Host $LivePortraitPy
            & $LivePortraitPy -m venv $Venv

            if ($LASTEXITCODE -eq 0 -and (Test-Path $Py)) {
                $Created = $true
            }
        }
    }

    # Fallback: use a separately installed/registered system Python 3.10.
    # Run the probe through cmd.exe so py.exe's stderr does not become a
    # terminating NativeCommandError under Windows PowerShell.
    if (-not $Created -and (Get-Command py -ErrorAction SilentlyContinue)) {
        cmd /c "py -3.10 --version >nul 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Creating MuseTalk venv with system Python 3.10..."
            & py -3.10 -m venv $Venv

            if ($LASTEXITCODE -eq 0 -and (Test-Path $Py)) {
                $Created = $true
            }
        }
    }

    if (-not $Created) {
        throw @"
Python 3.10 is required, but no usable Python 3.10 interpreter was found.

The installer checked:
  1. C:\DFB_AI_Runtime\source\LivePortrait-main\.venv\Scripts\python.exe
  2. py -3.10

Do not continue until Python 3.10 is available.
"@
    }
}

if (-not (Test-Path $Py)) {
    throw "MuseTalk virtual environment was not created: $Py"
}

Write-Host "MuseTalk Python:"
& $Py --version

& $Py -m pip install --upgrade pip setuptools wheel
& $Py -m pip install --no-cache-dir torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118
& $Py -m pip install --no-cache-dir -r (Join-Path $Root "requirements.txt")

& $Py -m pip install --no-cache-dir -U openmim
$Mim = Join-Path $Venv "Scripts\mim.exe"
if (-not (Test-Path $Mim)) { throw "mim.exe was not installed correctly." }

& $Mim install mmengine
& $Mim install "mmcv==2.0.1"
& $Mim install "mmdet==3.1.0"
& $Mim install "mmpose==1.1.0"

$WeightScript = "E:\DFB_AI_Studio\scripts\download_musetalk_weights.ps1"
if (-not (Test-Path $WeightScript)) {
    throw "MuseTalk weight downloader not found: $WeightScript"
}

Write-Host ""
Write-Host "Downloading MuseTalk inference weights with resumable curl..."
& powershell -ExecutionPolicy Bypass -File $WeightScript -Root $Root
if ($LASTEXITCODE -ne 0) {
    throw "MuseTalk weight download failed. Rerun scripts\download_musetalk_weights.ps1 to resume."
}

$Models = Join-Path $Root "models"
$Required = @(
    (Join-Path $Models "musetalkV15\unet.pth"),
    (Join-Path $Models "musetalkV15\musetalk.json"),
    (Join-Path $Models "sd-vae\diffusion_pytorch_model.bin"),
    (Join-Path $Models "whisper\pytorch_model.bin"),
    (Join-Path $Models "dwpose\dw-ll_ucoco_384.pth"),
    (Join-Path $Models "face-parse-bisent\79999_iter.pth")
)

$Missing = $Required | Where-Object { -not (Test-Path $_) }
if ($Missing.Count -gt 0) {
    Write-Host "Missing required files:"
    $Missing | ForEach-Object { Write-Host " - $_" }
    throw "MuseTalk installation is incomplete."
}

Write-Host ""
& $Py -c "import torch; print('Torch:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
Write-Host ""
Write-Host "MuseTalk 1.5 installation complete."
Write-Host "Runtime: $Root"
