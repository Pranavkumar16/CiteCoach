import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Message role in the conversation.
enum MessageRole {
  user('user'),
  assistant('assistant');

  const MessageRole(this.value);
  final String value;

  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => MessageRole.user,
    );
  }
}

/// Input method for user messages.
enum InputMethod {
  text('text'),
  voice('voice');

  const InputMethod(this.value);
  final String value;

  static InputMethod fromString(String value) {
    return InputMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => InputMethod.text,
    );
  }
}

/// Data class representing a chat message in the database.
class ChatMessageRecord {
  const ChatMessageRecord({
    this.id,
    required this.documentId,
    required this.role,
    required this.content,
    this.citations = const [],
    this.inputMethod = InputMethod.text,
    this.isCached = false,
    this.processingTimeMs,
    this.createdAt,
  });

  final int? id;
  final int documentId;
  final MessageRole role;
  final String content;
  final List<int> citations; // Page numbers
  final InputMethod inputMethod;
  final bool isCached;
  final int? processingTimeMs;
  final DateTime? createdAt;

  /// Create from database row.
  factory ChatMessageRecord.fromMap(Map<String, dynamic> map) {
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

    return ChatMessageRecord(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      role: MessageRole.fromString(map['role'] as String),
      content: map['content'] as String,
      citations: citations,
      inputMethod: InputMethod.fromString(map['input_method'] as String? ?? 'text'),
      isCached: (map['is_cached'] as int? ?? 0) == 1,
      processingTimeMs: map['processing_time_ms'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'role': role.value,
      'content': content,
      'citations_json': citations.isNotEmpty ? jsonEncode(citations) : null,
      'input_method': inputMethod.value,
      'is_cached': isCached ? 1 : 0,
      'processing_time_ms': processingTimeMs,
    };
  }

  /// Create a copy with updated fields.
  ChatMessageRecord copyWith({
    int? id,
    int? documentId,
    MessageRole? role,
    String? content,
    List<int>? citations,
    InputMethod? inputMethod,
    bool? isCached,
    int? processingTimeMs,
    DateTime? createdAt,
  }) {
    return ChatMessageRecord(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      inputMethod: inputMethod ?? this.inputMethod,
      isCached: isCached ?? this.isCached,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this is a user message.
  bool get isUser => role == MessageRole.user;

  /// Check if this is an assistant message.
  bool get isAssistant => role == MessageRole.assistant;

  /// Check if this message has citations.
  bool get hasCitations => citations.isNotEmpty;
}

/// Database operations for the chat_messages table.
class ChatMessagesTable {
  const ChatMessagesTable(this._db);

  final Database _db;
  static const String tableName = 'chat_messages';

  /// Insert a new message.
  Future<int> insert(ChatMessageRecord message) async {
    return _db.insert(tableName, message.toMap());
  }

  /// Insert a user message and return the record with ID.
  Future<ChatMessageRecord> insertUserMessage({
    required int documentId,
    required String content,
    InputMethod inputMethod = InputMethod.text,
  }) async {
    final message = ChatMessageRecord(
      documentId: documentId,
      role: MessageRole.user,
      content: content,
      inputMethod: inputMethod,
    );

    final id = await insert(message);
    return message.copyWith(
      id: id,
      createdAt: DateTime.now(),
    );
  }

  /// Insert an assistant message and return the record with ID.
  Future<ChatMessageRecord> insertAssistantMessage({
    required int documentId,
    required String content,
    List<int> citations = const [],
    bool isCached = false,
    int? processingTimeMs,
  }) async {
    final message = ChatMessageRecord(
      documentId: documentId,
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      isCached: isCached,
      processingTimeMs: processingTimeMs,
    );

    final id = await insert(message);
    return message.copyWith(
      id: id,
      createdAt: DateTime.now(),
    );
  }

  /// Get all messages for a document in chronological order.
  Future<List<ChatMessageRecord>> getByDocumentId(int documentId) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at ASC',
    );

    return results.map(ChatMessageRecord.fromMap).toList();
  }

  /// Get the most recent N messages for a document.
  Future<List<ChatMessageRecord>> getRecentMessages(
    int documentId, {
    int limit = 20,
  }) async {
    final results = await _db.query(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    // Reverse to get chronological order
    return results.reversed.map(ChatMessageRecord.fromMap).toList();
  }

  /// Get a message by ID.
  Future<ChatMessageRecord?> getById(int id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ChatMessageRecord.fromMap(results.first);
  }

  /// Delete a message by ID.
  Future<int> delete(int id) async {
    return _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all messages for a document.
  Future<int> deleteByDocumentId(int documentId) async {
    return _db.delete(
      tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get message count for a document.
  Future<int> countByDocumentId(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE document_id = ?',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get cached message count for a document.
  Future<int> countCachedByDocumentId(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE document_id = ? AND is_cached = 1',
      [documentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get average processing time for a document.
  Future<double?> getAverageProcessingTime(int documentId) async {
    final result = await _db.rawQuery(
      'SELECT AVG(processing_time_ms) as avg FROM $tableName WHERE document_id = ? AND processing_time_ms IS NOT NULL AND is_cached = 0',
      [documentId],
    );

    final avg = result.first['avg'];
    if (avg == null) return null;
    return (avg as num).toDouble();
  }
}
