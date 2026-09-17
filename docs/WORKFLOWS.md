# Workflow guide

## SDXL image generation

Load `workflows\image_generation\SDXL_simple.json`. Select
`sd_xl_base_1.0.safetensors`, use 768x768 and batch 1 for drafts. Its separate
refiner branch is optional and the refiner weight is not installed; bypass it.

For img2img, replace Empty Latent Image with Load Image -> VAE Encode and use
denoise 0.25-0.55. Lower values preserve composition; higher values redesign it.

## ControlNet

Use Xinsir ControlNet Union SDXL with the auxiliary preprocessors. Add
`SetUnionControlNetType` where needed and select the matching mode. Starting
strengths: Canny/lineart 0.55-0.8, depth 0.4-0.7, OpenPose 0.65-0.9. End control
near 0.75 of sampling so textures can resolve. Avoid stacking full-strength
controls.

## Character consistency

Load `workflows\identity\IPAdapter_portrait.json` and use the SDXL ViT-H Plus
Face adapter. Start at weight 0.55-0.75. Use one sharp, evenly lit reference;
keep prompt, seed, sampler and dimensions fixed. Add pose control after identity
is stable. `IPAdapter_simple.json` is an upstream SD 1.5 node reference and
requires an SD 1.5 checkpoint that is not installed.

## LivePortrait

Run `start_liveportrait.bat`. Use a front-facing source with visible chin and
forehead and a driving clip with modest head rotation. Output goes to
`outputs\portrait_animation`. Reuse the generated `.pkl` motion template to
avoid repeating driving-video analysis.

## Wan 2.1 1.3B

Use the JSON files in `workflows\video_generation`. Begin at 480p, 33 frames,
16 fps and one clip. Text-to-video uses the 1.3B FP16 model. The camera workflow
uses the 1.3B BF16 Fun Camera model and a starting image.

## Footage to cartoon/stylized video

1. Convert source to CFR with `media_tools.py cfr`.
2. Load with VideoHelperSuite or extract PNG frames.
3. Use SDXL img2img at denoise 0.25-0.4.
4. Add lineart/soft-edge plus depth or pose; hold seed/settings constant.
5. Add a style reference with IP-Adapter at low-to-moderate weight.
6. Reassemble at source CFR, optionally RIFE 2x, then restore audio.
7. Export ProRes 422 HQ plus an H.264 review copy.

Process shots separately; long clips amplify drift.

## Style presets

| Preset | Prompt additions | Controls |
|---|---|---|
| Clean cel | clean two-tone cel shading, crisp ink contours, limited palette, animation key art | lineart 0.75, depth 0.4, denoise 0.3 |
| Graphic novel | bold brush inking, halftone shadows, restrained color, dramatic rim light | soft-edge 0.65, depth 0.5, denoise 0.38 |
| Painterly | hand-painted gouache, visible brush texture, simplified shapes, cinematic color script | depth 0.55, style adapter 0.45, denoise 0.42 |
| Anime finish | precise anime linework, flat colors, controlled highlights, production cel | lineart 0.8, pose 0.75, denoise 0.3 |

Useful negatives: `photorealistic skin, extra fingers, duplicate limbs, warped
face, text, watermark, noisy outlines, inconsistent line weight`.
