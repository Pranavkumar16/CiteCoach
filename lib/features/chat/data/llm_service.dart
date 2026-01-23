import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/model_files.dart';
import '../domain/chat_message.dart';
import 'rag_service.dart';

/// Provider for the LLM service.
final llmServiceProvider = Provider<LlmService>((ref) {
  final modelFiles = ref.watch(modelFilesProvider);
  return LlmService(modelFiles);
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
  LlmService(this._modelFiles);

  final ModelFiles _modelFiles;

  /// Whether the model is loaded and ready.
  bool _isModelLoaded = false;

  /// Check if model is ready.
  bool get isModelLoaded => _isModelLoaded;

  /// Initialize the LLM model.
  /// 
  /// In V1, this is a no-op stub.
  Future<bool> initialize() async {
    if (_isModelLoaded) return true;

    final hasModel = await _modelFiles.hasLlmModel();
    if (!hasModel) {
      debugPrint('LlmService: Model file missing, cannot initialize');
      return false;
    }

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
      final initialized = await initialize();
      if (!initialized) {
        return GenerationResult.error(
          'Model not available. Download the AI model to enable chat.',
        );
      }
    }

    try {
      debugPrint('LlmService: Generating response for query');

      if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
        return GenerationResult.error(
          'No relevant information found in the document.',
        );
      }

      // Generate extractive response
      final response = await _generateExtractiveResponse(
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

  /// Generate a response based on the retrieved context.
  ///
  /// This stub uses extractive snippets to provide grounded answers.
  Future<String> _generateExtractiveResponse(
    String query,
    RetrievalResult retrievalResult,
    StreamCallback? onToken,
  ) async {
    final citations = retrievalResult.citations;
    final queryTerms = _tokenize(query);

    final contextByPage = _parseContextByPage(retrievalResult.context);
    final candidates = <_SnippetCandidate>[];
    for (final citation in citations) {
      final text = citation.text.isNotEmpty
          ? citation.text
          : contextByPage[citation.pageNumber] ?? '';
      if (text.isEmpty) continue;
      candidates.add(_SnippetCandidate(
        pageNumber: citation.pageNumber,
        text: _trimSnippet(text),
      ));
    }

    if (candidates.isEmpty && contextByPage.isNotEmpty) {
      contextByPage.forEach((page, text) {
        if (text.isNotEmpty) {
          candidates.add(
            _SnippetCandidate(pageNumber: page, text: _trimSnippet(text)),
          );
        }
      });
    }

    final scored = candidates.map((candidate) {
      final score = _scoreSnippet(candidate.text, queryTerms);
      return _ScoredCandidate(candidate: candidate, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final selected = scored.isNotEmpty
        ? scored.take(3).toList()
        : <_ScoredCandidate>[];

    final topic = _extractTopic(query);
    final buffer = StringBuffer()
      ..writeln('Based on the document, $topic:');

    if (selected.isNotEmpty) {
      for (final item in selected) {
        buffer.writeln(
          '• ${item.candidate.text} (p.${item.candidate.pageNumber})',
        );
      }
    } else {
      buffer.writeln('• Relevant information was found in the document.');
    }

    // Add page citations
    if (citations.isNotEmpty) {
      final pageRefs =
          citations.map((c) => 'p.${c.pageNumber}').toSet().join(', ');
      buffer.writeln('\n[Source: $pageRefs]');
    }

    final response = buffer.toString().trim();

    // Simulate streaming if callback provided
    if (onToken != null) {
      await _simulateStreaming(response, onToken);
    }

    return response;
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

  Map<int, String> _parseContextByPage(String context) {
    final regex = RegExp(r'\[Page (\d+)\]\s');
    final matches = regex.allMatches(context).toList();
    final result = <int, String>{};
    if (matches.isEmpty) return result;

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final pageNumber = int.tryParse(match.group(1) ?? '');
      if (pageNumber == null) continue;
      final start = match.end;
      final end = i + 1 < matches.length ? matches[i + 1].start : context.length;
      final text = context.substring(start, end).trim();
      if (text.isNotEmpty) {
        result[pageNumber] = text;
      }
    }
    return result;
  }

  List<String> _tokenize(String text) {
    return RegExp(r"[A-Za-z0-9']+")
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => token.length > 1)
        .toList();
  }

  double _scoreSnippet(String text, List<String> queryTerms) {
    if (queryTerms.isEmpty) return 0.0;
    final lower = text.toLowerCase();
    int matches = 0;
    for (final term in queryTerms) {
      if (lower.contains(term)) {
        matches++;
      }
    }
    return matches / queryTerms.length;
  }

  String _trimSnippet(String text, {int maxLength = 240}) {
    if (text.length <= maxLength) return text;
    final cutoff = text.lastIndexOf('. ', maxLength - 3);
    if (cutoff > maxLength / 2) {
      return text.substring(0, cutoff + 1);
    }
    final spaceIndex = text.lastIndexOf(' ', maxLength - 3);
    if (spaceIndex > maxLength / 2) {
      return '${text.substring(0, spaceIndex)}...';
    }
    return '${text.substring(0, maxLength - 3)}...';
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

class _SnippetCandidate {
  const _SnippetCandidate({
    required this.pageNumber,
    required this.text,
  });

  final int pageNumber;
  final String text;
}

class _ScoredCandidate {
  const _ScoredCandidate({
    required this.candidate,
    required this.score,
  });

  final _SnippetCandidate candidate;
  final double score;
}
