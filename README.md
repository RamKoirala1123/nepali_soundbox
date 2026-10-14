# nepali_tts

A high-performance Nepali text-to-speech (TTS) soundbox package for Flutter, designed for **currency, payment, and transaction announcements** (eSewa / Khalti / POS soundbox style).

Pre-bundled with **110 studio-quality, volume-normalized audio clips** (0–99, units, and payment suffixes) enabling seamless, zero-latency, completely offline audio playback without requiring cloud TTS API keys or internet access at runtime.

---

## Features

- 🔊 **100% Offline & Instant**: All 110 number and currency clips (`0`–`99`, `hundred`, `thousand`, `lakh`, `crore`, `arab`, `rupaiya`, `paisa`, `matra`, `prapta_bhayo`, `ra`) are bundled directly into the package.
- ⚡ **Zero-Latency Soundbox Sequencing**: Uses in-memory byte caching with seamless sequencing, emulating physical merchant soundbox terminals.
- 🎛️ **Speed & Gap Control**: Configure speech rate (`0.5x` to `2.0x`) and inter-word silence spacing (`gapMs` from `-100ms` for rapid continuous speech up to `200ms` for deliberate cadence).
- 🇳🇵 **Accurate Nepali Grammar & Numbering**: Decomposes numbers according to the South Asian / Nepali numbering system (एक, सय, हजार, लाख, करोड, अर्ब, रुपैयाँ, पैसा, मात्र, प्राप्त भयो).
- 🛠️ **Configurable Suffixes**: Toggle "मात्र" (only), "प्राप्त भयो" (received), and "र" (and) conjunctions.
- 🌐 **Cross-Platform**: Supports Android, iOS, Web, macOS, Windows, and Linux out-of-the-box.
- 🧪 **Fully Tested**: Comprehensive unit test suite covering single digits to multi-crore amounts and paisa combinations.

---

## Installation

Add `nepali_tts` to your `pubspec.yaml`:

```yaml
dependencies:
  nepali_tts: ^0.0.1
```

Or via Flutter CLI:

```bash
flutter pub add nepali_tts
```

---

## Usage

### 1. Speak an Amount (eSewa / Khalti Style)

```dart
import 'package:nepali_tts/nepali_tts.dart';

final tts = NepaliTTS();

// Announces: "एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो"
await tts.speakAmount(1530.30);

// Stop playback at any time:
await tts.stop();
```

---

### 2. Speed and Gap Tuning

Adjust speech tempo and word gap spacing to match your app's desired soundbox pace:

```dart
await tts.speakAmount(
  500,
  speed: 1.1,     // Playback rate: 0.5x to 2.0x (default: 1.0)
  gapMs: -30,     // Gap between clips in ms (-100 to 200 ms, default: 0)
);
```

---

### 3. Custom Announcement Options

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

### 4. Convert Amount to Nepali Text or Clip Keys

You can also use the converter directly without playing audio:

```dart
import 'package:nepali_tts/nepali_tts.dart';

// Get Spoken Devanagari Words
String words = NepaliAmountConverter.toWords(1530.30);
// -> "एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो"

// Get Audio Clip Keys Sequence
List<String> clips = NepaliAmountConverter.toClips(1530.30);
// -> ['1', 'thousand', '5', 'hundred', '30', 'rupaiya', '30', 'paisa', 'matra', 'prapta_bhayo']
```

---

## Bundled Clip Catalog

| Clip Keys | Nepali Words | Meaning |
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

Check out the interactive demo in `example/lib/main.dart` featuring real-time amount inputs, quick amount chips, speed slider, and gap tuning:

```bash
cd example
flutter run
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
