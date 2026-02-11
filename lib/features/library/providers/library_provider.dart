import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_repository.dart';
import '../data/pdf_import_service.dart';
import '../domain/document.dart';

/// State for the library screen.
class LibraryState extends Equatable {
  const LibraryState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.sortOption = DocumentSortOption.addedNewest,
    this.isImporting = false,
    this.importError,
  });

  /// List of documents in the library.
  final List<Document> documents;

  /// Whether documents are being loaded.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Current sort option.
  final DocumentSortOption sortOption;

  /// Whether a PDF import is in progress.
  final bool isImporting;

  /// Error from the last import attempt.
  final String? importError;

  /// Check if the library is empty.
  bool get isEmpty => documents.isEmpty && !isLoading;

  /// Check if there's an error.
  bool get hasError => error != null;

  /// Get document count.
  int get documentCount => documents.length;

  /// Get documents that are ready.
  List<Document> get readyDocuments =>
      documents.where((d) => d.isReady).toList();

  /// Get documents that are processing.
  List<Document> get processingDocuments =>
      documents.where((d) => d.isProcessing).toList();

  /// Copy with updated fields.
  LibraryState copyWith({
    List<Document>? documents,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DocumentSortOption? sortOption,
    bool? isImporting,
    String? importError,
    bool clearImportError = false,
  }) {
    return LibraryState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sortOption: sortOption ?? this.sortOption,
      isImporting: isImporting ?? this.isImporting,
      importError: clearImportError ? null : (importError ?? this.importError),
    );
  }

  @override
  List<Object?> get props => [
        documents,
        isLoading,
        error,
        sortOption,
        isImporting,
        importError,
      ];
}

/// Provider for the library state notifier.
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  final importService = ref.watch(pdfImportServiceProvider);
  return LibraryNotifier(repository, importService);
});

/// Provider for just the document list.
final documentsProvider = Provider<List<Document>>((ref) {
  return ref.watch(libraryProvider).documents;
});

/// Provider for library loading state.
final isLibraryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(libraryProvider).isLoading;
});

/// Provider for library empty state.
final isLibraryEmptyProvider = Provider<bool>((ref) {
  return ref.watch(libraryProvider).isEmpty;
});

/// State notifier for managing the document library.
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._repository, this._importService)
      : super(const LibraryState()) {
    loadDocuments();
  }

  final DocumentRepository _repository;
  final PdfImportService _importService;

  /// Load all documents from the repository.
  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final documents = await _repository.getAllDocuments(
        sort: state.sortOption,
      );
      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
      debugPrint('LibraryNotifier: Loaded ${documents.length} documents');
    } catch (e) {
      debugPrint('LibraryNotifier: Error loading documents: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents',
      );
    }
  }

  /// Refresh the document list.
  Future<void> refresh() async {
    await loadDocuments();
  }

  /// Change the sort option.
  Future<void> setSortOption(DocumentSortOption option) async {
    if (state.sortOption == option) return;

    state = state.copyWith(sortOption: option);
    await loadDocuments();
  }

  /// Import a PDF using the file picker.
  Future<Document?> importPdf() async {
    state = state.copyWith(isImporting: true, clearImportError: true);

    try {
      final result = await _importService.pickAndImportPdf();

      if (result.cancelled) {
        state = state.copyWith(isImporting: false);
        return null;
      }

      if (result.isError) {
        state = state.copyWith(
          isImporting: false,
          importError: result.error,
        );
        return null;
      }

      // Reload documents to include the new one
      await loadDocuments();
      state = state.copyWith(isImporting: false);

      return result.document;
    } catch (e) {
      debugPrint('LibraryNotifier: Error importing PDF: $e');
      state = state.copyWith(
        isImporting: false,
        importError: 'Failed to import PDF',
      );
      return null;
    }
  }

  /// Import a PDF from a known path.
  Future<Document?> importFromPath(String filePath) async {
    state = state.copyWith(isImporting: true, clearImportError: true);

    try {
      final result = await _importService.importFromPath(filePath);

      if (result.isError) {
        state = state.copyWith(
          isImporting: false,
          importError: result.error,
        );
        return null;
      }

      await loadDocuments();
      state = state.copyWith(isImporting: false);

      return result.document;
    } catch (e) {
      debugPrint('LibraryNotifier: Error importing from path: $e');
      state = state.copyWith(
        isImporting: false,
        importError: 'Failed to import PDF',
      );
      return null;
    }
  }

  /// Get a single document by ID.
  Future<Document?> getDocument(int documentId) async {
    try {
      return await _repository.getDocument(documentId);
    } catch (e) {
      debugPrint('LibraryNotifier: Error getting document: $e');
      return null;
    }
  }

  /// Delete a document.
  Future<bool> deleteDocument(int documentId) async {
    try {
      final success = await _repository.deleteDocument(documentId);
      if (success) {
        await loadDocuments();
      }
      return success;
    } catch (e) {
      debugPrint('LibraryNotifier: Error deleting document: $e');
      return false;
    }
  }

  /// Update a document's last opened timestamp.
  Future<void> markDocumentOpened(int documentId) async {
    try {
      await _repository.updateLastOpened(documentId);
      // Reload if sorting by recently opened
      if (state.sortOption == DocumentSortOption.openedRecent) {
        await loadDocuments();
      }
    } catch (e) {
      debugPrint('LibraryNotifier: Error updating last opened: $e');
    }
  }

  /// Update a document in the list (e.g., after processing).
  void updateDocument(Document document) {
    final index = state.documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      final updatedList = List<Document>.from(state.documents);
      updatedList[index] = document;
      state = state.copyWith(documents: updatedList);
    }
  }

  /// Clear import error.
  void clearImportError() {
    state = state.copyWith(clearImportError: true);
  }

  /// Clear general error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for a single document by ID.
final documentByIdProvider =
    FutureProvider.family<Document?, int>((ref, id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocument(id);
});
