import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

FFMPEG = r"C:\Users\User\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe"
FFPROBE = r"C:\Users\User\AppData\Local\Microsoft\WinGet\Links\ffprobe.exe"

AUDIO_FILE = Path("assets/eleven/sample.mp3")

cmd = [
    FFMPEG, "-i", str(AUDIO_FILE),
    "-af", "silencedetect=noise=-32dB:d=0.15",
    "-f", "null", "-"
]
res = subprocess.run(cmd, capture_output=True, text=True)
lines = res.stderr.splitlines()

silences = []
current_start = None

for line in lines:
    m_start = re.search(r"silence_start:\s*([\d\.]+)", line)
    if m_start:
        current_start = float(m_start.group(1))
    m_end = re.search(r"silence_end:\s*([\d\.]+)\s*\|\s*silence_duration:\s*([\d\.]+)", line)
    if m_end and current_start is not None:
        silences.append({
            "start": current_start,
            "end": float(m_end.group(1)),
            "duration": float(m_end.group(2))
        })
        current_start = None

# Calculate speech segments between silences
segments = []
prev_end = 0.0
for s in silences:
    if s["start"] > prev_end + 0.1:
        segments.append({
            "start": prev_end,
            "end": s["start"],
            "duration": s["start"] - prev_end
        })
    prev_end = s["end"]

print(f"Total silence blocks found: {len(silences)}")
print(f"Total audio segments found: {len(segments)}")
for idx, seg in enumerate(segments[:15]):
    print(f"Seg {idx}: {seg['start']:.2f}s -> {seg['end']:.2f}s (dur: {seg['duration']:.2f}s)")
if len(segments) > 15:
    print(f"... and {len(segments)-15} more segments up to {segments[-1]['end']:.2f}s")
