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

/// Service for generating text embeddings using a local approach.
/// 
/// This implementation uses a combination of:
/// - TF-IDF-like term frequency analysis
/// - Character n-gram hashing
/// - Semantic word clustering via predefined categories
/// 
/// This provides reasonable semantic similarity without external APIs,
/// making the app fully functional offline.
class EmbeddingService {
  EmbeddingService();

  /// Embedding dimension (matches TinyBERT standard for compatibility).
  static const int embeddingDimension = 384;

  /// Whether the model is loaded and ready.
  bool _isModelLoaded = false;

  /// Common stop words to filter out.
  static const Set<String> _stopWords = {
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'must', 'shall', 'can', 'to', 'of', 'in',
    'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through',
    'during', 'before', 'after', 'above', 'below', 'between', 'under',
    'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'each', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 'just', 'and', 'but', 'if', 'or', 'because', 'until',
    'while', 'this', 'that', 'these', 'those', 'it', 'its',
  };

  /// Semantic category keywords for domain awareness.
  static const Map<String, List<String>> _semanticCategories = {
    'biology': ['cell', 'dna', 'protein', 'gene', 'organism', 'species', 'evolution', 'enzyme', 'metabolism', 'photosynthesis', 'mitochondria', 'nucleus', 'membrane', 'tissue', 'organ'],
    'chemistry': ['atom', 'molecule', 'element', 'compound', 'reaction', 'bond', 'electron', 'proton', 'acid', 'base', 'solution', 'concentration', 'oxidation', 'reduction'],
    'physics': ['force', 'energy', 'mass', 'velocity', 'acceleration', 'momentum', 'gravity', 'electric', 'magnetic', 'wave', 'frequency', 'quantum', 'relativity'],
    'mathematics': ['equation', 'function', 'variable', 'integral', 'derivative', 'theorem', 'proof', 'matrix', 'vector', 'probability', 'statistics', 'calculus'],
    'medicine': ['disease', 'symptom', 'treatment', 'diagnosis', 'patient', 'drug', 'therapy', 'surgery', 'infection', 'immune', 'chronic', 'acute'],
    'computer': ['algorithm', 'data', 'program', 'code', 'software', 'hardware', 'network', 'database', 'memory', 'processor', 'interface', 'system'],
    'economics': ['market', 'price', 'supply', 'demand', 'inflation', 'gdp', 'trade', 'investment', 'capital', 'labor', 'fiscal', 'monetary'],
    'history': ['century', 'war', 'revolution', 'empire', 'civilization', 'dynasty', 'treaty', 'colonial', 'independence', 'reform'],
    'literature': ['author', 'novel', 'poem', 'character', 'theme', 'narrative', 'plot', 'symbolism', 'metaphor', 'genre'],
    'general': ['important', 'significant', 'therefore', 'however', 'conclusion', 'result', 'analysis', 'method', 'process', 'example'],
  };

  /// Check if model is ready.
  bool get isModelLoaded => _isModelLoaded;

  /// Initialize the embedding service.
  Future<bool> initialize() async {
    if (_isModelLoaded) return true;
    
    debugPrint('EmbeddingService: Initializing local embedding model...');
    
    // Local implementation requires no external loading
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isModelLoaded = true;
    debugPrint('EmbeddingService: Local embedding model ready');
    
    return true;
  }

  /// Generate embeddings for a list of text chunks.
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

        final embedding = _generateEmbedding(chunks[i].text);
        embeddings[i] = embedding;

        // Small delay to prevent UI blocking
        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
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
      return _generateEmbedding(text);
    } catch (e) {
      debugPrint('EmbeddingService: Error generating query embedding: $e');
      return null;
    }
  }

  /// Generate embedding vector for text using local methods.
  Float32List _generateEmbedding(String text) {
    final embedding = Float32List(embeddingDimension);
    final normalizedText = text.toLowerCase();
    
    // Extract tokens
    final tokens = _tokenize(normalizedText);
    final filteredTokens = tokens.where((t) => !_stopWords.contains(t) && t.length > 2).toList();
    
    if (filteredTokens.isEmpty) {
      // Return zero vector for empty text
      return embedding;
    }

    // 1. Term frequency component (dimensions 0-127)
    _addTermFrequencyComponent(embedding, filteredTokens, 0, 128);

    // 2. Character n-gram hashing (dimensions 128-255)
    _addNgramComponent(embedding, normalizedText, 128, 128);

    // 3. Semantic category scores (dimensions 256-319)
    _addSemanticComponent(embedding, filteredTokens, 256, 64);

    // 4. Statistical features (dimensions 320-383)
    _addStatisticalComponent(embedding, text, tokens, 320, 64);

    // L2 normalize the embedding
    _normalizeVector(embedding);
    
    return embedding;
  }

  /// Tokenize text into words.
  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Add term frequency component using hashing.
  void _addTermFrequencyComponent(Float32List embedding, List<String> tokens, int start, int size) {
    final termFreq = <String, int>{};
    for (final token in tokens) {
      termFreq[token] = (termFreq[token] ?? 0) + 1;
    }

    for (final entry in termFreq.entries) {
      final hash = entry.key.hashCode.abs() % size;
      final tf = 1 + log(entry.value.toDouble());
      embedding[start + hash] += tf;
    }
  }

  /// Add character n-gram component.
  void _addNgramComponent(Float32List embedding, String text, int start, int size) {
    // Use character trigrams
    for (int i = 0; i < text.length - 2; i++) {
      final trigram = text.substring(i, i + 3);
      final hash = trigram.hashCode.abs() % size;
      embedding[start + hash] += 1.0;
    }
  }

  /// Add semantic category component.
  void _addSemanticComponent(Float32List embedding, List<String> tokens, int start, int size) {
    final tokenSet = tokens.toSet();
    final categoriesPerSlot = _semanticCategories.length;
    final slotSize = size ~/ categoriesPerSlot;

    int categoryIndex = 0;
    for (final category in _semanticCategories.entries) {
      double score = 0;
      for (final keyword in category.value) {
        if (tokenSet.contains(keyword)) {
          score += 1.0;
        }
        // Partial matching for compound words
        for (final token in tokens) {
          if (token.contains(keyword) || keyword.contains(token)) {
            score += 0.5;
          }
        }
      }
      
      // Distribute score across slots for this category
      for (int i = 0; i < slotSize && (start + categoryIndex * slotSize + i) < embedding.length; i++) {
        embedding[start + categoryIndex * slotSize + i] = score / slotSize;
      }
      categoryIndex++;
    }
  }

  /// Add statistical features component.
  void _addStatisticalComponent(Float32List embedding, String text, List<String> tokens, int start, int size) {
    if (start + size > embedding.length) return;

    // Text length features
    embedding[start] = log(text.length.toDouble() + 1) / 10;
    embedding[start + 1] = log(tokens.length.toDouble() + 1) / 5;
    
    // Average word length
    if (tokens.isNotEmpty) {
      final avgLen = tokens.map((t) => t.length).reduce((a, b) => a + b) / tokens.length;
      embedding[start + 2] = avgLen / 10;
    }
    
    // Punctuation density
    final punctCount = text.replaceAll(RegExp(r'[^\.\,\!\?\;\:]'), '').length;
    embedding[start + 3] = punctCount / (text.length + 1);
    
    // Digit presence
    final digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    embedding[start + 4] = digitCount / (text.length + 1);
    
    // Uppercase ratio
    final upperCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    embedding[start + 5] = upperCount / (text.length + 1);

    // Unique word ratio
    embedding[start + 6] = tokens.toSet().length / (tokens.length + 1);
  }

  /// L2 normalize the embedding vector.
  void _normalizeVector(Float32List embedding) {
    double sumSquares = 0;
    for (int i = 0; i < embedding.length; i++) {
      sumSquares += embedding[i] * embedding[i];
    }
    
    final norm = sqrt(sumSquares);
    if (norm > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= norm;
      }
    }
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

  /// Dispose of resources.
  void dispose() {
    _isModelLoaded = false;
    debugPrint('EmbeddingService: Disposed');
  }
}
