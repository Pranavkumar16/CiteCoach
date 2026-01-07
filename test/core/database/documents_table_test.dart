import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:citecoach/core/database/migrations.dart';
import 'package:citecoach/core/database/tables/documents_table.dart';

void main() {
  late Database db;
  late DocumentsTable documentsTable;

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
    documentsTable = DocumentsTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DocumentsTable', () {
    test('insert and retrieve document', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        fileSize: 1024,
        pageCount: 10,
        importedAt: DateTime.now(),
      );

      final id = await documentsTable.insert(document);
      expect(id, greaterThan(0));

      final retrieved = await documentsTable.getById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Test Document'));
      expect(retrieved.filePath, equals('/path/to/test.pdf'));
      expect(retrieved.fileSize, equals(1024));
      expect(retrieved.pageCount, equals(10));
      expect(retrieved.status, equals(DocumentStatus.pending));
    });

    test('update document status', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        importedAt: DateTime.now(),
      );

      final id = await documentsTable.insert(document);
      
      await documentsTable.updateStatus(id, DocumentStatus.processing);
      var retrieved = await documentsTable.getById(id);
      expect(retrieved!.status, equals(DocumentStatus.processing));

      await documentsTable.updateStatus(id, DocumentStatus.ready);
      retrieved = await documentsTable.getById(id);
      expect(retrieved!.status, equals(DocumentStatus.ready));

      await documentsTable.updateStatus(
        id,
        DocumentStatus.error,
        errorMessage: 'Failed to process',
      );
      retrieved = await documentsTable.getById(id);
      expect(retrieved!.status, equals(DocumentStatus.error));
      expect(retrieved.errorMessage, equals('Failed to process'));
    });

    test('update processing progress', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        importedAt: DateTime.now(),
      );

      final id = await documentsTable.insert(document);
      
      await documentsTable.updateProgress(id, 0.5);
      var retrieved = await documentsTable.getById(id);
      expect(retrieved!.processingProgress, equals(0.5));

      await documentsTable.updateProgress(id, 1.0);
      retrieved = await documentsTable.getById(id);
      expect(retrieved!.processingProgress, equals(1.0));
    });

    test('update last opened', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        importedAt: DateTime.now(),
      );

      final id = await documentsTable.insert(document);
      
      await documentsTable.updateLastOpened(id, lastReadPage: 5);
      final retrieved = await documentsTable.getById(id);
      expect(retrieved!.lastOpenedAt, isNotNull);
      expect(retrieved.lastReadPage, equals(5));
    });

    test('get all documents', () async {
      for (var i = 1; i <= 3; i++) {
        await documentsTable.insert(DocumentRecord(
          title: 'Document $i',
          filePath: '/path/to/doc$i.pdf',
          importedAt: DateTime.now(),
        ));
      }

      final documents = await documentsTable.getAll();
      expect(documents.length, equals(3));
    });

    test('get documents by status', () async {
      await documentsTable.insert(DocumentRecord(
        title: 'Pending Doc',
        filePath: '/path/to/pending.pdf',
        status: DocumentStatus.pending,
        importedAt: DateTime.now(),
      ));

      final readyDoc = DocumentRecord(
        title: 'Ready Doc',
        filePath: '/path/to/ready.pdf',
        importedAt: DateTime.now(),
      );
      final readyId = await documentsTable.insert(readyDoc);
      await documentsTable.updateStatus(readyId, DocumentStatus.ready);

      final pendingDocs = await documentsTable.getByStatus(DocumentStatus.pending);
      expect(pendingDocs.length, equals(1));
      expect(pendingDocs.first.title, equals('Pending Doc'));

      final readyDocs = await documentsTable.getReadyDocuments();
      expect(readyDocs.length, equals(1));
      expect(readyDocs.first.title, equals('Ready Doc'));
    });

    test('delete document', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        importedAt: DateTime.now(),
      );

      final id = await documentsTable.insert(document);
      expect(await documentsTable.count(), equals(1));

      await documentsTable.delete(id);
      expect(await documentsTable.count(), equals(0));
      expect(await documentsTable.getById(id), isNull);
    });

    test('check exists by path', () async {
      final document = DocumentRecord(
        title: 'Test Document',
        filePath: '/path/to/test.pdf',
        importedAt: DateTime.now(),
      );

      await documentsTable.insert(document);

      expect(await documentsTable.existsByPath('/path/to/test.pdf'), isTrue);
      expect(await documentsTable.existsByPath('/path/to/other.pdf'), isFalse);
    });

    test('DocumentRecord copyWith', () {
      final original = DocumentRecord(
        id: 1,
        title: 'Original',
        filePath: '/path/to/original.pdf',
        importedAt: DateTime.now(),
      );

      final copied = original.copyWith(title: 'Modified');
      expect(copied.title, equals('Modified'));
      expect(copied.filePath, equals('/path/to/original.pdf'));
      expect(copied.id, equals(1));
    });
  });
}
