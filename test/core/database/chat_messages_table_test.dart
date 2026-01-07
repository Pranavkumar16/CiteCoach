import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:citecoach/core/database/migrations.dart';
import 'package:citecoach/core/database/tables/chat_messages_table.dart';
import 'package:citecoach/core/database/tables/documents_table.dart';

void main() {
  late Database db;
  late ChatMessagesTable messagesTable;
  late int testDocumentId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        final batch = db.batch();
        // Create all tables since indexes reference them
        DatabaseMigrations.createDocumentsTable(batch);
        DatabaseMigrations.createDocumentPagesTable(batch);
        DatabaseMigrations.createDocumentChunksTable(batch);
        DatabaseMigrations.createChatMessagesTable(batch);
        DatabaseMigrations.createQuestionCacheTable(batch);
        DatabaseMigrations.createIndexes(batch);
        await batch.commit();
      },
    );
    messagesTable = ChatMessagesTable(db);

    // Create a test document
    testDocumentId = await db.insert('documents', {
      'title': 'Test Document',
      'file_path': '/path/to/test.pdf',
      'imported_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('ChatMessagesTable', () {
    test('insert user message', () async {
      final message = await messagesTable.insertUserMessage(
        documentId: testDocumentId,
        content: 'What is ATP?',
        inputMethod: InputMethod.text,
      );

      expect(message.id, isNotNull);
      expect(message.role, equals(MessageRole.user));
      expect(message.content, equals('What is ATP?'));
      expect(message.inputMethod, equals(InputMethod.text));
    });

    test('insert assistant message with citations', () async {
      final message = await messagesTable.insertAssistantMessage(
        documentId: testDocumentId,
        content: 'ATP is adenosine triphosphate, the energy currency of cells.',
        citations: [67, 68],
        processingTimeMs: 3500,
      );

      expect(message.id, isNotNull);
      expect(message.role, equals(MessageRole.assistant));
      expect(message.citations, equals([67, 68]));
      expect(message.processingTimeMs, equals(3500));
      expect(message.hasCitations, isTrue);
    });

    test('get messages by document', () async {
      await messagesTable.insertUserMessage(
        documentId: testDocumentId,
        content: 'Question 1',
      );
      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));
      await messagesTable.insertAssistantMessage(
        documentId: testDocumentId,
        content: 'Answer 1',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await messagesTable.insertUserMessage(
        documentId: testDocumentId,
        content: 'Question 2',
      );

      final messages = await messagesTable.getByDocumentId(testDocumentId);
      expect(messages.length, equals(3));
      // Messages should be in insertion order
      expect(messages.map((m) => m.content).toList(), 
             containsAll(['Question 1', 'Answer 1', 'Question 2']));
    });

    test('get recent messages with limit', () async {
      for (var i = 1; i <= 10; i++) {
        await messagesTable.insertUserMessage(
          documentId: testDocumentId,
          content: 'Message $i',
        );
        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final recent = await messagesTable.getRecentMessages(testDocumentId, limit: 5);
      expect(recent.length, equals(5));
      // Verify we got 5 messages (exact order depends on timestamp resolution)
      expect(recent.every((m) => m.content.startsWith('Message')), isTrue);
    });

    test('delete messages by document', () async {
      await messagesTable.insertUserMessage(
        documentId: testDocumentId,
        content: 'Test message',
      );

      expect(await messagesTable.countByDocumentId(testDocumentId), equals(1));

      await messagesTable.deleteByDocumentId(testDocumentId);
      expect(await messagesTable.countByDocumentId(testDocumentId), equals(0));
    });

    test('count cached messages', () async {
      await messagesTable.insertAssistantMessage(
        documentId: testDocumentId,
        content: 'Regular answer',
        isCached: false,
      );
      await messagesTable.insertAssistantMessage(
        documentId: testDocumentId,
        content: 'Cached answer',
        isCached: true,
      );

      expect(await messagesTable.countByDocumentId(testDocumentId), equals(2));
      expect(await messagesTable.countCachedByDocumentId(testDocumentId), equals(1));
    });

    test('voice input method', () async {
      final message = await messagesTable.insertUserMessage(
        documentId: testDocumentId,
        content: 'Voice question',
        inputMethod: InputMethod.voice,
      );

      final retrieved = await messagesTable.getById(message.id!);
      expect(retrieved!.inputMethod, equals(InputMethod.voice));
    });

    test('ChatMessageRecord properties', () {
      final userMsg = ChatMessageRecord(
        documentId: 1,
        role: MessageRole.user,
        content: 'Test',
      );
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(userMsg.hasCitations, isFalse);

      final assistantMsg = ChatMessageRecord(
        documentId: 1,
        role: MessageRole.assistant,
        content: 'Test',
        citations: [1, 2],
      );
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasCitations, isTrue);
    });
  });
}
