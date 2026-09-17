$ErrorActionPreference = 'Stop'
$Root = 'E:\DFB_AI_Studio'
$LogDir = Join-Path $Root 'logs'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Log = Join-Path $LogDir "update_$Stamp.log"
Start-Transcript -Path $Log | Out-Null

Write-Host 'Updating DFB AI Studio' -ForegroundColor Cyan
Write-Host 'Models are never deleted or automatically replaced.'

$ComfyUpdate = Join-Path $Root 'apps\ComfyUI_windows_portable\update\update_comfyui.bat'
if (Test-Path -LiteralPath $ComfyUpdate) {
    Write-Host "`nUpdating ComfyUI code with its official updater..." -ForegroundColor Yellow
    & $ComfyUpdate
    if ($LASTEXITCODE -ne 0) { throw "ComfyUI updater failed with exit code $LASTEXITCODE" }
} else {
    Write-Warning 'ComfyUI uses a reviewed source snapshot on C:. Automatic replacement is intentionally disabled; see README.md for the safe update procedure.'
}

$LiveDir = 'C:\DFB_AI_Runtime\source\LivePortrait-main'
if (Test-Path -LiteralPath (Join-Path $LiveDir '.git')) {
    Write-Host "`nChecking LivePortrait..." -ForegroundColor Yellow
    git -C $LiveDir status --short
    $Dirty = git -C $LiveDir status --porcelain
    if ($Dirty) {
        Write-Warning 'LivePortrait has local changes; update skipped to protect them.'
    } else {
        git -C $LiveDir pull --ff-only
        Write-Host 'Code updated. Dependencies were not changed automatically; review upstream requirements before changing the isolated environment.'
    }
}
elseif (Test-Path -LiteralPath $LiveDir) {
    Write-Warning 'LivePortrait was installed from an official source archive, not a Git checkout. Automatic code update is intentionally skipped; see README.md for the reviewed update procedure.'
}

Write-Host "`nUpdate log: $Log" -ForegroundColor Green
Stop-Transcript | Out-Null
