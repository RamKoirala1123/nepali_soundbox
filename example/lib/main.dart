import 'package:flutter/material.dart';
import 'package:nepali_soundbox/nepali_soundbox.dart';

void main() {
  runApp(const NepaliSoundboxDemoApp());
}

class NepaliSoundboxDemoApp extends StatelessWidget {
  const NepaliSoundboxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'नेपाली Soundbox',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          surface: Colors.white,
        ),
      ),
      home: const FlatSoundboxScreen(),
    );
  }
}

class FlatSoundboxScreen extends StatefulWidget {
  const FlatSoundboxScreen({super.key});

  @override
  State<FlatSoundboxScreen> createState() => _FlatSoundboxScreenState();
}

class _FlatSoundboxScreenState extends State<FlatSoundboxScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '1530.30');
  late final NepaliSoundbox _soundbox;

  bool _includeMatra = true;
  bool _includePraptaBhayo = true;
  bool _includeRaForPaisa = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _gapMs = 0;

  final List<double> _quickAmounts = [
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
    _soundbox = NepaliSoundbox();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _soundbox.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() => _isPlaying = true);

    try {
      await _soundbox.speakAmount(
        amount,
        speed: _speed,
        gapMs: _gapMs,
        options: NepaliAmountOptions(
          includeMatra: _includeMatra,
          includePraptaBhayo: _includePraptaBhayo,
          includeRaForPaisa: _includeRaForPaisa,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _stop() async {
    await _soundbox.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 640;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'नेपाली Soundbox (TTS)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          // Generous breathable spacing on desktop / high screens, natural on mobile
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 36 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Amount Input (Clean & Flat)
                const Text(
                  'Amount in Rupees (रकम)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    prefixText: 'रु. ',
                    prefixStyle: TextStyle(
                      fontSize: isDesktop ? 26 : 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F766E),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isDesktop ? 18 : 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F766E),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              setState(() => _amountController.clear());
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 14),

                // Quick Select Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amt) {
                    final label = amt >= 100000
                        ? 'रु. १ लाख'
                        : 'रु. ${amt.toString().replaceAll(RegExp(r"\.0$"), "")}';
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _amountController.text =
                              amt.toString().replaceAll(RegExp(r"\.0$"), "");
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 2. Play Sound Button
                SizedBox(
                  height: isDesktop ? 52 : 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isPlaying ? _stop : _speak,
                    icon: Icon(
                      _isPlaying
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _isPlaying ? 'रोक्नुहोस् (Stop)' : 'बोल्नुहोस् (Speak)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // 3. Settings at Bottom (Completely flat, no card)
                const Text(
                  'Settings (सेटिङ)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Speed Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Playback Speed (गति)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${_speed.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: const Color(0xFF0F766E),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) => setState(() => _speed = val),
                  ),
                ),

                const SizedBox(height: 8),

                // Gap Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Silence Gap (शब्द दूरी)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${_gapMs}ms',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _gapMs.toDouble(),
                    min: 0,
                    max: 200,
                    divisions: 20,
                    activeColor: const Color(0xFF0F766E),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) => setState(() => _gapMs = val.round()),
                  ),
                ),

                const Divider(color: Color(0xFFF1F5F9), height: 32),

                // Suffix Toggles
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Add "मात्र" (Only)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  activeColor: const Color(0xFF0F766E),
                  value: _includeMatra,
                  onChanged: (val) => setState(() => _includeMatra = val),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Add "प्राप्त भयो" (Received)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  activeColor: const Color(0xFF0F766E),
                  value: _includePraptaBhayo,
                  onChanged: (val) =>
                      setState(() => _includePraptaBhayo = val),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Add "र" before Paisa',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  activeColor: const Color(0xFF0F766E),
                  value: _includeRaForPaisa,
                  onChanged: (val) =>
                      setState(() => _includeRaForPaisa = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
