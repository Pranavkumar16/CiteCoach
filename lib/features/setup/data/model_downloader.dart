import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider for the model downloader service.
final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  return ModelDownloader();
});

/// Download status for the AI model.
enum DownloadStatus {
  idle,
  downloading,
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
  });

  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? error;

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

/// Service for downloading the AI model.
/// 
/// In V1, this uses a simulated download for development.
/// Real implementation will be added in Commit 9 with actual model files.
class ModelDownloader {
  ModelDownloader();

  /// Model file information.
  static const String modelName = 'gemma-2b-it-q4';
  static const String modelVersion = '1.0.0';
  static const int modelSizeBytes = 1500 * 1024 * 1024; // 1.5 GB

  /// Stream controller for progress updates.
  StreamController<DownloadProgress>? _progressController;

  /// Current download status.
  DownloadStatus _status = DownloadStatus.idle;

  /// Timer for simulated download.
  Timer? _simulationTimer;

  /// Current progress.
  double _progress = 0.0;

  /// Check if download is in progress.
  bool get isDownloading => _status == DownloadStatus.downloading;

  /// Check if download is paused.
  bool get isPaused => _status == DownloadStatus.paused;

  /// Check if download is completed.
  bool get isCompleted => _status == DownloadStatus.completed;

  /// Get the model storage path.
  Future<String> getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/$modelName';
  }

  /// Check if model already exists.
  Future<bool> isModelDownloaded() async {
    // In real implementation, check if model file exists and is valid
    // For now, return false to allow download flow testing
    return _status == DownloadStatus.completed;
  }

  /// Restore download progress from persisted state.
  void restoreProgress(double progress, {bool isPaused = false}) {
    _progress = progress.clamp(0.0, 1.0);

    if (_progress >= 1.0) {
      _status = DownloadStatus.completed;
    } else if (_progress > 0.0 && isPaused) {
      _status = DownloadStatus.paused;
    } else if (_progress > 0.0) {
      _status = DownloadStatus.idle;
    } else {
      _status = DownloadStatus.idle;
    }
  }

  /// Start or resume downloading the model.
  /// Returns a stream of progress updates.
  Stream<DownloadProgress> startDownload() {
    _progressController?.close();
    _progressController = StreamController<DownloadProgress>.broadcast();

    if (_status == DownloadStatus.completed) {
      _progressController!.add(DownloadProgress.completed());
      return _progressController!.stream;
    }

    if (_status == DownloadStatus.downloading) {
      // Already downloading, return existing stream
      return _progressController!.stream;
    }

    _status = DownloadStatus.downloading;
    _startSimulatedDownload();

    return _progressController!.stream;
  }

  /// Pause the download.
  void pauseDownload() {
    if (_status != DownloadStatus.downloading) return;

    _status = DownloadStatus.paused;
    _simulationTimer?.cancel();
    
    _progressController?.add(DownloadProgress(
      status: DownloadStatus.paused,
      progress: _progress,
      downloadedBytes: (_progress * modelSizeBytes).toInt(),
      totalBytes: modelSizeBytes,
    ));

    debugPrint('ModelDownloader: Download paused at ${(_progress * 100).toInt()}%');
  }

  /// Resume a paused download.
  void resumeDownload() {
    if (_status != DownloadStatus.paused) return;

    _status = DownloadStatus.downloading;
    _startSimulatedDownload();

    debugPrint('ModelDownloader: Download resumed from ${(_progress * 100).toInt()}%');
  }

  /// Cancel the download.
  void cancelDownload() {
    _simulationTimer?.cancel();
    _status = DownloadStatus.idle;
    _progress = 0.0;
    
    _progressController?.add(DownloadProgress.idle());
    _progressController?.close();
    _progressController = null;

    debugPrint('ModelDownloader: Download cancelled');
  }

  /// Simulate a download for development/testing.
  /// 
  /// In Commit 9, this will be replaced with actual HTTP download
  /// using Dio with background download support.
  void _startSimulatedDownload() {
    debugPrint('ModelDownloader: Starting simulated download from ${(_progress * 100).toInt()}%');

    // Simulate download progress
    // In development, complete in ~10 seconds for testing
    // Each tick represents ~1% progress
    const tickDuration = Duration(milliseconds: 100);
    const progressPerTick = 0.01;

    _simulationTimer = Timer.periodic(tickDuration, (timer) {
      if (_status != DownloadStatus.downloading) {
        timer.cancel();
        return;
      }

      _progress += progressPerTick;

      if (_progress >= 1.0) {
        _progress = 1.0;
        _status = DownloadStatus.completed;
        timer.cancel();

        _progressController?.add(const DownloadProgress(
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: modelSizeBytes,
          totalBytes: modelSizeBytes,
        ));

        debugPrint('ModelDownloader: Download completed!');
        return;
      }

      _progressController?.add(DownloadProgress(
        status: DownloadStatus.downloading,
        progress: _progress,
        downloadedBytes: (_progress * modelSizeBytes).toInt(),
        totalBytes: modelSizeBytes,
      ));
    });
  }

  /// Clean up resources.
  void dispose() {
    _simulationTimer?.cancel();
    _progressController?.close();
  }
}
