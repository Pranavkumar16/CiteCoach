import 'package:sqflite/sqflite.dart';

/// Document status values.
enum DocumentStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  ready('READY'),
  error('ERROR');

  const DocumentStatus(this.value);
  final String value;

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.pending,
    );
  }
}

/// Data class representing a document in the database.
class DocumentRecord {
  const DocumentRecord({
    this.id,
    required this.title,
    required this.filePath,
    this.fileSize = 0,
    this.pageCount = 0,
    this.status = DocumentStatus.pending,
    this.errorMessage,
    required this.importedAt,
    this.lastOpenedAt,
    this.lastReadPage = 1,
    this.processingProgress = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String filePath;
  final int fileSize;
  final int pageCount;
  final DocumentStatus status;
  final String? errorMessage;
  final DateTime importedAt;
  final DateTime? lastOpenedAt;
  final int lastReadPage;
  final double processingProgress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create from database row.
  factory DocumentRecord.fromMap(Map<String, dynamic> map) {
    return DocumentRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int? ?? 0,
      pageCount: map['page_count'] as int? ?? 0,
      status: DocumentStatus.fromString(map['status'] as String? ?? 'PENDING'),
      errorMessage: map['error_message'] as String?,
      importedAt: DateTime.parse(map['imported_at'] as String),
      lastOpenedAt: map['last_opened_at'] != null
          ? DateTime.parse(map['last_opened_at'] as String)
          : null,
      lastReadPage: map['last_read_page'] as int? ?? 1,
      processingProgress: (map['processing_progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'file_path': filePath,
      'file_size': fileSize,
      'page_count': pageCount,
      'status': status.value,
      'error_message': errorMessage,
      'imported_at': importedAt.toIso8601String(),
      'last_opened_at': lastOpenedAt?.toIso8601String(),
      'last_read_page': lastReadPage,
      'processing_progress': processingProgress,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  DocumentRecord copyWith({
    int? id,
    String? title,
    String? filePath,
    int? fileSize,
    int? pageCount,
    DocumentStatus? status,
    String? errorMessage,
    DateTime? importedAt,
    DateTime? lastOpenedAt,
    int? lastReadPage,
    double? processingProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      processingProgress: processingProgress ?? this.processingProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Database operations for the documents table.
class DocumentsTable {
  const DocumentsTable(this._db);
  
  final Database _db;
  static const String tableName = 'documents';

  /// Insert a new document.
  Future<int> insert(DocumentRecord document) async {
    return _db.insert(tableName, document.toMap());
  }

  /// Get a document by ID.
  Future<DocumentRecord?> getById(int id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return DocumentRecord.fromMap(results.first);
  }

  /// Get all documents ordered by last opened date.
  Future<List<DocumentRecord>> getAll() async {
    final results = await _db.query(
      tableName,
      orderBy: 'last_opened_at DESC, imported_at DESC',
    );
    
    return results.map(DocumentRecord.fromMap).toList();
  }

  /// Get documents by status.
  Future<List<DocumentRecord>> getByStatus(DocumentStatus status) async {
    final results = await _db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'imported_at DESC',
    );
    
    return results.map(DocumentRecord.fromMap).toList();
  }

  /// Get documents that are ready for chat.
  Future<List<DocumentRecord>> getReadyDocuments() async {
    return getByStatus(DocumentStatus.ready);
  }

  /// Update a document.
  Future<int> update(DocumentRecord document) async {
    if (document.id == null) {
      throw ArgumentError('Cannot update document without ID');
    }
    
    return _db.update(
      tableName,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  /// Update document status.
  Future<int> updateStatus(int id, DocumentStatus status, {String? errorMessage}) async {
    return _db.update(
      tableName,
      {
        'status': status.value,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update processing progress.
  Future<int> updateProgress(int id, double progress) async {
    return _db.update(
      tableName,
      {
        'processing_progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update last opened timestamp and optionally last read page.
  Future<int> updateLastOpened(int id, {int? lastReadPage}) async {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'last_opened_at': now,
      'updated_at': now,
    };
    
    if (lastReadPage != null) {
      updates['last_read_page'] = lastReadPage;
    }
    
    return _db.update(
      tableName,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update page count after processing.
  Future<int> updatePageCount(int id, int pageCount) async {
    return _db.update(
      tableName,
      {
        'page_count': pageCount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a document by ID.
  /// Related pages, chunks, messages, and cache entries are deleted via CASCADE.
  Future<int> delete(int id) async {
    return _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get document count.
  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if a document exists by file path.
  Future<bool> existsByPath(String filePath) async {
    final result = await _db.query(
      tableName,
      columns: ['id'],
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
