# coding: utf-8
"""
Patch the local LivePortrait pipeline so long-form renders can skip the
three-panel concat preview. The stock pipeline builds every concat frame in
RAM before it writes the actual animated video, which can exhaust 16 GB RAM
on long clips.

The patch is guarded by DFB_LIVEPORTRAIT_SKIP_CONCAT=1.
"""
from pathlib import Path
import shutil
import sys

TARGET = Path(r"C:\DFB_AI_Runtime\source\LivePortrait-main\src\live_portrait_pipeline.py")
BACKUP = TARGET.with_suffix(".py.dfb_backup")

MARKER = '        wfp_concat = None\n'
GUARD_MARKER = 'DFB_LIVEPORTRAIT_SKIP_CONCAT'

INSERT = r'''
        # DFB long-form mode: skip the memory-heavy 3-panel concat preview.
        # The stock concat_frames() call materializes every 512x1536 preview
        # frame in RAM before the actual animation is written.
        if os.environ.get("DFB_LIVEPORTRAIT_SKIP_CONCAT", "0") == "1" and (
            flag_is_driving_video or (flag_is_source_video and not flag_is_driving_video)
        ):
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

            # Release large lists that are not required for the final encode.
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
                    'with this template path next time to avoid cropping video, motion '
                    'making and protecting privacy.',
                    style='bold green'
                )
            log(f'Animated video: {wfp}', style='bold green')
            log('DFB long-form mode: concat preview skipped to conserve RAM.', style='bold yellow')
            return wfp, None

'''

def main():
    if not TARGET.exists():
        raise FileNotFoundError(f"LivePortrait pipeline not found: {TARGET}")

    text = TARGET.read_text(encoding="utf-8")

    if GUARD_MARKER in text:
        print("DFB long-form patch already installed.")
        return

    if MARKER not in text:
        print("Expected insertion marker was not found; refusing to modify the runtime.")
        print(f"Target: {TARGET}")
        sys.exit(2)

    if not BACKUP.exists():
        shutil.copy2(TARGET, BACKUP)
        print(f"Backup created: {BACKUP}")

    text = text.replace(MARKER, MARKER + INSERT, 1)
    TARGET.write_text(text, encoding="utf-8")
    print("Installed DFB LivePortrait long-form patch.")
    print("Set DFB_LIVEPORTRAIT_SKIP_CONCAT=1 to bypass concat preview.")

if __name__ == "__main__":
    main()
