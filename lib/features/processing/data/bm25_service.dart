import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the BM25 service.
final bm25ServiceProvider = Provider<BM25Service>((ref) {
  return BM25Service();
});

/// BM25 (Okapi BM25) retrieval service for document search.
///
/// Replaces neural embeddings with a proven information retrieval algorithm
/// that requires no model download. BM25 is used by Elasticsearch, Lucene,
/// and most production search engines.
///
/// Advantages:
/// - No model required (works instantly offline)
/// - Extremely fast (microseconds per query)
/// - Production-proven for decades
/// - Excellent for keyword-heavy academic text
class BM25Service {
  BM25Service();

  /// BM25 tuning parameters.
  /// k1 controls term frequency saturation (1.2-2.0 typical).
  static const double k1 = 1.5;

  /// b controls document length normalization (0.75 typical).
  static const double b = 0.75;

  /// Build a BM25 index from a list of text chunks.
  ///
  /// Returns a [BM25Index] that can be used for fast retrieval.
  BM25Index buildIndex(List<IndexableChunk> chunks) {
    debugPrint('BM25Service: Building index for ${chunks.length} chunks');

    final tokenizedDocs = <int, List<String>>{};
    final docLengths = <int, int>{};
    int totalLength = 0;

    // Tokenize all documents
    for (final chunk in chunks) {
      final tokens = _tokenize(chunk.text);
      tokenizedDocs[chunk.id] = tokens;
      docLengths[chunk.id] = tokens.length;
      totalLength += tokens.length;
    }

    final avgDocLength =
        chunks.isEmpty ? 1.0 : totalLength / chunks.length;

    // Compute document frequency for each term
    final docFrequency = <String, int>{};
    for (final tokens in tokenizedDocs.values) {
      final uniqueTerms = tokens.toSet();
      for (final term in uniqueTerms) {
        docFrequency[term] = (docFrequency[term] ?? 0) + 1;
      }
    }

    // Compute term frequencies per document
    final termFrequencies = <int, Map<String, int>>{};
    for (final entry in tokenizedDocs.entries) {
      final tf = <String, int>{};
      for (final token in entry.value) {
        tf[token] = (tf[token] ?? 0) + 1;
      }
      termFrequencies[entry.key] = tf;
    }

    debugPrint(
        'BM25Service: Index built - ${chunks.length} docs, ${docFrequency.length} unique terms');

    return BM25Index(
      chunkCount: chunks.length,
      avgDocLength: avgDocLength,
      docFrequency: docFrequency,
      termFrequencies: termFrequencies,
      docLengths: docLengths,
      chunks: {for (final c in chunks) c.id: c},
    );
  }

  /// Score all documents against a query using BM25.
  ///
  /// Returns chunks sorted by relevance score (highest first).
  List<BM25Result> search(BM25Index index, String query, {int topK = 5}) {
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    final scores = <int, double>{};
    final n = index.chunkCount;

    for (final entry in index.termFrequencies.entries) {
      final docId = entry.key;
      final tf = entry.value;
      final docLength = index.docLengths[docId] ?? 1;
      double score = 0.0;

      for (final term in queryTokens) {
        final termFreq = tf[term] ?? 0;
        if (termFreq == 0) continue;

        final df = index.docFrequency[term] ?? 0;
        if (df == 0) continue;

        // IDF component: log((N - df + 0.5) / (df + 0.5) + 1)
        final idf = log((n - df + 0.5) / (df + 0.5) + 1);

        // TF component with length normalization
        final tfNorm = (termFreq * (k1 + 1)) /
            (termFreq + k1 * (1 - b + b * docLength / index.avgDocLength));

        score += idf * tfNorm;
      }

      if (score > 0) {
        scores[docId] = score;
      }
    }

    // Sort by score descending
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(topK).map((entry) {
      final chunk = index.chunks[entry.key]!;
      return BM25Result(
        chunk: chunk,
        score: entry.value,
      );
    }).toList();
  }

  /// Tokenize text into normalized terms.
  ///
  /// Performs:
  /// - Lowercasing
  /// - Punctuation removal
  /// - Whitespace splitting
  /// - Stop word removal
  /// - Minimum length filtering (>= 2 chars)
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2 && !_stopWords.contains(t))
        .toList();
  }

  /// Common English stop words to exclude from indexing.
  static const _stopWords = <String>{
    'the', 'be', 'to', 'of', 'and', 'in', 'that', 'have', 'it',
    'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her',
    'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there',
    'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get',
    'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no',
    'just', 'him', 'know', 'take', 'people', 'into', 'year', 'your',
    'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then',
    'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also',
    'back', 'after', 'use', 'two', 'how', 'our', 'work', 'first',
    'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these',
    'give', 'day', 'most', 'us', 'is', 'are', 'was', 'were', 'been',
    'has', 'had', 'did', 'does', 'am',
  };
}

/// A chunk of text that can be indexed by BM25.
class IndexableChunk {
  const IndexableChunk({
    required this.id,
    required this.text,
    required this.pageNumber,
    required this.chunkIndex,
    this.startOffset = 0,
    this.endOffset = 0,
  });

  final int id;
  final String text;
  final int pageNumber;
  final int chunkIndex;
  final int startOffset;
  final int endOffset;
}

/// Pre-computed BM25 index for fast retrieval.
class BM25Index {
  const BM25Index({
    required this.chunkCount,
    required this.avgDocLength,
    required this.docFrequency,
    required this.termFrequencies,
    required this.docLengths,
    required this.chunks,
  });

  final int chunkCount;
  final double avgDocLength;
  final Map<String, int> docFrequency;
  final Map<int, Map<String, int>> termFrequencies;
  final Map<int, int> docLengths;
  final Map<int, IndexableChunk> chunks;
}

/// Result of a BM25 search.
class BM25Result {
  const BM25Result({
    required this.chunk,
    required this.score,
  });

  final IndexableChunk chunk;
  final double score;
}
