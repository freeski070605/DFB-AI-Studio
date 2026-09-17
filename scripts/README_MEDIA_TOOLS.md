# Media tools

Run these with ComfyUI's isolated Python after installation, or with any Python
3.9+ runtime. All paths may be absolute.

```bat
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py cfr input.mp4 output_cfr.mp4 --fps 23.976
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py extract input.mp4 frames --fps 23.976
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py assemble frames styled.mp4 --fps 23.976
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py restore-audio styled.mp4 original.mp4 final.mp4
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py preview input.mov preview.mp4 --nvenc
C:\DFB_AI_Runtime\source\ComfyUI-master\.venv\Scripts\python.exe E:\DFB_AI_Studio\scripts\media_tools.py prores input.mp4 master.mov --profile 3
```

The `cfr` command prevents variable-frame-rate drift. `restore-audio` maps audio
from the original source and stops at the shorter stream. ProRes profile 3 is
ProRes 422 HQ and uses 24-bit PCM audio.
