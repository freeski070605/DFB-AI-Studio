param(
    [string]$Root = "E:\DFB_AI_Runtime\source\MuseTalk"
)

$ErrorActionPreference = "Stop"

function Download-Resumable {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination,
        [long]$MinBytes = 1
    )

    $Dir = Split-Path $Destination
    $Partial = "$Destination.partial"
    New-Item -ItemType Directory -Force $Dir | Out-Null

    if (Test-Path $Destination) {
        $Existing = (Get-Item $Destination).Length
        if ($Existing -ge $MinBytes) {
            Write-Host "OK already present: $Destination"
            return
        }
        Write-Host "Existing file is too small; replacing: $Destination"
        Remove-Item $Destination -Force
    }

    Write-Host ""
    Write-Host "Downloading:"
    Write-Host $Url
    Write-Host "To:"
    Write-Host $Destination

    $Curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $Curl) {
        throw "curl.exe was not found. Windows curl is required for the resumable model downloads."
    }

    & $Curl.Source `
        -L `
        --fail `
        --retry 50 `
        --retry-all-errors `
        --retry-delay 2 `
        --connect-timeout 30 `
        --continue-at - `
        --output $Partial `
        $Url

    if ($LASTEXITCODE -ne 0) {
        throw "Download failed for $Url. Leave the .partial file in place and rerun this script; curl will resume it."
    }

    $Size = (Get-Item $Partial).Length
    if ($Size -lt $MinBytes) {
        throw "Downloaded file is unexpectedly small: $Partial ($Size bytes)"
    }

    Move-Item $Partial $Destination -Force
    Write-Host "Completed: $Destination"
}

$Models = Join-Path $Root "models"
New-Item -ItemType Directory -Force $Models | Out-Null

Write-Host ""
Write-Host "============================================================"
Write-Host "DFB MuseTalk 1.5 Resumable Weight Downloader"
Write-Host "Root: $Root"
Write-Host "============================================================"
Write-Host ""

# MuseTalk 1.5
Download-Resumable `
  -Url "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalkV15/unet.pth?download=true" `
  -Destination (Join-Path $Models "musetalkV15\unet.pth") `
  -MinBytes 3000000000

Download-Resumable `
  -Url "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalkV15/musetalk.json?download=true" `
  -Destination (Join-Path $Models "musetalkV15\musetalk.json") `
  -MinBytes 500

# SD VAE
Download-Resumable `
  -Url "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/config.json?download=true" `
  -Destination (Join-Path $Models "sd-vae\config.json") `
  -MinBytes 300

Download-Resumable `
  -Url "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/diffusion_pytorch_model.bin?download=true" `
  -Destination (Join-Path $Models "sd-vae\diffusion_pytorch_model.bin") `
  -MinBytes 300000000

# Whisper tiny
Download-Resumable `
  -Url "https://huggingface.co/openai/whisper-tiny/resolve/main/config.json?download=true" `
  -Destination (Join-Path $Models "whisper\config.json") `
  -MinBytes 1000

Download-Resumable `
  -Url "https://huggingface.co/openai/whisper-tiny/resolve/main/pytorch_model.bin?download=true" `
  -Destination (Join-Path $Models "whisper\pytorch_model.bin") `
  -MinBytes 140000000

Download-Resumable `
  -Url "https://huggingface.co/openai/whisper-tiny/resolve/main/preprocessor_config.json?download=true" `
  -Destination (Join-Path $Models "whisper\preprocessor_config.json") `
  -MinBytes 100000

# DWPose
Download-Resumable `
  -Url "https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384.pth?download=true" `
  -Destination (Join-Path $Models "dwpose\dw-ll_ucoco_384.pth") `
  -MinBytes 350000000

# Face parsing
Download-Resumable `
  -Url "https://huggingface.co/ManyOtherFunctions/face-parse-bisent/resolve/main/79999_iter.pth?download=true" `
  -Destination (Join-Path $Models "face-parse-bisent\79999_iter.pth") `
  -MinBytes 45000000

Download-Resumable `
  -Url "https://huggingface.co/ManyOtherFunctions/face-parse-bisent/resolve/main/resnet18-5c106cde.pth?download=true" `
  -Destination (Join-Path $Models "face-parse-bisent\resnet18-5c106cde.pth") `
  -MinBytes 40000000

# Validate required JSON files parse correctly.
Get-Content (Join-Path $Models "musetalkV15\musetalk.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $Models "sd-vae\config.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $Models "whisper\config.json") -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $Models "whisper\preprocessor_config.json") -Raw | ConvertFrom-Json | Out-Null

Write-Host ""
Write-Host "============================================================"
Write-Host "MuseTalk 1.5 inference weights are present and validated."
Write-Host "============================================================"
