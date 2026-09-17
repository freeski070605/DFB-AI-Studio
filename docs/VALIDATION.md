# Validation record

Validation date: 2026-09-17.

## Passed

- RTX 3070 Laptop GPU detected: 8 GiB, compute capability 8.6.
- FFmpeg exposes H.264/HEVC NVENC and ProRes encoding.
- ComfyUI 0.36.0 starts on `127.0.0.1:8188`; `/system_stats` returned HTTP 200.
- Comfy PyTorch 2.14.0+cu130 reports CUDA available.
- Manager 4.2.2 completes its security scan.
- IP-Adapter, ControlNet Auxiliary, VideoHelperSuite and RIFE import cleanly.
- LivePortrait torch 2.3.0+cu121 sees the GPU.
- The `start_liveportrait.bat` browser UI returned HTTP 200 at
  `127.0.0.1:8890` after applying the recorded compatibility pins.
- LivePortrait loaded every required human weight and completed its bundled
  example: 78 frames; render stage about 17 seconds. Outputs are
  `outputs\portrait_animation\s0--d0.mp4` and `s0--d0_concat.mp4`.
- The editorial helper completed a synthetic 24 fps test through CFR conversion,
  24 lossless PNG frames, reassembly, audio restoration and ProRes 422 HQ export.
  Test artifacts are under `outputs\validation`.

## Qualified pass

LivePortrait ONNX Runtime 1.18 cannot load its CUDA provider DLL (Windows error
126) in this runtime set, so detector/landmark sessions use CPU. Its main Torch
animation network remains CUDA-accelerated and end-to-end output completed.

## After any model transfer/update

Large model files must be verified by a successful loader/use, not filename
alone. Run the SDXL simple workflow, then a 33-frame Wan proof and record timing.
