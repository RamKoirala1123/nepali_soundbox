# nepali_tts

A high-performance Nepali text-to-speech (TTS) soundbox package for Flutter, designed for **payment and currency amount announcements** (eSewa / Khalti / POS soundbox style).

Pre-bundled with **110 studio-normalized neural audio clips** generated via Azure Speech (`ne-NP-HemkalaNeural`) and normalized to **-18 LUFS** with FFmpeg, enabling seamless, zero-latency, offline audio playback without requiring cloud TTS API calls at runtime.

---

## Features

- 🔊 **Offline & Instant**: All 110 number and currency clips (`0`-`99`, `hundred`, `thousand`, `lakh`, `crore`, `arab`, `rupaiya`, `paisa`, `matra`, `prapta_bhayo`, `ra`) are bundled directly.
- ⚡ **Zero-Latency Soundbox Sequencing**: Stitches clips seamlessly without silence gaps, sounding like physical merchant soundbox terminals.
- 🇳🇵 **Accurate Nepali Grammar & Numbering**: Decomposes numbers according to the South Asian / Nepali numbering system (एक, सय, हजार, लाख, करोड, अर्ब, रुपैयाँ, पैसा, मात्र, प्राप्त भयो).
- 🛠️ **Configurable**: Toggle "मात्र" (only), "प्राप्त भयो" (received), and "र" (and) conjunctions.
- 🧪 **Fully Tested**: Includes unit tests verifying amounts from 0 to Crores.

---

## Installation

Add `nepali_tts` to your `pubspec.yaml`:

```yaml
dependencies:
  nepali_tts:
    git:
      url: https://github.com/RamKoirala1123/nepali_tts.git
```

Ensure audio assets are bundled (handled automatically when consuming the package).

---

## Usage

### 1. Speak an Amount Directly (eSewa Soundbox Style)

```dart
import 'package:nepali_tts/nepali_tts.dart';

final tts = NepaliTTS();

// Announces: "एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो"
await tts.speakAmount(1530.30);

// Stop playback at any time:
await tts.stop();
```

---

### 2. Custom Announcement Options

```dart
await tts.speakAmount(
  500,
  options: const NepaliAmountOptions(
    includeMatra: true,         // Adds "मात्र" at the end
    includePraptaBhayo: true,   // Adds "प्राप्त भयो" at the end
    includeRaForPaisa: true,    // Adds "र" before paisa (e.g. रुपैयाँ र २५ पैसा)
  ),
);
```

---

### 3. Convert Amount to Nepali Text or Clip Keys

You can also use the converter directly without playing audio:

```dart
import 'package:nepali_tts/nepali_tts.dart';

// Get Spoken Nepali Text
String words = NepaliAmountConverter.toWords(1530.30);
// -> "एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो"

// Get Audio Clip File Sequence
List<String> clips = NepaliAmountConverter.toClips(1530.30);
// -> ['1', 'thousand', '5', 'hundred', '30', 'rupaiya', '30', 'paisa', 'matra', 'prapta_bhayo']
```

---

## Clip List & Manifest

All 110 clips, their exact durations, and Nepali spellings are cataloged in [assets/audio/MANIFEST.md](assets/audio/MANIFEST.md).

| Clip | Nepali Text | Meaning |
| :--- | :--- | :--- |
| `0` - `99` | शून्य - उनान्सय | 0 to 99 |
| `hundred` | सय | Hundred (100) |
| `thousand` | हजार | Thousand (1,000) |
| `lakh` | लाख | Lakh (1,00,000) |
| `crore` | करोड | Crore (1,00,00,000) |
| `arab` | अर्ब | Arab (1,00,00,00,000) |
| `rupaiya` | रुपैयाँ | Rupees |
| `paisa` | पैसा | Paisa |
| `matra` | मात्र | Only |
| `prapta_bhayo` | प्राप्त भयो | Received |
| `ra` | र | And |

---

## Example App

Check out the interactive demo in `example/lib/main.dart`:

```bash
cd example
flutter run
```

---

## License

MIT License.
