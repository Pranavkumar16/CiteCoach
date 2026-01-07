import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// Provider for the database instance.
/// Use this to access the database throughout the app.
final databaseProvider = FutureProvider<Database>((ref) async {
  final dbProvider = DatabaseProvider();
  return dbProvider.database;
});

/// Manages SQLite database initialization and access.
/// 
/// The database stores:
/// - Documents metadata
/// - Extracted page text and embeddings
/// - Chunk data for RAG retrieval
/// - Chat messages with citations
/// - Question/answer cache for performance
class DatabaseProvider {
  static Database? _database;
  static const String _databaseName = 'citecoach.db';
  static const int _databaseVersion = 1;

  /// Get the database instance, initializing if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    debugPrint('DatabaseProvider: Initializing database at $path');

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings.
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys for referential integrity
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables on first database creation.
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseProvider: Creating database schema v$version');
    
    final batch = db.batch();
    
    // Create all tables
    DatabaseMigrations.createDocumentsTable(batch);
    DatabaseMigrations.createDocumentPagesTable(batch);
    DatabaseMigrations.createDocumentChunksTable(batch);
    DatabaseMigrations.createChatMessagesTable(batch);
    DatabaseMigrations.createQuestionCacheTable(batch);
    
    // Create indexes for performance
    DatabaseMigrations.createIndexes(batch);
    
    await batch.commit(noResult: true);
    
    debugPrint('DatabaseProvider: Database schema created successfully');
  }

  /// Handle database upgrades between versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('DatabaseProvider: Upgrading database from v$oldVersion to v$newVersion');
    
    // Future migrations will be handled here
    // For now, we only have version 1
    
    if (oldVersion < 2) {
      // Future: Add migration to version 2
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('DatabaseProvider: Database closed');
    }
  }

  /// Delete the database (for testing or reset purposes).
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    await close();
    await databaseFactory.deleteDatabase(path);
    
    debugPrint('DatabaseProvider: Database deleted');
  }

  /// Get database statistics for debugging.
  Future<Map<String, int>> getTableCounts() async {
    final db = await database;
    final tables = ['documents', 'document_pages', 'document_chunks', 'chat_messages', 'question_cache'];
    final counts = <String, int>{};
    
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      counts[table] = Sqflite.firstIntValue(result) ?? 0;
    }
    
    return counts;
  }
}
