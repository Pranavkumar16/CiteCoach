import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../processing/data/document_text_extractor.dart';
import '../domain/document.dart';
import 'document_repository.dart';

/// Provider for the document import service.
final documentImportServiceProvider = Provider<DocumentImportService>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentImportService(repository);
});

// Keep old name for backward compatibility
final pdfImportServiceProvider = documentImportServiceProvider;

/// Result of a document import operation.
class ImportResult {
  const ImportResult({
    this.document,
    this.error,
    this.cancelled = false,
  });

  final Document? document;
  final String? error;
  final bool cancelled;

  bool get isSuccess => document != null && error == null && !cancelled;
  bool get isError => error != null;

  factory ImportResult.success(Document document) =>
      ImportResult(document: document);
  factory ImportResult.error(String message) => ImportResult(error: message);
  factory ImportResult.cancelled() => const ImportResult(cancelled: true);
}

/// Service for importing documents of all supported types.
///
/// Supports: PDF, DOCX, DOC, TXT, MD, EPUB, JPG, PNG, and other images.
/// Scanned PDFs and images are handled via on-device OCR.
class DocumentImportService {
  DocumentImportService(this._repository);

  final DocumentRepository _repository;

  /// Open file picker and import selected document.
  Future<ImportResult> pickAndImportDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentType.supportedExtensions,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('DocumentImportService: User cancelled file picker');
        return ImportResult.cancelled();
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null || filePath.isEmpty) {
        return ImportResult.error('Could not access the selected file');
      }

      // Validate extension
      final docType = DocumentType.fromExtension(filePath);
      if (docType == DocumentType.unknown) {
        return ImportResult.error(
          'Unsupported file format. Supported: PDF, Word, TXT, Markdown, EPUB, and images.',
        );
      }

      debugPrint('DocumentImportService: Selected $docType file: $filePath');

      // Import the document
      final document = await _repository.importDocument(filePath);

      if (document == null) {
        return ImportResult.error('Failed to import the document');
      }

      debugPrint('DocumentImportService: Successfully imported: ${document.title}');
      return ImportResult.success(document);
    } catch (e) {
      debugPrint('DocumentImportService: Error: $e');
      return ImportResult.error('Error importing document: ${e.toString()}');
    }
  }

  /// Import a document from a known path (e.g., from share intent).
  Future<ImportResult> importFromPath(String filePath) async {
    try {
      final docType = DocumentType.fromExtension(filePath);
      if (docType == DocumentType.unknown) {
        return ImportResult.error('Unsupported file format');
      }

      final document = await _repository.importDocument(filePath);
      if (document == null) {
        return ImportResult.error('Failed to import the document');
      }

      return ImportResult.success(document);
    } catch (e) {
      return ImportResult.error('Error importing: ${e.toString()}');
    }
  }

  /// Legacy method name — redirects to pickAndImportDocument.
  Future<ImportResult> pickAndImportPdf() => pickAndImportDocument();
}

/// Backward-compatible type alias.
typedef PdfImportService = DocumentImportService;
