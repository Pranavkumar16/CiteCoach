import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:citecoach/core/database/migrations.dart';
import 'package:citecoach/core/database/tables/question_cache_table.dart';

void main() {
  late Database db;
  late QuestionCacheTable cacheTable;
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
    cacheTable = QuestionCacheTable(db);

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

  group('QuestionCacheTable', () {
    test('cache and lookup answer', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'What is ATP?',
        answer: 'ATP is adenosine triphosphate.',
        citations: [67, 68],
      );

      final cached = await cacheTable.lookup(testDocumentId, 'What is ATP?');
      expect(cached, isNotNull);
      expect(cached!.answer, equals('ATP is adenosine triphosphate.'));
      expect(cached.citations, equals([67, 68]));
    });

    test('normalize question for fuzzy matching', () {
      // Test various normalizations
      expect(
        QuestionCacheTable.normalizeQuestion('What is ATP?'),
        equals('what is atp'),
      );
      expect(
        QuestionCacheTable.normalizeQuestion('WHAT IS ATP'),
        equals('what is atp'),
      );
      expect(
        QuestionCacheTable.normalizeQuestion('  what   is   atp  '),
        equals('what is atp'),
      );
      expect(
        QuestionCacheTable.normalizeQuestion('What is ATP???'),
        equals('what is atp'),
      );
    });

    test('lookup with different question variations', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'What is ATP?',
        answer: 'ATP is the energy currency.',
      );

      // All these variations should find the same cached answer
      expect(await cacheTable.lookup(testDocumentId, 'What is ATP?'), isNotNull);
      expect(await cacheTable.lookup(testDocumentId, 'what is atp'), isNotNull);
      expect(await cacheTable.lookup(testDocumentId, 'WHAT IS ATP'), isNotNull);
      expect(await cacheTable.lookup(testDocumentId, '  What is ATP??  '), isNotNull);
    });

    test('lookup returns null for non-existent question', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'What is ATP?',
        answer: 'Answer',
      );

      final cached = await cacheTable.lookup(testDocumentId, 'What is DNA?');
      expect(cached, isNull);
    });

    test('hit count increments on lookup', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'What is ATP?',
        answer: 'Answer',
      );

      // First lookup - records hit but returns entry with hit count from before update
      var cached = await cacheTable.lookup(testDocumentId, 'What is ATP?');
      expect(cached, isNotNull);

      // Second lookup
      cached = await cacheTable.lookup(testDocumentId, 'What is ATP?');
      expect(cached, isNotNull);

      // Third lookup
      cached = await cacheTable.lookup(testDocumentId, 'What is ATP?');
      expect(cached, isNotNull);
      
      // Verify total hits via stats
      final stats = await cacheTable.getStats(testDocumentId);
      expect(stats.totalHits, equals(3));
    });

    test('get top questions by hit count', () async {
      // Add questions with different hit counts
      for (var i = 1; i <= 5; i++) {
        await cacheTable.cacheAnswer(
          documentId: testDocumentId,
          question: 'Question $i',
          answer: 'Answer $i',
        );
      }

      // Simulate hits - Question 3 gets 5 hits
      for (var i = 0; i < 5; i++) {
        await cacheTable.lookup(testDocumentId, 'Question 3');
      }
      // Question 1 gets 3 hits
      for (var i = 0; i < 3; i++) {
        await cacheTable.lookup(testDocumentId, 'Question 1');
      }
      // Question 5 gets 1 hit
      await cacheTable.lookup(testDocumentId, 'Question 5');

      final top = await cacheTable.getTopQuestions(testDocumentId, limit: 3);
      expect(top.length, equals(3));
      // Verify that Question 3 has the most hits
      expect(top[0].hitCount, greaterThanOrEqualTo(top[1].hitCount));
      expect(top[1].hitCount, greaterThanOrEqualTo(top[2].hitCount));
      // Question 3 should have 5 hits
      final q3 = top.firstWhere((q) => q.questionOriginal == 'Question 3');
      expect(q3.hitCount, equals(5));
    });

    test('get cache stats', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'Q1',
        answer: 'A1',
      );
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'Q2',
        answer: 'A2',
      );

      // Create some hits
      await cacheTable.lookup(testDocumentId, 'Q1');
      await cacheTable.lookup(testDocumentId, 'Q1');
      await cacheTable.lookup(testDocumentId, 'Q2');

      final stats = await cacheTable.getStats(testDocumentId);
      expect(stats.entryCount, equals(2));
      expect(stats.totalHits, equals(3));
      expect(stats.averageHits, equals(1.5));
    });

    test('delete by document', () async {
      await cacheTable.cacheAnswer(
        documentId: testDocumentId,
        question: 'Test',
        answer: 'Answer',
      );

      expect(await cacheTable.countByDocumentId(testDocumentId), equals(1));

      await cacheTable.deleteByDocumentId(testDocumentId);
      expect(await cacheTable.countByDocumentId(testDocumentId), equals(0));
    });

    test('QuestionCacheRecord isExpired', () {
      final notExpired = QuestionCacheRecord(
        documentId: 1,
        questionOriginal: 'Q',
        questionNormalized: 'q',
        answer: 'A',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(notExpired.isExpired, isFalse);

      final expired = QuestionCacheRecord(
        documentId: 1,
        questionOriginal: 'Q',
        questionNormalized: 'q',
        answer: 'A',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isExpired, isTrue);

      final noExpiry = QuestionCacheRecord(
        documentId: 1,
        questionOriginal: 'Q',
        questionNormalized: 'q',
        answer: 'A',
      );
      expect(noExpiry.isExpired, isFalse);
    });
  });
}
