import 'package:equatable/equatable.dart';

import '../../../core/database/tables/documents_table.dart';

/// Domain model representing a PDF document in the library.
class Document extends Equatable {
  const Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.status,
    this.pageCount = 0,
    this.fileSize = 0,
    this.processingProgress = 0.0,
    this.errorMessage,
    required this.importedAt,
    this.lastOpenedAt,
  });

  /// Unique identifier.
  final int id;

  /// Document title (derived from filename or user-edited).
  final String title;

  /// Path to the PDF file in app storage.
  final String filePath;

  /// Current processing status.
  final DocumentStatus status;

  /// Total number of pages (set after text extraction).
  final int pageCount;

  /// File size in bytes.
  final int fileSize;

  /// Processing progress (0.0 to 1.0).
  final double processingProgress;

  /// Error message if processing failed.
  final String? errorMessage;

  /// When the document was added to the library.
  final DateTime importedAt;

  /// When the document was last opened.
  final DateTime? lastOpenedAt;

  /// Check if document is ready for chat.
  bool get isReady => status == DocumentStatus.ready;

  /// Check if document is currently processing.
  bool get isProcessing => status == DocumentStatus.processing;

  /// Check if document has an error.
  bool get hasError => status == DocumentStatus.error;

  /// Check if document is pending processing.
  bool get isPending => status == DocumentStatus.pending;

  /// Get human-readable file size.
  String get fileSizeFormatted {
    if (fileSize == 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get relative time string for when document was added.
  String get addedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(importedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${importedAt.day}/${importedAt.month}/${importedAt.year}';
  }

  /// Create from database record.
  factory Document.fromRecord(DocumentRecord record) {
    return Document(
      id: record.id!,
      title: record.title,
      filePath: record.filePath,
      status: record.status,
      pageCount: record.pageCount,
      fileSize: record.fileSize,
      processingProgress: record.processingProgress,
      errorMessage: record.errorMessage,
      importedAt: record.importedAt,
      lastOpenedAt: record.lastOpenedAt,
    );
  }

  /// Convert to database record for insertion.
  DocumentRecord toRecord() {
    return DocumentRecord(
      id: id == 0 ? null : id,
      title: title,
      filePath: filePath,
      status: status,
      pageCount: pageCount,
      fileSize: fileSize,
      processingProgress: processingProgress,
      errorMessage: errorMessage,
      importedAt: importedAt,
      lastOpenedAt: lastOpenedAt,
    );
  }

  /// Copy with updated fields.
  Document copyWith({
    int? id,
    String? title,
    String? filePath,
    DocumentStatus? status,
    int? pageCount,
    int? fileSize,
    double? processingProgress,
    String? errorMessage,
    bool clearError = false,
    DateTime? importedAt,
    DateTime? lastOpenedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      processingProgress: processingProgress ?? this.processingProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        filePath,
        status,
        pageCount,
        fileSize,
        processingProgress,
        errorMessage,
        importedAt,
        lastOpenedAt,
      ];
}

/// Sort options for the document library.
enum DocumentSortOption {
  /// Most recently added first.
  addedNewest,

  /// Oldest added first.
  addedOldest,

  /// Most recently opened first.
  openedRecent,

  /// Alphabetically by title.
  titleAZ,

  /// Reverse alphabetically by title.
  titleZA,
}

/// Extension for sort option labels.
extension DocumentSortOptionExtension on DocumentSortOption {
  String get label {
    switch (this) {
      case DocumentSortOption.addedNewest:
        return 'Newest First';
      case DocumentSortOption.addedOldest:
        return 'Oldest First';
      case DocumentSortOption.openedRecent:
        return 'Recently Opened';
      case DocumentSortOption.titleAZ:
        return 'Title A-Z';
      case DocumentSortOption.titleZA:
        return 'Title Z-A';
    }
  }
}
