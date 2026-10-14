import json
import os
import subprocess
import sys
from pathlib import Path

FFMPEG = r"C:\Users\User\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe"
AUDIO_FILE = Path("assets/eleven/sample.mp3")
OUT_DIR = Path("assets/audio")

d = json.load(open("assets/eleven/aligned_words.json", encoding="utf-8"))
words = d["words"]

# Build map of clip_name -> (start_sec, end_sec)
clip_ranges = {}

# 0 to 30: 1-to-1 mapping
for i in range(31):
    w = words[i]
    clip_ranges[str(i)] = (w["offset_sec"], w["offset_sec"] + w["duration_sec"])

# 31 is words[31] + words[32] ("एक तिस")
clip_ranges["31"] = (words[31]["offset_sec"], words[32]["offset_sec"] + words[32]["duration_sec"])

# 32 to 40: words[33] to words[41]
for i in range(32, 41):
    w = words[i + 1]
    clip_ranges[str(i)] = (w["offset_sec"], w["offset_sec"] + w["duration_sec"])

# 41 is words[42] + words[43] ("एक चालिस")
clip_ranges["41"] = (words[42]["offset_sec"], words[43]["offset_sec"] + words[43]["duration_sec"])

# 42 to 97: words[44] to words[99]
for i in range(42, 98):
    w = words[i + 2]
    clip_ranges[str(i)] = (w["offset_sec"], w["offset_sec"] + w["duration_sec"])

# 98 is words[100] + words[101] ("अठार नब्बे")
clip_ranges["98"] = (words[100]["offset_sec"], words[101]["offset_sec"] + words[101]["duration_sec"])

# 99 is words[102]
clip_ranges["99"] = (words[102]["offset_sec"], words[102]["offset_sec"] + words[102]["duration_sec"])

# Extra words:
# hundred: words[103]
clip_ranges["hundred"] = (words[103]["offset_sec"], words[103]["offset_sec"] + words[103]["duration_sec"])

# thousand: words[104]
clip_ranges["thousand"] = (words[104]["offset_sec"], words[104]["offset_sec"] + words[104]["duration_sec"])

# lakh: words[105]
clip_ranges["lakh"] = (words[105]["offset_sec"], words[105]["offset_sec"] + words[105]["duration_sec"])

# crore: words[106]
clip_ranges["crore"] = (words[106]["offset_sec"], words[106]["offset_sec"] + words[106]["duration_sec"])

# arab: words[107]
clip_ranges["arab"] = (words[107]["offset_sec"], words[107]["offset_sec"] + words[107]["duration_sec"])

# rupaiya: words[108]
clip_ranges["rupaiya"] = (words[108]["offset_sec"], words[108]["offset_sec"] + words[108]["duration_sec"])

# paisa: words[109]
clip_ranges["paisa"] = (words[109]["offset_sec"], words[109]["offset_sec"] + words[109]["duration_sec"])

# matra: words[110]
clip_ranges["matra"] = (words[110]["offset_sec"], words[110]["offset_sec"] + words[110]["duration_sec"])

# prapta_bhayo: words[111] + words[112] ("प्राप्त भयो")
clip_ranges["prapta_bhayo"] = (words[111]["offset_sec"], words[112]["offset_sec"] + words[112]["duration_sec"])

# ra: words[113]
clip_ranges["ra"] = (words[113]["offset_sec"], words[113]["offset_sec"] + words[113]["duration_sec"])

print(f"Total mapped clips: {len(clip_ranges)}")
assert len(clip_ranges) == 110, f"Expected 110 clips, got {len(clip_ranges)}"

OUT_DIR.mkdir(parents=True, exist_ok=True)

# Post-processing filter: trim silence padding + normalize volume
af = (
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02,"
    "areverse,"
    "loudnorm=I=-18:TP=-1.5:LRA=7"
)

# Slice and process each clip
for name, (start_sec, end_sec) in clip_ranges.items():
    # Expand slightly by 40ms to avoid clipping plosives/tails
    padded_start = max(0.0, start_sec - 0.04)
    padded_end = end_sec + 0.04
    dur = padded_end - padded_start

    out_file = OUT_DIR / f"{name}.mp3"

    cmd = [
        FFMPEG, "-y", "-loglevel", "error",
        "-ss", f"{padded_start:.3f}",
        "-t", f"{dur:.3f}",
        "-i", str(AUDIO_FILE),
        "-af", af,
        "-ar", "24000", "-ac", "1", "-b:a", "64k",
        "-codec:a", "libmp3lame",
        str(out_file)
    ]
    subprocess.run(cmd, check=True)

print("All 110 ElevenLabs clips sliced, trimmed, normalized, and saved to assets/audio/!")
