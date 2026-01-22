import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider for the model downloader service.
final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  const downloadUrl =
      String.fromEnvironment(ModelDownloader.modelDownloadUrlEnvKey);
  return ModelDownloader(downloadUrl: downloadUrl);
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
    if (totalBytes <= 0) {
      return 'Unknown';
    }
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
  ModelDownloader({
    String? downloadUrl,
    Dio? dio,
    bool allowSimulatedFallback = true,
  })  : _downloadUrl = downloadUrl?.trim() ?? '',
        _dio = dio ?? Dio(),
        _allowSimulatedFallback = allowSimulatedFallback;

  /// Model file information.
  static const String modelName = 'gemma-2b-it-q4';
  static const String modelVersion = '1.0.0';
  static const int modelSizeBytes = 1500 * 1024 * 1024; // 1.5 GB
  static const String modelDownloadUrlEnvKey = 'MODEL_DOWNLOAD_URL';

  final Dio _dio;
  final String _downloadUrl;
  final bool _allowSimulatedFallback;

  CancelToken? _cancelToken;

  /// Stream controller for progress updates.
  StreamController<DownloadProgress>? _progressController;

  /// Current download status.
  DownloadStatus _status = DownloadStatus.idle;

  /// Timer for simulated download.
  Timer? _simulationTimer;

  /// Current progress.
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  bool _isSimulatedDownload = false;

  /// Check if download is in progress.
  bool get isDownloading => _status == DownloadStatus.downloading;

  /// Check if download is paused.
  bool get isPaused => _status == DownloadStatus.paused;

  /// Check if download is completed.
  bool get isCompleted => _status == DownloadStatus.completed;

  /// Whether an actual download URL is configured.
  bool get hasDownloadUrl => _downloadUrl.isNotEmpty;

  /// Whether the downloader is using the simulated fallback.
  bool get isUsingSimulatedDownload => _isSimulatedDownload;

  /// Bytes downloaded so far (if known).
  int get downloadedBytes => _downloadedBytes;

  /// Total bytes for the download (if known).
  int get totalBytes => _totalBytes;

  /// Get the model storage path.
  Future<String> getModelPath() async {
    final modelsDir = await _getModelsDirectory();
    return '${modelsDir.path}/$modelName';
  }

  Future<String> _getTempPath() async {
    final modelsDir = await _getModelsDirectory();
    return '${modelsDir.path}/$modelName.part';
  }

  Future<Directory> _getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Check if model already exists.
  Future<bool> isModelDownloaded() async {
    final modelPath = await getModelPath();
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      return false;
    }

    final size = await modelFile.length();
    if (size <= 0) {
      return false;
    }

    _status = DownloadStatus.completed;
    _progress = 1.0;
    _downloadedBytes = size;
    _totalBytes = size;
    return true;
  }

  /// Restore download progress from persisted state.
  void restoreProgress(double progress, {bool isPaused = false}) {
    _progress = progress.clamp(0.0, 1.0);
    _totalBytes = modelSizeBytes;
    _downloadedBytes = (_totalBytes * _progress).toInt();
    _isSimulatedDownload = false;

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
      _emitProgress(const DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
      ));
      return _progressController!.stream;
    }

    if (_status == DownloadStatus.downloading) {
      // Already downloading, return existing stream
      return _progressController!.stream;
    }

    _status = DownloadStatus.downloading;
    if (_downloadUrl.isEmpty) {
      if (_allowSimulatedFallback) {
        _isSimulatedDownload = true;
        _startSimulatedDownload();
      } else {
        _status = DownloadStatus.failed;
        _emitProgress(DownloadProgress.failed(
          'Model download URL not configured. '
          'Set ${ModelDownloader.modelDownloadUrlEnvKey}.',
        ));
      }
      return _progressController!.stream;
    }

    _isSimulatedDownload = false;
    _startHttpDownload();

    return _progressController!.stream;
  }

  /// Pause the download.
  void pauseDownload() {
    if (_status != DownloadStatus.downloading) return;

    _status = DownloadStatus.paused;
    _simulationTimer?.cancel();
    _cancelToken?.cancel('paused');
    
    _emitProgress(DownloadProgress(
      status: DownloadStatus.paused,
      progress: _progress,
      downloadedBytes: _downloadedBytes,
      totalBytes: _totalBytes,
    ));

    debugPrint('ModelDownloader: Download paused at ${(_progress * 100).toInt()}%');
  }

  /// Resume a paused download.
  void resumeDownload() {
    if (_status != DownloadStatus.paused) return;

    _status = DownloadStatus.downloading;
    if (_isSimulatedDownload || _downloadUrl.isEmpty) {
      _startSimulatedDownload();
    } else {
      _startHttpDownload();
    }

    debugPrint('ModelDownloader: Download resumed from ${(_progress * 100).toInt()}%');
  }

  /// Cancel the download.
  void cancelDownload() {
    _simulationTimer?.cancel();
    _cancelToken?.cancel('cancelled');
    _cancelToken = null;
    _status = DownloadStatus.idle;
    _progress = 0.0;
    _downloadedBytes = 0;
    _totalBytes = 0;
    
    _emitProgress(DownloadProgress.idle());
    _progressController?.close();
    _progressController = null;

    Future(() async {
      final tempPath = await _getTempPath();
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    debugPrint('ModelDownloader: Download cancelled');
  }

  void _emitProgress(DownloadProgress progress) {
    if (_progressController == null || _progressController!.isClosed) return;
    _progressController!.add(progress);
  }

  Future<void> _startHttpDownload() async {
    try {
      if (await isModelDownloaded()) {
        _emitProgress(DownloadProgress(
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: _downloadedBytes,
          totalBytes: _totalBytes,
        ));
        return;
      }

      final modelPath = await getModelPath();
      final tempPath = await _getTempPath();
      final tempFile = File(tempPath);
      final modelFile = File(modelPath);

      int existingBytes = 0;
      if (await tempFile.exists()) {
        existingBytes = await tempFile.length();
      }

      _downloadedBytes = existingBytes;
      _totalBytes = _totalBytes > 0 ? _totalBytes : modelSizeBytes;
      _progress = _totalBytes > 0 ? _downloadedBytes / _totalBytes : 0.0;
      _emitProgress(DownloadProgress(
        status: DownloadStatus.downloading,
        progress: _progress,
        downloadedBytes: _downloadedBytes,
        totalBytes: _totalBytes,
      ));

      _cancelToken = CancelToken();
      final headers = <String, dynamic>{};
      if (existingBytes > 0) {
        headers['range'] = 'bytes=$existingBytes-';
      }

      final baseBytes = existingBytes;
      await _dio.download(
        _downloadUrl,
        tempPath,
        cancelToken: _cancelToken,
        options: Options(headers: headers, followRedirects: true),
        onReceiveProgress: (received, total) {
          final totalBytes = total > 0 ? baseBytes + total : _totalBytes;
          final overallReceived = baseBytes + received;

          _downloadedBytes = overallReceived;
          _totalBytes = totalBytes > 0 ? totalBytes : _totalBytes;
          _progress = _totalBytes > 0 ? overallReceived / _totalBytes : 0.0;

          _emitProgress(DownloadProgress(
            status: DownloadStatus.downloading,
            progress: _progress,
            downloadedBytes: _downloadedBytes,
            totalBytes: _totalBytes,
          ));
        },
      );

      if (_status != DownloadStatus.downloading) return;

      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      await tempFile.rename(modelPath);

      final finalSize = await modelFile.length();
      final expectedBytes = _totalBytes;
      if (!_isSimulatedDownload &&
          expectedBytes > 0 &&
          finalSize < expectedBytes) {
        _status = DownloadStatus.failed;
        _emitProgress(DownloadProgress.failed(
          'Download incomplete. Expected $expectedBytes bytes, got $finalSize.',
        ));
        return;
      }

      _status = DownloadStatus.completed;
      _progress = 1.0;
      _downloadedBytes = finalSize;
      _totalBytes = finalSize;
      _emitProgress(DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: _downloadedBytes,
        totalBytes: _totalBytes,
      ));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (_status == DownloadStatus.paused) {
          _emitProgress(DownloadProgress(
            status: DownloadStatus.paused,
            progress: _progress,
            downloadedBytes: _downloadedBytes,
            totalBytes: _totalBytes,
          ));
        } else if (_status == DownloadStatus.idle) {
          _emitProgress(DownloadProgress.idle());
        }
        return;
      }

      _status = DownloadStatus.failed;
      _emitProgress(DownloadProgress.failed(
        e.message ?? 'Download failed',
      ));
    } catch (e) {
      _status = DownloadStatus.failed;
      _emitProgress(DownloadProgress.failed('Download failed: $e'));
    }
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

        _downloadedBytes = modelSizeBytes;
        _totalBytes = modelSizeBytes;
        _emitProgress(const DownloadProgress(
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: modelSizeBytes,
          totalBytes: modelSizeBytes,
        ));

        _ensurePlaceholderModelFile();

        debugPrint('ModelDownloader: Download completed!');
        return;
      }

      _downloadedBytes = (_progress * modelSizeBytes).toInt();
      _totalBytes = modelSizeBytes;
      _emitProgress(DownloadProgress(
        status: DownloadStatus.downloading,
        progress: _progress,
        downloadedBytes: _downloadedBytes,
        totalBytes: modelSizeBytes,
      ));
    });
  }

  Future<void> _ensurePlaceholderModelFile() async {
    try {
      final modelPath = await getModelPath();
      final modelFile = File(modelPath);
      if (await modelFile.exists()) return;
      await modelFile.writeAsBytes([0]);
    } catch (e) {
      debugPrint('ModelDownloader: Failed to create placeholder model: $e');
    }
  }

  /// Clean up resources.
  void dispose() {
    _simulationTimer?.cancel();
    _cancelToken?.cancel('dispose');
    _cancelToken = null;
    _progressController?.close();
  }
}
