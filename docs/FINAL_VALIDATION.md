# Final local validation

The runtime and supporting tools have already passed server-level, CUDA, LivePortrait, and Premiere/FFmpeg handoff checks. The remaining model-level proof is one real SDXL generation followed by one compact 33-frame Wan 2.1 1.3B generation.

## Run

From `E:\DFB_AI_Studio`, double-click:

`final_validate.bat`

The launcher will:

1. Confirm the active ComfyUI runtime exists on `C:`.
2. Confirm the required SDXL and Wan weights exist on `Z:`.
3. Reuse the local ComfyUI server if it is already running, or start it automatically.
4. Run `scripts\validate_sdxl.py`.
5. Run `scripts\validate_wan.py` at 832x480, 33 frames.
6. Save proof output under `E:\DFB_AI_Studio\outputs\validation`.
7. Write a transcript under `E:\DFB_AI_Studio\logs`.

## Expected result

Both Python scripts should report `success`. The Wan test deliberately saves decoded frames rather than depending on a particular video-container custom node; this proves that the Wan text encoder, 1.3B diffusion model, VAE, CUDA execution path, and 33-frame decode all work together.

If either test fails, keep the generated log and use its exact error for the next fix. Do not redownload all models unless the error specifically indicates a corrupt or missing weight.
