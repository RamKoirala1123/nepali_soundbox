import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_tts/nepali_tts.dart';

void main() {
  group('NepaliAmountConverter Tests', () {
    test('Converts 0 rupees and 0 paisa', () {
      final clips = NepaliAmountConverter.toClips(0);
      expect(clips, ['0', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(0);
      expect(words, 'शून्य रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts single digit: 5', () {
      final clips = NepaliAmountConverter.toClips(5);
      expect(clips, ['5', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(5);
      expect(words, 'पाँच रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts two digits: 25', () {
      final clips = NepaliAmountConverter.toClips(25);
      expect(clips, ['25', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(25);
      expect(words, 'पच्चीस रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts hundred: 100', () {
      final clips = NepaliAmountConverter.toClips(100);
      expect(clips, ['1', 'hundred', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(100);
      expect(words, 'एक सय रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts hundred with remainder: 105', () {
      final clips = NepaliAmountConverter.toClips(105);
      expect(clips, ['1', 'hundred', '5', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(105);
      expect(words, 'एक सय पाँच रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts 1530.30 (sample preview sequence)', () {
      final clips = NepaliAmountConverter.toClips(1530.30);
      expect(clips, [
        '1', 'thousand',
        '5', 'hundred',
        '30', 'rupaiya',
        '30', 'paisa',
        'matra',
        'prapta_bhayo'
      ]);

      final words = NepaliAmountConverter.toWords(1530.30);
      expect(
        words,
        'एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो',
      );
    });

    test('Converts lakhs: 250000', () {
      final clips = NepaliAmountConverter.toClips(250000);
      expect(clips, ['2', 'lakh', '50', 'thousand', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(250000);
      expect(words, 'दुई लाख पचास हजार रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts crores: 10000000', () {
      final clips = NepaliAmountConverter.toClips(10000000);
      expect(clips, ['1', 'crore', 'rupaiya', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(10000000);
      expect(words, 'एक करोड रुपैयाँ मात्र प्राप्त भयो');
    });

    test('Converts only paisa: 0.50', () {
      final clips = NepaliAmountConverter.toClips(0.50);
      expect(clips, ['50', 'paisa', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(0.50);
      expect(words, 'पचास पैसा मात्र प्राप्त भयो');
    });

    test('Converts with custom options (no matra, no prapta_bhayo)', () {
      final clips = NepaliAmountConverter.toClips(
        100,
        options: const NepaliAmountOptions(
          includeMatra: false,
          includePraptaBhayo: false,
        ),
      );
      expect(clips, ['1', 'hundred', 'rupaiya']);

      final words = NepaliAmountConverter.toWords(
        100,
        options: const NepaliAmountOptions(
          includeMatra: false,
          includePraptaBhayo: false,
        ),
      );
      expect(words, 'एक सय रुपैयाँ');
    });

    test('Converts with includeRaForPaisa option', () {
      final clips = NepaliAmountConverter.toClips(
        50.25,
        options: const NepaliAmountOptions(includeRaForPaisa: true),
      );
      expect(clips, ['50', 'rupaiya', 'ra', '25', 'paisa', 'matra', 'prapta_bhayo']);

      final words = NepaliAmountConverter.toWords(
        50.25,
        options: const NepaliAmountOptions(includeRaForPaisa: true),
      );
      expect(words, 'पचास रुपैयाँ र पच्चीस पैसा मात्र प्राप्त भयो');
    });
  });
}
