import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  EmbeddingService();

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
      final random = Random(42); // Fixed seed for reproducibility in testing

      for (int i = 0; i < chunks.length; i++) {
        onProgress?.call(i + 1, chunks.length);

        // Generate random embedding (stub)
        // Real implementation will call TinyBERT model
        final embedding = _generateStubEmbedding(chunks[i].text, random);
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
      final random = Random(text.hashCode); // Deterministic based on text
      return _generateStubEmbedding(text, random);
    } catch (e) {
      debugPrint('EmbeddingService: Error generating query embedding: $e');
      return null;
    }
  }

  /// Generate a stub embedding vector.
  /// 
  /// In real implementation, this will be replaced with TinyBERT inference.
  /// For now, generates normalized random vectors.
  Float32List _generateStubEmbedding(String text, Random random) {
    final embedding = Float32List(embeddingDimension);
    
    // Generate random values
    double sumSquares = 0;
    for (int i = 0; i < embeddingDimension; i++) {
      // Use text hash to add some text-dependent variation
      final textFactor = (text.hashCode + i) % 100 / 100.0;
      embedding[i] = (random.nextDouble() * 2 - 1) + textFactor * 0.1;
      sumSquares += embedding[i] * embedding[i];
    }
    
    // L2 normalize
    final norm = sqrt(sumSquares);
    if (norm > 0) {
      for (int i = 0; i < embeddingDimension; i++) {
        embedding[i] /= norm;
      }
    }
    
    return embedding;
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
