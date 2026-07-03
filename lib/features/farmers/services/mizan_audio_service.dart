// filepath: lib/features/farmers/services/mizan_audio_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service to handle Text-to-Speech (TTS) for Mizan PLC Expert Advisors.
/// Supports English and regional Ethiopian languages with strict Markdown filtering.
class MizanAudioService {
  final FlutterTts _tts = FlutterTts();

  // Callbacks used to update the "Speaking..." UI state in MizanExpertAdvisorsPage
  VoidCallback? onStart;
  VoidCallback? onComplete;

  MizanAudioService() {
    _initTts();
  }

  /// Configures the TTS engine for clear, professional agricultural advice.
  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    // 0.45 rate is optimized for technical advice in regional languages
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    // Event handlers to notify the UI when audio starts or stops
    _tts.setStartHandler(() {
      if (onStart != null) {
        onStart!();
      }
    });

    _tts.setCompletionHandler(() {
      if (onComplete != null) {
        onComplete!();
      }
    });

    _tts.setErrorHandler((msg) {
      debugPrint("Mizan TTS Error: $msg");
      if (onComplete != null) {
        onComplete!();
      }
    });
  }

  /// Refined cleaner to remove Markdown visual artifacts while preserving
  /// Ethiopian punctuation (፡ ፣ ። ፤) and sentence structure.
  String _cleanTextForSpeech(String text) {
    return text
        // Remove Markdown bold/italic/headers (***, **, *, #)
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'_+'), '')
        // Replace multiple spaces or newlines with a single space
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Speaks text in the selected language using the appropriate regional locale.
  /// Supported: 'am' (Amharic), 'ti' (Tigrigna), 'om' (Oromo), 'so' (Somali), 'en' (English).
  Future<void> speak(String text, String languageCode) async {
    // Sanitize the text before it reaches the speech engine
    final String cleanText = _cleanTextForSpeech(text);

    if (cleanText.isEmpty) {
      return;
    }

    String ttsLanguage;

    // Map Mizan language codes to System TTS Locales
    switch (languageCode) {
      case 'am':
        ttsLanguage = "am-ET";
        break;
      case 'ti':
        ttsLanguage = "ti-ET";
        break;
      case 'om':
        ttsLanguage = "om-ET";
        break;
      case 'so':
        ttsLanguage = "so-ET";
        break;
      case 'en':
        ttsLanguage = "en-US";
        break;
      default:
        ttsLanguage = "am-ET"; // Default to Amharic for Mizan PLC operations
    }

    try {
      // Check if language is available on the device before attempting to speak
      bool isLanguageAvailable = await _tts.isLanguageAvailable(ttsLanguage);

      if (isLanguageAvailable) {
        await _tts.setLanguage(ttsLanguage);
        await _tts.speak(cleanText);
      } else {
        // Fallback to English if regional voice is not installed
        await _tts.setLanguage("en-US");
        await _tts.speak(cleanText);
      }
    } catch (e) {
      debugPrint("TTS Execution Failed: $e");
      if (onComplete != null) {
        onComplete!();
      }
    }
  }

  /// Stops audio immediately (e.g., when the farmer clicks the STOP button).
  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      if (onComplete != null) {
        onComplete!();
      }
    }
  }
}
