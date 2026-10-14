#!/usr/bin/env python3
"""
Generate assets/audio/MANIFEST.md and assets/audio/preview.mp3.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

NUMBERS_0_99 = [
    "शून्य", "एक", "दुई", "तीन", "चार", "पाँच", "छ", "सात", "आठ", "नौ",              # 0-9
    "दश", "एघार", "बाह्र", "तेह्र", "चौध", "पन्ध्र", "सोह्र", "सत्र", "अठार", "उन्नाइस",  # 10-19
    "बीस", "एक्काइस", "बाइस", "तेइस", "चौबीस", "पच्चीस", "छब्बीस", "सत्ताइस", "अठ्ठाइस", "उनन्तीस",  # 20-29
    "तीस", "एकतीस", "बत्तीस", "तेत्तीस", "चौँतीस", "पैँतीस", "छत्तीस", "सैँतीस", "अठतीस", "उनन्चालीस",  # 30-39
    "चालीस", "एकचालीस", "बयालीस", "त्रिचालीस", "चौवालीस", "पैँतालीस", "छयालीस", "सतचालीस", "अठचालीस", "उनन्चास",  # 40-49
    "पचास", "एकाउन्न", "बाउन्न", "त्रिपन्न", "चौवन्न", "पचपन्न", "छपन्न", "सन्ताउन्न", "अन्ठाउन्न", "उनन्साठी",  # 50-59
    "साठी", "एकसट्ठी", "बैसट्ठी", "त्रिसट्ठी", "चौंसट्ठी", "पैंसट्ठी", "छयसट्ठी", "सतसट्ठी", "अठसट्ठी", "उनन्सत्तरी",  # 60-69
    "सत्तरी", "एकहत्तर", "बहत्तर", "त्रिहत्तर", "चौहत्तर", "पचहत्तर", "छयहत्तर", "सतहत्तर", "अठहत्तर", "उनासी",  # 70-79
    "असी", "एकासी", "बयासी", "त्रियासी", "चौरासी", "पचासी", "छयासी", "सतासी", "अठासी", "उनानब्बे",  # 80-89
    "नब्बे", "एकानब्बे", "बयानब्बे", "त्रियानब्बे", "चौरानब्बे", "पन्चानब्बे", "छयानब्बे", "सन्तानब्बे", "अठानब्बे", "उनान्सय",  # 90-99
]

EXTRA_WORDS = {
    "hundred": "सय",
    "thousand": "हजार",
    "lakh": "लाख",
    "crore": "करोड",
    "arab": "अर्ब",
    "rupaiya": "रुपैयाँ",
    "paisa": "पैसा",
    "matra": "मात्र",
    "prapta_bhayo": "प्राप्त भयो",
    "ra": "र",
}

def find_binary(name: str) -> str:
    b = shutil.which(name)
    if b:
        return b
    localappdata = os.environ.get("LOCALAPPDATA", "")
    if localappdata:
        winget_path = Path(localappdata) / "Microsoft" / "WinGet" / "Links" / f"{name}.exe"
        if winget_path.exists():
            return str(winget_path)
    return name

FFMPEG = find_binary("ffmpeg")
FFPROBE = find_binary("ffprobe")

AUDIO_DIR = Path("assets/audio")

def get_duration(file_path: Path) -> float:
    cmd = [
        FFPROBE, "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(file_path)
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return float(res.stdout.strip())

def main():
    clips = {str(i): word for i, word in enumerate(NUMBERS_0_99)}
    clips.update(EXTRA_WORDS)

    # 1. Write MANIFEST.md
    manifest_lines = [
        "# Nepali TTS Audio Clips Manifest",
        "",
        "This manifest lists all 110 generated audio clips with their Nepali text, duration, and file size.",
        "",
        "| Clip Name | Nepali Text | Duration (s) | File Size |",
        "| :--- | :--- | :--- | :--- |",
    ]

    for name, text in clips.items():
        fpath = AUDIO_DIR / f"{name}.mp3"
        dur = get_duration(fpath)
        size_kb = fpath.stat().st_size / 1024
        manifest_lines.append(f"| `{name}` | {text} | {dur:.3f}s | {size_kb:.2f} KB |")

    manifest_path = AUDIO_DIR / "MANIFEST.md"
    manifest_path.write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
    print(f"Generated manifest: {manifest_path} ({len(clips)} clips)")

    # 2. Generate preview.mp3
    # Sequence: 1, thousand, 5, hundred, 30, rupaiya, 30, paisa, matra, prapta_bhayo
    # Nepali: १ हजार ५ सय ३० रुपैयाँ ३० पैसा मात्र प्राप्त भयो
    preview_sequence = [
        "1", "thousand", "5", "hundred", "30", "rupaiya", "30", "paisa", "matra", "prapta_bhayo"
    ]
    print("\nPreview Sequence:", " -> ".join(preview_sequence))

    concat_list_path = AUDIO_DIR / "concat_preview.txt"
    with open(concat_list_path, "w", encoding="utf-8") as f:
        for clip in preview_sequence:
            f.write(f"file '{clip}.mp3'\n")

    preview_output = AUDIO_DIR / "preview.mp3"
    cmd = [
        FFMPEG, "-y", "-f", "concat", "-safe", "0",
        "-i", str(concat_list_path),
        "-c", "copy",
        str(preview_output)
    ]
    subprocess.run(cmd, check=True)
    if concat_list_path.exists():
        concat_list_path.unlink()

    preview_dur = get_duration(preview_output)
    preview_size = preview_output.stat().st_size
    print(f"Generated preview: {preview_output}")
    print(f"Preview duration: {preview_dur:.3f}s | Size: {preview_size / 1024:.2f} KB")

if __name__ == "__main__":
    main()
