import struct
import math

with open("assets/eleven/audio.raw", "rb") as f:
    raw = f.read()

samples = struct.unpack(f"<{len(raw)//2}h", raw)
sr = 16000

frame_len = 320
hop_len = 160
num_frames = (len(samples) - frame_len) // hop_len

rms_list = []
for i in range(num_frames):
    frame = samples[i*hop_len : i*hop_len + frame_len]
    mean_sq = sum(s*s for s in frame) / len(frame)
    rms_list.append(math.sqrt(mean_sq))

max_rms = max(rms_list)

def get_segments(thresh_ratio, min_speech_ms, min_silence_ms):
    thresh = max_rms * thresh_ratio
    is_speech = [r > thresh for r in rms_list]
    
    min_speech_frames = int(min_speech_ms / 10)
    min_silence_frames = int(min_silence_ms / 10)
    
    smoothed = list(is_speech)
    gap = 0
    for idx, sp in enumerate(is_speech):
        if not sp:
            gap += 1
        else:
            if 0 < gap < min_silence_frames:
                for j in range(idx - gap, idx):
                    smoothed[j] = True
            gap = 0
            
    segments = []
    in_seg = False
    start_f = 0
    for idx, sp in enumerate(smoothed):
        if sp and not in_seg:
            in_seg = True
            start_f = idx
        elif not sp and in_seg:
            in_seg = False
            if (idx - start_f) >= min_speech_frames:
                segments.append((start_f * 0.01, idx * 0.01))
    if in_seg and (len(smoothed) - start_f) >= min_speech_frames:
        segments.append((start_f * 0.01, len(smoothed) * 0.01))
    return segments

for min_sil in [80, 100, 120, 150]:
    for r in range(50, 85, 5):
        ratio = r / 1000.0
        segs = get_segments(ratio, 100, min_sil)
        if 100 <= len(segs) <= 120:
            print(f"min_sil: {min_sil}ms, ratio: {ratio:.3f} -> {len(segs)} segments")
