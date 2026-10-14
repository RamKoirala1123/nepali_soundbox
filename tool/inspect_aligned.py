import json
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

d = json.load(open("assets/eleven/aligned_words.json", encoding="utf-8"))
words = d["words"]
print(f"Total words: {len(words)}")
for i, w in enumerate(words):
    print(f"[{i:3d}] {w['word']:>15} | {w['offset_sec']:6.2f}s - {w['offset_sec']+w['duration_sec']:6.2f}s (dur: {w['duration_sec']:4.2f}s)")
