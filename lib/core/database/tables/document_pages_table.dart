import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

/// Data class representing a page in the database.
class PageRecord {
  const PageRecord({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.pageText,
    this.pageEmbedding,
    this.chunkCount = 0,
    this.charCount = 0,
    this.createdAt,
  });

  final int? id;
  final int documentId;
  final int pageNumber;
  final String pageText;
  final Float32List? pageEmbedding; // 384-dim vector
  final int chunkCount;
  final int charCount;
  final DateTime? createdAt;

  /// Create from database row.
  factory PageRecord.fromMap(Map<String, dynamic> map) {
    Float32List? embedding;
    final embeddingBlob = map['page_embedding'];
    if (embeddingBlob != null && embeddingBlob is Uint8List) {
      embedding = embeddingBlob.buffer.asFloat32List();
    }

    return PageRecord(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      pageNumber: map['page_number'] as int,
      pageText: map['page_text'] as String,
      pageEmbedding: embedding,
      chunkCount: map['chunk_count'] as int? ?? 0,
      charCount: map['char_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    Uint8List? embeddingBlob;
    if (pageEmbedding != null) {
      embeddingBlob = Uint8List.view(pageEmbedding!.buffer);
    }

    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'page_text': pageText,
      'page_embedding': embeddingBlob,
      'chunk_count': chunkCount,
      'char_count': charCount,
    };
  }

  /// Create a copy with updated fields.
  PageRecord copyWith({
    int? id,
    int? documentId,
    int? pageNumber,
    String? pageText,
    Float32List? pageEmbedding,
    int? chunkCount,
    int? charCount,
    DateTime? createdAt,
  }) {
    return PageRecord(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      pageText: pageText ?? this.pageText,
      pageEmbedding: pageEmbedding ?? this.pageEmbedding,
      chunkCount: chunkCount ?? this.chunkCount,
      charCount: charCount ?? this.charCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Database operations for the document_pages table.
class DocumentPagesTable {
  const DocumentPagesTable(this._db);

  final Database _db;
  static const String tableName = 'document_pages';

  /// Insert a new page.
  Future<int> insert(PageRecord page) async {
    return _db.insert(
      tableName,
      page.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple pages in a batch (more efficient).
  Future<void> insertBatch(List<PageRecord> pages) async {
    final batch = _db.batch();
    for (final page in pages) {
      batch.insert(
        tableName,
        page.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get a page by document ID and page number.
  Future<PageRecord?> getPage(int documentId, int pageNumber) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return PageRecord.fromMap(results.first);
  }

  /// Get all pages for a document.
  Future<List<PageRecord>> getByDocumentId(int documentId) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC',
    );

    return results.map(PageRecord.fromMap).toList();
  }

  /// Get page text only (without embeddings for memory efficiency).
  Future<List<Map<String, dynamic>>> getPageTexts(int documentId) async {
    return _db.query(
      tableName,
      columns: ['page_number', 'page_text', 'char_count'],
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC',
    );
  }

  /// Get page embeddings only for hierarchical retrieval (Stage 1).
  /// Returns list of (pageNumber, embedding) for similarity search.
  Future<List<(int, Float32List)>> getPageEmbeddings(int documentId) async {
    final results = await _db.query(
      tableName,
      columns: ['page_number', 'page_embedding'],
      where: 'document_id = ? AND page_embedding IS NOT NULL',
      whereArgs: [documentId],
      orderBy: 'page_number ASC',
    );

    return results.map((row) {
      final pageNumber = row['page_number'] as int;
      final embeddingBlob = row['page_embedding'] as Uint8List;
      final embedding = embeddingBlob.buffer.asFloat32List();
      return (pageNumber, embedding);
    }).toList();
  }

  /// Update page embedding.
  Future<int> updateEmbedding(int documentId, int pageNumber, Float32List embedding) async {
    final embeddingBlob = Uint8List.view(embedding.buffer);
    
    return _db.update(
      tableName,
      {'page_embedding': embeddingBlob},
      where: 'document_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
    );
  }

  /// Update chunk count for a page.
  Future<int> updateChunkCount(int documentId, int pageNumber, int chunkCount) async {
    return _db.update(
      tableName,
      {'chunk_count': chunkCount},
      where: 'document_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
    );
  }

  /// Delete all pages for a document.
  Future<int> deleteByDocumentId(int documentId) async {
    return _db.delete(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get page count for a document.
  Future<int> countByDocumentId(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total character count for a document.
  Future<int> getTotalCharCount(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(char_count) as total FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
