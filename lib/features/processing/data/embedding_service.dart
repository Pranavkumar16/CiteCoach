import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_processor.dart';

/// Provider for the embedding service.
final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  return EmbeddingService();
});

/// Result of embedding generation.
class EmbeddingResult {
  const EmbeddingResult({
    required this.embeddings,
    this.error,
  });
  final Map<int, Float32List> embeddings;
  final String? error;
  bool get isSuccess => error == null;
}

typedef EmbeddingProgressCallback = void Function(int current, int total);

/// Platform channel bridge to native TFLite/CoreML inference.
/// Uses MiniLM-L6-v2 (22MB) for 384-dim sentence embeddings.
/// Falls back to TF-IDF projection when native model unavailable.
class EmbeddingService {
  EmbeddingService();

  static const int embeddingDimension = 384;
  static const _channel = MethodChannel('com.citecoach.citecoach/embedding');

  bool _isModelLoaded = false;
  bool _usingNativeInference = false;
  Map<String, int> _vocabulary = {};
  Map<String, double> _idfScores = {};

  bool get isModelLoaded => _isModelLoaded;
  bool get isNativeInference => _usingNativeInference;

  Future<bool> initialize() async {
    if (_isModelLoaded) return true;
    debugPrint('EmbeddingService: Initializing...');

    try {
      final modelPath = await _getModelPath();
      final modelFile = File(modelPath);

      if (await modelFile.exists()) {
        final result = await _channel.invokeMethod<bool>('loadModel', {
          'modelPath': modelPath,
          'numThreads': 2,
          'useGpuDelegate': false,
        });
        if (result == true) {
          _usingNativeInference = true;
          _isModelLoaded = true;
          debugPrint('EmbeddingService: Native TFLite model loaded');
          return true;
        }
      }
    } on PlatformException catch (e) {
      debugPrint('EmbeddingService: Platform error: $e');
    } catch (e) {
      debugPrint('EmbeddingService: Init error: $e');
    }

    // Fallback to TF-IDF projection
    _usingNativeInference = false;
    _isModelLoaded = true;
    debugPrint('EmbeddingService: Using TF-IDF fallback');
    return true;
  }

  Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/embedding_model.tflite';
  }

  Future<EmbeddingResult> generateEmbeddings(
    List<TextChunk> chunks, {
    EmbeddingProgressCallback? onProgress,
  }) async {
    if (!_isModelLoaded) await initialize();

    try {
      debugPrint('EmbeddingService: Generating ${chunks.length} embeddings');

      if (!_usingNativeInference) {
        _buildVocabulary(chunks.map((c) => c.text).toList());
      }

      final embeddings = <int, Float32List>{};
      const batchSize = 8;

      for (int i = 0; i < chunks.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, chunks.length);
        for (int j = i; j < end; j++) {
          onProgress?.call(j + 1, chunks.length);
          final emb = await _generateSingleEmbedding(chunks[j].text);
          if (emb != null) embeddings[j] = emb;
        }
        await Future.delayed(const Duration(milliseconds: 5));
      }

      debugPrint('EmbeddingService: Generated ${embeddings.length} embeddings');
      return EmbeddingResult(embeddings: embeddings);
    } catch (e) {
      debugPrint('EmbeddingService: Error: $e');
      return EmbeddingResult(embeddings: {}, error: e.toString());
    }
  }

  Future<Float32List?> generateQueryEmbedding(String text) async {
    if (!_isModelLoaded) await initialize();
    try {
      return await _generateSingleEmbedding(text);
    } catch (e) {
      debugPrint('EmbeddingService: Query embedding error: $e');
      return null;
    }
  }

  Future<Float32List?> _generateSingleEmbedding(String text) async {
    if (_usingNativeInference) return _nativeInference(text);
    return _tfidfEmbedding(text);
  }

  Future<Float32List?> _nativeInference(String text) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('embed', {
        'text': _preprocessText(text),
      });
      if (result != null && result.length == embeddingDimension) {
        final emb = Float32List(embeddingDimension);
        for (int i = 0; i < embeddingDimension; i++) {
          emb[i] = (result[i] as num).toDouble();
        }
        return _l2Normalize(emb);
      }
      return null;
    } on PlatformException {
      return _tfidfEmbedding(text);
    }
  }

  String _preprocessText(String text) {
    var p = text.trim();
    if (p.length > 1024) p = p.substring(0, 1024);
    return p.replaceAll(RegExp(r'\s+'), ' ');
  }

  void _buildVocabulary(List<String> texts) {
    _vocabulary.clear();
    _idfScores.clear();
    final df = <String, int>{};
    int idx = 0;
    for (final text in texts) {
      final unique = _tokenize(text).toSet();
      for (final w in unique) {
        if (!_vocabulary.containsKey(w)) _vocabulary[w] = idx++;
        df[w] = (df[w] ?? 0) + 1;
      }
    }
    final n = texts.length;
    for (final e in df.entries) {
      _idfScores[e.key] = log((n + 1) / (e.value + 1)) + 1.0;
    }
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }

  /// TF-IDF with random projection fallback for semantic similarity.
  Float32List _tfidfEmbedding(String text) {
    final words = _tokenize(text);
    if (words.isEmpty) return Float32List(embeddingDimension);

    final tf = <String, double>{};
    for (final w in words) tf[w] = (tf[w] ?? 0) + 1.0;
    for (final k in tf.keys.toList()) tf[k] = tf[k]! / words.length;

    final emb = Float32List(embeddingDimension);
    for (final e in tf.entries) {
      final idf = _idfScores[e.key] ?? 1.0;
      final tfidf = e.value * idf;
      final h = e.key.hashCode;
      for (int p = 0; p < 3; p++) {
        final dim = ((h + p * 7919) % embeddingDimension).abs();
        final sign = ((h + p * 6271) % 2 == 0) ? 1.0 : -1.0;
        emb[dim] += tfidf * sign;
      }
    }
    // Bigram features
    for (int i = 0; i < words.length - 1; i++) {
      final bg = '${words[i]}_${words[i + 1]}';
      emb[(bg.hashCode % embeddingDimension).abs()] += 0.5;
    }
    return _l2Normalize(emb);
  }

  static Float32List _l2Normalize(Float32List v) {
    double ss = 0;
    for (int i = 0; i < v.length; i++) ss += v[i] * v[i];
    final norm = sqrt(ss);
    if (norm > 0) {
      for (int i = 0; i < v.length; i++) v[i] /= norm;
    }
    return v;
  }

  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) throw ArgumentError('Dimension mismatch');
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    final d = sqrt(na) * sqrt(nb);
    return d == 0 ? 0 : dot / d;
  }

  void dispose() {
    if (_usingNativeInference) {
      try { _channel.invokeMethod('dispose'); } catch (_) {}
    }
    _isModelLoaded = false;
    _vocabulary.clear();
    _idfScores.clear();
    debugPrint('EmbeddingService: Disposed');
  }
}
