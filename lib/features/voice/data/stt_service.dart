import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Provider for the STT service.
final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

/// Callback for speech recognition results.
typedef SttResultCallback = void Function(String text, bool isFinal);

/// Callback for speech recognition errors.
typedef SttErrorCallback = void Function(String error);

/// Callback for sound level changes.
typedef SttSoundLevelCallback = void Function(double level);

/// Service for Speech-to-Text using platform native APIs.
class SttService {
  SttService() : _speech = SpeechToText();

  final SpeechToText _speech;

  SttErrorCallback? _onError;
  String? _initializationError;
  String? get initializationError => _initializationError;
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLocaleId = 'en_US';

  /// Whether the service is initialized and ready.
  bool get isInitialized => _isInitialized;

  /// Whether speech recognition is currently active.
  bool get isListening => _isListening;

  /// Available locales for speech recognition.
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }

  /// Current locale ID.
  String get currentLocaleId => _currentLocaleId;

  /// Initialize the speech recognition service.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('SttService: Initializing...');

      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        _initializationError = null;
        // Get system locale
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null) {
          _currentLocaleId = systemLocale.localeId;
        }
        debugPrint('SttService: Initialized with locale: $_currentLocaleId');
      } else {
        _initializationError ??=
            'Allow microphone access and enable your phone’s speech recognition service in Settings. You can still type your question.';
        debugPrint('SttService: Failed to initialize');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('SttService: Initialization error: $e');
      return false;
    }
  }

  /// Start listening for speech.
  Future<bool> startListening({
    required SttResultCallback onResult,
    SttErrorCallback? onError,
    SttSoundLevelCallback? onSoundLevel,
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    _onError = onError;
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call(
          _initializationError ??
              'Voice input is unavailable. You can still type your question.',
        );
        return false;
      }
    }

    if (_isListening) {
      debugPrint('SttService: Already listening');
      return true;
    }

    try {
      debugPrint('SttService: Starting to listen...');

      _isListening = true;

      await _speech.listen(
        onResult: (result) => _handleResult(result, onResult),
        onSoundLevelChange: onSoundLevel,
        localeId: localeId ?? _currentLocaleId,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('SttService: Listen error: $e');
      _isListening = false;
      onError?.call(
        'Could not start voice input. Check microphone access in phone Settings.',
      );
      return false;
    }
  }

  /// Stop listening for speech.
  Future<void> stopListening() async {
    if (!_isListening) return;

    debugPrint('SttService: Stopping...');

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('SttService: Stop error: $e');
    } finally {
      _isListening = false;
    }
  }

  /// Cancel the current listening session.
  Future<void> cancelListening() async {
    if (!_isListening) return;

    debugPrint('SttService: Cancelling...');

    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('SttService: Cancel error: $e');
    } finally {
      _isListening = false;
    }
  }

  /// Set the locale for speech recognition.
  void setLocale(String localeId) {
    _currentLocaleId = localeId;
    debugPrint('SttService: Locale set to: $localeId');
  }

  /// Handle speech recognition results.
  void _handleResult(
    SpeechRecognitionResult result,
    SttResultCallback callback,
  ) {
    debugPrint(
      'SttService: Result: "${result.recognizedWords}" (final: ${result.finalResult})',
    );
    callback(result.recognizedWords, result.finalResult);

    if (result.finalResult) {
      _isListening = false;
    }
  }

  /// Handle speech recognition errors.
  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      'SttService: Error: ${error.errorMsg} (permanent: ${error.permanent})',
    );

    final message = error.errorMsg.contains('permission')
        ? 'Allow microphone access for CiteCoach in your phone Settings.'
        : error.errorMsg.contains('network')
        ? 'Your phone’s speech service needs a connection. You can still type your question.'
        : error.errorMsg.contains('no_match') ||
              error.errorMsg.contains('speech_timeout')
        ? 'No speech was detected. Tap the microphone to try again, or type your question.'
        : 'Voice input stopped. Try again or type your question.';
    _initializationError = message;
    _onError?.call(message);
    if (error.permanent) {
      _isListening = false;
    }
  }

  /// Handle speech recognition status changes.
  void _handleStatus(String status) {
    debugPrint('SttService: Status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Check if speech recognition is available on this device.
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized && _speech.isAvailable;
  }

  /// Dispose of resources.
  void dispose() {
    if (_isListening) {
      _speech.cancel();
    }
    _isListening = false;
    _onError = null;
    debugPrint('SttService: Disposed');
  }
}
