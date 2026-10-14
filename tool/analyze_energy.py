import struct
import math

with open("assets/eleven/audio.raw", "rb") as f:
    raw = f.read()

samples = struct.unpack(f"<{len(raw)//2}h", raw)
sr = 16000

# Compute RMS energy in 20ms frames (320 samples) with 10ms hop (160 samples)
frame_len = 320
hop_len = 160
num_frames = (len(samples) - frame_len) // hop_len

rms_list = []
for i in range(num_frames):
    frame = samples[i*hop_len : i*hop_len + frame_len]
    mean_sq = sum(s*s for s in frame) / len(frame)
    rms = math.sqrt(mean_sq)
    rms_list.append(rms)

max_rms = max(rms_list)
print(f"Total frames: {len(rms_list)} ({len(rms_list)*0.01:.2f}s)")
print(f"Max RMS: {max_rms:.1f}, Min RMS: {min(rms_list):.1f}")

# Threshold for speech vs silence
# Try multiple thresholds
for thresh_ratio in [0.03, 0.05, 0.08, 0.1]:
    thresh = max_rms * thresh_ratio
    is_speech = [r > thresh for r in rms_list]
    
    # Group contiguous speech frames (min speech = 120ms, min silence = 120ms)
    min_speech_frames = 12
    min_silence_frames = 12
    
    # Smooth
    smoothed = list(is_speech)
    # Fill short gaps
    gap = 0
    for idx, sp in enumerate(is_speech):
        if not sp:
            gap += 1
        else:
            if 0 < gap < min_silence_frames:
                for j in range(idx - gap, idx):
                    smoothed[j] = True
            gap = 0
            
    # Count segments
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
        
    print(f"Thresh ratio {thresh_ratio:.2f}: {len(segments)} segments found")
