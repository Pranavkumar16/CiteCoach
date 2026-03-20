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
  final documentRepository = ref.watch(documentRepositoryProvider);

  return ProcessingNotifier(
    documentId: documentId,
    db: db,
    pdfProcessor: pdfProcessor,
    documentRepository: documentRepository,
  );
});

/// State notifier for document processing.
///
/// Processing pipeline:
/// 1. Load PDF file
/// 2. Extract text page by page (Syncfusion)
/// 3. Chunk text with overlap for RAG retrieval
/// 4. Store pages and chunks in SQLite
///
/// BM25 retrieval indexes are built on-the-fly at query time
/// from the stored text, so no embedding step is needed.
class ProcessingNotifier extends StateNotifier<ProcessingState> {
  ProcessingNotifier({
    required this.documentId,
    required Database? db,
    required PdfProcessor pdfProcessor,
    required DocumentRepository documentRepository,
  })  : _db = db,
        _pdfProcessor = pdfProcessor,
        _documentRepository = documentRepository,
        super(ProcessingState.initial(documentId));

  final int documentId;
  final Database? _db;
  final PdfProcessor _pdfProcessor;
  final DocumentRepository _documentRepository;

  bool _isCancelled = false;

  /// Start processing the document.
  Future<bool> startProcessing() async {
    if (_db == null) {
      state = ProcessingState.error(documentId, 'Database not available');
      return false;
    }

    _isCancelled = false;

    try {
      debugPrint(
          'ProcessingNotifier: Starting processing for document $documentId');

      // Get the document
      final document = await _documentRepository.getDocument(documentId);
      if (document == null) {
        state = ProcessingState.error(documentId, 'Document not found');
        return false;
      }

      // Update status to processing
      await _documentRepository.updateStatus(
          documentId, DocumentStatus.processing);

      // Step 1: Load PDF
      state = state.copyWith(
        currentPhase: ProcessingPhase.loading,
        overallProgress: 0.05,
        stepProgress: 0.0,
      );

      if (_isCancelled) return false;

      // Step 2: Extract text
      state = state.copyWith(
        currentPhase: ProcessingPhase.extractingText,
        overallProgress: 0.1,
        stepProgress: 0.0,
      );

      final extractionResult = await _pdfProcessor.extractText(
        document.filePath,
        onProgress: (current, total, status) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.1 + (stepProgress * 0.4); // 10-50%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
              pageCount: total,
              pagesProcessed: current,
            );
          }
        },
      );

      if (_isCancelled) return false;

      if (!extractionResult.isSuccess) {
        await _setError(extractionResult.error ?? 'Text extraction failed');
        return false;
      }

      debugPrint(
          'ProcessingNotifier: Extracted ${extractionResult.pages.length} pages');

      // Save extracted pages to database
      await _savePages(extractionResult.pages);

      // Step 3: Chunk text
      state = state.copyWith(
        currentPhase: ProcessingPhase.chunking,
        overallProgress: 0.5,
        stepProgress: 0.0,
        pageCount: extractionResult.pageCount,
      );

      if (_isCancelled) return false;

      final chunkingResult = await _pdfProcessor.chunkText(
        extractionResult.pages,
        onProgress: (current, total, status) {
          if (!_isCancelled) {
            final stepProgress = current / total;
            final overallProgress = 0.5 + (stepProgress * 0.3); // 50-80%
            state = state.copyWith(
              stepProgress: stepProgress,
              overallProgress: overallProgress,
            );
          }
        },
      );

      if (_isCancelled) return false;

      if (!chunkingResult.isSuccess) {
        await _setError(chunkingResult.error ?? 'Text chunking failed');
        return false;
      }

      debugPrint(
          'ProcessingNotifier: Created ${chunkingResult.chunks.length} chunks');

      // Save chunks to database
      await _saveChunks(chunkingResult.chunks);

      state = state.copyWith(
        chunksCreated: chunkingResult.chunks.length,
      );

      // Step 4: Finalize (no embedding step needed - BM25 works from text)
      state = state.copyWith(
        currentPhase: ProcessingPhase.finalizing,
        overallProgress: 0.95,
        stepProgress: 0.0,
      );

      if (_isCancelled) return false;

      // Mark document as ready
      await _documentRepository.markReady(
          documentId, extractionResult.pageCount);

      // Complete
      state = ProcessingState.completed(
        documentId,
        extractionResult.pageCount,
        chunkingResult.chunks.length,
      );

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
      ));
    }

    await pagesTable.insertBatch(pageRecords);
    debugPrint('ProcessingNotifier: Saved ${pageRecords.length} pages');
  }

  /// Save chunks to the database.
  Future<void> _saveChunks(List<TextChunk> chunks) async {
    if (_db == null) return;

    final chunksTable = DocumentChunksTable(_db);
    final chunkRecords = <ChunkRecord>[];

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
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
    debugPrint('ProcessingNotifier: Saved ${chunkRecords.length} chunks');
  }

  /// Set error state.
  Future<void> _setError(String message) async {
    await _documentRepository.setError(documentId, message);
    state = ProcessingState.error(documentId, message);
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
