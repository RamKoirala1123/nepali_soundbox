import 'package:flutter/material.dart';
import 'package:nepali_tts/nepali_tts.dart';

void main() {
  runApp(const NepaliTtsDemoApp());
}

class NepaliTtsDemoApp extends StatelessWidget {
  const NepaliTtsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nepali TTS Soundbox Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
      ),
      home: const SoundboxScreen(),
    );
  }
}

class SoundboxScreen extends StatefulWidget {
  const SoundboxScreen({super.key});

  @override
  State<SoundboxScreen> createState() => _SoundboxScreenState();
}

class _SoundboxScreenState extends State<SoundboxScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '1530.30');
  late final NepaliTTS _tts;

  bool _includeMatra = true;
  bool _includePraptaBhayo = true;
  bool _isPlaying = false;
  String _nepaliWords = '';
  List<String> _clips = [];

  final List<double> _quickAmounts = [
    10,
    50,
    100,
    500,
    1530.30,
    2500,
    100000,
  ];

  @override
  void initState() {
    super.initState();
    // Default asset prefix for local package testing
    _tts = NepaliTTS(assetPrefix: 'assets/audio');
    _updateDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tts.dispose();
    super.dispose();
  }

  void _updateDetails() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final options = NepaliAmountOptions(
      includeMatra: _includeMatra,
      includePraptaBhayo: _includePraptaBhayo,
    );
    setState(() {
      _nepaliWords = NepaliAmountConverter.toWords(amount, options: options);
      _clips = NepaliAmountConverter.toClips(amount, options: options);
    });
  }

  Future<void> _speak() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() => _isPlaying = true);
    try {
      await _tts.speakAmount(
        amount,
        options: NepaliAmountOptions(
          includeMatra: _includeMatra,
          includePraptaBhayo: _includePraptaBhayo,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('नेपाली Soundbox (TTS)'),
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'रकम प्रविष्ट गर्नुहोस् (Enter Amount in Rs.)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'रु. ',
                        prefixStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (_) => _updateDetails(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'द्रुत रकम (Quick Select):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickAmounts.map((amt) {
                        return ActionChip(
                          label: Text(
                            amt >= 100000
                              ? 'रु. ${amt.toStringAsFixed(0)} (१ लाख)'
                              : 'रु. ${amt.toString().replaceAll(RegExp(r"\.0$"), "")}',
                          ),
                          onPressed: () {
                            _amountController.text =
                                amt.toString().replaceAll(RegExp(r"\.0$"), "");
                            _updateDetails();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Add "मात्र" (Only)'),
                      value: _includeMatra,
                      onChanged: (val) {
                        setState(() => _includeMatra = val);
                        _updateDetails();
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Add "प्राप्त भयो" (Received)'),
                      value: _includePraptaBhayo,
                      onChanged: (val) {
                        setState(() => _includePraptaBhayo = val);
                        _updateDetails();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Spoken Announcement Display
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'नेपाली बोली (Announcement):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nepaliWords.isEmpty ? '(रकम खाली छ)' : _nepaliWords,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Audio Clips Sequence:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _clips.map((c) {
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '$c.mp3',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Play / Stop Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isPlaying ? null : _speak,
                    icon: _isPlaying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(
                      _isPlaying ? 'बोल्दैछ... (Speaking)' : 'बोल्नुहोस् (Speak)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_isPlaying) ...[
                  const SizedBox(width: 12),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.stop_rounded, color: Colors.white),
                    onPressed: _stop,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
