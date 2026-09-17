$ErrorActionPreference = 'Continue'
$Root = 'E:\DFB_AI_Studio'
$LogDir = Join-Path $Root 'logs'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Log = Join-Path $LogDir "system_check_$Stamp.log"

Start-Transcript -Path $Log | Out-Null
Write-Host 'DFB AI Studio system check' -ForegroundColor Cyan
Write-Host "Log: $Log"
Write-Host ''

Write-Host '== NVIDIA ==' -ForegroundColor Yellow
& nvidia-smi

Write-Host "`n== Drives ==" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Select-Object Name, Root,
    @{N='UsedGiB';E={[math]::Round($_.Used / 1GB, 2)}},
    @{N='FreeGiB';E={[math]::Round($_.Free / 1GB, 2)}} | Format-Table -AutoSize

Write-Host '== FFmpeg ==' -ForegroundColor Yellow
& ffmpeg -version | Select-Object -First 1
& ffprobe -version | Select-Object -First 1

$ComfyPython = 'C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe'
if (Test-Path -LiteralPath $ComfyPython) {
    Write-Host "`n== ComfyUI PyTorch / CUDA ==" -ForegroundColor Yellow
    & $ComfyPython -c "import torch; print('torch:', torch.__version__); print('cuda available:', torch.cuda.is_available()); print('torch CUDA:', torch.version.cuda); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'none'); print('VRAM GiB:', round(torch.cuda.get_device_properties(0).total_memory/1024**3,2) if torch.cuda.is_available() else 0)"
} else {
    Write-Warning "ComfyUI Python not found: $ComfyPython"
}

$LivePython = 'C:\DFB_AI_Runtime\source\LivePortrait-main\.venv\Scripts\python.exe'
if (Test-Path -LiteralPath $LivePython) {
    Write-Host "`n== LivePortrait PyTorch / CUDA ==" -ForegroundColor Yellow
    & $LivePython -c "import torch; print('torch:', torch.__version__); print('cuda available:', torch.cuda.is_available()); print('torch CUDA:', torch.version.cuda)"
} else {
    Write-Warning "LivePortrait Python not found: $LivePython"
}

Write-Host "`n== Required paths ==" -ForegroundColor Yellow
@(
    'models', 'workflows', 'inputs', 'outputs', 'temp', 'logs'
) | ForEach-Object {
    $Path = Join-Path $Root $_
    [pscustomobject]@{Path=$Path; Exists=(Test-Path -LiteralPath $Path)}
} | Format-Table -AutoSize

@(
    [pscustomobject]@{Path='C:\DFB_AI_Runtime\source\ComfyUI-master'; Exists=(Test-Path -LiteralPath 'C:\DFB_AI_Runtime\source\ComfyUI-master')}
    [pscustomobject]@{Path='C:\DFB_AI_Runtime\source\LivePortrait-main'; Exists=(Test-Path -LiteralPath 'C:\DFB_AI_Runtime\source\LivePortrait-main')}
    [pscustomobject]@{Path='Z:\DFB_AI_Models'; Exists=(Test-Path -LiteralPath 'Z:\DFB_AI_Models')}
) | Format-Table -AutoSize

Stop-Transcript | Out-Null
