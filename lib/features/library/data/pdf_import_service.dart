import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/document.dart';
import 'document_repository.dart';

/// Provider for the PDF import service.
final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return PdfImportService(repository);
});

/// Result of a PDF import operation.
class ImportResult {
  const ImportResult({
    this.document,
    this.error,
    this.cancelled = false,
  });

  /// The imported document (if successful).
  final Document? document;

  /// Error message (if failed).
  final String? error;

  /// Whether the user cancelled the picker.
  final bool cancelled;

  /// Check if import was successful.
  bool get isSuccess => document != null && error == null && !cancelled;

  /// Check if import failed.
  bool get isError => error != null;

  /// Create a successful result.
  factory ImportResult.success(Document document) {
    return ImportResult(document: document);
  }

  /// Create an error result.
  factory ImportResult.error(String message) {
    return ImportResult(error: message);
  }

  /// Create a cancelled result.
  factory ImportResult.cancelled() {
    return const ImportResult(cancelled: true);
  }
}

/// Service for importing PDF files.
class PdfImportService {
  PdfImportService(this._repository);

  final DocumentRepository _repository;

  /// Open file picker and import selected PDF.
  Future<ImportResult> pickAndImportPdf() async {
    try {
      // Open file picker for PDFs only
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // Don't load file into memory
        withReadStream: false,
      );

      // Check if user cancelled
      if (result == null || result.files.isEmpty) {
        debugPrint('PdfImportService: User cancelled file picker');
        return ImportResult.cancelled();
      }

      final file = result.files.first;
      final filePath = file.path;

      // Validate file path
      if (filePath == null || filePath.isEmpty) {
        debugPrint('PdfImportService: Invalid file path');
        return ImportResult.error('Could not access the selected file');
      }

      // Validate file extension
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        return ImportResult.error('Please select a PDF file');
      }

      debugPrint('PdfImportService: Selected file: $filePath');

      // Import the PDF
      final document = await _repository.importPdf(filePath);

      if (document == null) {
        return ImportResult.error('Failed to import the PDF file');
      }

      debugPrint('PdfImportService: Successfully imported: ${document.title}');
      return ImportResult.success(document);
    } catch (e) {
      debugPrint('PdfImportService: Error during import: $e');
      return ImportResult.error('Error importing PDF: ${e.toString()}');
    }
  }

  /// Import a PDF from a known path (e.g., from share intent).
  Future<ImportResult> importFromPath(String filePath) async {
    try {
      // Validate file extension
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        return ImportResult.error('Please select a PDF file');
      }

      // Import the PDF
      final document = await _repository.importPdf(filePath);

      if (document == null) {
        return ImportResult.error('Failed to import the PDF file');
      }

      return ImportResult.success(document);
    } catch (e) {
      debugPrint('PdfImportService: Error importing from path: $e');
      return ImportResult.error('Error importing PDF: ${e.toString()}');
    }
  }
}
