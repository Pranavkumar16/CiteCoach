import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/document_chunks_table.dart';
import '../../../core/database/tables/document_pages_table.dart';
import '../../processing/data/embedding_service.dart';
import '../domain/chat_message.dart';

/// Provider for the RAG service.
final ragServiceProvider = Provider<RagService>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  final embeddingService = ref.watch(embeddingServiceProvider);
  return RagService(db, embeddingService);
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

/// A scored chunk from retrieval.
class ScoredChunk {
  const ScoredChunk({
    required this.chunk,
    required this.score,
  });

  final ChunkRecord chunk;
  final double score;
}

/// Service for Retrieval-Augmented Generation (RAG).
/// 
/// Implements a hierarchical retrieval strategy:
/// 1. First, find relevant pages using page-level embeddings
/// 2. Then, retrieve chunks from those pages
/// 3. Rank chunks by similarity and return top-k
class RagService {
  RagService(this._db, this._embeddingService);

  final Database? _db;
  final EmbeddingService _embeddingService;

  /// Configuration
  static const int topKPages = 3; // Number of pages to consider
  static const int topKChunks = 5; // Number of chunks to return
  static const int maxContextTokens = 3000; // ~12000 chars
  static const double minSimilarityThreshold = 0.3;

  /// Retrieve relevant context for a query.
  Future<RetrievalResult> retrieve(int documentId, String query) async {
    if (_db == null) {
      return RetrievalResult.error('Database not available');
    }

    try {
      debugPrint('RagService: Retrieving context for query: "${query.substring(0, query.length.clamp(0, 50))}..."');

      // Generate query embedding
      final queryEmbedding = await _embeddingService.generateQueryEmbedding(query);
      if (queryEmbedding == null) {
        return RetrievalResult.error('Failed to generate query embedding');
      }

      // Step 1: Find relevant pages
      final relevantPages = await _findRelevantPages(documentId, queryEmbedding);
      if (relevantPages.isEmpty) {
        debugPrint('RagService: No relevant pages found');
        return RetrievalResult.empty();
      }

      debugPrint('RagService: Found ${relevantPages.length} relevant pages');

      // Step 2: Retrieve and rank chunks from relevant pages
      final rankedChunks = await _retrieveAndRankChunks(
        documentId,
        relevantPages,
        queryEmbedding,
      );

      if (rankedChunks.isEmpty) {
        debugPrint('RagService: No relevant chunks found');
        return RetrievalResult.empty();
      }

      debugPrint('RagService: Retrieved ${rankedChunks.length} chunks');

      // Step 3: Build context and citations
      return _buildResult(rankedChunks);
    } catch (e) {
      debugPrint('RagService: Retrieval error: $e');
      return RetrievalResult.error('Retrieval failed: ${e.toString()}');
    }
  }

  /// Find relevant pages using page-level embeddings.
  Future<List<int>> _findRelevantPages(
    int documentId,
    Float32List queryEmbedding,
  ) async {
    final pagesTable = DocumentPagesTable(_db!);
    final pageEmbeddingsList = await pagesTable.getPageEmbeddings(documentId);

    if (pageEmbeddingsList.isEmpty) {
      // Fall back to returning all pages if no embeddings
      final pages = await pagesTable.getByDocumentId(documentId);
      return pages.map((p) => p.pageNumber).take(topKPages).toList();
    }

    // Score each page - pageEmbeddingsList is List<(int, Float32List)>
    final scoredPages = <MapEntry<int, double>>[];
    for (final (pageNumber, embedding) in pageEmbeddingsList) {
      final score = EmbeddingService.cosineSimilarity(queryEmbedding, embedding);
      if (score >= minSimilarityThreshold) {
        scoredPages.add(MapEntry(pageNumber, score));
      }
    }

    // Sort by score descending
    scoredPages.sort((a, b) => b.value.compareTo(a.value));

    // Return top-k page numbers
    return scoredPages.take(topKPages).map((e) => e.key).toList();
  }

  /// Retrieve and rank chunks from relevant pages.
  Future<List<ScoredChunk>> _retrieveAndRankChunks(
    int documentId,
    List<int> pageNumbers,
    Float32List queryEmbedding,
  ) async {
    final chunksTable = DocumentChunksTable(_db!);
    
    // Get chunks from relevant pages
    final chunks = await chunksTable.getByPages(documentId, pageNumbers);
    
    if (chunks.isEmpty) {
      return [];
    }

    // Get embeddings for these chunks - returns List<(int, int, Float32List)>
    final chunkEmbeddingsList = await chunksTable.getChunkEmbeddingsByPages(
      documentId,
      pageNumbers,
    );

    // Convert to map for lookup: chunkId -> embedding
    final chunkEmbeddings = <int, Float32List>{};
    for (final (id, _, embedding) in chunkEmbeddingsList) {
      chunkEmbeddings[id] = embedding;
    }

    // Score each chunk
    final scoredChunks = <ScoredChunk>[];
    for (final chunk in chunks) {
      final embedding = chunkEmbeddings[chunk.id];
      double score = 0.0;
      
      if (embedding != null) {
        score = EmbeddingService.cosineSimilarity(queryEmbedding, embedding);
      } else {
        // Fall back to keyword matching if no embedding
        score = _keywordScore(chunk.chunkText, queryEmbedding.toString());
      }

      if (score >= minSimilarityThreshold) {
        scoredChunks.add(ScoredChunk(chunk: chunk, score: score));
      }
    }

    // Sort by score descending
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    // Return top-k chunks, respecting token limit
    return _selectChunksWithinLimit(scoredChunks);
  }

  /// Simple keyword-based scoring fallback.
  double _keywordScore(String text, String query) {
    final textLower = text.toLowerCase();
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    
    int matches = 0;
    for (final word in queryWords) {
      if (word.length > 2 && textLower.contains(word)) {
        matches++;
      }
    }
    
    return queryWords.isNotEmpty ? matches / queryWords.length : 0.0;
  }

  /// Select chunks within the token limit.
  List<ScoredChunk> _selectChunksWithinLimit(List<ScoredChunk> chunks) {
    final selected = <ScoredChunk>[];
    int totalTokens = 0;

    for (final chunk in chunks) {
      if (selected.length >= topKChunks) break;
      
      final chunkTokens = chunk.chunk.tokenCount;
      if (totalTokens + chunkTokens <= maxContextTokens) {
        selected.add(chunk);
        totalTokens += chunkTokens;
      }
    }

    return selected;
  }

  /// Build the final result with context and citations.
  RetrievalResult _buildResult(List<ScoredChunk> rankedChunks) {
    final contextParts = <String>[];
    final citations = <Citation>[];

    for (int i = 0; i < rankedChunks.length; i++) {
      final scored = rankedChunks[i];
      final chunk = scored.chunk;

      // Add to context with page reference
      contextParts.add('[Page ${chunk.pageNumber}] ${chunk.chunkText}');

      // Create citation
      citations.add(Citation(
        pageNumber: chunk.pageNumber,
        chunkIndex: chunk.chunkIndex,
        text: _createSnippet(chunk.chunkText),
        relevanceScore: scored.score,
      ));
    }

    final context = contextParts.join('\n\n');

    debugPrint('RagService: Built context with ${contextParts.length} chunks, ${context.length} chars');

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
