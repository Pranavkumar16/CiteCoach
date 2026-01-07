import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/documents_table.dart';
import '../domain/document.dart';

/// Provider for the document repository.
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  if (db == null) {
    throw Exception('Database not initialized');
  }
  return DocumentRepository(db);
});

/// Repository for managing PDF documents.
class DocumentRepository {
  DocumentRepository(this._db);

  final Database _db;

  /// Get the documents table helper.
  DocumentsTable get _table => DocumentsTable(_db);

  /// Get the directory for storing PDF files.
  Future<Directory> get _documentsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  /// Import a PDF file into the library.
  /// 
  /// Copies the file to app storage and creates a database record.
  /// Returns the created Document or null if import failed.
  Future<Document?> importPdf(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('DocumentRepository: Source file does not exist: $sourcePath');
        return null;
      }

      // Check if already imported
      final fileName = path.basename(sourcePath);
      final existingDoc = await _table.existsByPath(sourcePath);
      if (existingDoc) {
        debugPrint('DocumentRepository: File already imported: $fileName');
        // Return the existing document
        final docs = await _table.getAll();
        final existing = docs.firstWhere(
          (d) => d.filePath.endsWith(fileName),
          orElse: () => docs.first,
        );
        return Document.fromRecord(existing);
      }

      // Get file info
      final fileSize = await sourceFile.length();
      final title = _extractTitle(fileName);

      // Copy to app storage
      final docsDir = await _documentsDirectory;
      final destPath = '${docsDir.path}/$fileName';
      
      // Handle duplicate filenames
      String finalPath = destPath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final ext = path.extension(fileName);
        finalPath = '${docsDir.path}/${nameWithoutExt}_$counter$ext';
        counter++;
      }

      await sourceFile.copy(finalPath);
      debugPrint('DocumentRepository: Copied PDF to $finalPath');

      // Create database record
      final record = DocumentRecord(
        title: title,
        filePath: finalPath,
        status: DocumentStatus.pending,
        fileSize: fileSize,
        importedAt: DateTime.now(),
      );

      final id = await _table.insert(record);
      debugPrint('DocumentRepository: Created document record with id $id');

      // Fetch and return the created document
      final created = await _table.getById(id);
      if (created != null) {
        return Document.fromRecord(created);
      }
      return null;
    } catch (e) {
      debugPrint('DocumentRepository: Error importing PDF: $e');
      return null;
    }
  }

  /// Extract a clean title from the filename.
  String _extractTitle(String fileName) {
    // Remove extension
    String title = path.basenameWithoutExtension(fileName);
    
    // Replace underscores and hyphens with spaces
    title = title.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Remove multiple spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize first letter of each word
    title = title.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return title;
  }

  /// Get all documents, optionally sorted.
  Future<List<Document>> getAllDocuments({
    DocumentSortOption sort = DocumentSortOption.addedNewest,
  }) async {
    final records = await _table.getAll();
    final documents = records.map(Document.fromRecord).toList();
    
    // Sort based on option
    switch (sort) {
      case DocumentSortOption.addedNewest:
        documents.sort((a, b) => b.importedAt.compareTo(a.importedAt));
        break;
      case DocumentSortOption.addedOldest:
        documents.sort((a, b) => a.importedAt.compareTo(b.importedAt));
        break;
      case DocumentSortOption.openedRecent:
        documents.sort((a, b) {
          if (a.lastOpenedAt == null && b.lastOpenedAt == null) return 0;
          if (a.lastOpenedAt == null) return 1;
          if (b.lastOpenedAt == null) return -1;
          return b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
        });
        break;
      case DocumentSortOption.titleAZ:
        documents.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case DocumentSortOption.titleZA:
        documents.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
    
    return documents;
  }

  /// Get a single document by ID.
  Future<Document?> getDocument(int id) async {
    final record = await _table.getById(id);
    if (record != null) {
      return Document.fromRecord(record);
    }
    return null;
  }

  /// Get documents by status.
  Future<List<Document>> getDocumentsByStatus(DocumentStatus status) async {
    final records = await _table.getByStatus(status);
    return records.map(Document.fromRecord).toList();
  }

  /// Update document status.
  Future<bool> updateStatus(int id, DocumentStatus status) async {
    final rows = await _table.updateStatus(id, status);
    return rows > 0;
  }

  /// Update processing progress.
  Future<bool> updateProgress(int id, double progress) async {
    final rows = await _table.updateProgress(id, progress);
    return rows > 0;
  }

  /// Update page count after extraction.
  Future<bool> updatePageCount(int id, int pageCount) async {
    final rows = await _db.update(
      'documents',
      {'page_count': pageCount},
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  /// Set error state with message.
  Future<bool> setError(int id, String errorMessage) async {
    final rows = await _db.update(
      'documents',
      {
        'status': DocumentStatus.error.value,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  /// Mark document as ready.
  Future<bool> markReady(int id, int pageCount) async {
    final rows = await _db.update(
      'documents',
      {
        'status': DocumentStatus.ready.value,
        'page_count': pageCount,
        'processing_progress': 1.0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  /// Update last opened timestamp.
  Future<bool> updateLastOpened(int id) async {
    final rows = await _table.updateLastOpened(id);
    return rows > 0;
  }

  /// Update document title.
  Future<bool> updateTitle(int id, String title) async {
    final rows = await _db.update(
      'documents',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  /// Delete a document and its file.
  Future<bool> deleteDocument(int id) async {
    try {
      // Get the document first
      final doc = await getDocument(id);
      if (doc == null) return false;

      // Delete from database
      final deletedRows = await _table.delete(id);
      if (deletedRows == 0) return false;

      // Delete the file
      final file = File(doc.filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('DocumentRepository: Deleted file ${doc.filePath}');
      }

      return true;
    } catch (e) {
      debugPrint('DocumentRepository: Error deleting document: $e');
      return false;
    }
  }

  /// Get document count.
  Future<int> getDocumentCount() async {
    return _table.count();
  }

  /// Check if a file is already in the library.
  Future<bool> isFileImported(String filePath) async {
    final fileName = path.basename(filePath);
    final docs = await _table.getAll();
    return docs.any((d) => d.filePath.endsWith(fileName));
  }
}
