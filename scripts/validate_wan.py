"""Submit a compact deterministic Wan 2.1 1.3B smoke test to a running local ComfyUI.

This intentionally saves decoded frames instead of depending on a particular
video-container node. A successful run proves the text encoder, Wan diffusion
model, VAE, CUDA path, and 33-frame decode all function together.
"""

import json
import time
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8188"
TIMEOUT_SECONDS = 45 * 60

PROMPT = {
    "1": {
        "class_type": "CLIPLoader",
        "inputs": {
            "clip_name": "umt5_xxl_fp8_e4m3fn_scaled.safetensors",
            "type": "wan",
            "device": "default",
        },
    },
    "2": {
        "class_type": "VAELoader",
        "inputs": {"vae_name": "wan_2.1_vae.safetensors"},
    },
    "3": {
        "class_type": "UNETLoader",
        "inputs": {
            "unet_name": "wan2.1_t2v_1.3B_fp16.safetensors",
            "weight_dtype": "default",
        },
    },
    "4": {
        "class_type": "CLIPTextEncode",
        "inputs": {
            "text": "a small red toy rocket slowly rotating on a clean studio turntable, soft light, fixed camera",
            "clip": ["1", 0],
        },
    },
    "5": {
        "class_type": "CLIPTextEncode",
        "inputs": {
            "text": "blurry, distorted, text, watermark, low quality, camera shake",
            "clip": ["1", 0],
        },
    },
    "6": {
        "class_type": "EmptyHunyuanLatentVideo",
        "inputs": {"width": 832, "height": 480, "length": 33, "batch_size": 1},
    },
    "7": {
        "class_type": "ModelSamplingSD3",
        "inputs": {"model": ["3", 0], "shift": 8.0},
    },
    "8": {
        "class_type": "KSampler",
        "inputs": {
            "seed": 20260917,
            "steps": 12,
            "cfg": 6.0,
            "sampler_name": "uni_pc",
            "scheduler": "simple",
            "denoise": 1.0,
            "model": ["7", 0],
            "positive": ["4", 0],
            "negative": ["5", 0],
            "latent_image": ["6", 0],
        },
    },
    "9": {
        "class_type": "VAEDecode",
        "inputs": {"samples": ["8", 0], "vae": ["2", 0]},
    },
    "10": {
        "class_type": "SaveImage",
        "inputs": {"filename_prefix": "validation/WAN_smoke", "images": ["9", 0]},
    },
}


def request(path: str, payload=None):
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        BASE + path,
        data=data,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"ComfyUI HTTP {exc.code}: {body}") from exc


start = time.time()
print("Checking ComfyUI...")
request("/system_stats")
print("Queuing 33-frame Wan 2.1 1.3B smoke test...")
result = request("/prompt", {"prompt": PROMPT})
prompt_id = result["prompt_id"]
print("queued", prompt_id)

while True:
    history = request("/history/" + prompt_id)
    if prompt_id in history:
        record = history[prompt_id]
        status = record.get("status", {})
        if status.get("status_str") != "success":
            raise RuntimeError(json.dumps(record, indent=2))

        images = record.get("outputs", {}).get("10", {}).get("images", [])
        elapsed = time.time() - start
        print(f"success: decoded {len(images)} frames in {elapsed:.1f} seconds")
        if images:
            print("first frame:", images[0].get("filename"))
            print("last frame:", images[-1].get("filename"))
        break

    elapsed = time.time() - start
    if elapsed > TIMEOUT_SECONDS:
        raise TimeoutError(
            f"Wan test did not finish within {TIMEOUT_SECONDS // 60} minutes"
        )
    if int(elapsed) % 30 < 2:
        print(f"waiting... {elapsed:.0f}s")
    time.sleep(2)
