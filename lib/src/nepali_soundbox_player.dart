import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'nepali_amount_converter.dart';

/// Soundbox audio player for announcing Nepali amounts.
class NepaliTTS {
  final AudioPlayer _player;
  final String assetPrefix;
  bool _isPlaying = false;
  Completer<void>? _currentPlaybackCompleter;

  /// Creates a [NepaliTTS] instance.
  ///
  /// [assetPrefix] specifies the base asset path for audio files.
  /// Defaults to 'packages/nepali_tts/assets/audio' when used as a dependency,
  /// or 'assets/audio' when used locally.
  NepaliTTS({
    AudioPlayer? player,
    this.assetPrefix = "packages/nepali_tts/assets/audio",
  }) : _player = player ?? AudioPlayer();

  /// Whether audio is currently being played.
  bool get isPlaying => _isPlaying;

  /// Underlying [AudioPlayer] instance.
  AudioPlayer get player => _player;

  /// Speaks the given payment [amount] in Nepali.
  ///
  /// Example:
  /// ```dart
  /// final tts = NepaliTTS();
  /// await tts.speakAmount(1530.30);
  /// ```
  Future<void> speakAmount(
    num amount, {
    NepaliAmountOptions options = const NepaliAmountOptions(),
  }) async {
    final clips = NepaliAmountConverter.toClips(amount, options: options);
    await playClips(clips);
  }

  /// Plays a given sequence of audio clip keys in order without silence.
  Future<void> playClips(List<String> clipKeys) async {
    await stop();

    if (clipKeys.isEmpty) return;

    _isPlaying = true;
    final completer = Completer<void>();
    _currentPlaybackCompleter = completer;

    try {
      for (final key in clipKeys) {
        if (!_isPlaying || completer.isCompleted) break;

        final path = "$assetPrefix/$key.mp3";
        await _player.stop();
        await _player.play(AssetSource(path));
        // Wait for the clip to finish playing
        await _player.onPlayerComplete.first;
      }
    } catch (e) {
      // If package asset path fails (e.g. running inside local package example), try without package prefix
      if (assetPrefix.startsWith("packages/")) {
        final fallbackPrefix = assetPrefix.replaceFirst(RegExp(r"^packages/[^/]+/"), "");
        for (final key in clipKeys) {
          if (!_isPlaying || completer.isCompleted) break;
          final fallbackPath = "$fallbackPrefix/$key.mp3";
          await _player.stop();
          await _player.play(AssetSource(fallbackPath));
          await _player.onPlayerComplete.first;
        }
      } else {
        rethrow;
      }
    } finally {
      _isPlaying = false;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Stops any currently playing audio sequence immediately.
  Future<void> stop() async {
    _isPlaying = false;
    _currentPlaybackCompleter?.complete();
    await _player.stop();
  }

  /// Releases audio player resources.
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
