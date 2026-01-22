import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Provider for the TTS service.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Callback for TTS progress updates.
typedef TtsProgressCallback = void Function(String text, int start, int end);

/// Callback for TTS completion.
typedef TtsCompletionCallback = void Function();

/// Callback for TTS errors.
typedef TtsErrorCallback = void Function(String error);

/// TTS speaking state.
enum TtsState {
  stopped,
  playing,
  paused,
}

/// Service for Text-to-Speech using platform native APIs.
class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;

  bool _isInitialized = false;
  TtsState _state = TtsState.stopped;
  
  // Settings
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String _language = 'en-US';
  // ignore: unused_field
  String? _voice;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Current TTS state.
  TtsState get state => _state;

  /// Whether TTS is currently speaking.
  bool get isSpeaking => _state == TtsState.playing;

  /// Current volume (0.0 to 1.0).
  double get volume => _volume;

  /// Current pitch (0.5 to 2.0).
  double get pitch => _pitch;

  /// Current speech rate (0.0 to 1.0).
  double get speechRate => _speechRate;

  /// Current language.
  String get language => _language;

  /// Initialize the TTS service.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('TtsService: Initializing...');

      // Set up handlers
      _tts.setStartHandler(() {
        debugPrint('TtsService: Started speaking');
        _state = TtsState.playing;
      });

      _tts.setCompletionHandler(() {
        debugPrint('TtsService: Completed speaking');
        _state = TtsState.stopped;
      });

      _tts.setCancelHandler(() {
        debugPrint('TtsService: Cancelled');
        _state = TtsState.stopped;
      });

      _tts.setPauseHandler(() {
        debugPrint('TtsService: Paused');
        _state = TtsState.paused;
      });

      _tts.setContinueHandler(() {
        debugPrint('TtsService: Continued');
        _state = TtsState.playing;
      });

      _tts.setErrorHandler((error) {
        debugPrint('TtsService: Error: $error');
        _state = TtsState.stopped;
      });

      // Apply default settings
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setLanguage(_language);

      // iOS specific settings
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _isInitialized = true;
      debugPrint('TtsService: Initialized');
      return true;
    } catch (e) {
      debugPrint('TtsService: Initialization error: $e');
      return false;
    }
  }

  /// Speak the given text.
  Future<bool> speak(
    String text, {
    TtsCompletionCallback? onComplete,
    TtsErrorCallback? onError,
    TtsProgressCallback? onProgress,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('TTS not available');
        return false;
      }
    }

    if (text.trim().isEmpty) {
      onError?.call('No text to speak');
      return false;
    }

    try {
      debugPrint('TtsService: Speaking: "${text.substring(0, text.length.clamp(0, 50))}..."');

      // Set up progress callback if provided
      if (onProgress != null) {
        _tts.setProgressHandler((text, start, end, word) {
          onProgress(text, start, end);
        });
      }

      // Set up completion callback
      if (onComplete != null) {
        _tts.setCompletionHandler(() {
          _state = TtsState.stopped;
          onComplete();
        });
      }

      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      debugPrint('TtsService: Speak error: $e');
      onError?.call('Failed to speak: ${e.toString()}');
      return false;
    }
  }

  /// Stop speaking.
  Future<void> stop() async {
    if (_state == TtsState.stopped) return;

    try {
      await _tts.stop();
      _state = TtsState.stopped;
    } catch (e) {
      debugPrint('TtsService: Stop error: $e');
    }
  }

  /// Pause speaking (iOS only).
  Future<void> pause() async {
    if (_state != TtsState.playing) return;

    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('TtsService: Pause error: $e');
    }
  }

  /// Set the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }

  /// Set the pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }

  /// Set the speech rate (0.0 to 1.0).
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Set the language.
  Future<void> setLanguage(String language) async {
    _language = language;
    await _tts.setLanguage(_language);
  }

  /// Set the voice.
  Future<void> setVoice(String voice) async {
    _voice = voice;
    await _tts.setVoice({'name': voice, 'locale': _language});
  }

  /// Get available languages.
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await initialize();
    
    final languages = await _tts.getLanguages;
    return languages.cast<String>();
  }

  /// Get available voices.
  Future<List<Map<String, String>>> getVoices() async {
    if (!_isInitialized) await initialize();
    
    final voices = await _tts.getVoices;
    return voices.cast<Map<String, String>>();
  }

  /// Check if a language is available.
  Future<bool> isLanguageAvailable(String language) async {
    if (!_isInitialized) await initialize();
    
    final result = await _tts.isLanguageAvailable(language);
    return result == 1;
  }

  /// Dispose of resources.
  void dispose() {
    stop();
    debugPrint('TtsService: Disposed');
  }
}
