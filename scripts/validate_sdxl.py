"""Submit a small deterministic SDXL smoke test to a running local ComfyUI."""

import json
import time
import urllib.request

BASE = "http://127.0.0.1:8188"
PROMPT = {
    "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
    "2": {"class_type": "CLIPTextEncode", "inputs": {"text": "studio product photograph of a red ceramic toy rocket, clean gray background, sharp focus", "clip": ["1", 1]}},
    "3": {"class_type": "CLIPTextEncode", "inputs": {"text": "text, watermark, blurry, distorted", "clip": ["1", 1]}},
    "4": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
    "5": {"class_type": "KSampler", "inputs": {"seed": 20260917, "steps": 10, "cfg": 6.0, "sampler_name": "euler", "scheduler": "normal", "denoise": 1.0, "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
    "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
    "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": "validation/SDXL_smoke", "images": ["6", 0]}},
}


def request(path: str, payload=None):
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


result = request("/prompt", {"prompt": PROMPT})
prompt_id = result["prompt_id"]
print("queued", prompt_id)
for _ in range(180):
    history = request("/history/" + prompt_id)
    if prompt_id in history:
        status = history[prompt_id].get("status", {})
        if not status.get("status_str") == "success":
            raise RuntimeError(json.dumps(history[prompt_id], indent=2))
        images = history[prompt_id]["outputs"]["7"]["images"]
        print("success", images[0]["filename"])
        break
    time.sleep(2)
else:
    raise TimeoutError("SDXL test did not finish within six minutes")
