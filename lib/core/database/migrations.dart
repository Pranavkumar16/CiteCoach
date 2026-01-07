import 'package:sqflite/sqflite.dart';

/// Database migrations and schema definitions.
/// 
/// Schema based on the CiteCoach V1 Architecture spec:
/// - documents: Document metadata and status
/// - document_pages: Page text and page-level embeddings
/// - document_chunks: Chunked text with embeddings for RAG
/// - chat_messages: Conversation history with citations
/// - question_cache: Q&A cache for instant responses
abstract final class DatabaseMigrations {
  /// Documents table - stores imported PDF metadata.
  /// 
  /// Status values: PENDING, PROCESSING, READY, ERROR
  static void createDocumentsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        page_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING',
        error_message TEXT,
        imported_at TEXT NOT NULL,
        last_opened_at TEXT,
        last_read_page INTEGER DEFAULT 1,
        processing_progress REAL DEFAULT 0.0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  /// Document pages table - stores extracted page text and page-level embeddings.
  /// 
  /// Page embeddings enable hierarchical retrieval (Stage 1: page-level search).
  /// Embedding is stored as BLOB (384 floats = 1536 bytes).
  static void createDocumentPagesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE document_pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        page_text TEXT NOT NULL,
        page_embedding BLOB,
        chunk_count INTEGER NOT NULL DEFAULT 0,
        char_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
        UNIQUE(document_id, page_number)
      )
    ''');
  }

  /// Document chunks table - stores chunked text for fine-grained RAG retrieval.
  /// 
  /// Chunks are 200-600 tokens with 50-token overlap.
  /// Embedding is stored as BLOB (384 floats = 1536 bytes).
  static void createDocumentChunksTable(Batch batch) {
    batch.execute('''
      CREATE TABLE document_chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        chunk_index INTEGER NOT NULL,
        chunk_text TEXT NOT NULL,
        chunk_embedding BLOB,
        start_offset INTEGER NOT NULL DEFAULT 0,
        end_offset INTEGER NOT NULL DEFAULT 0,
        token_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Chat messages table - stores conversation history per document.
  /// 
  /// Each message can have citations stored as JSON array of page numbers.
  /// Role values: user, assistant
  /// Input method values: text, voice
  static void createChatMessagesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        citations_json TEXT,
        input_method TEXT NOT NULL DEFAULT 'text',
        is_cached BOOLEAN NOT NULL DEFAULT 0,
        processing_time_ms INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Question cache table - stores normalized Q&A pairs for instant responses.
  /// 
  /// Normalized questions enable fuzzy matching (e.g., "What is ATP?" = "what is atp").
  /// Expected hit rate: 50-60% (students ask similar questions).
  static void createQuestionCacheTable(Batch batch) {
    batch.execute('''
      CREATE TABLE question_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        question_original TEXT NOT NULL,
        question_normalized TEXT NOT NULL,
        answer TEXT NOT NULL,
        citations_json TEXT,
        hit_count INTEGER NOT NULL DEFAULT 0,
        last_hit_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        expires_at TEXT,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create indexes for query performance.
  static void createIndexes(Batch batch) {
    // Documents indexes
    batch.execute('CREATE INDEX idx_documents_status ON documents(status)');
    batch.execute('CREATE INDEX idx_documents_last_opened ON documents(last_opened_at DESC)');
    
    // Document pages indexes
    batch.execute('CREATE INDEX idx_pages_document ON document_pages(document_id)');
    batch.execute('CREATE INDEX idx_pages_document_page ON document_pages(document_id, page_number)');
    
    // Document chunks indexes
    batch.execute('CREATE INDEX idx_chunks_document ON document_chunks(document_id)');
    batch.execute('CREATE INDEX idx_chunks_document_page ON document_chunks(document_id, page_number)');
    
    // Chat messages indexes
    batch.execute('CREATE INDEX idx_messages_document ON chat_messages(document_id)');
    batch.execute('CREATE INDEX idx_messages_document_created ON chat_messages(document_id, created_at DESC)');
    
    // Question cache indexes
    batch.execute('CREATE INDEX idx_cache_document ON question_cache(document_id)');
    batch.execute('CREATE INDEX idx_cache_normalized ON question_cache(document_id, question_normalized)');
    batch.execute('CREATE INDEX idx_cache_expires ON question_cache(expires_at)');
  }

  /// Drop all tables (for testing or complete reset).
  static Future<void> dropAllTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS question_cache');
    await db.execute('DROP TABLE IF EXISTS chat_messages');
    await db.execute('DROP TABLE IF EXISTS document_chunks');
    await db.execute('DROP TABLE IF EXISTS document_pages');
    await db.execute('DROP TABLE IF EXISTS documents');
  }
}
