"""Local FFmpeg helpers for DFB AI Studio and Adobe Premiere Pro handoff."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from fractions import Fraction
from pathlib import Path


def require_tool(name: str) -> str:
    path = shutil.which(name)
    if not path:
        raise SystemExit(f"Required executable is not on PATH: {name}")
    return path


FFMPEG = require_tool("ffmpeg")
FFPROBE = require_tool("ffprobe")


def run(args: list[str]) -> None:
    print("Running:", subprocess.list2cmdline(args))
    subprocess.run(args, check=True)


def probe_fps(path: Path) -> str:
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=avg_frame_rate", "-of", "json", str(path)],
        check=True, capture_output=True, text=True,
    )
    rate = json.loads(result.stdout)["streams"][0]["avg_frame_rate"]
    if Fraction(rate) <= 0:
        raise SystemExit(f"Could not determine a valid frame rate for {path}")
    return rate


def extract(ns: argparse.Namespace) -> None:
    ns.output.mkdir(parents=True, exist_ok=True)
    vf = [f"fps={ns.fps}"] if ns.fps else []
    run([FFMPEG, "-hide_banner", "-y", "-i", str(ns.input),
         *( ["-vf", ",".join(vf)] if vf else [] ),
         "-vsync", "0", str(ns.output / "%08d.png")])


def assemble(ns: argparse.Namespace) -> None:
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    run([FFMPEG, "-hide_banner", "-y", "-framerate", str(ns.fps),
         "-i", str(ns.frames / ns.pattern), "-c:v", "libx264",
         "-preset", "slow", "-crf", str(ns.crf), "-pix_fmt", "yuv420p",
         "-movflags", "+faststart", str(ns.output)])


def restore_audio(ns: argparse.Namespace) -> None:
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    run([FFMPEG, "-hide_banner", "-y", "-i", str(ns.video),
         "-i", str(ns.source), "-map", "0:v:0", "-map", "1:a?",
         "-c:v", "copy", "-c:a", "aac", "-b:a", "320k", "-shortest",
         "-movflags", "+faststart", str(ns.output)])


def cfr(ns: argparse.Namespace) -> None:
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    fps = str(ns.fps) if ns.fps else probe_fps(ns.input)
    run([FFMPEG, "-hide_banner", "-y", "-i", str(ns.input),
         "-vf", f"fps={fps}", "-fps_mode", "cfr", "-c:v", "libx264",
         "-preset", "slow", "-crf", str(ns.crf), "-pix_fmt", "yuv420p",
         "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart",
         str(ns.output)])


def preview(ns: argparse.Namespace) -> None:
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    encoder = "h264_nvenc" if ns.nvenc else "libx264"
    quality = ["-preset", "p6", "-cq", str(ns.crf)] if ns.nvenc else ["-preset", "slow", "-crf", str(ns.crf)]
    run([FFMPEG, "-hide_banner", "-y", "-i", str(ns.input),
         "-fps_mode", "cfr", "-c:v", encoder, *quality, "-pix_fmt", "yuv420p",
         "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart",
         str(ns.output)])


def prores(ns: argparse.Namespace) -> None:
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    run([FFMPEG, "-hide_banner", "-y", "-i", str(ns.input),
         "-fps_mode", "cfr", "-c:v", "prores_ks", "-profile:v", str(ns.profile),
         "-pix_fmt", "yuv422p10le", "-c:a", "pcm_s24le", str(ns.output)])


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)

    q = sub.add_parser("extract", help="Extract lossless PNG frames")
    q.add_argument("input", type=Path); q.add_argument("output", type=Path)
    q.add_argument("--fps", type=float); q.set_defaults(func=extract)

    q = sub.add_parser("assemble", help="Assemble numbered frames to constant-frame-rate MP4")
    q.add_argument("frames", type=Path); q.add_argument("output", type=Path)
    q.add_argument("--fps", type=float, required=True); q.add_argument("--pattern", default="%08d.png")
    q.add_argument("--crf", type=int, default=15); q.set_defaults(func=assemble)

    q = sub.add_parser("restore-audio", help="Mux source audio onto processed video")
    q.add_argument("video", type=Path); q.add_argument("source", type=Path); q.add_argument("output", type=Path)
    q.set_defaults(func=restore_audio)

    q = sub.add_parser("cfr", help="Normalize footage to constant frame rate")
    q.add_argument("input", type=Path); q.add_argument("output", type=Path)
    q.add_argument("--fps", type=float); q.add_argument("--crf", type=int, default=15); q.set_defaults(func=cfr)

    q = sub.add_parser("preview", help="Create Premiere-friendly H.264 MP4")
    q.add_argument("input", type=Path); q.add_argument("output", type=Path)
    q.add_argument("--crf", type=int, default=17); q.add_argument("--nvenc", action="store_true")
    q.set_defaults(func=preview)

    q = sub.add_parser("prores", help="Create Premiere-friendly ProRes MOV")
    q.add_argument("input", type=Path); q.add_argument("output", type=Path)
    q.add_argument("--profile", type=int, choices=range(0, 6), default=3,
                   help="0 proxy, 1 LT, 2 standard, 3 HQ (default), 4 4444, 5 4444 XQ")
    q.set_defaults(func=prores)
    return p


def main() -> int:
    ns = parser().parse_args()
    try:
        ns.func(ns)
    except subprocess.CalledProcessError as exc:
        print(f"FFmpeg failed with exit code {exc.returncode}", file=sys.stderr)
        return exc.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

