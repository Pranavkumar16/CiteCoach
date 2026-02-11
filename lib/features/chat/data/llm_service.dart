import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

/// Service for LLM inference using Google Generative AI (Gemini).
/// 
/// This service provides real AI-powered responses with:
/// - Evidence-based answers from document context
/// - Citation generation
/// - Streaming response support
/// - Graceful fallback for offline/error scenarios
class LlmService {
  LlmService();

  /// Gemini model instance.
  GenerativeModel? _model;

  /// Whether the model is initialized.
  bool _isInitialized = false;

  /// API key for Gemini (should be set via environment or secure storage).
  /// For production, use: --dart-define=GEMINI_API_KEY=your_key
  static const String _defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Check if model is ready.
  bool get isModelLoaded => _isInitialized;

  /// System prompt for citation-aware responses.
  static const String _systemPrompt = '''
You are CiteCoach, an evidence-based document assistant. Your role is to answer questions using ONLY the provided context from the user's PDF document.

CRITICAL RULES:
1. Always cite page numbers using the format (p.X) or (p.X, p.Y) for multiple pages
2. NEVER make up information not present in the context
3. If the answer isn't in the context, say "I don't see that information in this document"
4. Be concise and precise - aim for clear, helpful answers
5. When multiple sources are relevant, cite all applicable pages
6. Use the [Page X] markers in the context to determine correct page numbers

Your answers should be educational, accurate, and always supported by the document content.
''';

  /// Initialize the LLM service.
  Future<bool> initialize({String? apiKey}) async {
    if (_isInitialized && _model != null) return true;

    final key = apiKey ?? _defaultApiKey;
    
    if (key.isEmpty) {
      debugPrint('LlmService: No API key provided, using fallback mode');
      _isInitialized = true;
      return true;
    }

    try {
      debugPrint('LlmService: Initializing Gemini model...');
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        generationConfig: GenerationConfig(
          maxOutputTokens: 500,
          temperature: 0.3,
          topP: 0.8,
          topK: 40,
        ),
        systemInstruction: Content.text(_systemPrompt),
      );

      _isInitialized = true;
      debugPrint('LlmService: Gemini model initialized');
      return true;
    } catch (e) {
      debugPrint('LlmService: Failed to initialize: $e');
      _isInitialized = true; // Allow fallback mode
      return false;
    }
  }

  /// Generate a response to a query given context.
  Future<GenerationResult> generate({
    required String query,
    required RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory = const [],
    StreamCallback? onToken,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('LlmService: Generating response for query');

      if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
        return GenerationResult.error(
          'No relevant information found in the document.',
        );
      }

      // Try Gemini API first
      if (_model != null) {
        try {
          return await _generateWithGemini(
            query,
            retrievalResult,
            conversationHistory,
            onToken,
          );
        } catch (e) {
          debugPrint('LlmService: Gemini API error: $e, using fallback');
          // Fall through to fallback
        }
      }

      // Fallback to local response generation
      return await _generateFallbackResponse(
        query,
        retrievalResult,
        onToken,
      );
    } catch (e) {
      debugPrint('LlmService: Generation error: $e');
      return GenerationResult.error('Failed to generate response: ${e.toString()}');
    }
  }

  /// Generate response using Gemini API.
  Future<GenerationResult> _generateWithGemini(
    String query,
    RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory,
    StreamCallback? onToken,
  ) async {
    // Build the prompt with context
    final prompt = _buildPrompt(query, retrievalResult, conversationHistory);

    if (onToken != null) {
      // Streaming response
      final response = _model!.generateContentStream([Content.text(prompt)]);
      final buffer = StringBuffer();

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          buffer.write(text);
          onToken(text);
        }
      }

      return GenerationResult(
        response: buffer.toString(),
        citations: retrievalResult.citations,
      );
    } else {
      // Non-streaming response
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return GenerationResult(
        response: text,
        citations: retrievalResult.citations,
      );
    }
  }

  /// Build prompt with context and conversation history.
  String _buildPrompt(
    String query,
    RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory,
  ) {
    final buffer = StringBuffer();

    // Add context from document
    buffer.writeln('DOCUMENT CONTEXT:');
    buffer.writeln('---');
    buffer.writeln(retrievalResult.context);
    buffer.writeln('---');
    buffer.writeln();

    // Add recent conversation history (last 3 exchanges)
    if (conversationHistory.isNotEmpty) {
      buffer.writeln('RECENT CONVERSATION:');
      final recent = conversationHistory.length > 6
          ? conversationHistory.sublist(conversationHistory.length - 6)
          : conversationHistory;
      
      for (final msg in recent) {
        final role = msg.isUser ? 'User' : 'Assistant';
        buffer.writeln('$role: ${msg.content}');
      }
      buffer.writeln();
    }

    // Add current question
    buffer.writeln('USER QUESTION: $query');
    buffer.writeln();
    buffer.writeln('Please provide a helpful, evidence-based answer with page citations.');

    return buffer.toString();
  }

  /// Generate fallback response when API is unavailable.
  Future<GenerationResult> _generateFallbackResponse(
    String query,
    RetrievalResult retrievalResult,
    StreamCallback? onToken,
  ) async {
    final citations = retrievalResult.citations;
    final queryLower = query.toLowerCase();

    String response;
    
    if (citations.isEmpty) {
      response = "I couldn't find specific information about that in the document. "
          "Try rephrasing your question or asking about a different topic covered in the PDF.";
    } else {
      // Build response from retrieved chunks
      final topCitation = citations.first;
      final pageRefs = citations.map((c) => 'p.${c.pageNumber}').toSet().take(3).join(', ');

      if (queryLower.contains('what') || queryLower.contains('define') || queryLower.contains('explain')) {
        response = 'Based on the document, here\'s what I found:\n\n'
            '"${topCitation.preview}"\n\n'
            'This information is from ($pageRefs).';
      } else if (queryLower.contains('how')) {
        response = 'According to the document ($pageRefs):\n\n'
            '"${topCitation.preview}"\n\n'
            'The document provides more details on this topic in the referenced pages.';
      } else {
        response = 'From the document:\n\n'
            '"${topCitation.preview}"\n\n'
            'Source: ($pageRefs)';
      }
    }

    // Simulate streaming if callback provided
    if (onToken != null) {
      await _simulateStreaming(response, onToken);
    }

    return GenerationResult(
      response: response,
      citations: citations,
    );
  }

  /// Simulate token-by-token streaming for fallback mode.
  Future<void> _simulateStreaming(String response, StreamCallback onToken) async {
    final words = response.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final token = i == 0 ? words[i] : ' ${words[i]}';
      onToken(token);
      await Future.delayed(Duration(milliseconds: 20 + (i % 3) * 10));
    }
  }

  /// Dispose of resources.
  void dispose() {
    _model = null;
    _isInitialized = false;
    debugPrint('LlmService: Disposed');
  }
}
