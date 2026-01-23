import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/model_files.dart';
import 'pdf_processor.dart';

/// Provider for the embedding service.
final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  final modelFiles = ref.watch(modelFilesProvider);
  return EmbeddingService(modelFiles);
});

/// Result of embedding generation.
class EmbeddingResult {
  const EmbeddingResult({
    required this.embeddings,
    this.error,
  });

  /// Map of chunk index to embedding vector.
  final Map<int, Float32List> embeddings;

  /// Error message if generation failed.
  final String? error;

  /// Check if generation was successful.
  bool get isSuccess => error == null;
}

/// Progress callback for embedding generation.
typedef EmbeddingProgressCallback = void Function(int current, int total);

/// Service for generating text embeddings.
/// 
/// In V1, this is a stub that generates random embeddings.
/// Real implementation with TinyBERT will be added in Commit 9.
/// 
/// The embedding model produces 384-dimensional vectors (TinyBERT).
class EmbeddingService {
  EmbeddingService(this._modelFiles);

  final ModelFiles _modelFiles;

  bool _isUsingStub = true;

  /// Whether the service is using stub embeddings.
  bool get isUsingStub => _isUsingStub;

  /// Embedding dimension (TinyBERT produces 384-dim vectors).
  static const int embeddingDimension = 384;

  /// Whether the model is loaded and ready.
  bool _isModelLoaded = false;

  /// Check if model is ready.
  bool get isModelLoaded => _isModelLoaded;

  /// Initialize the embedding model.
  /// 
  /// In V1, this is a no-op stub.
  /// Real implementation will load TinyBERT model weights.
  Future<bool> initialize() async {
    if (_isModelLoaded) return true;

    final hasModel = await _modelFiles.hasEmbeddingModel();
    if (!hasModel) {
      debugPrint('EmbeddingService: Embedding model not found, using stub');
      _isUsingStub = true;
    } else {
      debugPrint('EmbeddingService: Embedding model found (stub backend active)');
      _isUsingStub = true;
    }

    debugPrint('EmbeddingService: Initializing (stub)');
    
    // Simulate model loading time
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isModelLoaded = true;
    debugPrint('EmbeddingService: Model ready (stub)');
    
    return true;
  }

  /// Generate embeddings for a list of text chunks.
  /// 
  /// In V1, this generates random embeddings for testing.
  /// Real implementation will use TinyBERT inference.
  Future<EmbeddingResult> generateEmbeddings(
    List<TextChunk> chunks, {
    EmbeddingProgressCallback? onProgress,
  }) async {
    if (!_isModelLoaded) {
      await initialize();
    }

    try {
      debugPrint('EmbeddingService: Generating embeddings for ${chunks.length} chunks');

      final embeddings = <int, Float32List>{};

      for (int i = 0; i < chunks.length; i++) {
        onProgress?.call(i + 1, chunks.length);

        // Generate random embedding (stub)
        // Real implementation will call TinyBERT model
        final embedding = _generateStubEmbedding(chunks[i].text);
        embeddings[i] = embedding;

        // Simulate processing time
        await Future.delayed(const Duration(milliseconds: 20));
      }

      debugPrint('EmbeddingService: Generated ${embeddings.length} embeddings');

      return EmbeddingResult(embeddings: embeddings);
    } catch (e) {
      debugPrint('EmbeddingService: Error generating embeddings: $e');
      return EmbeddingResult(
        embeddings: {},
        error: 'Failed to generate embeddings: ${e.toString()}',
      );
    }
  }

  /// Generate embedding for a single text (for query embedding).
  Future<Float32List?> generateQueryEmbedding(String text) async {
    if (!_isModelLoaded) {
      await initialize();
    }

    try {
      return _generateStubEmbedding(text);
    } catch (e) {
      debugPrint('EmbeddingService: Error generating query embedding: $e');
      return null;
    }
  }

  /// Generate a stub embedding vector.
  ///
  /// In real implementation, this will be replaced with TinyBERT inference.
  /// For now, uses a deterministic hashing trick for text similarity.
  Float32List _generateStubEmbedding(String text) {
    final embedding = Float32List(embeddingDimension);

    final tokens = _tokenize(text);
    if (tokens.isEmpty) {
      return embedding;
    }

    for (final token in tokens) {
      final hash = _stableHash(token);
      final index = hash.abs() % embeddingDimension;
      final sign = (hash & 1) == 0 ? 1.0 : -1.0;
      final weight = token.length < 4 ? 0.8 : 1.0;
      embedding[index] += sign * weight;
    }

    // L2 normalize
    double sumSquares = 0;
    for (int i = 0; i < embeddingDimension; i++) {
      sumSquares += embedding[i] * embedding[i];
    }
    final norm = sqrt(sumSquares);
    if (norm > 0) {
      for (int i = 0; i < embeddingDimension; i++) {
        embedding[i] /= norm;
      }
    }

    return embedding;
  }

  List<String> _tokenize(String text) {
    final matches = RegExp(r"[A-Za-z0-9']+")
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => token.length > 1)
        .toList();
    return matches;
  }

  int _stableHash(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash;
  }

  /// Compute cosine similarity between two embeddings.
  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) {
      throw ArgumentError('Embeddings must have same dimension');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 0;

    return dotProduct / denominator;
  }

  /// Dispose of model resources.
  void dispose() {
    _isModelLoaded = false;
    debugPrint('EmbeddingService: Disposed');
  }
}
