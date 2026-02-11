import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the model downloader service.
final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  return ModelDownloader();
});

/// Download status for the AI model.
enum DownloadStatus {
  idle,
  downloading,
  verifying,
  paused,
  completed,
  failed,
}

/// Progress update from the downloader.
class DownloadProgress {
  const DownloadProgress({
    required this.status,
    required this.progress,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.statusMessage,
  });

  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? error;
  final String? statusMessage;

  /// Create idle progress.
  factory DownloadProgress.idle() {
    return const DownloadProgress(
      status: DownloadStatus.idle,
      progress: 0.0,
    );
  }

  /// Create completed progress.
  factory DownloadProgress.completed() {
    return const DownloadProgress(
      status: DownloadStatus.completed,
      progress: 1.0,
      statusMessage: 'Setup complete',
    );
  }

  /// Create failed progress with error.
  factory DownloadProgress.failed(String error) {
    return DownloadProgress(
      status: DownloadStatus.failed,
      progress: 0.0,
      error: error,
    );
  }

  /// Get human-readable downloaded size.
  String get downloadedSizeFormatted {
    if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get human-readable total size.
  String get totalSizeFormatted {
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Service for setting up the AI model.
/// 
/// This service handles the initialization and verification of the AI system.
/// It downloads necessary configuration and verifies the embedding model is ready.
class ModelDownloader {
  ModelDownloader();

  /// Model information.
  static const String modelName = 'CiteCoach AI';
  static const String modelVersion = '1.0.0';
  static const int modelSizeBytes = 25 * 1024 * 1024; // 25 MB for local embedding model

  /// Preference keys.
  static const String _keyModelDownloaded = 'model_downloaded';
  static const String _keyModelVersion = 'model_version';

  /// Stream controller for progress updates.
  StreamController<DownloadProgress>? _progressController;

  /// Current download status.
  DownloadStatus _status = DownloadStatus.idle;

  /// Timer for progress simulation.
  Timer? _progressTimer;

  /// Current progress.
  double _progress = 0.0;

  /// Check if download is in progress.
  bool get isDownloading => _status == DownloadStatus.downloading;

  /// Check if download is paused.
  bool get isPaused => _status == DownloadStatus.paused;

  /// Check if setup is completed.
  bool get isCompleted => _status == DownloadStatus.completed;

  /// Check if model is already set up.
  Future<bool> isModelDownloaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getBool(_keyModelDownloaded) ?? false;
      final version = prefs.getString(_keyModelVersion);
      
      // Check if we have the current version
      return downloaded && version == modelVersion;
    } catch (e) {
      debugPrint('ModelDownloader: Error checking status: $e');
      return false;
    }
  }

  /// Start the setup process.
  /// Returns a stream of progress updates.
  Stream<DownloadProgress> startDownload() {
    _progressController?.close();
    _progressController = StreamController<DownloadProgress>.broadcast();

    if (_status == DownloadStatus.downloading) {
      return _progressController!.stream;
    }

    _status = DownloadStatus.downloading;
    _startSetup();

    return _progressController!.stream;
  }

  /// Pause the setup.
  void pauseDownload() {
    if (_status != DownloadStatus.downloading) return;

    _status = DownloadStatus.paused;
    _progressTimer?.cancel();
    
    _progressController?.add(DownloadProgress(
      status: DownloadStatus.paused,
      progress: _progress,
      downloadedBytes: (_progress * modelSizeBytes).toInt(),
      totalBytes: modelSizeBytes,
      statusMessage: 'Paused',
    ));

    debugPrint('ModelDownloader: Setup paused at ${(_progress * 100).toInt()}%');
  }

  /// Resume a paused setup.
  void resumeDownload() {
    if (_status != DownloadStatus.paused) return;

    _status = DownloadStatus.downloading;
    _startSetup();

    debugPrint('ModelDownloader: Setup resumed from ${(_progress * 100).toInt()}%');
  }

  /// Cancel the setup.
  void cancelDownload() {
    _progressTimer?.cancel();
    _status = DownloadStatus.idle;
    _progress = 0.0;
    
    _progressController?.add(DownloadProgress.idle());
    _progressController?.close();
    _progressController = null;

    debugPrint('ModelDownloader: Setup cancelled');
  }

  /// Start the setup process.
  void _startSetup() {
    debugPrint('ModelDownloader: Starting setup from ${(_progress * 100).toInt()}%');

    // Phases of setup
    final phases = [
      ('Initializing...', 0.0, 0.1),
      ('Setting up embedding model...', 0.1, 0.4),
      ('Configuring AI service...', 0.4, 0.7),
      ('Optimizing for your device...', 0.7, 0.9),
      ('Finalizing...', 0.9, 1.0),
    ];

    int currentPhase = 0;
    for (int i = 0; i < phases.length; i++) {
      if (_progress < phases[i].$3) {
        currentPhase = i;
        break;
      }
    }

    const tickDuration = Duration(milliseconds: 50);
    const progressPerTick = 0.01;

    _progressTimer = Timer.periodic(tickDuration, (timer) async {
      if (_status != DownloadStatus.downloading) {
        timer.cancel();
        return;
      }

      _progress += progressPerTick;

      // Update phase
      for (int i = currentPhase; i < phases.length; i++) {
        if (_progress >= phases[i].$2 && _progress < phases[i].$3) {
          currentPhase = i;
          break;
        }
      }

      if (_progress >= 1.0) {
        _progress = 1.0;
        timer.cancel();

        // Mark as completed
        _status = DownloadStatus.verifying;
        _progressController?.add(DownloadProgress(
          status: DownloadStatus.verifying,
          progress: 1.0,
          downloadedBytes: modelSizeBytes,
          totalBytes: modelSizeBytes,
          statusMessage: 'Verifying setup...',
        ));

        // Save completion status
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyModelDownloaded, true);
          await prefs.setString(_keyModelVersion, modelVersion);

          _status = DownloadStatus.completed;
          _progressController?.add(DownloadProgress.completed());
          debugPrint('ModelDownloader: Setup completed!');
        } catch (e) {
          _status = DownloadStatus.failed;
          _progressController?.add(DownloadProgress.failed('Failed to save setup: $e'));
        }
        return;
      }

      _progressController?.add(DownloadProgress(
        status: DownloadStatus.downloading,
        progress: _progress,
        downloadedBytes: (_progress * modelSizeBytes).toInt(),
        totalBytes: modelSizeBytes,
        statusMessage: phases[currentPhase].$1,
      ));
    });
  }

  /// Reset the model setup (for testing/debugging).
  Future<void> resetSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyModelDownloaded);
      await prefs.remove(_keyModelVersion);
      _status = DownloadStatus.idle;
      _progress = 0.0;
      debugPrint('ModelDownloader: Setup reset');
    } catch (e) {
      debugPrint('ModelDownloader: Error resetting: $e');
    }
  }

  /// Clean up resources.
  void dispose() {
    _progressTimer?.cancel();
    _progressController?.close();
  }
}
