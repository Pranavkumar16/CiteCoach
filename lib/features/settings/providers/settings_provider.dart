import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../voice/data/tts_service.dart';

/// State for user settings.
class SettingsState extends Equatable {
  const SettingsState({
    this.lowPowerMode = false,
    this.speechSpeed = 1.0,
    this.hapticFeedback = true,
    this.cacheEnabled = true,
    this.cacheSizeMb = 50,
  });

  final bool lowPowerMode;
  final double speechSpeed;
  final bool hapticFeedback;
  final bool cacheEnabled;
  final int cacheSizeMb;

  SettingsState copyWith({
    bool? lowPowerMode,
    double? speechSpeed,
    bool? hapticFeedback,
    bool? cacheEnabled,
    int? cacheSizeMb,
  }) {
    return SettingsState(
      lowPowerMode: lowPowerMode ?? this.lowPowerMode,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
    );
  }

  @override
  List<Object?> get props => [
        lowPowerMode,
        speechSpeed,
        hapticFeedback,
        cacheEnabled,
        cacheSizeMb,
      ];
}

/// Provider for settings state.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return SettingsNotifier(storage, ttsService);
});

/// Manages settings persistence and side effects.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage, this._ttsService)
      : super(const SettingsState()) {
    _load();
  }

  final StorageService _storage;
  final TtsService _ttsService;

  Future<void> _load() async {
    if (!_storage.isReady) return;

    final speechSpeed = _storage.speechSpeed;
    state = state.copyWith(
      lowPowerMode: _storage.isLowPowerMode,
      speechSpeed: speechSpeed,
      hapticFeedback: _storage.isHapticFeedback,
      cacheEnabled: _storage.isCacheEnabled,
      cacheSizeMb: _storage.cacheSizeMb,
    );

    await _applySpeechRate(speechSpeed);
  }

  Future<void> setLowPowerMode(bool value) async {
    state = state.copyWith(lowPowerMode: value);
    await _storage.setLowPowerMode(value);
  }

  void previewSpeechSpeed(double speed) {
    state = state.copyWith(speechSpeed: _clampSpeechSpeed(speed));
  }

  Future<void> setSpeechSpeed(double speed) async {
    final clamped = _clampSpeechSpeed(speed);
    state = state.copyWith(speechSpeed: clamped);
    await _storage.setSpeechSpeed(clamped);
    await _applySpeechRate(clamped);
  }

  Future<void> setHapticFeedback(bool value) async {
    state = state.copyWith(hapticFeedback: value);
    await _storage.setHapticFeedback(value);
  }

  Future<void> setCacheEnabled(bool value) async {
    state = state.copyWith(cacheEnabled: value);
    await _storage.setCacheEnabled(value);
  }

  Future<void> setCacheSizeMb(int sizeMb) async {
    state = state.copyWith(cacheSizeMb: sizeMb);
    await _storage.setCacheSizeMb(sizeMb);
  }

  Future<void> _applySpeechRate(double speed) async {
    await _ttsService.initialize();
    await _ttsService.setSpeechRate(_mapSpeedToRate(speed));
  }

  double _mapSpeedToRate(double speed) {
    return (speed / 2.0).clamp(0.0, 1.0);
  }

  double _clampSpeechSpeed(double speed) {
    return speed.clamp(0.5, 2.0);
  }
}
