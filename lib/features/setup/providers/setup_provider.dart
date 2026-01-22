import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/network_service.dart';
import '../data/model_downloader.dart';
import '../data/setup_repository.dart';
import '../domain/setup_state.dart';

/// Provider for the setup state notifier.
final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  final repository = ref.watch(setupRepositoryProvider);
  final downloader = ref.watch(modelDownloaderProvider);
  final networkService = ref.watch(networkServiceProvider);
  return SetupNotifier(repository, downloader, networkService);
});

/// Provider to check if setup is completed (for routing).
final isSetupCompletedProvider = Provider<bool>((ref) {
  final setupState = ref.watch(setupProvider);
  return setupState.currentStep == SetupStep.done;
});

/// Provider to get the current setup step.
final currentSetupStepProvider = Provider<SetupStep>((ref) {
  return ref.watch(setupProvider).currentStep;
});

/// State notifier for managing the setup flow.
class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier(this._repository, this._downloader, this._networkService)
      : super(SetupState.initial()) {
    _initialize();
  }

  final SetupRepository _repository;
  final ModelDownloader _downloader;
  final NetworkService _networkService;
  StreamSubscription<DownloadProgress>? _downloadSubscription;

  /// Initialize the setup state from persisted data.
  void _initialize() {
    final savedState = _repository.loadSetupState();
    final hasPartialDownload =
        savedState.downloadProgress > 0 && savedState.downloadProgress < 1.0;
    final shouldPause =
        savedState.currentStep == SetupStep.downloading && hasPartialDownload;
    final estimatedTotalBytes =
        savedState.downloadProgress > 0 ? ModelDownloader.modelSizeBytes : 0;
    final downloadedBytes =
        (estimatedTotalBytes * savedState.downloadProgress).toInt();
    state = savedState.copyWith(
      isDownloading: false,
      isPaused: shouldPause,
      downloadedBytes: downloadedBytes,
      totalBytes: estimatedTotalBytes,
    );
    _downloader.restoreProgress(
      savedState.downloadProgress,
      isPaused: shouldPause,
    );
    debugPrint('SetupNotifier: Initialized with step ${savedState.currentStep}');
    _syncModelFileStatus();
  }

  Future<void> _syncModelFileStatus() async {
    final isDownloadedOnDisk = await _downloader.isModelDownloaded();
    if (isDownloadedOnDisk) {
      if (!state.isModelDownloaded || state.downloadProgress < 1.0) {
        await _repository.saveModelDownloaded(true);
        await _repository.saveDownloadProgress(1.0);
        state = state.copyWith(
          isModelDownloaded: true,
          downloadProgress: 1.0,
          downloadedBytes: _downloader.downloadedBytes,
          totalBytes: _downloader.totalBytes,
        );
      }
      return;
    }

    if (state.isModelDownloaded) {
      await _repository.saveModelDownloaded(false);
      await _repository.saveDownloadProgress(0.0);
      state = state.copyWith(
        isModelDownloaded: false,
        downloadProgress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
      );
    }
  }

  /// Complete the splash screen and advance to privacy.
  void completeSplash() {
    if (state.currentStep != SetupStep.splash) return;
    
    state = state.copyWith(currentStep: SetupStep.privacy);
    debugPrint('SetupNotifier: Advanced to privacy step');
  }

  /// Accept privacy notice and advance to model setup.
  Future<void> acceptPrivacy() async {
    if (state.currentStep != SetupStep.privacy) return;

    await _repository.savePrivacyAccepted(true);
    state = state.copyWith(
      currentStep: SetupStep.modelSetup,
      isPrivacyAccepted: true,
    );
    debugPrint('SetupNotifier: Privacy accepted, advanced to model setup');
  }

  /// Start model download.
  Future<void> startDownload() async {
    if (state.isModelDownloaded) {
      // Model already downloaded, skip to complete
      state = state.copyWith(currentStep: SetupStep.complete);
      return;
    }

    final onWifi = await _networkService.isWifiConnected();
    if (!onWifi) {
      state = state.copyWith(
        downloadError: AppStrings.errorNoInternet,
        isDownloading: false,
      );
      return;
    }

    state = state.copyWith(
      currentStep: SetupStep.downloading,
      isDownloading: true,
      isPaused: false,
      clearError: true,
    );

    _downloadSubscription?.cancel();
    final progressStream = _downloader.startDownload();
    
    _downloadSubscription = progressStream.listen(
      _onDownloadProgress,
      onError: _onDownloadError,
    );
  }

  /// Handle download progress updates.
  void _onDownloadProgress(DownloadProgress progress) async {
    final fallbackTotal = state.totalBytes > 0
        ? state.totalBytes
        : ModelDownloader.modelSizeBytes;
    final totalBytes = progress.totalBytes > 0 ? progress.totalBytes : fallbackTotal;
    final downloadedBytes = progress.downloadedBytes > 0
        ? progress.downloadedBytes
        : (totalBytes * progress.progress).toInt();

    switch (progress.status) {
      case DownloadStatus.downloading:
        state = state.copyWith(
          downloadProgress: progress.progress,
          isDownloading: true,
          isPaused: false,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
        // Persist progress periodically (every 5%)
        if ((progress.progress * 100).toInt() % 5 == 0) {
          await _repository.saveDownloadProgress(progress.progress);
        }
        break;

      case DownloadStatus.paused:
        state = state.copyWith(
          downloadProgress: progress.progress,
          isDownloading: false,
          isPaused: true,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
        await _repository.saveDownloadProgress(progress.progress);
        break;

      case DownloadStatus.completed:
        await _repository.saveModelDownloaded(true);
        await _repository.saveDownloadProgress(1.0);
        await _repository.saveModelVersion(ModelDownloader.modelVersion);
        state = state.copyWith(
          currentStep: SetupStep.complete,
          downloadProgress: 1.0,
          isModelDownloaded: true,
          isDownloading: false,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
        debugPrint('SetupNotifier: Download completed, advanced to complete step');
        break;

      case DownloadStatus.failed:
        state = state.copyWith(
          downloadError: progress.error ?? 'Download failed',
          isDownloading: false,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
        break;

      case DownloadStatus.idle:
        state = state.copyWith(
          isDownloading: false,
          downloadProgress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
        );
        break;
    }
  }

  /// Handle download errors.
  void _onDownloadError(Object error) {
    state = state.copyWith(
      downloadError: error.toString(),
      isDownloading: false,
    );
    debugPrint('SetupNotifier: Download error: $error');
  }

  /// Pause download.
  void pauseDownload() {
    _downloader.pauseDownload();
  }

  /// Resume download.
  Future<void> resumeDownload() async {
    if (_downloadSubscription == null) {
      await startDownload();
      return;
    }
    _downloader.resumeDownload();
  }

  /// Cancel download.
  void cancelDownload() {
    _downloader.cancelDownload();
    _downloadSubscription?.cancel();
    state = state.copyWith(
      currentStep: SetupStep.modelSetup,
      isDownloading: false,
      downloadProgress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      clearError: true,
    );
    _repository.saveDownloadProgress(0.0);
  }

  /// Retry download after error.
  Future<void> retryDownload() async {
    state = state.copyWith(clearError: true);
    await startDownload();
  }

  /// Skip download for now (can access library but not chat).
  Future<void> skipDownload() async {
    await _repository.saveSetupCompleted(true);
    state = state.copyWith(
      currentStep: SetupStep.done,
      isSetupCompleted: true,
    );
    debugPrint('SetupNotifier: Download skipped, setup marked as done (limited functionality)');
  }

  /// Complete setup and enter main app.
  Future<void> completeSetup() async {
    if (state.currentStep != SetupStep.complete) return;

    await _repository.saveSetupCompleted(true);
    state = state.copyWith(
      currentStep: SetupStep.done,
      isSetupCompleted: true,
    );
    debugPrint('SetupNotifier: Setup completed, entering main app');
  }

  /// Go back to model setup (from download screen).
  void goBackToModelSetup() {
    cancelDownload();
    state = state.copyWith(
      currentStep: SetupStep.modelSetup,
      isDownloading: false,
      clearError: true,
    );
  }

  /// Reset setup (for testing or re-onboarding).
  Future<void> resetSetup() async {
    cancelDownload();
    await _repository.resetSetupState();
    state = SetupState.initial();
    debugPrint('SetupNotifier: Setup reset to initial state');
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _downloader.dispose();
    super.dispose();
  }
}
