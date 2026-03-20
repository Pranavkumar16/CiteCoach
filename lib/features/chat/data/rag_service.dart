import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/document_chunks_table.dart';
import '../../processing/data/bm25_service.dart';
import '../domain/chat_message.dart';

/// Provider for the RAG service.
final ragServiceProvider = Provider<RagService>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  final bm25Service = ref.watch(bm25ServiceProvider);
  return RagService(db, bm25Service);
});

/// Result of RAG retrieval.
class RetrievalResult {
  const RetrievalResult({
    required this.context,
    required this.citations,
    this.error,
  });

  /// The combined context text for the LLM.
  final String context;

  /// Citations for the retrieved chunks.
  final List<Citation> citations;

  /// Error message if retrieval failed.
  final String? error;

  /// Check if retrieval was successful.
  bool get isSuccess => error == null && context.isNotEmpty;

  /// Create an error result.
  factory RetrievalResult.error(String message) {
    return RetrievalResult(
      context: '',
      citations: [],
      error: message,
    );
  }

  /// Create an empty result.
  factory RetrievalResult.empty() {
    return const RetrievalResult(
      context: '',
      citations: [],
    );
  }
}

/// Service for Retrieval-Augmented Generation (RAG).
///
/// Uses BM25 ranking for fast, model-free retrieval:
/// 1. Load all chunks for the document
/// 2. Build BM25 index from chunk text
/// 3. Score chunks against the query
/// 4. Return top-k chunks as context with citations
class RagService {
  RagService(this._db, this._bm25Service);

  final Database? _db;
  final BM25Service _bm25Service;

  /// Configuration
  static const int topKChunks = 5;
  static const int maxContextTokens = 3000; // ~12000 chars
  static const double minScoreThreshold = 0.1;

  /// Cache for BM25 indexes per document.
  final Map<int, BM25Index> _indexCache = {};

  /// Retrieve relevant context for a query.
  Future<RetrievalResult> retrieve(int documentId, String query) async {
    if (_db == null) {
      return RetrievalResult.error('Database not available');
    }

    try {
      debugPrint(
          'RagService: Retrieving context for: "${query.substring(0, query.length.clamp(0, 50))}..."');

      // Get or build BM25 index for this document
      final index = await _getOrBuildIndex(documentId);
      if (index == null || index.chunkCount == 0) {
        return RetrievalResult.error(
            'No indexed content found for this document');
      }

      // Search using BM25
      final results = _bm25Service.search(index, query, topK: topKChunks);

      if (results.isEmpty) {
        debugPrint('RagService: No relevant chunks found');
        return RetrievalResult.empty();
      }

      // Filter by minimum score
      final filtered =
          results.where((r) => r.score >= minScoreThreshold).toList();

      if (filtered.isEmpty) {
        debugPrint('RagService: All results below score threshold');
        return RetrievalResult.empty();
      }

      debugPrint('RagService: Found ${filtered.length} relevant chunks');

      // Build context and citations within token limit
      return _buildResult(filtered);
    } catch (e) {
      debugPrint('RagService: Retrieval error: $e');
      return RetrievalResult.error('Retrieval failed: ${e.toString()}');
    }
  }

  /// Get cached index or build a new one.
  Future<BM25Index?> _getOrBuildIndex(int documentId) async {
    if (_indexCache.containsKey(documentId)) {
      return _indexCache[documentId];
    }

    final chunksTable = DocumentChunksTable(_db!);
    final chunks = await chunksTable.getByDocumentId(documentId);

    if (chunks.isEmpty) return null;

    final indexableChunks = chunks
        .map((c) => IndexableChunk(
              id: c.id ?? 0,
              text: c.chunkText,
              pageNumber: c.pageNumber,
              chunkIndex: c.chunkIndex,
              startOffset: c.startOffset,
              endOffset: c.endOffset,
            ))
        .toList();

    final index = _bm25Service.buildIndex(indexableChunks);
    _indexCache[documentId] = index;
    return index;
  }

  /// Invalidate cached index for a document (call after reprocessing).
  void invalidateIndex(int documentId) {
    _indexCache.remove(documentId);
  }

  /// Build the final result with context and citations, respecting token limit.
  RetrievalResult _buildResult(List<BM25Result> results) {
    final contextParts = <String>[];
    final citations = <Citation>[];
    int totalChars = 0;
    const maxChars = maxContextTokens * 4; // ~4 chars per token

    for (final result in results) {
      final chunk = result.chunk;
      final chunkText = chunk.text;

      if (totalChars + chunkText.length > maxChars) {
        // Truncate if needed to fit within limit
        final remaining = maxChars - totalChars;
        if (remaining > 100) {
          final truncated = chunkText.substring(0, remaining);
          contextParts.add('[Page ${chunk.pageNumber}] $truncated...');
          citations.add(Citation(
            pageNumber: chunk.pageNumber,
            chunkIndex: chunk.chunkIndex,
            text: _createSnippet(chunkText),
            relevanceScore: result.score,
          ));
        }
        break;
      }

      contextParts.add('[Page ${chunk.pageNumber}] $chunkText');
      citations.add(Citation(
        pageNumber: chunk.pageNumber,
        chunkIndex: chunk.chunkIndex,
        text: _createSnippet(chunkText),
        relevanceScore: result.score,
      ));
      totalChars += chunkText.length;
    }

    final context = contextParts.join('\n\n');

    debugPrint(
        'RagService: Built context with ${contextParts.length} chunks, ${context.length} chars');

    return RetrievalResult(
      context: context,
      citations: citations,
    );
  }

  /// Create a short snippet from chunk text.
  String _createSnippet(String text, {int maxLength = 150}) {
    if (text.length <= maxLength) return text;

    // Try to cut at a sentence boundary
    final cutoff = text.lastIndexOf('. ', maxLength - 3);
    if (cutoff > maxLength / 2) {
      return text.substring(0, cutoff + 1);
    }

    // Fall back to word boundary
    final spaceIndex = text.lastIndexOf(' ', maxLength - 3);
    if (spaceIndex > maxLength / 2) {
      return '${text.substring(0, spaceIndex)}...';
    }

    return '${text.substring(0, maxLength - 3)}...';
  }
}
