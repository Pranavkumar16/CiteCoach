import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Provider for the storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
    data: (prefs) => prefs,
    orElse: () => null,
  );
  return StorageService(prefs);
});

/// Keys for stored values.
abstract final class StorageKeys {
  // Setup state
  static const String setupCompleted = 'setup_completed';
  static const String privacyAccepted = 'privacy_accepted';
  static const String modelDownloaded = 'model_downloaded';
  static const String modelDownloadProgress = 'model_download_progress';
  static const String modelVersion = 'model_version';

  // Settings
  static const String lowPowerMode = 'low_power_mode';
  static const String speechSpeed = 'speech_speed';
  static const String hapticFeedback = 'haptic_feedback';

  // App state
  static const String lastOpenedDocumentId = 'last_opened_document_id';
  static const String onboardingVersion = 'onboarding_version';
  static const String appLaunchCount = 'app_launch_count';
  static const String firstLaunchDate = 'first_launch_date';

  // Cache settings
  static const String cacheEnabled = 'cache_enabled';
  static const String cacheSizeMb = 'cache_size_mb';
}

/// Service for managing persistent key-value storage.
/// 
/// Used for:
/// - Setup state (privacy accepted, model downloaded)
/// - User settings (low power mode, speech speed)
/// - App state (last opened document, launch count)
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences? _prefs;

  /// Check if preferences are available.
  bool get isReady => _prefs != null;

  // ============================================
  // Setup State
  // ============================================

  /// Check if initial setup has been completed.
  bool get isSetupCompleted {
    return _prefs?.getBool(StorageKeys.setupCompleted) ?? false;
  }

  /// Mark setup as completed.
  Future<bool> setSetupCompleted(bool value) async {
    return _prefs?.setBool(StorageKeys.setupCompleted, value) ?? Future.value(false);
  }

  /// Check if privacy screen has been accepted.
  bool get isPrivacyAccepted {
    return _prefs?.getBool(StorageKeys.privacyAccepted) ?? false;
  }

  /// Mark privacy as accepted.
  Future<bool> setPrivacyAccepted(bool value) async {
    return _prefs?.setBool(StorageKeys.privacyAccepted, value) ?? Future.value(false);
  }

  /// Check if the model has been downloaded.
  bool get isModelDownloaded {
    return _prefs?.getBool(StorageKeys.modelDownloaded) ?? false;
  }

  /// Mark model as downloaded.
  Future<bool> setModelDownloaded(bool value) async {
    return _prefs?.setBool(StorageKeys.modelDownloaded, value) ?? Future.value(false);
  }

  /// Get model download progress (0.0 to 1.0).
  double get modelDownloadProgress {
    return _prefs?.getDouble(StorageKeys.modelDownloadProgress) ?? 0.0;
  }

  /// Set model download progress.
  Future<bool> setModelDownloadProgress(double progress) async {
    return _prefs?.setDouble(StorageKeys.modelDownloadProgress, progress) ?? Future.value(false);
  }

  /// Get downloaded model version.
  String? get modelVersion {
    return _prefs?.getString(StorageKeys.modelVersion);
  }

  /// Set model version.
  Future<bool> setModelVersion(String version) async {
    return _prefs?.setString(StorageKeys.modelVersion, version) ?? Future.value(false);
  }

  // ============================================
  // Settings
  // ============================================

  /// Check if low power mode is enabled.
  bool get isLowPowerMode {
    return _prefs?.getBool(StorageKeys.lowPowerMode) ?? false;
  }

  /// Set low power mode.
  Future<bool> setLowPowerMode(bool value) async {
    return _prefs?.setBool(StorageKeys.lowPowerMode, value) ?? Future.value(false);
  }

  /// Get speech speed multiplier (0.5 to 2.0).
  double get speechSpeed {
    return _prefs?.getDouble(StorageKeys.speechSpeed) ?? 1.0;
  }

  /// Set speech speed.
  Future<bool> setSpeechSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    return _prefs?.setDouble(StorageKeys.speechSpeed, clampedSpeed) ?? Future.value(false);
  }

  /// Check if haptic feedback is enabled.
  bool get isHapticFeedback {
    return _prefs?.getBool(StorageKeys.hapticFeedback) ?? true;
  }

  /// Set haptic feedback.
  Future<bool> setHapticFeedback(bool value) async {
    return _prefs?.setBool(StorageKeys.hapticFeedback, value) ?? Future.value(false);
  }

  // ============================================
  // App State
  // ============================================

  /// Get the last opened document ID.
  int? get lastOpenedDocumentId {
    return _prefs?.getInt(StorageKeys.lastOpenedDocumentId);
  }

  /// Set the last opened document ID.
  Future<bool> setLastOpenedDocumentId(int? id) async {
    if (id == null) {
      return _prefs?.remove(StorageKeys.lastOpenedDocumentId) ?? Future.value(false);
    }
    return _prefs?.setInt(StorageKeys.lastOpenedDocumentId, id) ?? Future.value(false);
  }

  /// Get app launch count.
  int get appLaunchCount {
    return _prefs?.getInt(StorageKeys.appLaunchCount) ?? 0;
  }

  /// Increment app launch count.
  Future<bool> incrementAppLaunchCount() async {
    final count = appLaunchCount + 1;
    return _prefs?.setInt(StorageKeys.appLaunchCount, count) ?? Future.value(false);
  }

  /// Get first launch date.
  DateTime? get firstLaunchDate {
    final timestamp = _prefs?.getString(StorageKeys.firstLaunchDate);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Set first launch date (only if not already set).
  Future<bool> setFirstLaunchDateIfNeeded() async {
    if (firstLaunchDate != null) return true;
    return _prefs?.setString(
      StorageKeys.firstLaunchDate,
      DateTime.now().toIso8601String(),
    ) ?? Future.value(false);
  }

  // ============================================
  // Cache Settings
  // ============================================

  /// Check if Q&A caching is enabled.
  bool get isCacheEnabled {
    return _prefs?.getBool(StorageKeys.cacheEnabled) ?? true;
  }

  /// Set cache enabled.
  Future<bool> setCacheEnabled(bool value) async {
    return _prefs?.setBool(StorageKeys.cacheEnabled, value) ?? Future.value(false);
  }

  /// Get max cache size in MB.
  int get cacheSizeMb {
    return _prefs?.getInt(StorageKeys.cacheSizeMb) ?? 50;
  }

  /// Set max cache size.
  Future<bool> setCacheSizeMb(int sizeMb) async {
    return _prefs?.setInt(StorageKeys.cacheSizeMb, sizeMb) ?? Future.value(false);
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Clear all stored data (for testing or reset).
  Future<bool> clear() async {
    return _prefs?.clear() ?? Future.value(false);
  }

  /// Remove a specific key.
  Future<bool> remove(String key) async {
    return _prefs?.remove(key) ?? Future.value(false);
  }

  /// Check if a key exists.
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// Get all keys.
  Set<String> get keys {
    return _prefs?.getKeys() ?? {};
  }
}

/// Extension for easier access to setup state.
extension SetupStateExtension on StorageService {
  /// Check if user can access main app (model may not be downloaded).
  bool get canAccessLibrary {
    return isPrivacyAccepted;
  }

  /// Check if chat is available (model must be downloaded).
  bool get canUseChat {
    return isModelDownloaded;
  }
}
