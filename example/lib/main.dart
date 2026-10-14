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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Crisp slate-50
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669), // Emerald
          primary: const Color(0xFF059669),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const CleanSoundboxScreen(),
    );
  }
}

class CleanSoundboxScreen extends StatefulWidget {
  const CleanSoundboxScreen({super.key});

  @override
  State<CleanSoundboxScreen> createState() => _CleanSoundboxScreenState();
}

class _CleanSoundboxScreenState extends State<CleanSoundboxScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '1530.30');
  late final NepaliSoundbox _soundbox;

  bool _includeMatra = true;
  bool _includePraptaBhayo = true;
  bool _includeRaForPaisa = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _gapMs = 0;
  int _currentClipIndex = -1;
  String _nepaliWords = '';
  List<String> _clips = [];

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
    _updateDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _soundbox.dispose();
    super.dispose();
  }

  void _updateDetails() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final options = NepaliAmountOptions(
      includeMatra: _includeMatra,
      includePraptaBhayo: _includePraptaBhayo,
      includeRaForPaisa: _includeRaForPaisa,
    );
    setState(() {
      _nepaliWords = NepaliAmountConverter.toWords(amount, options: options);
      _clips = NepaliAmountConverter.toClips(amount, options: options);
    });
  }

  Future<void> _speak() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _isPlaying = true;
      _currentClipIndex = -1;
    });
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
        onClipStarted: (clip, index) {
          if (mounted) {
            setState(() => _currentClipIndex = index);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentClipIndex = -1;
        });
      }
    }
  }

  Future<void> _stop() async {
    await _soundbox.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentClipIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              // Generous breathable spacing on desktop / high screens, natural on mobile
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Brand
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // 1. TOP: Amount Enter Field
                    _buildAmountField(),

                    const SizedBox(height: 12),

                    // Quick Select Chips
                    _buildQuickChips(),

                    const SizedBox(height: 20),

                    // 2. BELOW AMOUNT: Play Sound Button
                    _buildPlayButton(),

                    const SizedBox(height: 24),

                    // 3. MIDDLE: Nepali Words & Live Clip Sequence
                    _buildNepaliWordsCard(),

                    const SizedBox(height: 24),

                    // 4. BOTTOM: Settings
                    _buildSettingsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA7F3D0),
                ),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'नेपाली Soundbox (TTS)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Payment Soundbox Simulator',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isPlaying
                ? const Color(0xFFECFDF5)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPlaying
                  ? const Color(0xFF34D399)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isPlaying ? 'Playing' : 'Ready',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _isPlaying
                      ? const Color(0xFF059669)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'रकम प्रविष्ट गर्नुहोस् (ENTER AMOUNT)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'रु. ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  onChanged: (_) => _updateDetails(),
                ),
              ),
              if (_amountController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 20, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _amountController.clear();
                    _updateDetails();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickAmounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final amt = _quickAmounts[index];
          final label = amt >= 100000
              ? 'रु. १ लाख'
              : 'रु. ${amt.toString().replaceAll(RegExp(r"\.0$"), "")}';
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _amountController.text =
                  amt.toString().replaceAll(RegExp(r"\.0$"), "");
              _updateDetails();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: _isPlaying ? const Color(0xFFDC2626) : const Color(0xFF059669),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isPlaying ? const Color(0xFFDC2626) : const Color(0xFF059669))
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isPlaying ? _stop : _speak,
        icon: _isPlaying
            ? const Icon(Icons.stop_rounded, size: 28)
            : const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          _isPlaying ? 'रोक्नुहोस् (Stop)' : 'बोल्नुहोस् (Speak)',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildNepaliWordsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: Color(0xFF059669)),
              SizedBox(width: 6),
              Text(
                'नेपाली बोली (Spoken Words):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _nepaliWords.isEmpty ? '(रकम खाली छ)' : _nepaliWords,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.45,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 12),
          const Text(
            'Audio Clips Track:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_clips.length, (idx) {
              final c = _clips[idx];
              final isCurrent = _currentClipIndex == idx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF059669)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF059669)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  '$c.mp3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'सेटिङ (Audio Settings)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Speed Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'गति (Speed):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                '${_speed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: const Color(0xFF059669),
            onChanged: (val) => setState(() => _speed = val),
          ),

          // Gap Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'शब्द दूरी (Silence Gap):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                '${_gapMs}ms',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          Slider(
            value: _gapMs.toDouble(),
            min: 0,
            max: 200,
            divisions: 20,
            activeColor: const Color(0xFF059669),
            onChanged: (val) => setState(() => _gapMs = val.round()),
          ),

          const Divider(color: Color(0xFFE2E8F0), height: 16),

          // Suffix Toggles
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Add "मात्र" (Only)'),
            activeColor: const Color(0xFF059669),
            value: _includeMatra,
            onChanged: (val) {
              setState(() => _includeMatra = val);
              _updateDetails();
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Add "प्राप्त भयो" (Received)'),
            activeColor: const Color(0xFF059669),
            value: _includePraptaBhayo,
            onChanged: (val) {
              setState(() => _includePraptaBhayo = val);
              _updateDetails();
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Add "र" before Paisa'),
            activeColor: const Color(0xFF059669),
            value: _includeRaForPaisa,
            onChanged: (val) {
              setState(() => _includeRaForPaisa = val);
              _updateDetails();
            },
          ),
        ],
      ),
    );
  }
}
