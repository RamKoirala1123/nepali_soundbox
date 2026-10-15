import 'nepali_words.dart';

/// Configuration options for converting an amount to words or audio clips.
class NepaliAmountOptions {
  /// Whether to append 'मात्र' (only) at the end of the amount announcement.
  final bool includeMatra;

  /// Whether to append 'प्राप्त भयो' (received) at the end.
  final bool includePraptaBhayo;

  /// Whether to include 'र' (and) between rupees and paisa.
  final bool includeRaForPaisa;

  /// Creates a [NepaliAmountOptions] configuration.
  const NepaliAmountOptions({
    this.includeMatra = true,
    this.includePraptaBhayo = true,
    this.includeRaForPaisa = false,
  });
}

/// Utility class for decomposing numeric amounts into Nepali words and audio clip identifiers.
abstract final class NepaliAmountConverter {
  NepaliAmountConverter._();
  /// Converts an amount (e.g. `1530.30`) to an ordered list of audio clip keys.
  ///
  /// Example:
  /// `1530.30` -> `['1', 'thousand', '5', 'hundred', '30', 'rupaiya', '30', 'paisa', 'matra', 'prapta_bhayo']`
  static List<String> toClips(
    num amount, {
    NepaliAmountOptions options = const NepaliAmountOptions(),
  }) {
    final double value = amount.toDouble().abs();
    final int rupees = value.floor();
    // Round paisa to nearest 2 decimal places
    final int paisa = ((value - rupees) * 100).round();

    final List<String> clips = [];

    if (rupees > 0) {
      clips.addAll(_integerToClips(rupees));
      clips.add("rupaiya");
    } else if (paisa == 0) {
      // 0 rupees and 0 paisa
      clips.add("0");
      clips.add("rupaiya");
    }

    if (paisa > 0) {
      if (options.includeRaForPaisa && clips.isNotEmpty) {
        clips.add("ra");
      }
      clips.addAll(_integerToClips(paisa));
      clips.add("paisa");
    }

    if (options.includeMatra) {
      clips.add("matra");
    }

    if (options.includePraptaBhayo) {
      clips.add("prapta_bhayo");
    }

    return clips;
  }

  /// Converts an amount (e.g. `1530.30`) to its spoken Nepali text.
  ///
  /// Example:
  /// `1530.30` -> `"एक हजार पाँच सय तीस रुपैयाँ तीस पैसा मात्र प्राप्त भयो"`
  static String toWords(
    num amount, {
    NepaliAmountOptions options = const NepaliAmountOptions(),
  }) {
    final double value = amount.toDouble().abs();
    final int rupees = value.floor();
    final int paisa = ((value - rupees) * 100).round();

    final List<String> words = [];

    if (rupees > 0) {
      words.addAll(_integerToWords(rupees));
      words.add(nepaliExtraWords["rupaiya"]!);
    } else if (paisa == 0) {
      words.add(nepaliNumbers0To99[0]);
      words.add(nepaliExtraWords["rupaiya"]!);
    }

    if (paisa > 0) {
      if (options.includeRaForPaisa && words.isNotEmpty) {
        words.add(nepaliExtraWords["ra"]!);
      }
      words.addAll(_integerToWords(paisa));
      words.add(nepaliExtraWords["paisa"]!);
    }

    if (options.includeMatra) {
      words.add(nepaliExtraWords["matra"]!);
    }

    if (options.includePraptaBhayo) {
      words.add(nepaliExtraWords["prapta_bhayo"]!);
    }

    return words.join(" ");
  }

  /// Helper to convert an integer up to Arab into clip tokens.
  static List<String> _integerToClips(int number) {
    if (number <= 0) return [];
    if (number < 100) return [number.toString()];

    final List<String> result = [];
    int rem = number;

    // Arab (10^9 = 1,00,00,00,000)
    if (rem >= 1000000000) {
      final int arab = rem ~/ 1000000000;
      result.addAll(_integerToClips(arab));
      result.add("arab");
      rem %= 1000000000;
    }

    // Crore (10^7 = 1,00,00,000)
    if (rem >= 10000000) {
      final int crore = rem ~/ 10000000;
      result.addAll(_integerToClips(crore));
      result.add("crore");
      rem %= 10000000;
    }

    // Lakh (10^5 = 1,00,000)
    if (rem >= 100000) {
      final int lakh = rem ~/ 100000;
      result.addAll(_integerToClips(lakh));
      result.add("lakh");
      rem %= 100000;
    }

    // Thousand / Hajar (10^3 = 1,000)
    if (rem >= 1000) {
      final int thousand = rem ~/ 1000;
      result.addAll(_integerToClips(thousand));
      result.add("thousand");
      rem %= 1000;
    }

    // Hundred / Saya (10^2 = 100)
    if (rem >= 100) {
      final int hundred = rem ~/ 100;
      result.addAll(_integerToClips(hundred));
      result.add("hundred");
      rem %= 100;
    }

    // Remaining 1-99
    if (rem > 0) {
      result.add(rem.toString());
    }

    return result;
  }

  /// Helper to convert an integer up to Arab into Nepali words.
  static List<String> _integerToWords(int number) {
    if (number <= 0) return [];
    if (number < 100) return [nepaliNumbers0To99[number]];

    final List<String> result = [];
    int rem = number;

    if (rem >= 1000000000) {
      final int arab = rem ~/ 1000000000;
      result.addAll(_integerToWords(arab));
      result.add(nepaliExtraWords["arab"]!);
      rem %= 1000000000;
    }

    if (rem >= 10000000) {
      final int crore = rem ~/ 10000000;
      result.addAll(_integerToWords(crore));
      result.add(nepaliExtraWords["crore"]!);
      rem %= 10000000;
    }

    if (rem >= 100000) {
      final int lakh = rem ~/ 100000;
      result.addAll(_integerToWords(lakh));
      result.add(nepaliExtraWords["lakh"]!);
      rem %= 100000;
    }

    if (rem >= 1000) {
      final int thousand = rem ~/ 1000;
      result.addAll(_integerToWords(thousand));
      result.add(nepaliExtraWords["thousand"]!);
      rem %= 1000;
    }

    if (rem >= 100) {
      final int hundred = rem ~/ 100;
      result.addAll(_integerToWords(hundred));
      result.add(nepaliExtraWords["hundred"]!);
      rem %= 100;
    }

    if (rem > 0) {
      result.add(nepaliNumbers0To99[rem]);
    }

    return result;
  }
}
