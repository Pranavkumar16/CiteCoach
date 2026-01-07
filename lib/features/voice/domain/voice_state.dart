import 'package:equatable/equatable.dart';

/// Voice input/output mode.
enum VoiceMode {
  /// Idle - not listening or speaking.
  idle,

  /// Listening for user speech.
  listening,

  /// Processing the transcribed text.
  processing,

  /// Speaking the response.
  speaking,

  /// Error state.
  error,
}

/// State for voice interactions.
class VoiceState extends Equatable {
  const VoiceState({
    this.mode = VoiceMode.idle,
    this.transcribedText = '',
    this.partialText = '',
    this.soundLevel = 0.0,
    this.responseText = '',
    this.speakingProgress = 0.0,
    this.error,
    this.isSttAvailable = false,
    this.isTtsAvailable = false,
    this.autoSpeak = true,
  });

  /// Current voice mode.
  final VoiceMode mode;

  /// Final transcribed text from STT.
  final String transcribedText;

  /// Partial (interim) transcribed text.
  final String partialText;

  /// Current sound level (0.0 to 1.0) for waveform visualization.
  final double soundLevel;

  /// Response text being spoken.
  final String responseText;

  /// Speaking progress (0.0 to 1.0).
  final double speakingProgress;

  /// Error message if in error state.
  final String? error;

  /// Whether STT is available on this device.
  final bool isSttAvailable;

  /// Whether TTS is available on this device.
  final bool isTtsAvailable;

  /// Whether to automatically speak responses.
  final bool autoSpeak;

  /// Whether currently listening.
  bool get isListening => mode == VoiceMode.listening;

  /// Whether currently speaking.
  bool get isSpeaking => mode == VoiceMode.speaking;

  /// Whether processing.
  bool get isProcessing => mode == VoiceMode.processing;

  /// Whether idle.
  bool get isIdle => mode == VoiceMode.idle;

  /// Whether in error state.
  bool get hasError => mode == VoiceMode.error || error != null;

  /// The current display text (partial or final).
  String get displayText => 
      partialText.isNotEmpty ? partialText : transcribedText;

  /// Whether voice features are available.
  bool get isVoiceAvailable => isSttAvailable || isTtsAvailable;

  /// Copy with updated fields.
  VoiceState copyWith({
    VoiceMode? mode,
    String? transcribedText,
    String? partialText,
    double? soundLevel,
    String? responseText,
    double? speakingProgress,
    String? error,
    bool? isSttAvailable,
    bool? isTtsAvailable,
    bool? autoSpeak,
    bool clearError = false,
    bool clearText = false,
  }) {
    return VoiceState(
      mode: mode ?? this.mode,
      transcribedText: clearText ? '' : (transcribedText ?? this.transcribedText),
      partialText: clearText ? '' : (partialText ?? this.partialText),
      soundLevel: soundLevel ?? this.soundLevel,
      responseText: clearText ? '' : (responseText ?? this.responseText),
      speakingProgress: speakingProgress ?? this.speakingProgress,
      error: clearError ? null : (error ?? this.error),
      isSttAvailable: isSttAvailable ?? this.isSttAvailable,
      isTtsAvailable: isTtsAvailable ?? this.isTtsAvailable,
      autoSpeak: autoSpeak ?? this.autoSpeak,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        transcribedText,
        partialText,
        soundLevel,
        responseText,
        speakingProgress,
        error,
        isSttAvailable,
        isTtsAvailable,
        autoSpeak,
      ];
}
