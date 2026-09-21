# coding: utf-8
"""
Force LivePortrait to skip the memory-heavy 3-panel concat preview for video runs.

This patch is intentionally unconditional because long portrait renders on a
16 GB machine can finish animation successfully and then crash while building
the concat preview in RAM.

It preserves:
- the actual animated result
- paste-back result when enabled
- driving/source audio
It skips only:
- driving | source | generated comparison video
"""
from pathlib import Path
import shutil
import sys

TARGET = Path(r"C:\DFB_AI_Runtime\source\LivePortrait-main\src\live_portrait_pipeline.py")
BACKUP = TARGET.with_suffix(".py.pre_no_concat_backup")

START = "        wfp_concat = None\n"
END = "        return wfp, wfp_concat\n"

REPLACEMENT = r'''        wfp_concat = None
        # DFB FORCE NO-CONCAT MODE:
        # Long-form LivePortrait renders can exhaust system RAM when
        # concat_frames() materializes thousands of 512x1536 comparison frames.
        # Write only the real animated output and restore audio.
        if flag_is_driving_video or (flag_is_source_video and not flag_is_driving_video):
            import gc

            flag_source_has_audio = flag_is_source_video and has_audio_stream(args.source)
            flag_driving_has_audio = (not flag_load_from_template) and has_audio_stream(args.driving)

            output_fps = source_fps if flag_is_source_video else output_fps
            wfp = osp.join(args.output_dir, f'{basename(args.source)}--{basename(args.driving)}.mp4')

            final_frames = (
                I_p_pstbk_lst
                if I_p_pstbk_lst is not None and len(I_p_pstbk_lst) > 0
                else I_p_lst
            )

            # Free large lists that are no longer needed before encoding.
            try:
                del driving_rgb_crop_256x256_lst
            except Exception:
                pass
            try:
                del source_rgb_lst
            except Exception:
                pass
            if final_frames is I_p_pstbk_lst:
                try:
                    del I_p_lst
                except Exception:
                    pass
            gc.collect()

            images2video(final_frames, wfp=wfp, fps=output_fps)

            if flag_source_has_audio or flag_driving_has_audio:
                wfp_with_audio = osp.join(
                    args.output_dir,
                    f'{basename(args.source)}--{basename(args.driving)}_with_audio.mp4'
                )
                audio_from_which_video = (
                    args.driving
                    if (
                        (flag_driving_has_audio and args.audio_priority == 'driving')
                        or (not flag_source_has_audio)
                    )
                    else args.source
                )
                log(f"Audio is selected from {audio_from_which_video}")
                add_audio_to_video(wfp, audio_from_which_video, wfp_with_audio)
                os.replace(wfp_with_audio, wfp)
                log(f"Replace {wfp_with_audio} with {wfp}")

            if wfp_template not in (None, ''):
                log(
                    f'Animated template: {wfp_template}, you can specify `-d` argument '
                    'with this template path next time to avoid cropping video and motion making.',
                    style='bold green'
                )

            log(f'Animated video: {wfp}', style='bold green')
            log('DFB no-concat mode: comparison preview intentionally skipped.', style='bold yellow')
            return wfp, None

        # Image-only path below remains unchanged.
'''

def main():
    if not TARGET.exists():
        raise FileNotFoundError(f"Pipeline not found: {TARGET}")

    text = TARGET.read_text(encoding="utf-8")

    if "DFB FORCE NO-CONCAT MODE" in text:
        print("Force no-concat patch is already installed.")
        return

    # If the prior guarded DFB patch exists, restore its backup first when available.
    old_backup = TARGET.with_suffix(".py.dfb_backup")
    if "DFB_LIVEPORTRAIT_SKIP_CONCAT" in text and old_backup.exists():
        print(f"Restoring clean pre-patch pipeline from: {old_backup}")
        shutil.copy2(old_backup, TARGET)
        text = TARGET.read_text(encoding="utf-8")

    start = text.find(START)
    if start < 0:
        print("Could not find concat section start; refusing to patch.")
        sys.exit(2)

    end = text.find(END, start)
    if end < 0:
        print("Could not find concat section end; refusing to patch.")
        sys.exit(3)

    if not BACKUP.exists():
        shutil.copy2(TARGET, BACKUP)
        print(f"Backup created: {BACKUP}")

    # Keep the stock image-only save code. Replace the start marker with the
    # force no-concat video branch, then leave the remaining stock code in place.
    patched = text[:start] + REPLACEMENT + text[start + len(START):]
    TARGET.write_text(patched, encoding="utf-8")

    print("Installed FORCE no-concat patch.")
    print("Long video runs will save the real animation and skip only the comparison preview.")

if __name__ == "__main__":
    main()
