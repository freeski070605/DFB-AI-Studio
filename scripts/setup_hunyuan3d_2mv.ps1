param(
    [string]$ComfyRoot = "C:\DFB_AI_Runtime\source\ComfyUI-master",
    [string]$ModelRoot = "Z:\DFB_AI_Models",
    [string]$StudioRoot = "E:\DFB_AI_Studio"
)

$ErrorActionPreference = "Stop"

$ModelName = "hunyuan3d-dit-v2-mv-turbo_fp16.safetensors"
$ModelDir = Join-Path $ModelRoot "checkpoints"
$ModelPath = Join-Path $ModelDir $ModelName
$ModelUrl = "https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged/resolve/main/split_files/$ModelName?download=true"

$ComfyInput = Join-Path $ComfyRoot "input"
$NodeFile = Join-Path $ComfyRoot "comfy_extras\nodes_hunyuan3d.py"

$FrontCandidates = @(
    (Join-Path $StudioRoot "outputs\Drew_Character_Master\portraits\CharacterSheet_01_FrontNeutral.png"),
    (Join-Path $StudioRoot "outputs\Drew_Character_Master\CharacterSheet_01_FrontNeutral.png")
)

$RightCandidates = @(
    (Join-Path $StudioRoot "outputs\Drew_Character_Master\portraits\CharacterSheet_03_SideProfile.png"),
    (Join-Path $StudioRoot "outputs\Drew_Character_Master\CharacterSheet_03_SideProfile.png")
)

function Find-FirstExisting([string[]]$Candidates, [string]$Label) {
    foreach ($p in $Candidates) {
        if (Test-Path $p) { return $p }
    }
    Write-Host "$Label reference was not found. Checked:"
    $Candidates | ForEach-Object { Write-Host "  $_" }
    throw "$Label reference was not found."
}

function Download-Resumable([string]$Url, [string]$Destination) {
    $partial = "$Destination.partial"
    New-Item -ItemType Directory -Force (Split-Path $Destination) | Out-Null

    if (Test-Path $Destination) {
        $size = (Get-Item $Destination).Length
        if ($size -gt 100MB) {
            Write-Host "Model already present: $Destination"
            return
        }
        Remove-Item $Destination -Force
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) { throw "curl.exe was not found." }

    Write-Host ""
    Write-Host "Downloading Hunyuan3D 2mv Turbo model..."
    Write-Host "Destination: $Destination"
    Write-Host "The .partial file is resumable if the connection drops."
    Write-Host ""

    & $curl.Source -L --fail --retry 50 --retry-all-errors --retry-delay 2 --connect-timeout 30 --continue-at - --output $partial $Url

    if ($LASTEXITCODE -ne 0) {
        throw "Model download stopped. Rerun this setup script and curl will resume the .partial file."
    }

    if ((Get-Item $partial).Length -lt 100MB) {
        throw "Downloaded model file is unexpectedly small: $partial"
    }

    Move-Item $partial $Destination -Force
}

Write-Host ""
Write-Host "============================================================"
Write-Host "DFB Hunyuan3D 2mv — FREE LOCAL SETUP"
Write-Host "============================================================"
Write-Host ""

if (-not (Test-Path $ComfyRoot)) { throw "ComfyUI not found: $ComfyRoot" }
if (-not (Test-Path $NodeFile)) { throw "Native Hunyuan3D node file not found: $NodeFile" }

$nodeText = Get-Content $NodeFile -Raw
if ($nodeText -notmatch "Hunyuan3Dv2ConditioningMultiView") {
    throw "This ComfyUI build is too old for native Hunyuan3D 2mv. Update ComfyUI before continuing."
}

$Front = Find-FirstExisting $FrontCandidates "Front Neutral"
$Right = Find-FirstExisting $RightCandidates "Right/Profile"

New-Item -ItemType Directory -Force $ComfyInput, $ModelDir | Out-Null

Copy-Item $Front (Join-Path $ComfyInput "DFB_Drew_Head_Front.png") -Force
Copy-Item $Right (Join-Path $ComfyInput "DFB_Drew_Head_Right.png") -Force

Write-Host "Prepared inputs:"
Write-Host "  Front: $Front"
Write-Host "  Right: $Right"

Download-Resumable $ModelUrl $ModelPath

Write-Host ""
Write-Host "Checking shared model path..."
$ExtraPaths = Join-Path $ComfyRoot "extra_model_paths.yaml"
if (Test-Path $ExtraPaths) {
    $extra = Get-Content $ExtraPaths -Raw
    if ($extra -notmatch [regex]::Escape($ModelRoot)) {
        Write-Warning "extra_model_paths.yaml does not visibly contain $ModelRoot. If the model is not listed in ComfyUI, we will fix the shared model mapping."
    } else {
        Write-Host "Shared DFB model path appears configured."
    }
} else {
    Write-Warning "No extra_model_paths.yaml found. Your existing DFB shared-model setup may use another method."
}

Write-Host ""
Write-Host "============================================================"
Write-Host "SETUP COMPLETE"
Write-Host "============================================================"
Write-Host "Model:"
Write-Host "  $ModelPath"
Write-Host ""
Write-Host "Comfy inputs:"
Write-Host "  $ComfyInput\DFB_Drew_Head_Front.png"
Write-Host "  $ComfyInput\DFB_Drew_Head_Right.png"
Write-Host ""
Write-Host "Workflow:"
Write-Host "  $StudioRoot\workflows\3d_generation\Drew_Hunyuan3D_2mv_Head_Turbo.json"
Write-Host ""
Write-Host "Launch your normal DFB ComfyUI and load that workflow."
Write-Host "============================================================"
