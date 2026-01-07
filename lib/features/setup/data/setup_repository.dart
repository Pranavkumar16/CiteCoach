import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../domain/setup_state.dart';

/// Provider for the setup repository.
final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SetupRepository(storageService);
});

/// Repository for managing setup state persistence.
class SetupRepository {
  const SetupRepository(this._storage);

  final StorageService _storage;

  /// Load the current setup state from storage.
  SetupState loadSetupState() {
    if (!_storage.isReady) {
      return SetupState.initial();
    }

    final isPrivacyAccepted = _storage.isPrivacyAccepted;
    final isModelDownloaded = _storage.isModelDownloaded;
    final isSetupCompleted = _storage.isSetupCompleted;
    final downloadProgress = _storage.modelDownloadProgress;

    // Determine current step based on saved state
    SetupStep currentStep;
    if (isSetupCompleted) {
      currentStep = SetupStep.done;
    } else if (isModelDownloaded) {
      currentStep = SetupStep.complete;
    } else if (isPrivacyAccepted) {
      // Check if download was in progress
      if (downloadProgress > 0 && downloadProgress < 1.0) {
        currentStep = SetupStep.downloading;
      } else {
        currentStep = SetupStep.modelSetup;
      }
    } else {
      currentStep = SetupStep.splash;
    }

    return SetupState(
      currentStep: currentStep,
      isPrivacyAccepted: isPrivacyAccepted,
      isModelDownloaded: isModelDownloaded,
      isSetupCompleted: isSetupCompleted,
      downloadProgress: downloadProgress,
    );
  }

  /// Save privacy acceptance.
  Future<void> savePrivacyAccepted(bool accepted) async {
    await _storage.setPrivacyAccepted(accepted);
  }

  /// Save model download status.
  Future<void> saveModelDownloaded(bool downloaded) async {
    await _storage.setModelDownloaded(downloaded);
  }

  /// Save download progress.
  Future<void> saveDownloadProgress(double progress) async {
    await _storage.setModelDownloadProgress(progress);
  }

  /// Save model version.
  Future<void> saveModelVersion(String version) async {
    await _storage.setModelVersion(version);
  }

  /// Mark setup as completed.
  Future<void> saveSetupCompleted(bool completed) async {
    await _storage.setSetupCompleted(completed);
  }

  /// Reset all setup state (for testing or re-onboarding).
  Future<void> resetSetupState() async {
    await _storage.setPrivacyAccepted(false);
    await _storage.setModelDownloaded(false);
    await _storage.setSetupCompleted(false);
    await _storage.setModelDownloadProgress(0.0);
  }

  /// Check if setup is completed.
  bool get isSetupCompleted => _storage.isSetupCompleted;

  /// Check if privacy is accepted.
  bool get isPrivacyAccepted => _storage.isPrivacyAccepted;

  /// Check if model is downloaded.
  bool get isModelDownloaded => _storage.isModelDownloaded;

  /// Get model version.
  String? get modelVersion => _storage.modelVersion;
}
