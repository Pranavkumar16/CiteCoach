import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_message.dart';
import 'rag_service.dart';

/// Provider for the LLM service.
final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService();
});

/// Result of LLM generation.
class GenerationResult {
  const GenerationResult({
    required this.response,
    required this.citations,
    this.error,
    this.fromCache = false,
  });

  /// The generated response text.
  final String response;

  /// Citations from the RAG retrieval.
  final List<Citation> citations;

  /// Error message if generation failed.
  final String? error;

  /// Whether this response came from cache.
  final bool fromCache;

  /// Check if generation was successful.
  bool get isSuccess => error == null && response.isNotEmpty;

  /// Create an error result.
  factory GenerationResult.error(String message) {
    return GenerationResult(
      response: '',
      citations: [],
      error: message,
    );
  }
}

/// Callback for streaming response tokens.
typedef StreamCallback = void Function(String token);

/// Service for LLM inference.
/// 
/// In V1, this is a stub that generates mock responses.
/// Real implementation with Gemma 2B will be added in Commit 9.
class LlmService {
  LlmService();

  /// Whether the model is loaded and ready.
  bool _isModelLoaded = false;

  /// Check if model is ready.
  bool get isModelLoaded => _isModelLoaded;

  /// Initialize the LLM model.
  /// 
  /// In V1, this is a no-op stub.
  Future<bool> initialize() async {
    debugPrint('LlmService: Initializing (stub)');
    await Future.delayed(const Duration(milliseconds: 300));
    _isModelLoaded = true;
    debugPrint('LlmService: Model ready (stub)');
    return true;
  }

  /// Generate a response to a query given context.
  /// 
  /// In V1, this generates a mock response based on the context.
  Future<GenerationResult> generate({
    required String query,
    required RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory = const [],
    StreamCallback? onToken,
  }) async {
    if (!_isModelLoaded) {
      await initialize();
    }

    try {
      debugPrint('LlmService: Generating response for query');

      if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
        return GenerationResult.error(
          'No relevant information found in the document.',
        );
      }

      // Generate mock response
      final response = await _generateMockResponse(
        query,
        retrievalResult,
        onToken,
      );

      return GenerationResult(
        response: response,
        citations: retrievalResult.citations,
      );
    } catch (e) {
      debugPrint('LlmService: Generation error: $e');
      return GenerationResult.error('Failed to generate response: ${e.toString()}');
    }
  }

  /// Generate a mock response based on the context.
  /// 
  /// This stub creates a plausible response by:
  /// 1. Acknowledging the query
  /// 2. Summarizing relevant information from context
  /// 3. Adding citation references
  Future<String> _generateMockResponse(
    String query,
    RetrievalResult retrievalResult,
    StreamCallback? onToken,
  ) async {
    // Build a response that references the context
    final citations = retrievalResult.citations;
    final queryLower = query.toLowerCase();

    // Determine response type based on query
    String response;
    
    if (queryLower.contains('what') || queryLower.contains('explain')) {
      response = _buildExplanatoryResponse(query, retrievalResult);
    } else if (queryLower.contains('how')) {
      response = _buildHowToResponse(query, retrievalResult);
    } else if (queryLower.contains('why')) {
      response = _buildWhyResponse(query, retrievalResult);
    } else if (queryLower.contains('list') || queryLower.contains('what are')) {
      response = _buildListResponse(query, retrievalResult);
    } else {
      response = _buildGeneralResponse(query, retrievalResult);
    }

    // Add page citations
    if (citations.isNotEmpty) {
      final pageRefs = citations.map((c) => 'p.${c.pageNumber}').toSet().join(', ');
      response += '\n\n[Source: $pageRefs]';
    }

    // Simulate streaming if callback provided
    if (onToken != null) {
      await _simulateStreaming(response, onToken);
    }

    return response;
  }

  String _buildExplanatoryResponse(String query, RetrievalResult result) {
    final snippet = result.citations.isNotEmpty 
        ? result.citations.first.preview 
        : 'the document content';
    
    return 'Based on the document, ${_extractTopic(query)} refers to the following:\n\n'
        '$snippet\n\n'
        'This information provides context for understanding the main concepts discussed in the document.';
  }

  String _buildHowToResponse(String query, RetrievalResult result) {
    return 'According to the document, here is how ${_extractTopic(query)}:\n\n'
        '1. The document outlines the key steps and considerations.\n'
        '2. It emphasizes the importance of following the proper methodology.\n'
        '3. Additional details can be found in the referenced pages.\n\n'
        'The document provides comprehensive guidance on this topic.';
  }

  String _buildWhyResponse(String query, RetrievalResult result) {
    final snippet = result.citations.isNotEmpty 
        ? result.citations.first.preview 
        : '';
    
    return 'The document explains that ${_extractTopic(query)} is important because:\n\n'
        '${snippet.isNotEmpty ? '"$snippet"\n\n' : ''}'
        'This reasoning is central to the document\'s argument and supports its main conclusions.';
  }

  String _buildListResponse(String query, RetrievalResult result) {
    final items = result.citations.take(3).map((c) => '• ${c.preview}').join('\n');
    
    return 'Based on the document, here are the relevant points about ${_extractTopic(query)}:\n\n'
        '${items.isNotEmpty ? items : '• Key information from the document'}\n\n'
        'These points summarize the main content related to your query.';
  }

  String _buildGeneralResponse(String query, RetrievalResult result) {
    final snippet = result.citations.isNotEmpty 
        ? result.citations.first.preview 
        : 'the relevant content';
    
    return 'Regarding ${_extractTopic(query)}, the document states:\n\n'
        '"$snippet"\n\n'
        'This passage directly addresses your question and provides the key information available in the document.';
  }

  /// Extract the main topic from a query.
  String _extractTopic(String query) {
    // Remove common question words
    var topic = query
        .replaceAll(RegExp(r'^(what|how|why|when|where|who|which|can|does|is|are|do)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\?+$'), '')
        .trim();
    
    if (topic.length > 50) {
      topic = '${topic.substring(0, 47)}...';
    }
    
    return topic.isEmpty ? 'this topic' : topic;
  }

  /// Simulate token-by-token streaming.
  Future<void> _simulateStreaming(String response, StreamCallback onToken) async {
    final words = response.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final token = i == 0 ? words[i] : ' ${words[i]}';
      onToken(token);
      
      // Vary delay to simulate realistic streaming
      final delay = 20 + (i % 3) * 10;
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  /// Dispose of model resources.
  void dispose() {
    _isModelLoaded = false;
    debugPrint('LlmService: Disposed');
  }
}
