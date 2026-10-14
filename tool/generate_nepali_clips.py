#!/usr/bin/env python3
"""
Generate Nepali number / amount audio clips with Azure Speech (neural TTS).

Setup
-----
    pip install azure-cognitiveservices-speech
    # optional but recommended (trim silence + normalize volume):
    #   install ffmpeg and make sure `ffmpeg` is on your PATH

    export AZURE_SPEECH_KEY="your-key"          # Windows: set AZURE_SPEECH_KEY=your-key
    export AZURE_SPEECH_REGION="southeastasia"  # the region of your Speech resource

Run
---
    python generate_nepali_clips.py
    python generate_nepali_clips.py --voice ne-NP-SagarNeural --out assets/audio
    python generate_nepali_clips.py --only 1 2 thousand        # regenerate a few clips
    python generate_nepali_clips.py --force                    # overwrite existing files
    python generate_nepali_clips.py --no-post                  # skip ffmpeg post-processing

Output
------
    <out>/0.mp3 ... 99.mp3, hundred.mp3, thousand.mp3, lakh.mp3, crore.mp3, arab.mp3,
    rupaiya.mp3, paisa.mp3, matra.mp3, prapta_bhayo.mp3, ra.mp3

IMPORTANT: listen to every clip once. Verify spellings of the Nepali words below
with a native speaker; a few numbers (e.g. 37, 47, 61-68) have spelling variants.
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

# Fix Windows console encoding for Devanagari Unicode
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

try:
    import azure.cognitiveservices.speech as speechsdk
except ImportError:
    sys.exit("Missing dependency. Run: pip install azure-cognitiveservices-speech")

# --------------------------------------------------------------------------- #
# Words
# --------------------------------------------------------------------------- #

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

assert len(NUMBERS_0_99) == 100, "Number list must have exactly 100 entries"

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


def build_clip_map() -> dict:
    clips = {str(i): word for i, word in enumerate(NUMBERS_0_99)}
    clips.update(EXTRA_WORDS)
    return clips


# --------------------------------------------------------------------------- #
# Azure synthesis
# --------------------------------------------------------------------------- #

def make_ssml(text: str, voice: str, rate: str) -> str:
    # Slightly slower rate sounds clearer for single words.
    return (
        "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' "
        "xml:lang='ne-NP'>"
        f"<voice name='{voice}'>"
        f"<prosody rate='{rate}'>{text}</prosody>"
        "</voice></speak>"
    )


def synthesize(config, text: str, voice: str, rate: str, out_path: Path, retries: int = 3) -> bool:
    ssml = make_ssml(text, voice, rate)
    for attempt in range(1, retries + 1):
        audio_cfg = speechsdk.audio.AudioOutputConfig(filename=str(out_path))
        synth = speechsdk.SpeechSynthesizer(speech_config=config, audio_config=audio_cfg)
        result = synth.speak_ssml_async(ssml).get()
        # Release file handle before anything else touches it.
        del synth

        if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
            return True

        details = ""
        if result.reason == speechsdk.ResultReason.Canceled:
            c = result.cancellation_details
            details = f"{c.reason}: {c.error_details}"
            # Auth / quota problems won't fix themselves on retry.
            if c.reason == speechsdk.CancellationReason.Error and (
                "401" in details or "403" in details or "quota" in details.lower()
            ):
                print(f"   ! {details}")
                return False
        print(f"   ! attempt {attempt}/{retries} failed. {details}")
        time.sleep(1.5 * attempt)
    return False


# --------------------------------------------------------------------------- #
# ffmpeg post-processing: trim silence + normalize loudness
# --------------------------------------------------------------------------- #

def postprocess(path: Path) -> bool:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return False

    fd, tmp_str = tempfile.mkstemp(suffix=".mp3")
    os.close(fd)
    tmp = Path(tmp_str)
    # Trim leading silence, reverse, trim (now-leading) trailing silence, reverse back,
    # then loudness-normalize so every clip has the same volume.
    af = (
        "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,"
        "areverse,"
        "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,"
        "areverse,"
        "loudnorm=I=-18:TP=-1.5:LRA=7"
    )
    cmd = [
        ffmpeg, "-y", "-loglevel", "error", "-i", str(path),
        "-af", af, "-ar", "24000", "-ac", "1", "-b:a", "64k",
        "-codec:a", "libmp3lame", str(tmp),
    ]
    try:
        subprocess.run(cmd, check=True)
        if tmp.stat().st_size > 0:
            os.replace(str(tmp), str(path))
            return True
    except subprocess.CalledProcessError as e:
        print(f"   ! ffmpeg failed: {e}")
    finally:
        if tmp.exists():
            try:
                tmp.unlink()
            except Exception:
                pass
    return False


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Nepali amount clips with Azure TTS")
    parser.add_argument("--out", default="audio", help="output folder (default: ./audio)")
    parser.add_argument("--voice", default="ne-NP-HemkalaNeural",
                        help="ne-NP-HemkalaNeural (female) or ne-NP-SagarNeural (male)")
    parser.add_argument("--rate", default="-5%", help="speaking rate, e.g. -10%%, 0%%, +5%%")
    parser.add_argument("--force", action="store_true", help="overwrite existing clips")
    parser.add_argument("--no-post", action="store_true", help="skip ffmpeg trim/normalize")
    parser.add_argument("--only", nargs="*", help="generate only these clip names")
    args = parser.parse_args()

    key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not key or not region:
        sys.exit("Set AZURE_SPEECH_KEY and AZURE_SPEECH_REGION environment variables first.")

    config = speechsdk.SpeechConfig(subscription=key, region=region)
    config.speech_synthesis_voice_name = args.voice
    config.set_speech_synthesis_output_format(
        speechsdk.SpeechSynthesisOutputFormat.Audio24Khz48KBitRateMonoMp3
    )

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    clips = build_clip_map()
    if args.only:
        unknown = [n for n in args.only if n not in clips]
        if unknown:
            sys.exit(f"Unknown clip names: {unknown}")
        clips = {n: clips[n] for n in args.only}

    do_post = not args.no_post
    if do_post and not shutil.which("ffmpeg"):
        print("ffmpeg not found: skipping trim/normalize (install ffmpeg for better results).\n")
        do_post = False

    total_chars = sum(len(t) for t in clips.values())
    print(f"Voice: {args.voice} | clips: {len(clips)} | ~{total_chars} characters\n")

    ok, skipped, failed = 0, 0, []
    for i, (name, text) in enumerate(clips.items(), 1):
        path = out_dir / f"{name}.mp3"
        if path.exists() and not args.force:
            skipped += 1
            continue

        print(f"[{i}/{len(clips)}] {name:>14}  ->  {text}")
        if synthesize(config, text, args.voice, args.rate, path):
            if do_post:
                postprocess(path)
            ok += 1
        else:
            failed.append(name)
            if path.exists():
                path.unlink()

    print(f"\nDone. generated={ok} skipped(existing)={skipped} failed={len(failed)}")
    if failed:
        print("Failed clips:", ", ".join(failed))
        print("Re-run the script (existing files are skipped) or use --only <names>.")
    print(f"Output folder: {out_dir.resolve()}")


if __name__ == "__main__":
    main()
