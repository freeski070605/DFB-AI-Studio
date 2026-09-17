# DFB AI Studio - system audit

Audit date: 2026-09-17 (America/New_York)

## Hardware

| Item | Detected value |
|---|---|
| Computer | Alienware m15 R4 |
| OS | Windows 10 Home 22H2, build 19045, 64-bit |
| CPU | Intel Core i7-10870H, 8 cores / 16 threads |
| RAM | 16 GiB |
| GPU | NVIDIA GeForce RTX 3070 Laptop GPU |
| VRAM | 8 GiB |
| Compute capability | 8.6 (Ampere) |
| NVIDIA driver | 581.32 |
| Driver CUDA capability | 13.0 |

`nvidia-smi` detected the GPU. Its CUDA number is the newest runtime supported by
the driver, not a locally installed CUDA Toolkit. A standalone toolkit is not
needed for the prebuilt PyTorch packages used here.

## Storage discovery and final layout

The requested E: drive identifies as a USB flash device. A sustained-write test
dropped to roughly 0.3 MB/s, and extraction of tens of thousands of Python files
stalled. Z: is an SMB share (`\\FREESKI-AIO\mini500gb`), not a local disk.

The safe, usable layout is therefore:

| Location | Role |
|---|---|
| `E:\DFB_AI_Studio` | Launchers, workflows, inputs, outputs, logs and documentation |
| `C:\DFB_AI_Runtime` | Performance-sensitive Python environments and application code |
| `Z:\DFB_AI_Models` | Large, read-mostly model weights |

Junctions named `ComfyUI_NVMe` and `LivePortrait_NVMe` under `E:\DFB_AI_Studio\apps`
make the active C: runtimes easy to find. ComfyUI's `extra_model_paths.yaml`
maps the Z: model library without duplicating weights.

## Installed tools

| Tool | Result |
|---|---|
| Git / Git LFS | 2.52.0 / 3.7.1 |
| FFmpeg | 8.1.1 full build |
| GPU codecs | H.264/HEVC NVENC available |
| Premiere intermediate | `prores_ks` available |
| Visual Studio | VS 2022 Community plus 2019 Build Tools and C++ workloads |
| ComfyUI Python | 3.13.15 in a dedicated venv |
| ComfyUI PyTorch | 2.14.0+cu130; CUDA validated |
| LivePortrait Python | 3.10.21 in a separate venv |
| LivePortrait PyTorch | 2.3.0+cu121; CUDA validated |

## Practical limits

- SDXL, ControlNet, IP-Adapter, LivePortrait, tiled upscaling and RIFE are the
  reliable production tier on this machine.
- Run one heavy model at a time. Use batches of one and short video clips.
- LTX-2's official integration calls for at least 32 GiB VRAM and more than
  100 GiB disk. Installing it here would not create a usable workflow.
- Wan 14B, CogVideoX 5B and FLUX-class pipelines are excluded for the same
  VRAM/RAM reason. Wan 2.1 1.3B is the selected local video tier.

No paid API or cloud-generation dependency was installed. System Python was
left untouched.
