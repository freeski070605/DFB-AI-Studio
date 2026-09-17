$ErrorActionPreference = 'Stop'

$ModelRoot = 'Z:\DFB_AI_Models'
if (-not (Test-Path -LiteralPath $ModelRoot)) {
    throw "Model share is unavailable: $ModelRoot"
}

$Jobs = @(
    @{ Relative='checkpoints\sd_xl_base_1.0.safetensors'; Url='https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true' },
    @{ Relative='controlnet\xinsir_controlnet_union_sdxl_1.0_promax.safetensors'; Url='https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors?download=true' },
    @{ Relative='clip_vision\CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors'; Url='https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors?download=true' },
    @{ Relative='ipadapter\ip-adapter-plus_sdxl_vit-h.safetensors'; Url='https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors?download=true' },
    @{ Relative='ipadapter\ip-adapter-plus-face_sdxl_vit-h.safetensors'; Url='https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors?download=true' },
    @{ Relative='diffusion_models\wan2.1_t2v_1.3B_fp16.safetensors'; Url='https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors?download=true' },
    @{ Relative='diffusion_models\wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors'; Url='https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors?download=true' },
    @{ Relative='text_encoders\umt5_xxl_fp8_e4m3fn_scaled.safetensors'; Url='https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true' },
    @{ Relative='vae\wan_2.1_vae.safetensors'; Url='https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true' },
    @{ Relative='clip_vision\clip_vision_h.safetensors'; Url='https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true' }
)

foreach ($Job in $Jobs) {
    $Destination = Join-Path $ModelRoot $Job.Relative
    $Partial = "$Destination.partial"
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination) | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        Write-Host "Present: $Destination" -ForegroundColor Green
        continue
    }

    Write-Host "Downloading: $($Job.Relative)" -ForegroundColor Cyan
    & curl.exe -L --fail --retry 30 --retry-all-errors --retry-delay 2 `
        --connect-timeout 30 --continue-at - --output $Partial $Job.Url
    if ($LASTEXITCODE -ne 0) {
        throw "Download failed (partial retained): $Partial"
    }
    Move-Item -LiteralPath $Partial -Destination $Destination
}

Write-Host 'Model transfer set is complete.' -ForegroundColor Green
