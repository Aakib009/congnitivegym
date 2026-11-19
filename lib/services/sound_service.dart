import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Centralized service for low-volume, calming, non-intrusive sound effects
/// and tactile feedback across Cognitive Gym.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool isSoundEnabled = true;

  Future<void> _safeHaptic(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  /// Plays a soft, minimal tap sound for standard button presses.
  Future<void> playSoftTap() async {
    await _safeHaptic(HapticFeedback.selectionClick);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [440.0],
      durationMs: 35,
      maxVolume: 0.08,
    );
    await _playBytes(bytes);
  }

  /// Alias for soft pop/tap interaction feedback.
  Future<void> playPop() => playSoftTap();

  /// Plays a standard tap sound for interactive chips, buttons, and navigation cards.
  Future<void> playTap() => playSoftTap();

  /// Plays a soft click sound for card interactions and topic selections.
  Future<void> playCardClick() async {
    await _safeHaptic(HapticFeedback.selectionClick);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [520.0],
      durationMs: 30,
      maxVolume: 0.07,
    );
    await _playBytes(bytes);
  }

  /// Plays a soft dual-tone navigation sound when entering cognitive modules.
  Future<void> playNavigation() async {
    await _safeHaptic(HapticFeedback.lightImpact);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [523.25, 659.25], // C5 -> E5
      durationMs: 70,
      maxVolume: 0.10,
    );
    await _playBytes(bytes);
  }

  /// Plays a gentle sound when opening or closing the navigation drawer.
  Future<void> playDrawerToggle() async {
    await _safeHaptic(HapticFeedback.lightImpact);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [360.0, 300.0],
      durationMs: 50,
      maxVolume: 0.07,
    );
    await _playBytes(bytes);
  }

  /// Plays a gentle confirmation chime upon completing a cognitive exercise.
  Future<void> playConfirmation() async {
    await _safeHaptic(HapticFeedback.mediumImpact);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [523.25, 659.25, 783.99], // C5 -> E5 -> G5
      durationMs: 140,
      maxVolume: 0.12,
    );
    await _playBytes(bytes);
  }

  /// Plays a pleasant, small success sound when Logic/XP points are awarded.
  Future<void> playRewardSuccess() async {
    await _safeHaptic(HapticFeedback.mediumImpact);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [523.25, 659.25, 783.99],
      durationMs: 180,
      maxVolume: 0.12,
    );
    await _playBytes(bytes);
  }

  /// Plays a peaceful, harmonic level-up chime celebration.
  Future<void> playLevelUp() async {
    await _safeHaptic(HapticFeedback.heavyImpact);
    if (!isSoundEnabled) return;

    final bytes = _generateSoftWav(
      frequencies: [523.25, 659.25, 783.99, 1046.50], // C5, E5, G5, C6
      durationMs: 320,
      maxVolume: 0.15,
    );
    await _playBytes(bytes);
  }

  /// Plays synthesized WAV bytes using AudioPlayer with safe fallback.
  Future<void> _playBytes(Uint8List bytes) async {
    try {
      await _player.stop().catchError((_) {});
      await _player.play(BytesSource(bytes)).catchError((_) {});
    } catch (_) {
      // Audio playback fails gracefully if audio device is unavailable or in test environment
    }
  }

  /// Generates a smooth, 16-bit mono 44100Hz WAV byte array in memory.
  Uint8List _generateSoftWav({
    required List<double> frequencies,
    required int durationMs,
    required double maxVolume,
  }) {
    const sampleRate = 44100;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).round();
    final dataSize = totalSamples * 2; // 16-bit = 2 bytes per sample
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF Header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size
    buffer.setUint16(20, 1, Endian.little); // AudioFormat PCM
    buffer.setUint16(22, 1, Endian.little); // NumChannels Mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little); // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Audio sample synthesis with smooth exponential attack and decay
    final attackSamples = (totalSamples * 0.1).round().clamp(1, totalSamples);
    final noteLength = totalSamples / frequencies.length;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      // Select active frequency based on sequence index
      final freqIndex = (i / noteLength).floor().clamp(0, frequencies.length - 1);
      final freq = frequencies[freqIndex];

      // Pure sine wave sample
      double sampleValue = math.sin(2 * math.pi * freq * t);

      // Envelope modulation: smooth attack & exponential decay
      double envelope = 1.0;
      if (i < attackSamples) {
        envelope = i / attackSamples;
      } else {
        envelope = math.exp(-4.0 * (i - attackSamples) / (totalSamples - attackSamples));
      }

      final sample = (sampleValue * envelope * maxVolume * 32767.0).round().clamp(-32768, 32767);
      buffer.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
