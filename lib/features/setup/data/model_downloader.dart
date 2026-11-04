import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Check network connectivity before attempting download.
/// Uses multiple DNS lookups to avoid platform-specific blocking.
Future<bool> _checkNetworkConnectivity() async {
  // Try multiple hosts in case one is blocked on certain platforms
  final hosts = ['dns.google', 'one.one.one.one', 'example.com'];
  for (final host in hosts) {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      continue;
    } on TimeoutException catch (_) {
      continue;
    } catch (_) {
      continue;
    }
  }
  return false;
}

final modelDownloaderProvider = Provider<ModelDownloader>((ref) {
  return ModelDownloader();
});

enum DownloadStatus { idle, downloading, paused, completed, failed }

/// Internal package identity; product UI uses CiteCoach AI.
enum ModelVariant {
  gemma270m(
    fileName: 'google_gemma-3-270m-it-Q4_K_M.gguf',
    sizeBytes: 253115168,
    displayName: 'CiteCoach AI',
    urls: [
      'https://huggingface.co/bartowski/google_gemma-3-270m-it-GGUF/resolve/d127a4e2c6ed47fdf409a956867b604c040432f9/google_gemma-3-270m-it-Q4_K_M.gguf',
    ],
  );

  const ModelVariant({required this.fileName, required this.sizeBytes,
    required this.displayName, required this.urls});
  final String fileName;
  final int sizeBytes;
  final String displayName;
  final List<String> urls;
}

class DownloadProgress {
  const DownloadProgress({
    required this.status,
    required this.progress,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0,
    this.error,
  });
  final DownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int speedBytesPerSec;
  final String? error;

  factory DownloadProgress.idle() =>
      const DownloadProgress(status: DownloadStatus.idle, progress: 0.0);
  factory DownloadProgress.completed() =>
      const DownloadProgress(status: DownloadStatus.completed, progress: 1.0);
  factory DownloadProgress.failed(String error) =>
      DownloadProgress(status: DownloadStatus.failed, progress: 0.0, error: error);

  String get downloadedSizeFormatted {
    if (downloadedBytes < 1024 * 1024) return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    if (downloadedBytes < 1024 * 1024 * 1024) return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(downloadedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get totalSizeFormatted {
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get speedFormatted {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec} B/s';
    if (speedBytesPerSec < 1024 * 1024) return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get etaFormatted {
    if (speedBytesPerSec == 0 || progress >= 1.0) return '--';
    final remaining = totalBytes - downloadedBytes;
    final seconds = remaining / speedBytesPerSec;
    if (seconds < 60) return '${seconds.toInt()}s';
    if (seconds < 3600) return '${(seconds / 60).toInt()}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}

/// Model downloader with pinned package verification.
///
/// Features:
/// - Retry interrupted downloads from the beginning
/// - Speed tracking and ETA estimation
/// - Pause/resume support
/// - SHA-256 integrity verification
/// - Automatic retry on transient failures
class ModelDownloader {
  ModelDownloader();

  static const String modelVersion = '4.0.0';
  static const ModelVariant defaultVariant = ModelVariant.gemma270m;
  static const String modelFileName = 'google_gemma-3-270m-it-Q4_K_M.gguf';
  static const int modelSizeBytes = 253115168;
  static const String modelSha256 =
      'c866c9f113f2e9aa2225c5997ede437392b8fa844ba5db9e4c77e315ffe20800';

  /// Use the compact package on every device for predictable speed.
  Future<ModelVariant> selectedVariant() async => defaultVariant;

  /// Embedding model URL (MiniLM-L6-v2 ONNX → TFLite, ~22MB).
  /// TF-IDF fallback works without this, so it's optional.
  static const String _embeddingModelUrl =
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx';
  static const int _embeddingModelSize = 22 * 1024 * 1024; // 22 MB

  late final Dio _dio;
  StreamController<DownloadProgress>? _progressController;
  CancelToken? _cancelToken;
  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _lastSpeedCheckBytes = 0;
  DateTime _lastSpeedCheckTime = DateTime.now();
  int _currentSpeed = 0;
  static const int _maxRetries = 3;

  bool get isDownloading => _status == DownloadStatus.downloading;
  bool get isPaused => _status == DownloadStatus.paused;
  bool get isCompleted => _status == DownloadStatus.completed;

  Future<String> getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final variant = await selectedVariant();
    return '${appDir.path}/models/${variant.fileName}';
  }

  Future<String> _getEmbeddingModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/embedding_model.tflite';
  }

  Future<String> _getTempPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/.download_temp';
  }

  /// Check if model is fully downloaded and verified.
  /// Also cleans up any legacy/old model files to free up space.
  Future<bool> isModelDownloaded() async {
    try {
      await _cleanupLegacyModels();

      final variant = await selectedVariant();
      final modelPath = await getModelPath();
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) return false;

      final size = await modelFile.length();
      // The default package is pinned to an exact revision and size.
      return size == variant.sizeBytes;
    } catch (_) {
      return false;
    }
  }

  /// Delete obsolete model files from previous versions to reclaim storage.
  Future<void> _cleanupLegacyModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      if (!await modelsDir.exists()) return;

      // Files from older versions of the app
      final legacyFileNames = <String>[
        'gemma-2-2b-it-Q4_K_M.gguf',
      ];

      for (final name in legacyFileNames) {
        final f = File('${modelsDir.path}/$name');
        if (await f.exists()) {
          await f.delete();
          debugPrint('ModelDownloader: Removed obsolete model: $name');
        }
      }
    } catch (_) {}
  }

  /// Check storage space availability.
  Future<bool> hasEnoughStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      // Need ~2GB free (model + temp + buffer)
      // stat doesn't give free space; we'll try the download and handle errors
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Start or resume downloading both models.
  Stream<DownloadProgress> startDownload() {
    _progressController?.close();
    _progressController = StreamController<DownloadProgress>.broadcast();

    if (_status == DownloadStatus.downloading) {
      return _progressController!.stream;
    }

    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 60),
      sendTimeout: const Duration(seconds: 30),
    ));

    _status = DownloadStatus.downloading;
    _cancelToken = CancelToken();
    _startDownloadSequence();

    return _progressController!.stream;
  }

  /// Sequential download: LLM model first, then embedding model.
  Future<void> _startDownloadSequence() async {
    try {
      // Check network connectivity first
      final hasNetwork = await _checkNetworkConnectivity();
      if (!hasNetwork) {
        _status = DownloadStatus.failed;
        _progressController?.add(DownloadProgress.failed(
          'No internet connection. Please check your network settings and try again.',
        ));
        debugPrint('ModelDownloader: No network connectivity');
        return;
      }

      // Phase 1: Download LLM model (95% of progress)
      final variant = await selectedVariant();
      final modelPath = await getModelPath();
      await _ensureDirectoryExists(modelPath);

      final success = await _downloadFileWithRetry(
        urls: variant.urls,
        savePath: modelPath,
        expectedSize: variant.sizeBytes,
        progressWeight: 0.95,
        progressOffset: 0.0,
      );

      if (!success) return; // Error already reported
      if (_status != DownloadStatus.downloading) return; // Cancelled/paused

      // Phase 2: Download embedding model (best-effort; TF-IDF fallback if fails)
      final embPath = await _getEmbeddingModelPath();
      try {
        await _downloadFileWithRetry(
          urls: [_embeddingModelUrl],
          savePath: embPath,
          expectedSize: _embeddingModelSize,
          progressWeight: 0.05,
          progressOffset: 0.95,
        );
      } catch (e) {
        debugPrint(
            'ModelDownloader: Embedding download failed (will use TF-IDF fallback): $e');
      }

      // Don't fail the overall flow if only the optional embedding model failed.
      // The LLM is what matters; RAG works with TF-IDF fallback.
      if (_status == DownloadStatus.failed) {
        _status = DownloadStatus.downloading;
      }
      if (_status != DownloadStatus.downloading) return;

      // All downloads complete
      _status = DownloadStatus.completed;
      _progressController?.add(DownloadProgress.completed());
      debugPrint('ModelDownloader: Download sequence completed');
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('ModelDownloader: Download cancelled');
        return;
      }
      _status = DownloadStatus.failed;
      final errorMessage = _getUserFriendlyError(e);
      _progressController?.add(DownloadProgress.failed(errorMessage));
      debugPrint('ModelDownloader: Download failed: $e');
    }
  }

  /// Download a file with retries; interrupted transfers restart.
  Future<bool> _downloadFileWithRetry({
    required List<String> urls,
    required String savePath,
    required int expectedSize,
    required double progressWeight,
    required double progressOffset,
  }) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      for (final url in urls) {
        try {
          final tempPath = '$savePath.tmp';
          final tempFile = File(tempPath);
          const existingBytes = 0;
          if (await tempFile.exists()) await tempFile.delete();

          // Restart interrupted transfers; Dio.download does not append ranges.
          await _dio.download(
            url,
            tempPath,
            cancelToken: _cancelToken,
            deleteOnError: false,
            options: Options(
              headers: existingBytes > 0
                  ? {'Range': 'bytes=$existingBytes-'}
                  : null,
            ),
            onReceiveProgress: (received, total) {
              if (_status != DownloadStatus.downloading) return;

              final actualReceived = received + existingBytes;
              final actualTotal =
                  total > 0 ? total + existingBytes : expectedSize;

              _downloadedBytes = actualReceived;
              final fileProgress =
                  actualTotal > 0 ? actualReceived / actualTotal : 0.0;
              _progress = progressOffset + (fileProgress * progressWeight);

              // Calculate speed every 500ms
              final now = DateTime.now();
              final elapsed =
                  now.difference(_lastSpeedCheckTime).inMilliseconds;
              if (elapsed > 500) {
                final bytesDelta = actualReceived - _lastSpeedCheckBytes;
                _currentSpeed = (bytesDelta * 1000 / elapsed).toInt();
                _lastSpeedCheckBytes = actualReceived;
                _lastSpeedCheckTime = now;
              }

              _progressController?.add(DownloadProgress(
                status: DownloadStatus.downloading,
                progress: _progress.clamp(0.0, 1.0),
                downloadedBytes: actualReceived,
                totalBytes: actualTotal,
                speedBytesPerSec: _currentSpeed,
              ));
            },
          );

          // Verify the pinned package before replacing any installed file.
          if (savePath.endsWith(modelFileName)) {
            final digest = await sha256.bind(tempFile.openRead()).first;
            if (await tempFile.length() != modelSizeBytes ||
                digest.toString() != modelSha256) {
              await tempFile.delete();
              throw const FormatException('AI download verification failed. Please retry.');
            }
          }

          // Move temp to final path
          final finalFile = File(savePath);
          if (await finalFile.exists()) await finalFile.delete();
          await tempFile.rename(savePath);

          debugPrint('ModelDownloader: Downloaded $savePath');
          return true;
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) rethrow;
          debugPrint(
              'ModelDownloader: Attempt ${attempt + 1} failed for $url: $e');

          if (attempt == _maxRetries - 1 && url == urls.last) {
            _status = DownloadStatus.failed;
            final errorMsg = _getUserFriendlyError(e);
            _progressController?.add(DownloadProgress.failed(errorMsg));
            return false;
          }

          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }
    return false;
  }

  Future<void> _ensureDirectoryExists(String filePath) async {
    final dir = Directory(filePath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Convert exceptions to user-friendly error messages.
  String _getUserFriendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your internet and try again.';
        case DioExceptionType.receiveTimeout:
          return 'Download timed out. Please try again on a faster connection.';
        case DioExceptionType.connectionError:
          return 'Could not connect to the server. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            return 'Model file not found on server. Please try again later.';
          }
          if (statusCode != null && statusCode >= 500) {
            return 'Server error ($statusCode). Please try again later.';
          }
          return 'Download failed (HTTP $statusCode). Please try again.';
        default:
          return 'Download failed. Please check your connection and try again.';
      }
    }
    if (e is SocketException) {
      return 'Network error. Please check your internet connection.';
    }
    if (e is FileSystemException) {
      return 'Storage error. Please ensure you have enough free space.';
    }
    return 'Download failed. Please try again.';
  }

  void pauseDownload() {
    if (_status != DownloadStatus.downloading) return;
    _status = DownloadStatus.paused;
    _cancelToken?.cancel('paused');
    _progressController?.add(DownloadProgress(
      status: DownloadStatus.paused,
      progress: _progress,
      downloadedBytes: _downloadedBytes,
      totalBytes: modelSizeBytes + _embeddingModelSize,
    ));
    debugPrint('ModelDownloader: Paused at ${(_progress * 100).toInt()}%');
  }

  Future<void> resumeDownload() async {
    if (_status != DownloadStatus.paused) return;

    final hasNetwork = await _checkNetworkConnectivity();
    if (!hasNetwork) {
      _progressController?.add(DownloadProgress.failed(
        'No internet connection. Please check your network settings and try again.',
      ));
      return;
    }

    _status = DownloadStatus.downloading;
    _cancelToken = CancelToken();
    _startDownloadSequence();
    debugPrint('ModelDownloader: Resumed');
  }

  void cancelDownload() {
    _cancelToken?.cancel('cancelled');
    _status = DownloadStatus.idle;
    _progress = 0.0;
    _downloadedBytes = 0;
    _progressController?.add(DownloadProgress.idle());
    _progressController?.close();
    _progressController = null;

    // Clean up temp files
    _cleanupTempFiles();
    debugPrint('ModelDownloader: Cancelled');
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final modelPath = await getModelPath();
      final tmpFile = File('$modelPath.tmp');
      if (await tmpFile.exists()) await tmpFile.delete();
    } catch (_) {}
  }

  /// Delete downloaded models to free space.
  Future<void> deleteModels() async {
    try {
      final modelPath = await getModelPath();
      final embPath = await _getEmbeddingModelPath();
      final modelFile = File(modelPath);
      final embFile = File(embPath);
      if (await modelFile.exists()) await modelFile.delete();
      if (await embFile.exists()) await embFile.delete();
      debugPrint('ModelDownloader: Models deleted');
    } catch (e) {
      debugPrint('ModelDownloader: Error deleting models: $e');
    }
  }

  /// Get total size of downloaded model files.
  Future<int> getDownloadedSize() async {
    int total = 0;
    try {
      final modelFile = File(await getModelPath());
      final embFile = File(await _getEmbeddingModelPath());
      if (await modelFile.exists()) total += await modelFile.length();
      if (await embFile.exists()) total += await embFile.length();
    } catch (_) {}
    return total;
  }

  void dispose() {
    _cancelToken?.cancel('disposed');
    _progressController?.close();
  }
}
