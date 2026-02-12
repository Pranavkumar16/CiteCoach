import 'dart:convert';
import 'package:equatable/equatable.dart';

import '../../../core/database/tables/chat_messages_table.dart';

// Re-export these types from chat_messages_table for convenience
export '../../../core/database/tables/chat_messages_table.dart'
    show MessageRole, InputMethod;

/// Domain model for a chat message.
class ChatMessage extends Equatable {
  const ChatMessage({
    this.id,
    required this.documentId,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
    this.inputMethod = InputMethod.text,
    this.isStreaming = false,
  });

  /// Unique identifier (null for unsaved messages).
  final int? id;

  /// The document this message belongs to.
  final int documentId;

  /// Whether this is a user or assistant message.
  final MessageRole role;

  /// The message content.
  final String content;

  /// Citations for assistant messages.
  final List<Citation> citations;

  /// When the message was created.
  final DateTime createdAt;

  /// How the message was input (text or voice).
  final InputMethod inputMethod;

  /// Whether the message is currently streaming.
  final bool isStreaming;

  /// Check if this is a user message.
  bool get isUser => role == MessageRole.user;

  /// Check if this is an assistant message.
  bool get isAssistant => role == MessageRole.assistant;

  /// Check if this message has citations.
  bool get hasCitations => citations.isNotEmpty;

  /// Create a user message.
  factory ChatMessage.user({
    required int documentId,
    required String content,
    InputMethod inputMethod = InputMethod.text,
  }) {
    return ChatMessage(
      documentId: documentId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      inputMethod: inputMethod,
    );
  }

  /// Create an assistant message.
  factory ChatMessage.assistant({
    required int documentId,
    required String content,
    List<Citation> citations = const [],
    bool isStreaming = false,
  }) {
    return ChatMessage(
      documentId: documentId,
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      createdAt: DateTime.now(),
      isStreaming: isStreaming,
    );
  }

  /// Create a streaming placeholder message.
  factory ChatMessage.streaming(int documentId) {
    return ChatMessage(
      documentId: documentId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );
  }

  /// Create from database record.
  factory ChatMessage.fromRecord(ChatMessageRecord record) {
    // Note: Database stores citations as List<int> (page numbers) in V1.
    // Full persistence of text snippets requires schema migration or JSON storage.
    // For V1 MVP, we rely on page numbers which are sufficient for navigation.
    final citationObjects = record.citations.map((pageNum) {
      return Citation(
        pageNumber: pageNum,
        chunkIndex: 0,
        text: '', 
      );
    }).toList();

    return ChatMessage(
      id: record.id,
      documentId: record.documentId,
      role: record.role,
      content: record.content,
      citations: citationObjects,
      createdAt: record.createdAt ?? DateTime.now(),
      inputMethod: record.inputMethod,
    );
  }

  /// Convert to database record.
  ChatMessageRecord toRecord() {
    return ChatMessageRecord(
      id: id,
      documentId: documentId,
      role: role,
      content: content,
      // Store just page numbers for now as per schema
      citations: citations.map((c) => c.pageNumber).toList(),
      createdAt: createdAt,
      inputMethod: inputMethod,
    );
  }

  /// Copy with updated fields.
  ChatMessage copyWith({
    int? id,
    int? documentId,
    MessageRole? role,
    String? content,
    List<Citation>? citations,
    DateTime? createdAt,
    InputMethod? inputMethod,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      createdAt: createdAt ?? this.createdAt,
      inputMethod: inputMethod ?? this.inputMethod,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        role,
        content,
        citations,
        createdAt,
        inputMethod,
        isStreaming,
      ];
}

/// A citation referencing a specific location in the document.
class Citation extends Equatable {
  const Citation({
    required this.pageNumber,
    required this.chunkIndex,
    required this.text,
    this.relevanceScore = 0.0,
  });

  /// The page number (1-based).
  final int pageNumber;

  /// The chunk index within the document.
  final int chunkIndex;

  /// A snippet of the cited text.
  final String text;

  /// Relevance score from RAG retrieval.
  final double relevanceScore;

  /// Get a short preview of the citation text.
  String get preview {
    if (text.length <= 100) return text;
    return '${text.substring(0, 97)}...';
  }

  /// Create from JSON map.
  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      pageNumber: json['page'] as int,
      chunkIndex: json['chunk'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      relevanceScore: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'page': pageNumber,
      'chunk': chunkIndex,
      'text': text,
      'score': relevanceScore,
    };
  }

  @override
  List<Object?> get props => [pageNumber, chunkIndex, text, relevanceScore];
}
