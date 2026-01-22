import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/document_chunks_table.dart';
import '../../../core/database/tables/document_pages_table.dart';
import '../../../core/database/tables/documents_table.dart';
import '../../library/data/document_repository.dart';
import '../../library/domain/document.dart';
import '../data/embedding_service.dart';
import '../data/pdf_processor.dart';
import '../domain/processing_state.dart';

/// Provider for the processing state notifier.
/// Use with a document ID to get the processing state for that document.
final processingProvider = StateNotifierProvider.family<
    ProcessingNotifier, ProcessingState, int>((ref, documentId) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  final pdfProcessor = ref.watch(pdfProcessorProvider);
  final embeddingService = ref.watch(embeddingServiceProvider);
  final documentRepository = ref.watch(documentRepositoryProvider);

  return ProcessingNotifier(
    documentId: documentId,
    db: db,
    pdfProcessor: pdfProcessor,
    embeddingService: embeddingService,
    documentRepository: documentRepository,
  );
});

/// State notifier for document processing.
class ProcessingNotifier extends StateNotifier<ProcessingState> {
  ProcessingNotifier({
    required this.documentId,
    required Database? db,
    required PdfProcessor pdfProcessor,
    required EmbeddingService embeddingService,
    required DocumentRepository documentRepository,
  })  : _db = db,
        _pdfProcessor = pdfProcessor,
        _embeddingService = embeddingService,
        _documentRepository = documentRepository,
        super(ProcessingState.initial(documentId));

  final int documentId;
  final Database? _db;
  final PdfProcessor _pdfProcessor;
  final EmbeddingService _embeddingService;
  final DocumentRepository _documentRepository;

  bool _isCancelled = false;
  double _lastSavedProgress = 0.0;

  /// Start processing the document.
  Future<bool> startProcessing() async {
    if (_db == null) {
      state = ProcessingState.error(documentId, 'Database not available');
      return false;
    }

    _isCancelled = false;

    try {
      debugPrint('ProcessingNotifier: Starting processing for document $documentId');

      // Get the document
      final document = await _documentRepository.getDocument(documentId);
      if (document == null) {
        state = ProcessingState.error(documentId, 'Document not found');
        return false;
      }

      // Update status to processing
      await _documentRepository.updateStatus(documentId, DocumentStatus.processing);

      // Step 1: Load PDF
      state = state.copyWith(
        currentPhase: ProcessingPhase.loading,
        overallProgress: 0.05,
        stepProgress: 0.0,
      );
      _persistProgress(0.05);

      if (_isCancelled) return false;

      // Step 2: Extract text
      state = state.copyWith(
        currentPhase: ProcessingPhase.extractingText,
        overallProgress: 0.1,
        stepProgress: 0.0,
      );
      _persistProgress(0.1);

      final extractionResult = await _pdfProcessor.extractText(
        document.filePath,
        onProgress: (current, total, status) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.1 + (stepProgress * 0.3); // 10-40%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
              pageCount: total,
              pagesProcessed: current,
            );
            _persistProgress(overallProgress);
          }
        },
      );

      if (_isCancelled) return false;

      if (!extractionResult.isSuccess) {
        await _setError(extractionResult.error ?? 'Text extraction failed');
        return false;
      }

      debugPrint('ProcessingNotifier: Extracted ${extractionResult.pages.length} pages');

      // Save extracted pages to database
      await _savePages(extractionResult.pages);

      // Step 3: Chunk text
      state = state.copyWith(
        currentPhase: ProcessingPhase.chunking,
        overallProgress: 0.4,
        stepProgress: 0.0,
        pageCount: extractionResult.pageCount,
      );
      _persistProgress(0.4);

      if (_isCancelled) return false;

      final chunkingResult = await _pdfProcessor.chunkText(
        extractionResult.pages,
        onProgress: (current, total, status) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.4 + (stepProgress * 0.2); // 40-60%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
            );
            _persistProgress(overallProgress);
          }
        },
      );

      if (_isCancelled) return false;

      if (!chunkingResult.isSuccess) {
        await _setError(chunkingResult.error ?? 'Text chunking failed');
        return false;
      }

      debugPrint('ProcessingNotifier: Created ${chunkingResult.chunks.length} chunks');

      // Save chunks to database
      await _saveChunks(chunkingResult.chunks);

      state = state.copyWith(
        chunksCreated: chunkingResult.chunks.length,
      );

      // Step 4: Generate embeddings
      state = state.copyWith(
        currentPhase: ProcessingPhase.embedding,
        overallProgress: 0.6,
        stepProgress: 0.0,
      );
      _persistProgress(0.6);

      if (_isCancelled) return false;

      final embeddingResult = await _embeddingService.generateEmbeddings(
        chunkingResult.chunks,
        onProgress: (current, total) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.6 + (stepProgress * 0.2); // 60-80%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
            );
            _persistProgress(overallProgress);
          }
        },
      );

      if (_isCancelled) return false;

      if (!embeddingResult.isSuccess) {
        await _setError(embeddingResult.error ?? 'Embedding generation failed');
        return false;
      }

      debugPrint('ProcessingNotifier: Generated ${embeddingResult.embeddings.length} embeddings');

      // Save embeddings to database
      await _saveEmbeddings(chunkingResult.chunks, embeddingResult.embeddings);

      // Build page-level embeddings for hierarchical retrieval
      await _generatePageEmbeddings(
        extractionResult.pages,
        onProgress: (current, total) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.8 + (stepProgress * 0.1); // 80-90%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
              pagesProcessed: current,
            );
            _persistProgress(overallProgress);
          }
        },
      );

      // Step 5: Finalize
      state = state.copyWith(
        currentPhase: ProcessingPhase.finalizing,
        overallProgress: 0.9,
        stepProgress: 0.0,
      );
      _persistProgress(0.9);

      if (_isCancelled) return false;

      // Mark document as ready
      await _documentRepository.markReady(documentId, extractionResult.pageCount);

      // Complete
      state = ProcessingState.completed(
        documentId,
        extractionResult.pageCount,
        chunkingResult.chunks.length,
      );
      _persistProgress(1.0);

      debugPrint('ProcessingNotifier: Processing complete!');
      return true;
    } catch (e) {
      debugPrint('ProcessingNotifier: Error during processing: $e');
      await _setError('Processing failed: ${e.toString()}');
      return false;
    }
  }

  /// Save extracted pages to the database.
  Future<void> _savePages(Map<int, String> pages) async {
    if (_db == null) return;

    final pagesTable = DocumentPagesTable(_db);
    final pageRecords = <PageRecord>[];

    for (final entry in pages.entries) {
      pageRecords.add(PageRecord(
        documentId: documentId,
        pageNumber: entry.key,
        pageText: entry.value,
        charCount: entry.value.length,
      ));
    }

    await pagesTable.insertBatch(pageRecords);
    debugPrint('ProcessingNotifier: Saved ${pageRecords.length} pages');
  }

  /// Save chunks to the database.
  Future<void> _saveChunks(List<TextChunk> chunks) async {
    if (_db == null) return;

    final chunksTable = DocumentChunksTable(_db);
    final pagesTable = DocumentPagesTable(_db);
    final chunkRecords = <ChunkRecord>[];
    final chunkCounts = <int, int>{};

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      chunkCounts[chunk.pageNumber] =
          (chunkCounts[chunk.pageNumber] ?? 0) + 1;
      chunkRecords.add(ChunkRecord(
        documentId: documentId,
        pageNumber: chunk.pageNumber,
        chunkIndex: i,
        chunkText: chunk.text,
        startOffset: chunk.startOffset,
        endOffset: chunk.endOffset,
        tokenCount: chunk.estimatedTokens,
      ));
    }

    await chunksTable.insertBatch(chunkRecords);
    for (final entry in chunkCounts.entries) {
      await pagesTable.updateChunkCount(documentId, entry.key, entry.value);
    }
    debugPrint('ProcessingNotifier: Saved ${chunkRecords.length} chunks');
  }

  /// Generate and store page-level embeddings for hierarchical retrieval.
  Future<void> _generatePageEmbeddings(
    Map<int, String> pages, {
    EmbeddingProgressCallback? onProgress,
  }) async {
    if (_db == null) return;

    final pagesTable = DocumentPagesTable(_db);
    final pageNumbers = pages.keys.toList()..sort();

    for (int i = 0; i < pageNumbers.length; i++) {
      final pageNumber = pageNumbers[i];
      final text = pages[pageNumber] ?? '';

      final embedding = await _embeddingService.generateQueryEmbedding(text);
      if (embedding != null) {
        await pagesTable.updateEmbedding(documentId, pageNumber, embedding);
      }

      onProgress?.call(i + 1, pageNumbers.length);

      if (_isCancelled) return;
    }
  }

  /// Save embeddings to the database.
  Future<void> _saveEmbeddings(
    List<TextChunk> chunks,
    Map<int, dynamic> embeddings,
  ) async {
    if (_db == null) return;

    final chunksTable = DocumentChunksTable(_db);

    // Get chunk IDs from database (they were just inserted)
    final savedChunks = await chunksTable.getByDocumentId(documentId);

    for (int i = 0; i < savedChunks.length && i < embeddings.length; i++) {
      final chunk = savedChunks[i];
      final embedding = embeddings[i];
      if (chunk.id != null && embedding != null) {
        await chunksTable.updateEmbedding(chunk.id!, embedding);
      }
    }

    debugPrint('ProcessingNotifier: Saved embeddings');
  }

  /// Set error state.
  Future<void> _setError(String message) async {
    await _documentRepository.setError(documentId, message);
    state = ProcessingState.error(documentId, message);
  }

  Future<void> _persistProgress(double progress) async {
    if (_db == null) return;
    if (progress <= 0) return;

    final shouldPersist =
        progress >= 1.0 || (progress - _lastSavedProgress).abs() >= 0.05;
    if (!shouldPersist) return;

    _lastSavedProgress = progress;
    await _documentRepository.updateProgress(documentId, progress);
  }

  /// Cancel processing.
  void cancel() {
    _isCancelled = true;
    debugPrint('ProcessingNotifier: Processing cancelled');
  }

  /// Retry processing after an error.
  Future<bool> retry() async {
    state = ProcessingState.initial(documentId);
    return startProcessing();
  }

  @override
  void dispose() {
    _isCancelled = true;
    super.dispose();
  }
}

/// Provider to check if a document is fully processed.
final isDocumentProcessedProvider =
    FutureProvider.family<bool, int>((ref, documentId) async {
  final repository = ref.watch(documentRepositoryProvider);
  final document = await repository.getDocument(documentId);
  return document?.isReady ?? false;
});

/// Provider to get document by ID with auto-refresh.
final documentProvider =
    FutureProvider.family<Document?, int>((ref, documentId) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocument(documentId);
});
