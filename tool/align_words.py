import os
import sys
import subprocess
from pathlib import Path

try:
    import azure.cognitiveservices.speech as speechsdk
except ImportError:
    sys.exit("azure-cognitiveservices-speech not found")

key = os.environ.get("AZURE_SPEECH_KEY")
region = os.environ.get("AZURE_SPEECH_REGION")

wav_path = str(Path("assets/eleven/audio_16k.wav").resolve())
ffmpeg = r"C:\Users\User\AppData\Local\Microsoft\WinGet\Links\ffmpeg.exe"
print("Converting to 16kHz WAV...")
subprocess.run([ffmpeg, "-y", "-i", "assets/eleven/sample.mp3", "-ar", "16000", "-ac", "1", wav_path], check=True)

speech_config = speechsdk.SpeechConfig(subscription=key, region=region)
speech_config.speech_recognition_language = "ne-NP"
speech_config.request_word_level_timestamps()
speech_config.output_format = speechsdk.OutputFormat.Detailed

audio_config = speechsdk.audio.AudioConfig(filename=wav_path)
recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

all_words = []
recognized_texts = []

def handle_result(evt):
    import json
    data = json.loads(evt.result.json)
    recognized_texts.append(data.get("DisplayText", ""))
    if "NBest" in data and len(data["NBest"]) > 0:
        words = data["NBest"][0].get("Words", [])
        for w in words:
            all_words.append({
                "word": w.get("Word"),
                "offset_sec": w.get("Offset", 0) / 10000000.0,
                "duration_sec": w.get("Duration", 0) / 10000000.0
            })

recognizer.recognized.connect(handle_result)
done = False
def stop_cb(evt):
    global done
    done = True

recognizer.session_stopped.connect(stop_cb)
recognizer.canceled.connect(stop_cb)

print("Starting continuous recognition...")
recognizer.start_continuous_recognition()
import time
start_t = time.time()
while not done and (time.time() - start_t) < 120:
    time.sleep(1)

recognizer.stop_continuous_recognition()

print(f"\nFinished. Total recognized text phrases: {len(recognized_texts)}")
print(f"Total individual words recognized: {len(all_words)}")

import json
with open("assets/eleven/aligned_words.json", "w", encoding="utf-8") as f:
    json.dump({"phrases": recognized_texts, "words": all_words}, f, ensure_ascii=False, indent=2)

for i, p in enumerate(recognized_texts):
    print(f"P{i}: {p}")
