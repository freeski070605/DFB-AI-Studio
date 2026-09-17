$ErrorActionPreference = 'Stop'

$Root = 'E:\DFB_AI_Studio'
$Python = 'C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe'
$Main = 'C:\DFB_AI_Runtime\source\ComfyUI-master\main.py'
$LogDir = Join-Path $Root 'logs'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Log = Join-Path $LogDir "final_validation_$Stamp.log"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Start-Transcript -Path $Log | Out-Null

function Test-ComfyUI {
    try {
        Invoke-RestMethod -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 5 | Out-Null
        return $true
    } catch {
        return $false
    }
}

try {
    Write-Host 'DFB AI Studio final validation' -ForegroundColor Cyan
    Write-Host "Log: $Log"

    if (-not (Test-Path -LiteralPath $Python)) { throw "ComfyUI Python not found: $Python" }
    if (-not (Test-Path -LiteralPath $Main)) { throw "ComfyUI main.py not found: $Main" }

    $RequiredModels = @(
        'Z:\DFB_AI_Models\checkpoints\sd_xl_base_1.0.safetensors',
        'Z:\DFB_AI_Models\diffusion_models\wan2.1_t2v_1.3B_fp16.safetensors',
        'Z:\DFB_AI_Models\text_encoders\umt5_xxl_fp8_e4m3fn_scaled.safetensors',
        'Z:\DFB_AI_Models\vae\wan_2.1_vae.safetensors'
    )

    foreach ($Model in $RequiredModels) {
        if (-not (Test-Path -LiteralPath $Model)) { throw "Required model missing: $Model" }
        Write-Host "Found: $Model" -ForegroundColor Green
    }

    if (-not (Test-ComfyUI)) {
        Write-Host 'Starting ComfyUI for validation...' -ForegroundColor Yellow
        $Args = @(
            $Main,
            '--enable-manager',
            '--lowvram',
            '--reserve-vram', '1.5',
            '--input-directory', "$Root\inputs",
            '--output-directory', "$Root\outputs",
            '--temp-directory', 'C:\DFB_AI_Runtime\temp'
        )
        Start-Process -FilePath $Python -ArgumentList $Args -WorkingDirectory (Split-Path $Main) | Out-Null

        $Ready = $false
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Seconds 2
            if (Test-ComfyUI) { $Ready = $true; break }
        }
        if (-not $Ready) { throw 'ComfyUI did not become ready within 120 seconds.' }
    }

    Write-Host 'ComfyUI is ready.' -ForegroundColor Green

    Write-Host "`n== SDXL smoke test ==" -ForegroundColor Cyan
    & $Python "$Root\scripts\validate_sdxl.py"
    if ($LASTEXITCODE -ne 0) { throw "SDXL validation failed with exit code $LASTEXITCODE" }

    Write-Host "`n== Wan 2.1 1.3B 33-frame smoke test ==" -ForegroundColor Cyan
    & $Python "$Root\scripts\validate_wan.py"
    if ($LASTEXITCODE -ne 0) { throw "Wan validation failed with exit code $LASTEXITCODE" }

    Write-Host "`nBoth model-level smoke tests passed." -ForegroundColor Green
    Write-Host "Outputs: $Root\outputs\validation"
    Write-Host 'Next step: run the production image/video workflows from the workflows folder.'
}
finally {
    Stop-Transcript | Out-Null
}
