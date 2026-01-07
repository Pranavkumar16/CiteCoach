import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stt_service.dart';
import '../data/tts_service.dart';
import '../domain/voice_state.dart';

/// Provider for voice state management.
final voiceProvider =
    StateNotifierProvider.autoDispose<VoiceNotifier, VoiceState>((ref) {
  final sttService = ref.watch(sttServiceProvider);
  final ttsService = ref.watch(ttsServiceProvider);

  final notifier = VoiceNotifier(
    sttService: sttService,
    ttsService: ttsService,
  );

  ref.onDispose(() {
    notifier.dispose();
  });

  return notifier;
});

/// Callback when voice input is complete.
typedef VoiceInputCallback = void Function(String text);

/// Notifier for managing voice state.
class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier({
    required SttService sttService,
    required TtsService ttsService,
  })  : _sttService = sttService,
        _ttsService = ttsService,
        super(const VoiceState()) {
    _initialize();
  }

  final SttService _sttService;
  final TtsService _ttsService;

  VoiceInputCallback? _onInputComplete;

  /// Initialize voice services.
  Future<void> _initialize() async {
    debugPrint('VoiceNotifier: Initializing...');

    final sttAvailable = await _sttService.initialize();
    final ttsAvailable = await _ttsService.initialize();

    state = state.copyWith(
      isSttAvailable: sttAvailable,
      isTtsAvailable: ttsAvailable,
    );

    debugPrint('VoiceNotifier: STT available: $sttAvailable, TTS available: $ttsAvailable');
  }

  /// Start listening for voice input.
  Future<void> startListening({VoiceInputCallback? onComplete}) async {
    if (!state.isSttAvailable) {
      state = state.copyWith(
        mode: VoiceMode.error,
        error: 'Speech recognition is not available',
      );
      return;
    }

    if (state.isListening) return;

    _onInputComplete = onComplete;

    // Stop any ongoing TTS
    if (state.isSpeaking) {
      await _ttsService.stop();
    }

    state = state.copyWith(
      mode: VoiceMode.listening,
      clearText: true,
      clearError: true,
    );

    final success = await _sttService.startListening(
      onResult: _handleSttResult,
      onError: _handleSttError,
      onSoundLevel: _handleSoundLevel,
    );

    if (!success) {
      state = state.copyWith(
        mode: VoiceMode.error,
        error: 'Failed to start listening',
      );
    }
  }

  /// Stop listening for voice input.
  Future<void> stopListening() async {
    if (!state.isListening) return;

    await _sttService.stopListening();

    // If we have transcribed text, transition to processing
    if (state.transcribedText.isNotEmpty) {
      _completeInput(state.transcribedText);
    } else if (state.partialText.isNotEmpty) {
      // Use partial text if no final result
      _completeInput(state.partialText);
    } else {
      state = state.copyWith(
        mode: VoiceMode.idle,
        soundLevel: 0.0,
      );
    }
  }

  /// Cancel listening without processing.
  Future<void> cancelListening() async {
    await _sttService.cancelListening();

    state = state.copyWith(
      mode: VoiceMode.idle,
      clearText: true,
      soundLevel: 0.0,
    );

    _onInputComplete = null;
  }

  /// Complete the voice input and notify callback.
  void _completeInput(String text) {
    debugPrint('VoiceNotifier: Input complete: "$text"');

    state = state.copyWith(
      mode: VoiceMode.processing,
      transcribedText: text,
      partialText: '',
      soundLevel: 0.0,
    );

    _onInputComplete?.call(text);
    _onInputComplete = null;

    // Transition to idle after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state.mode == VoiceMode.processing) {
        state = state.copyWith(mode: VoiceMode.idle);
      }
    });
  }

  /// Speak the given text.
  Future<void> speak(String text) async {
    if (!state.isTtsAvailable) {
      debugPrint('VoiceNotifier: TTS not available');
      return;
    }

    if (text.trim().isEmpty) return;

    // Stop any ongoing listening
    if (state.isListening) {
      await _sttService.cancelListening();
    }

    state = state.copyWith(
      mode: VoiceMode.speaking,
      responseText: text,
      speakingProgress: 0.0,
    );

    await _ttsService.speak(
      text,
      onComplete: () {
        state = state.copyWith(
          mode: VoiceMode.idle,
          speakingProgress: 1.0,
        );
      },
      onError: (error) {
        state = state.copyWith(
          mode: VoiceMode.error,
          error: error,
        );
      },
      onProgress: (_, start, end) {
        if (text.isNotEmpty) {
          state = state.copyWith(
            speakingProgress: end / text.length,
          );
        }
      },
    );
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    if (!state.isSpeaking) return;

    await _ttsService.stop();

    state = state.copyWith(
      mode: VoiceMode.idle,
    );
  }

  /// Toggle auto-speak setting.
  void toggleAutoSpeak() {
    state = state.copyWith(autoSpeak: !state.autoSpeak);
  }

  /// Clear any error.
  void clearError() {
    state = state.copyWith(clearError: true);
    if (state.mode == VoiceMode.error) {
      state = state.copyWith(mode: VoiceMode.idle);
    }
  }

  /// Reset to idle state.
  void reset() {
    if (state.isListening) {
      _sttService.cancelListening();
    }
    if (state.isSpeaking) {
      _ttsService.stop();
    }

    state = state.copyWith(
      mode: VoiceMode.idle,
      clearText: true,
      clearError: true,
      soundLevel: 0.0,
      speakingProgress: 0.0,
    );

    _onInputComplete = null;
  }

  /// Handle STT results.
  void _handleSttResult(String text, bool isFinal) {
    if (isFinal) {
      state = state.copyWith(
        transcribedText: text,
        partialText: '',
      );
      _completeInput(text);
    } else {
      state = state.copyWith(
        partialText: text,
      );
    }
  }

  /// Handle STT errors.
  void _handleSttError(String error) {
    debugPrint('VoiceNotifier: STT error: $error');
    state = state.copyWith(
      mode: VoiceMode.error,
      error: error,
      soundLevel: 0.0,
    );
  }

  /// Handle sound level changes.
  void _handleSoundLevel(double level) {
    // Normalize level to 0.0 - 1.0
    // Sound levels from speech_to_text can range from -2 to 10 dB
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
    state = state.copyWith(soundLevel: normalized);
  }

  /// Dispose of resources.
  @override
  void dispose() {
    _sttService.dispose();
    _ttsService.dispose();
    _onInputComplete = null;
    super.dispose();
  }
}
