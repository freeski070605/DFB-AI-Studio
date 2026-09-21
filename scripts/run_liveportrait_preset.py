# coding: utf-8
import argparse
import json
import os
import sys
from dataclasses import fields

LIVE = r"C:\DFB_AI_Runtime\source\LivePortrait-main"

def allowed_kwargs(cls, data):
    names = {f.name for f in fields(cls)}
    return {k: v for k, v in data.items() if k in names}

def main():
    parser = argparse.ArgumentParser(description="Run LivePortrait from a DFB JSON preset.")
    parser.add_argument("--preset", required=True)
    parser.add_argument("--source", help="Override source portrait path")
    parser.add_argument("--driving", help="Override driving video/template path")
    parser.add_argument("--output-dir", help="Override output directory")
    args_cli = parser.parse_args()

    with open(args_cli.preset, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    if args_cli.source:
        cfg["source"] = args_cli.source
    if args_cli.driving:
        cfg["driving"] = args_cli.driving
    if args_cli.output_dir:
        cfg["output_dir"] = args_cli.output_dir

    for key in ("source", "driving"):
        if not os.path.exists(cfg[key]):
            raise FileNotFoundError(f"{key} not found: {cfg[key]}")

    os.makedirs(cfg["output_dir"], exist_ok=True)

    os.chdir(LIVE)
    sys.path.insert(0, LIVE)

    from src.config.argument_config import ArgumentConfig
    from src.config.inference_config import InferenceConfig
    from src.config.crop_config import CropConfig
    from src.live_portrait_pipeline import LivePortraitPipeline

    lp_args = ArgumentConfig(**allowed_kwargs(ArgumentConfig, cfg))
    inference_cfg = InferenceConfig(**allowed_kwargs(InferenceConfig, cfg))
    crop_cfg = CropConfig(**allowed_kwargs(CropConfig, cfg))

    print("DFB LivePortrait preset:", cfg.get("name", os.path.basename(args_cli.preset)))
    print("Source:", lp_args.source)
    print("Driving:", lp_args.driving)
    print("Output:", lp_args.output_dir)
    print("Driving multiplier:", lp_args.driving_multiplier)
    print("Driving option:", lp_args.driving_option)
    print("Animation region:", lp_args.animation_region)

    pipeline = LivePortraitPipeline(
        inference_cfg=inference_cfg,
        crop_cfg=crop_cfg
    )
    pipeline.execute(lp_args)

if __name__ == "__main__":
    main()
