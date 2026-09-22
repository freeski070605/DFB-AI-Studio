param(
    [Parameter(Mandatory=$true)]
    [string]$Video,

    [Parameter(Mandatory=$true)]
    [string]$AudioSource,

    [string]$Name = "Drew_Freestyle_LipSync",
    [int]$BatchSize = 4,
    [int]$ExtraMargin = 10,
    [int]$LeftCheekWidth = 90,
    [int]$RightCheekWidth = 90
)

$ErrorActionPreference = "Stop"

$Root = "E:\DFB_AI_Runtime\source\MuseTalk"
$Py = Join-Path $Root ".venv\Scripts\python.exe"
$Studio = "E:\DFB_AI_Studio"
$Work = Join-Path $Studio "temp\musetalk"
$ResultDir = Join-Path $Studio "outputs\musetalk"
$TempRoot = "E:\DFB_AI_Runtime\temp\musetalk"
$HfHome = "E:\DFB_AI_Runtime\hf_cache"

if (-not (Test-Path $Video)) { throw "Pose-only video not found: $Video" }
if (-not (Test-Path $AudioSource)) { throw "Audio source not found: $AudioSource" }
if (-not (Test-Path $Py)) { throw "MuseTalk is not installed at $Root. Run scripts\install_musetalk.ps1 first." }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { throw "ffmpeg was not found in PATH." }

New-Item -ItemType Directory -Force $Work, $ResultDir, $TempRoot, $HfHome | Out-Null
$env:TEMP = $TempRoot
$env:TMP = $TempRoot
$env:HF_HOME = $HfHome

$SafeName = ($Name -replace '[^A-Za-z0-9_-]', '_')
$Video25 = Join-Path $Work ($SafeName + "_pose_25fps.mp4")
$AudioWav = Join-Path $Work ($SafeName + "_audio_16k.wav")
$Yaml = Join-Path $Work ($SafeName + "_musetalk.yaml")

Write-Host ""
Write-Host "Preparing MuseTalk input..."
Write-Host "Pose video : $Video"
Write-Host "Audio      : $AudioSource"
Write-Host ""

& ffmpeg -y -hide_banner -loglevel warning -i $Video -vf "fps=25" -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p $Video25
if ($LASTEXITCODE -ne 0) { throw "Failed to create 25 fps MuseTalk video proxy." }

& ffmpeg -y -hide_banner -loglevel warning -i $AudioSource -vn -ac 1 -ar 16000 -c:a pcm_s16le $AudioWav
if ($LASTEXITCODE -ne 0) { throw "Failed to extract 16 kHz audio." }

$VideoYaml = $Video25.Replace("\","/")
$AudioYaml = $AudioWav.Replace("\","/")
$YamlText = "task_0:`n  video_path: `"$VideoYaml`"`n  audio_path: `"$AudioYaml`"`n  result_name: `"$SafeName.mp4`"`n"
Set-Content -Path $Yaml -Value $YamlText -Encoding UTF8

$FfmpegExe = (Get-Command ffmpeg).Source
$FfmpegDir = Split-Path $FfmpegExe

Write-Host ""
Write-Host "Running MuseTalk 1.5..."
Write-Host "Batch size: $BatchSize"
Write-Host "Extra mouth margin: $ExtraMargin"
Write-Host ""

Push-Location $Root
try {
    $Args = @(
        "-m", "scripts.inference",
        "--inference_config", $Yaml,
        "--result_dir", $ResultDir,
        "--unet_model_path", "models\musetalkV15\unet.pth",
        "--unet_config", "models\musetalkV15\musetalk.json",
        "--whisper_dir", "models\whisper",
        "--version", "v15",
        "--use_float16",
        "--batch_size", "$BatchSize",
        "--extra_margin", "$ExtraMargin",
        "--parsing_mode", "jaw",
        "--left_cheek_width", "$LeftCheekWidth",
        "--right_cheek_width", "$RightCheekWidth",
        "--ffmpeg_path", $FfmpegDir
    )
    & $Py @Args
    if ($LASTEXITCODE -ne 0) { throw "MuseTalk inference failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

$Output = Join-Path $ResultDir ("v15\" + $SafeName + ".mp4")
Write-Host ""
if (Test-Path $Output) {
    Write-Host "DONE"
    Write-Host "Output:"
    Write-Host $Output
} else {
    Write-Host "MuseTalk finished but the expected output was not found:"
    Write-Host $Output
    Write-Host "Check $ResultDir for the generated MP4."
}
