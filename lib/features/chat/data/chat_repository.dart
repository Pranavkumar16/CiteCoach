import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/chat_messages_table.dart';
import '../../../core/database/tables/question_cache_table.dart';
import '../domain/chat_message.dart';

/// Provider for the chat repository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  return ChatRepository(db);
});

/// Repository for managing chat messages and Q&A cache.
class ChatRepository {
  ChatRepository(this._db);

  final Database? _db;

  /// Get all messages for a document.
  Future<List<ChatMessage>> getMessages(int documentId) async {
    if (_db == null) return [];

    final table = ChatMessagesTable(_db);
    final records = await table.getByDocumentId(documentId);
    return records.map(ChatMessage.fromRecord).toList();
  }

  /// Save a new message.
  Future<ChatMessage?> saveMessage(ChatMessage message) async {
    if (_db == null) return null;

    final table = ChatMessagesTable(_db);
    final id = await table.insert(message.toRecord());
    return message.copyWith(id: id);
  }

  /// Delete a message.
  Future<bool> deleteMessage(int messageId) async {
    if (_db == null) return false;

    final table = ChatMessagesTable(_db);
    final rows = await table.delete(messageId);
    return rows > 0;
  }

  /// Delete all messages for a document.
  Future<bool> clearMessages(int documentId) async {
    if (_db == null) return false;

    final table = ChatMessagesTable(_db);
    await table.deleteByDocumentId(documentId);
    return true;
  }

  /// Look up a cached answer for a query.
  Future<QuestionCacheRecord?> getCachedAnswer(
    int documentId,
    String question,
  ) async {
    if (_db == null) return null;

    final table = QuestionCacheTable(_db);
    return table.lookup(documentId, question);
  }

  /// Cache an answer for a query.
  Future<bool> cacheAnswer({
    required int documentId,
    required String question,
    required String answer,
    required String context,
    required List<Map<String, dynamic>> citations,
  }) async {
    if (_db == null) return false;

    final table = QuestionCacheTable(_db);
    // Extract page numbers from citation objects
    final pageNumbers = citations
        .map((c) => c['page'] as int?)
        .where((p) => p != null)
        .cast<int>()
        .toList();

    final id = await table.cacheAnswer(
      documentId: documentId,
      question: question,
      answer: answer,
      citations: pageNumbers,
    );
    return id > 0;
  }

  /// Get cache statistics for a document.
  Future<CacheStats> getCacheStats(int documentId) async {
    if (_db == null) {
      return const CacheStats(entryCount: 0, totalHits: 0);
    }

    final table = QuestionCacheTable(_db);
    return table.getStats(documentId);
  }

  /// Get the message count for a document.
  Future<int> getMessageCount(int documentId) async {
    if (_db == null) return 0;

    final table = ChatMessagesTable(_db);
    return table.countByDocumentId(documentId);
  }

  /// Get the most recent messages for a document.
  Future<List<ChatMessage>> getRecentMessages(
    int documentId, {
    int limit = 10,
  }) async {
    if (_db == null) return [];

    final table = ChatMessagesTable(_db);
    final records = await table.getRecentMessages(documentId, limit: limit);
    return records.map(ChatMessage.fromRecord).toList();
  }
}
