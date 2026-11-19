import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Modular, safe Text-to-Speech service wrapping [FlutterTts].
///
/// Features graceful exception handling, conversational speech rate,
/// and automatic female voice selection when supported by the device.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Initializes the TTS engine safely with conversational rate and female voice preference.
  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();

      await _flutterTts?.setLanguage('en-US');
      await _flutterTts?.setSpeechRate(0.53); // Conversational, natural pace
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);

      // Attempt to auto-select a natural female voice if available on the device
      await _applyFemaleVoicePreference();

      _flutterTts?.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts?.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts?.setCancelHandler(() {
        _isPlaying = false;
      });

      _flutterTts?.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('[TtsService] TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] Initialization failed gracefully: $e');
      _isInitialized = false;
    }
  }

  /// Queries system voices and selects the most natural female voice if available.
  Future<void> _applyFemaleVoicePreference() async {
    try {
      final dynamic voicesResult = await _flutterTts?.getVoices;
      if (voicesResult is! List || voicesResult.isEmpty) return;

      Map<String, String>? bestFemaleVoice;

      for (final dynamic v in voicesResult) {
        if (v is Map) {
          final Map<String, String> voiceMap = Map<String, String>.from(
            v.map((key, value) => MapEntry(key.toString(), value.toString())),
          );

          final name = (voiceMap['name'] ?? '').toLowerCase();
          final gender = (voiceMap['gender'] ?? '').toLowerCase();
          final locale = (voiceMap['locale'] ?? voiceMap['language'] ?? '').toLowerCase();

          final isEnglish = locale.contains('en');
          final isFemale = gender.contains('female') ||
              name.contains('female') ||
              name.contains('woman') ||
              name.contains('samantha') ||
              name.contains('victoria') ||
              name.contains('karen') ||
              name.contains('zira') ||
              name.contains('f00') ||
              name.contains('wavenet') ||
              name.contains('neural');

          if (isEnglish && isFemale) {
            bestFemaleVoice = voiceMap;
            // Prefer Neural/Wavenet female voices if present
            if (name.contains('neural') || name.contains('wavenet')) {
              break;
            }
          } else if (isFemale && bestFemaleVoice == null) {
            bestFemaleVoice = voiceMap;
          }
        }
      }

      if (bestFemaleVoice != null) {
        await _flutterTts?.setVoice(bestFemaleVoice);
        debugPrint('[TtsService] Selected female voice: ${bestFemaleVoice['name']}');
      }
    } catch (e) {
      debugPrint('[TtsService] Voice selection preference fallback: $e');
    }
  }

  /// Speaks the provided text aloud.
  /// If already speaking, stops narration first.
  Future<void> speak(String text, {VoidCallback? onStateChanged}) async {
    try {
      await _initTts();
      if (_isPlaying) {
        await stop();
        onStateChanged?.call();
        return;
      }

      if (text.trim().isEmpty) return;

      _isPlaying = true;
      onStateChanged?.call();

      final result = await _flutterTts?.speak(text.trim());
      if (result == 1) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      onStateChanged?.call();
    } catch (e) {
      _isPlaying = false;
      onStateChanged?.call();
      debugPrint('[TtsService] Speak error handled gracefully: $e');
    }
  }

  /// Stops any ongoing narration.
  Future<void> stop({VoidCallback? onStateChanged}) async {
    try {
      if (_flutterTts != null) {
        await _flutterTts?.stop();
      }
    } catch (e) {
      debugPrint('[TtsService] Stop error handled gracefully: $e');
    } finally {
      _isPlaying = false;
      onStateChanged?.call();
    }
  }
}
