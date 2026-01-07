import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Data class representing a cached Q&A pair in the database.
class QuestionCacheRecord {
  const QuestionCacheRecord({
    this.id,
    required this.documentId,
    required this.questionOriginal,
    required this.questionNormalized,
    required this.answer,
    this.citations = const [],
    this.hitCount = 0,
    this.lastHitAt,
    this.createdAt,
    this.expiresAt,
  });

  final int? id;
  final int documentId;
  final String questionOriginal;
  final String questionNormalized;
  final String answer;
  final List<int> citations;
  final int hitCount;
  final DateTime? lastHitAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  /// Create from database row.
  factory QuestionCacheRecord.fromMap(Map<String, dynamic> map) {
    List<int> citations = [];
    final citationsJson = map['citations_json'] as String?;
    if (citationsJson != null && citationsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(citationsJson);
        if (decoded is List) {
          citations = decoded.cast<int>();
        }
      } catch (_) {
        // Invalid JSON, keep empty list
      }
    }

    return QuestionCacheRecord(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      questionOriginal: map['question_original'] as String,
      questionNormalized: map['question_normalized'] as String,
      answer: map['answer'] as String,
      citations: citations,
      hitCount: map['hit_count'] as int? ?? 0,
      lastHitAt: map['last_hit_at'] != null
          ? DateTime.parse(map['last_hit_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'question_original': questionOriginal,
      'question_normalized': questionNormalized,
      'answer': answer,
      'citations_json': citations.isNotEmpty ? jsonEncode(citations) : null,
      'hit_count': hitCount,
      'last_hit_at': lastHitAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  QuestionCacheRecord copyWith({
    int? id,
    int? documentId,
    String? questionOriginal,
    String? questionNormalized,
    String? answer,
    List<int>? citations,
    int? hitCount,
    DateTime? lastHitAt,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return QuestionCacheRecord(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      questionOriginal: questionOriginal ?? this.questionOriginal,
      questionNormalized: questionNormalized ?? this.questionNormalized,
      answer: answer ?? this.answer,
      citations: citations ?? this.citations,
      hitCount: hitCount ?? this.hitCount,
      lastHitAt: lastHitAt ?? this.lastHitAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if cache entry has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Database operations for the question_cache table.
class QuestionCacheTable {
  const QuestionCacheTable(this._db);

  final Database _db;
  static const String tableName = 'question_cache';

  /// Default cache expiration: 30 days.
  static const Duration defaultExpiration = Duration(days: 30);

  /// Max cache entries per document.
  static const int maxEntriesPerDocument = 500;

  /// Insert a new cache entry.
  Future<int> insert(QuestionCacheRecord entry) async {
    return _db.insert(tableName, entry.toMap());
  }

  /// Cache a Q&A pair with automatic normalization and expiration.
  Future<int> cacheAnswer({
    required int documentId,
    required String question,
    required String answer,
    List<int> citations = const [],
    Duration? expiration,
  }) async {
    final normalizedQuestion = normalizeQuestion(question);
    final expiresAt = DateTime.now().add(expiration ?? defaultExpiration);

    final entry = QuestionCacheRecord(
      documentId: documentId,
      questionOriginal: question,
      questionNormalized: normalizedQuestion,
      answer: answer,
      citations: citations,
      expiresAt: expiresAt,
    );

    // Check if we need to evict old entries
    final count = await countByDocumentId(documentId);
    if (count >= maxEntriesPerDocument) {
      await _evictOldestEntries(documentId, count - maxEntriesPerDocument + 1);
    }

    return insert(entry);
  }

  /// Lookup a cached answer by normalized question.
  /// Returns null if not found or expired.
  Future<QuestionCacheRecord?> lookup(int documentId, String question) async {
    final normalizedQuestion = normalizeQuestion(question);

    final results = await _db.query(
      tableName,
      where: 'document_id = ? AND question_normalized = ?',
      whereArgs: [documentId, normalizedQuestion],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final entry = QuestionCacheRecord.fromMap(results.first);

    // Check if expired
    if (entry.isExpired) {
      await delete(entry.id!);
      return null;
    }

    // Update hit count and last hit timestamp
    await _recordHit(entry.id!);

    return entry;
  }

  /// Normalize a question for fuzzy matching.
  /// Converts to lowercase, removes punctuation, trims whitespace.
  static String normalizeQuestion(String question) {
    return question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Record a cache hit.
  Future<int> _recordHit(int id) async {
    return _db.rawUpdate(
      'UPDATE $tableName SET hit_count = hit_count + 1, last_hit_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Evict oldest/least used entries for a document.
  Future<void> _evictOldestEntries(int documentId, int count) async {
    // Delete entries with lowest hit count, oldest last_hit_at
    await _db.rawDelete('''
      DELETE FROM $tableName 
      WHERE id IN (
        SELECT id FROM $tableName 
        WHERE document_id = ? 
        ORDER BY hit_count ASC, last_hit_at ASC NULLS FIRST 
        LIMIT ?
      )
    ''', [documentId, count]);
  }

  /// Get all cache entries for a document.
  Future<List<QuestionCacheRecord>> getByDocumentId(int documentId) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at DESC',
    );

    return results.map(QuestionCacheRecord.fromMap).toList();
  }

  /// Get top cached questions by hit count.
  Future<List<QuestionCacheRecord>> getTopQuestions(
    int documentId, {
    int limit = 10,
  }) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'hit_count DESC',
      limit: limit,
    );

    return results.map(QuestionCacheRecord.fromMap).toList();
  }

  /// Delete a cache entry by ID.
  Future<int> delete(int id) async {
    return _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all cache entries for a document.
  Future<int> deleteByDocumentId(int documentId) async {
    return _db.delete(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Delete expired cache entries.
  Future<int> deleteExpired() async {
    return _db.delete(
      tableName,
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  /// Get cache entry count for a document.
  Future<int> countByDocumentId(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total hits for a document.
  Future<int> getTotalHits(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(hit_count) as total FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get cache statistics for a document.
  Future<CacheStats> getStats(int documentId) async {
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count, SUM(hit_count) as hits FROM $tableName WHERE document_id = ?',
      [documentId],
    );

    final row = countResult.first;
    return CacheStats(
      entryCount: (row['count'] as int?) ?? 0,
      totalHits: (row['hits'] as int?) ?? 0,
    );
  }
}

/// Cache statistics for a document.
class CacheStats {
  const CacheStats({
    required this.entryCount,
    required this.totalHits,
  });

  final int entryCount;
  final int totalHits;

  /// Average hits per entry.
  double get averageHits => entryCount > 0 ? totalHits / entryCount : 0;
}
