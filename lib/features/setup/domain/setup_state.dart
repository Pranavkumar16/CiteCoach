import 'package:equatable/equatable.dart';

/// Represents the current state of the app setup process.
class SetupState extends Equatable {
  const SetupState({
    required this.currentStep,
    this.isPrivacyAccepted = false,
    this.isModelDownloaded = false,
    this.isSetupCompleted = false,
    this.downloadProgress = 0.0,
    this.downloadError,
    this.isDownloading = false,
    this.isPaused = false,
  });

  /// The current step in the setup flow.
  final SetupStep currentStep;

  /// Whether the user has accepted the privacy notice.
  final bool isPrivacyAccepted;

  /// Whether the AI model has been downloaded.
  final bool isModelDownloaded;

  /// Whether the entire setup process is completed.
  final bool isSetupCompleted;

  /// Download progress (0.0 to 1.0).
  final double downloadProgress;

  /// Error message if download failed.
  final String? downloadError;

  /// Whether a download is currently in progress.
  final bool isDownloading;

  /// Whether the download is paused.
  final bool isPaused;

  /// Initial state when app first launches.
  factory SetupState.initial() {
    return const SetupState(currentStep: SetupStep.splash);
  }

  /// State when setup is already completed (returning user).
  factory SetupState.completed() {
    return const SetupState(
      currentStep: SetupStep.done,
      isPrivacyAccepted: true,
      isModelDownloaded: true,
      isSetupCompleted: true,
    );
  }

  /// Check if the user can proceed to the library (privacy accepted).
  bool get canAccessLibrary => isPrivacyAccepted;

  /// Check if chat functionality is available (model downloaded).
  bool get canUseChat => isModelDownloaded;

  /// Check if download can be started or resumed.
  bool get canStartDownload => !isDownloading && !isModelDownloaded;

  /// Check if there's a download error.
  bool get hasError => downloadError != null;

  /// Get download progress as percentage string.
  String get downloadProgressPercent => '${(downloadProgress * 100).toInt()}%';

  /// Get downloaded size in MB (assuming 1.5GB total).
  String get downloadedSizeMb {
    final downloadedMb = (downloadProgress * 1500).toInt();
    return '$downloadedMb MB';
  }

  /// Copy with updated fields.
  SetupState copyWith({
    SetupStep? currentStep,
    bool? isPrivacyAccepted,
    bool? isModelDownloaded,
    bool? isSetupCompleted,
    double? downloadProgress,
    String? downloadError,
    bool clearError = false,
    bool? isDownloading,
    bool? isPaused,
  }) {
    return SetupState(
      currentStep: currentStep ?? this.currentStep,
      isPrivacyAccepted: isPrivacyAccepted ?? this.isPrivacyAccepted,
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadError: clearError ? null : (downloadError ?? this.downloadError),
      isDownloading: isDownloading ?? this.isDownloading,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isPrivacyAccepted,
        isModelDownloaded,
        isSetupCompleted,
        downloadProgress,
        downloadError,
        isDownloading,
        isPaused,
      ];
}

/// Steps in the setup flow.
enum SetupStep {
  /// Initial splash screen (auto-advances after animation).
  splash,

  /// Privacy notice screen.
  privacy,

  /// Model download explanation screen.
  modelSetup,

  /// Download progress screen.
  downloading,

  /// Setup complete celebration screen.
  complete,

  /// Setup is done, user should be in main app.
  done,
}

/// Extension methods for SetupStep.
extension SetupStepExtension on SetupStep {
  /// Get the route path for this step.
  String get routePath {
    switch (this) {
      case SetupStep.splash:
        return '/';
      case SetupStep.privacy:
        return '/setup/privacy';
      case SetupStep.modelSetup:
        return '/setup/model';
      case SetupStep.downloading:
        return '/setup/download';
      case SetupStep.complete:
        return '/setup/complete';
      case SetupStep.done:
        return '/library';
    }
  }

  /// Check if this is a setup step (not done).
  bool get isSetupStep => this != SetupStep.done;

  /// Get the next step in the flow.
  SetupStep? get nextStep {
    switch (this) {
      case SetupStep.splash:
        return SetupStep.privacy;
      case SetupStep.privacy:
        return SetupStep.modelSetup;
      case SetupStep.modelSetup:
        return SetupStep.downloading;
      case SetupStep.downloading:
        return SetupStep.complete;
      case SetupStep.complete:
        return SetupStep.done;
      case SetupStep.done:
        return null;
    }
  }
}
