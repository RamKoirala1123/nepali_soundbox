import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'nepali_amount_converter.dart';

/// Soundbox audio player for announcing Nepali amounts.
class NepaliTTS {
  final AudioPlayer _player;
  bool _isPlaying = false;
  Completer<void>? _currentPlaybackCompleter;

  /// Audio playback speed multiplier (e.g. 1.0 for normal, 1.1 for brisk announcement).
  double speed;

  /// Additional delay in milliseconds between consecutive clips (e.g. 0 to 200 ms).
  int gapMs;

  /// In-memory cache for audio clip bytes (total size for all 110 clips is ~700 KB).
  static final Map<String, Uint8List> _audioCache = {};

  /// Creates a [NepaliTTS] instance.
  NepaliTTS({
    AudioPlayer? player,
    this.speed = 1.0,
    this.gapMs = 0,
  }) : _player = player ?? AudioPlayer();

  /// Whether audio is currently being played.
  bool get isPlaying => _isPlaying;

  /// Underlying [AudioPlayer] instance.
  AudioPlayer get player => _player;

  /// Speaks the given payment [amount] in Nepali.
  ///
  /// Example:
  /// ```dart
  /// final tts = NepaliTTS(gapMs: 50);
  /// await tts.speakAmount(1530.30);
  /// ```
  Future<void> speakAmount(
    num amount, {
    NepaliAmountOptions options = const NepaliAmountOptions(),
    void Function(String clip, int index)? onClipStarted,
    double? speed,
    int? gapMs,
  }) async {
    final clips = NepaliAmountConverter.toClips(amount, options: options);
    await playClips(
      clips,
      onClipStarted: onClipStarted,
      speed: speed,
      gapMs: gapMs,
    );
  }

  /// Loads audio clip bytes from the asset bundle, checking candidate package prefixes.
  Future<Uint8List> _loadClipBytes(String clipKey) async {
    if (_audioCache.containsKey(clipKey)) {
      return _audioCache[clipKey]!;
    }

    final candidates = [
      "packages/nepali_tts/assets/audio/$clipKey.mp3",
      "assets/audio/$clipKey.mp3",
      "audio/$clipKey.mp3",
    ];

    for (final candidate in candidates) {
      try {
        final byteData = await rootBundle.load(candidate);
        final bytes = byteData.buffer.asUint8List();
        _audioCache[clipKey] = bytes;
        return bytes;
      } catch (_) {
        // Try next candidate
      }
    }

    throw FlutterError(
      "Could not find audio asset '$clipKey.mp3' in bundle. Checked: $candidates",
    );
  }

  /// Plays a given sequence of audio clip keys in order.
  Future<void> playClips(
    List<String> clipKeys, {
    void Function(String clip, int index)? onClipStarted,
    double? speed,
    int? gapMs,
  }) async {
    await stop();

    if (clipKeys.isEmpty) return;

    final effectiveSpeed = speed ?? this.speed;
    final effectiveGapMs = gapMs ?? this.gapMs;

    _isPlaying = true;
    final completer = Completer<void>();
    _currentPlaybackCompleter = completer;

    try {
      if (effectiveSpeed != 1.0) {
        try {
          await _player.setPlaybackRate(effectiveSpeed);
        } catch (_) {}
      }

      for (int i = 0; i < clipKeys.length; i++) {
        if (!_isPlaying || completer.isCompleted) break;
        final key = clipKeys[i];

        onClipStarted?.call(key, i);
        debugPrint(
            "[NepaliTTS] Playing clip [$i/${clipKeys.length}]: $key.mp3");

        final bytes = await _loadClipBytes(key);

        final completionFuture = Future.any<void>([
          _player.onPlayerComplete.first,
          Future<void>.delayed(const Duration(seconds: 2)),
        ]);

        await _player.play(BytesSource(bytes));
        if (effectiveSpeed != 1.0) {
          try {
            await _player.setPlaybackRate(effectiveSpeed);
          } catch (_) {}
        }
        await completionFuture;

        // Apply slight gap between consecutive clips if requested
        if (effectiveGapMs > 0 && i < clipKeys.length - 1 && _isPlaying) {
          await Future<void>.delayed(Duration(milliseconds: effectiveGapMs));
        }
      }
    } catch (e, st) {
      debugPrint("[NepaliTTS] Playback error: $e\n$st");
      rethrow;
    } finally {
      _isPlaying = false;
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (_currentPlaybackCompleter == completer) {
        _currentPlaybackCompleter = null;
      }
    }
  }

  /// Preloads all 110 audio clips into memory for instant playback.
  static Future<void> preloadAll() async {
    final tts = NepaliTTS();
    final allKeys = [
      for (int i = 0; i < 100; i++) i.toString(),
      "hundred",
      "thousand",
      "lakh",
      "crore",
      "arab",
      "rupaiya",
      "paisa",
      "matra",
      "prapta_bhayo",
      "ra",
    ];
    for (final key in allKeys) {
      try {
        await tts._loadClipBytes(key);
      } catch (_) {}
    }
    await tts.dispose();
  }

  /// Stops any currently playing audio sequence immediately.
  Future<void> stop() async {
    _isPlaying = false;
    final c = _currentPlaybackCompleter;
    _currentPlaybackCompleter = null;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Releases audio player resources.
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
