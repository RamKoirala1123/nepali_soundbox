## 0.0.2

* Fix dangling library doc comment warning in `nepali_words.dart`.
* Add dartdoc comments for `NepaliAmountOptions` and mark `NepaliAmountConverter` as non-instantiable utility class.
* Add package-level `analysis_options.yaml` adhering to `flutter_lints`.
* Fix deprecated `activeColor` usages in the example application.

## 0.0.1

* Initial release of `nepali_soundbox`.
* Offline Nepali currency and payment soundbox announcement engine (eSewa / Khalti style).
* Bundles 110 pre-normalized neural audio clips (0–99, hundred, thousand, lakh, crore, arab, rupaiya, paisa, matra, prapta_bhayo, ra).
* In-memory rootBundle audio decoding for zero-gap, continuous playback.
* Support for customizable playback speed (`speed` 0.5x–2.0x) and inter-word silence spacing (`gapMs` -100ms to 200ms).
* Full support for Flutter Web, Android, iOS, macOS, Windows, and Linux.
* Example demo app with amount inputs and customizable options.
