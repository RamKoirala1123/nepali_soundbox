#!/usr/bin/env python3
"""
Verification script for generated Nepali audio clips.
Checks file presence, sizes, durations, total folder size, and loudness consistency (LUFS).
Also generates MANIFEST.md and preview.mp3.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
import statistics

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

EXPECTED_NAMES = [str(i) for i in range(100)] + [
    "hundred", "thousand", "lakh", "crore", "arab",
    "rupaiya", "paisa", "matra", "prapta_bhayo", "ra"
]

AUDIO_DIR = Path("assets/audio")

def find_binary(name: str) -> str:
    # Check PATH first
    b = shutil.which(name)
    if b:
        return b
    # Check winget links on Windows
    localappdata = os.environ.get("LOCALAPPDATA", "")
    if localappdata:
        winget_path = Path(localappdata) / "Microsoft" / "WinGet" / "Links" / f"{name}.exe"
        if winget_path.exists():
            return str(winget_path)
    return name

FFMPEG = find_binary("ffmpeg")
FFPROBE = find_binary("ffprobe")

def get_duration(file_path: Path) -> float:
    cmd = [
        FFPROBE, "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(file_path)
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return float(res.stdout.strip())

def get_lufs(file_path: Path) -> float:
    # Run loudnorm in print_format=json mode
    cmd = [
        FFMPEG, "-i", str(file_path),
        "-af", "loudnorm=I=-18:TP=-1.5:LRA=7:print_format=json",
        "-f", "null", "-"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    stderr = res.stderr
    # Extract JSON from stderr
    start_idx = stderr.rfind("{")
    end_idx = stderr.rfind("}")
    if start_idx != -1 and end_idx != -1:
        json_str = stderr[start_idx:end_idx+1]
        data = json.loads(json_str)
        return float(data.get("input_i", -99.0))
    return -99.0

def main():
    print("=== NEPALI AUDIO CLIPS VERIFICATION ===\n")
    missing = []
    too_small = []
    too_long = []
    clip_stats = []

    total_size_bytes = 0
    all_files = list(AUDIO_DIR.glob("*.mp3"))
    for f in all_files:
        total_size_bytes += f.stat().st_size

    for name in EXPECTED_NAMES:
        fpath = AUDIO_DIR / f"{name}.mp3"
        if not fpath.exists():
            missing.append(f"{name}.mp3")
            continue
        
        size = fpath.stat().st_size
        if size < 2048:
            too_small.append((f"{name}.mp3", size))
        
        dur = get_duration(fpath)
        if dur > 2.5:
            too_long.append((f"{name}.mp3", dur))
        
        lufs = get_lufs(fpath)
        clip_stats.append({
            "name": name,
            "filename": f"{name}.mp3",
            "size": size,
            "duration": dur,
            "lufs": lufs
        })

    print(f"Total expected files: {len(EXPECTED_NAMES)}")
    print(f"Total matching files found: {len(clip_stats)}")
    print(f"Total files in {AUDIO_DIR}: {len(all_files)}")
    print(f"Total directory size: {total_size_bytes:,} bytes ({total_size_bytes / (1024*1024):.2f} MB)")

    print("\n--- Outlier Checks ---")
    if missing:
        print(f"Missing files ({len(missing)}): {missing}")
    else:
        print("Missing files: None (all 110 files present)")

    if too_small:
        print(f"Files smaller than 2 KB ({len(too_small)}): {too_small}")
    else:
        print("Files smaller than 2 KB: None")

    if too_long:
        print(f"Files longer than 2.5 seconds ({len(too_long)}): {too_long}")
    else:
        print("Files longer than 2.5 seconds: None")

    # Loudness analysis
    lufs_values = [c["lufs"] for c in clip_stats if c["lufs"] > -90]
    median_lufs = statistics.median(lufs_values) if lufs_values else -18.0
    print(f"\n--- Loudness Analysis (LUFS) ---")
    print(f"Median LUFS: {median_lufs:.2f} LUFS")
    print(f"Min LUFS: {min(lufs_values):.2f} LUFS, Max LUFS: {max(lufs_values):.2f} LUFS")

    loudness_outliers = []
    for c in clip_stats:
        diff = abs(c["lufs"] - median_lufs)
        if diff > 3.0:
            loudness_outliers.append((c["filename"], c["lufs"], diff))

    if loudness_outliers:
        print(f"Clips > 3 LU away from median ({len(loudness_outliers)}):")
        for fn, val, diff in loudness_outliers:
            print(f"  - {fn}: {val:.2f} LUFS (delta: {diff:.2f} LU)")
    else:
        print("Clips > 3 LU away from median: None (all clips are within 3 LU of median)")

    # Save stats json for manifest generation
    with open("assets/audio/stats.json", "w", encoding="utf-8") as out_f:
        json.dump(clip_stats, out_f, indent=2)

if __name__ == "__main__":
    main()
