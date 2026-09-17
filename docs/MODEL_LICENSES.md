# Model sources and licenses

Checked 2026-09-17. This is an engineering inventory, not legal advice. Re-check
the linked license before distributing a model or using output commercially.

| Model / weights | Source | Recorded license | Commercial note |
|---|---|---|---|
| Stable Diffusion XL Base 1.0 | `stabilityai/stable-diffusion-xl-base-1.0` | CreativeML Open RAIL++-M | Generally allowed subject to use restrictions. |
| Xinsir ControlNet Union SDXL ProMax | `xinsir/controlnet-union-sdxl-1.0` | Apache-2.0 | Permissive; retain notices when redistributing. |
| IP-Adapter SDXL Plus / Plus Face and ViT-H | `h94/IP-Adapter` | Apache-2.0 as published | Permissive; source-image and base-model rights still apply. Not the FaceID variant. |
| Wan 2.1 1.3B / Comfy repack | `Wan-AI/Wan2.1-T2V-1.3B`, `Comfy-Org/Wan_2.1_ComfyUI_repackaged` | Apache-2.0 | Permissive under its terms. |
| LivePortrait core human weights | `KlingTeam/LivePortrait` | MIT release | Core code/weights are permissive under published terms. |
| LivePortrait `buffalo_l` detector | bundled from InsightFace ecosystem | Upstream model-use terms restrictive/unclear | **Not cleared for paid work** until provenance is resolved or detector replaced. |
| RIFE interpolation | `hzwer/ECCV2022-RIFE` | MIT repository | Permissive; retain notices. |
| Real-ESRGAN x4plus / anime weights | `xinntao/Real-ESRGAN` | BSD-3-Clause repository | Permissive; retain notices. |

Sources:

- <https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md>
- <https://huggingface.co/xinsir/controlnet-union-sdxl-1.0>
- <https://github.com/tencent-ailab/IP-Adapter>
- <https://huggingface.co/Wan-AI/Wan2.1-T2V-1.3B/blob/main/LICENSE.txt>
- <https://github.com/KwaiVGI/LivePortrait>
- <https://github.com/deepinsight/insightface/tree/master/model_zoo>
- <https://github.com/hzwer/ECCV2022-RIFE>
- <https://github.com/xinntao/Real-ESRGAN>

InstantID and FaceID adapters were excluded because their common route depends
on InsightFace identity weights. LTX-2 was excluded because it requires 32 GiB+
VRAM and its license adds a paid-license condition at its revenue threshold.
Wan 14B, CogVideoX and FLUX-class models exceed this 8 GiB VRAM / 16 GiB RAM
production envelope.
