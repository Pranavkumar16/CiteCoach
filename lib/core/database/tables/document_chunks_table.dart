import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

/// Data class representing a text chunk in the database.
class ChunkRecord {
  const ChunkRecord({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.chunkIndex,
    required this.chunkText,
    this.chunkEmbedding,
    this.startOffset = 0,
    this.endOffset = 0,
    this.tokenCount = 0,
    this.createdAt,
  });

  final int? id;
  final int documentId;
  final int pageNumber;
  final int chunkIndex;
  final String chunkText;
  final Float32List? chunkEmbedding; // 384-dim vector
  final int startOffset;
  final int endOffset;
  final int tokenCount;
  final DateTime? createdAt;

  /// Create from database row.
  factory ChunkRecord.fromMap(Map<String, dynamic> map) {
    Float32List? embedding;
    final embeddingBlob = map['chunk_embedding'];
    if (embeddingBlob != null && embeddingBlob is Uint8List) {
      embedding = embeddingBlob.buffer.asFloat32List();
    }

    return ChunkRecord(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      pageNumber: map['page_number'] as int,
      chunkIndex: map['chunk_index'] as int,
      chunkText: map['chunk_text'] as String,
      chunkEmbedding: embedding,
      startOffset: map['start_offset'] as int? ?? 0,
      endOffset: map['end_offset'] as int? ?? 0,
      tokenCount: map['token_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    Uint8List? embeddingBlob;
    if (chunkEmbedding != null) {
      embeddingBlob = Uint8List.view(chunkEmbedding!.buffer);
    }

    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'chunk_index': chunkIndex,
      'chunk_text': chunkText,
      'chunk_embedding': embeddingBlob,
      'start_offset': startOffset,
      'end_offset': endOffset,
      'token_count': tokenCount,
    };
  }

  /// Create a copy with updated fields.
  ChunkRecord copyWith({
    int? id,
    int? documentId,
    int? pageNumber,
    int? chunkIndex,
    String? chunkText,
    Float32List? chunkEmbedding,
    int? startOffset,
    int? endOffset,
    int? tokenCount,
    DateTime? createdAt,
  }) {
    return ChunkRecord(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText ?? this.chunkText,
      chunkEmbedding: chunkEmbedding ?? this.chunkEmbedding,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Database operations for the document_chunks table.
class DocumentChunksTable {
  const DocumentChunksTable(this._db);

  final Database _db;
  static const String tableName = 'document_chunks';

  /// Insert a new chunk.
  Future<int> insert(ChunkRecord chunk) async {
    return _db.insert(tableName, chunk.toMap());
  }

  /// Insert multiple chunks in a batch (more efficient).
  Future<void> insertBatch(List<ChunkRecord> chunks) async {
    final batch = _db.batch();
    for (final chunk in chunks) {
      batch.insert(tableName, chunk.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Get all chunks for a document.
  Future<List<ChunkRecord>> getByDocumentId(int documentId) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC, chunk_index ASC',
    );

    return results.map(ChunkRecord.fromMap).toList();
  }

  /// Get chunks for specific pages (Stage 2 retrieval).
  /// Only loads chunks from the top N pages from Stage 1.
  Future<List<ChunkRecord>> getByPages(int documentId, List<int> pageNumbers) async {
    if (pageNumbers.isEmpty) return [];

    final placeholders = List.filled(pageNumbers.length, '?').join(',');
    final results = await _db.query(
      tableName,
      where: 'document_id = ? AND page_number IN ($placeholders)',
      whereArgs: [documentId, ...pageNumbers],
      orderBy: 'page_number ASC, chunk_index ASC',
    );

    return results.map(ChunkRecord.fromMap).toList();
  }

  /// Get chunk embeddings for specific pages (for similarity search).
  Future<List<(int, int, Float32List)>> getChunkEmbeddingsByPages(
    int documentId,
    List<int> pageNumbers,
  ) async {
    if (pageNumbers.isEmpty) return [];

    final placeholders = List.filled(pageNumbers.length, '?').join(',');
    final results = await _db.query(
      tableName,
      columns: ['id', 'page_number', 'chunk_embedding'],
      where: 'document_id = ? AND page_number IN ($placeholders) AND chunk_embedding IS NOT NULL',
      whereArgs: [documentId, ...pageNumbers],
    );

    return results.map((row) {
      final id = row['id'] as int;
      final pageNumber = row['page_number'] as int;
      final embeddingBlob = row['chunk_embedding'] as Uint8List;
      final embedding = embeddingBlob.buffer.asFloat32List();
      return (id, pageNumber, embedding);
    }).toList();
  }

  /// Get chunk by ID.
  Future<ChunkRecord?> getById(int id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ChunkRecord.fromMap(results.first);
  }

  /// Get chunks by IDs (for assembling context after retrieval).
  Future<List<ChunkRecord>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await _db.query(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return results.map(ChunkRecord.fromMap).toList();
  }

  /// Get chunks for a specific page.
  Future<List<ChunkRecord>> getByPage(int documentId, int pageNumber) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      orderBy: 'chunk_index ASC',
    );

    return results.map(ChunkRecord.fromMap).toList();
  }

  /// Update chunk embedding.
  Future<int> updateEmbedding(int id, Float32List embedding) async {
    final embeddingBlob = Uint8List.view(embedding.buffer);

    return _db.update(
      tableName,
      {'chunk_embedding': embeddingBlob},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all chunks for a document.
  Future<int> deleteByDocumentId(int documentId) async {
    return _db.delete(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get chunk count for a document.
  Future<int> countByDocumentId(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total token count for a document.
  Future<int> getTotalTokenCount(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(token_count) as total FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get chunk count by page for a document.
  Future<Map<int, int>> getChunkCountsByPage(int documentId) async {
    final results = await _db.rawQuery(
      'SELECT page_number, COUNT(*) as count FROM $tableName WHERE document_id = ? GROUP BY page_number',
      [documentId],
    );

    return {
      for (final row in results)
        row['page_number'] as int: row['count'] as int,
    };
  }
}
