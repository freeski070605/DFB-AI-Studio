param(
    [string]$ComfyRoot = 'C:\DFB_AI_Runtime\source\ComfyUI-master',
    [string]$ModelRoot = 'Z:\DFB_AI_Models',
    [string]$StudioRoot = 'E:\DFB_AI_Studio'
)

$ErrorActionPreference = 'Stop'

$ModelName = 'hunyuan3d-dit-v2-mv-turbo_fp16.safetensors'
$ModelDir = Join-Path $ModelRoot 'checkpoints'
$ModelPath = Join-Path $ModelDir $ModelName
$ModelUrl = 'https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged/resolve/main/split_files/' + $ModelName + '?download=true'

$ComfyInput = Join-Path $ComfyRoot 'input'
$NodeFile = Join-Path $ComfyRoot 'comfy_extras\nodes_hunyuan3d.py'
$FrontOut = Join-Path $ComfyInput 'DFB_Drew_Head_Front.png'
$RightOut = Join-Path $ComfyInput 'DFB_Drew_Head_Right.png'
$WorkflowPath = Join-Path $StudioRoot 'workflows\3d_generation\Drew_Hunyuan3D_2mv_Head_Turbo.json'

$FrontCandidates = @(
    (Join-Path $StudioRoot 'outputs\Drew_Character_Master\portraits\CharacterSheet_01_FrontNeutral.png'),
    (Join-Path $StudioRoot 'outputs\Drew_Character_Master\CharacterSheet_01_FrontNeutral.png')
)

$RightCandidates = @(
    (Join-Path $StudioRoot 'outputs\Drew_Character_Master\portraits\CharacterSheet_03_SideProfile.png'),
    (Join-Path $StudioRoot 'outputs\Drew_Character_Master\CharacterSheet_03_SideProfile.png')
)

function Find-FirstExisting {
    param(
        [string[]]$Candidates,
        [string]$Label
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    Write-Host ($Label + ' reference was not found. Checked:')
    foreach ($Candidate in $Candidates) {
        Write-Host ('  ' + $Candidate)
    }
    throw ($Label + ' reference was not found.')
}

function Download-Resumable {
    param(
        [string]$Url,
        [string]$Destination
    )

    $Partial = $Destination + '.partial'
    $DestinationDir = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null

    if (Test-Path -LiteralPath $Destination) {
        $ExistingSize = (Get-Item -LiteralPath $Destination).Length
        if ($ExistingSize -gt 100MB) {
            Write-Host ('Model already present: ' + $Destination)
            return
        }
        Remove-Item -LiteralPath $Destination -Force
    }

    $Curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
    if (-not $Curl) {
        throw 'curl.exe was not found.'
    }

    Write-Host ''
    Write-Host 'Downloading Hunyuan3D 2mv Turbo model...'
    Write-Host ('Destination: ' + $Destination)
    Write-Host 'The .partial file is resumable if the connection drops.'
    Write-Host ''

    & $Curl.Source -L --fail --retry 50 --retry-all-errors --retry-delay 2 --connect-timeout 30 --continue-at - --output $Partial $Url

    if ($LASTEXITCODE -ne 0) {
        throw 'Model download stopped. Rerun this setup script and curl will resume the .partial file.'
    }

    if (-not (Test-Path -LiteralPath $Partial)) {
        throw ('Download did not create the expected file: ' + $Partial)
    }

    if ((Get-Item -LiteralPath $Partial).Length -lt 100MB) {
        throw ('Downloaded model file is unexpectedly small: ' + $Partial)
    }

    Move-Item -LiteralPath $Partial -Destination $Destination -Force
}

Write-Host ''
Write-Host '============================================================'
Write-Host 'DFB Hunyuan3D 2mv - FREE LOCAL SETUP'
Write-Host '============================================================'
Write-Host ''

if (-not (Test-Path -LiteralPath $ComfyRoot)) {
    throw ('ComfyUI not found: ' + $ComfyRoot)
}

if (-not (Test-Path -LiteralPath $NodeFile)) {
    throw ('Native Hunyuan3D node file not found: ' + $NodeFile)
}

$NodeText = Get-Content -LiteralPath $NodeFile -Raw
if ($NodeText -notmatch 'Hunyuan3Dv2ConditioningMultiView') {
    throw 'This ComfyUI build is too old for native Hunyuan3D 2mv. Update ComfyUI before continuing.'
}

$Front = Find-FirstExisting -Candidates $FrontCandidates -Label 'Front Neutral'
$Right = Find-FirstExisting -Candidates $RightCandidates -Label 'Right/Profile'

New-Item -ItemType Directory -Force -Path $ComfyInput | Out-Null
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null

Copy-Item -LiteralPath $Front -Destination $FrontOut -Force
Copy-Item -LiteralPath $Right -Destination $RightOut -Force

Write-Host 'Prepared inputs:'
Write-Host ('  Front: ' + $Front)
Write-Host ('  Right: ' + $Right)

Download-Resumable -Url $ModelUrl -Destination $ModelPath

Write-Host ''
Write-Host 'Checking shared model path...'
$ExtraPaths = Join-Path $ComfyRoot 'extra_model_paths.yaml'

if (Test-Path -LiteralPath $ExtraPaths) {
    $ExtraText = Get-Content -LiteralPath $ExtraPaths -Raw
    if ($ExtraText -notmatch [regex]::Escape($ModelRoot)) {
        Write-Warning ('extra_model_paths.yaml does not visibly contain ' + $ModelRoot + '. If the model is not listed in ComfyUI, we will fix the shared model mapping.')
    } else {
        Write-Host 'Shared DFB model path appears configured.'
    }
} else {
    Write-Warning 'No extra_model_paths.yaml found. Your existing DFB shared-model setup may use another method.'
}

Write-Host ''
Write-Host '============================================================'
Write-Host 'SETUP COMPLETE'
Write-Host '============================================================'
Write-Host 'Model:'
Write-Host ('  ' + $ModelPath)
Write-Host ''
Write-Host 'Comfy inputs:'
Write-Host ('  ' + $FrontOut)
Write-Host ('  ' + $RightOut)
Write-Host ''
Write-Host 'Workflow:'
Write-Host ('  ' + $WorkflowPath)
Write-Host ''
Write-Host 'Launch your normal DFB ComfyUI and load that workflow.'
Write-Host '============================================================'
