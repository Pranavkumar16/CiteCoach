import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/chat_message.dart';
import 'rag_service.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService();
});

class GenerationResult {
  const GenerationResult({
    required this.response,
    required this.citations,
    this.error,
    this.fromCache = false,
  });
  final String response;
  final List<Citation> citations;
  final String? error;
  final bool fromCache;
  bool get isSuccess => error == null && response.isNotEmpty;

  factory GenerationResult.error(String message) {
    return GenerationResult(response: '', citations: [], error: message);
  }
}

typedef StreamCallback = void Function(String token);

/// On-device LLM inference via platform channels (llama.cpp).
///
/// Architecture:
/// - Android: llama.cpp via NDK/JNI (arm64-v8a)
/// - iOS: llama.cpp via C API (arm64, Metal accelerated)
/// - Prompt engineering: citation-grounded Q&A with context injection
///
/// The service constructs prompts that force the model to ground answers
/// in provided context with page-level citations.
class LlmService {
  LlmService();

  static const _channel = MethodChannel('com.citecoach/llm');
  static const _streamChannel = EventChannel('com.citecoach/llm_stream');
  static const String modelName = 'gemma-2-2b-it-Q4_K_M.gguf';
  static const int maxOutputTokens = 512;
  static const double temperature = 0.3;
  static const double topP = 0.9;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  StreamSubscription<dynamic>? _streamSubscription;

  /// Initialize the LLM model via platform channel.
  Future<bool> initialize() async {
    if (_isModelLoaded) return true;
    debugPrint('LlmService: Initializing...');

    try {
      final modelPath = await _getModelPath();
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        debugPrint('LlmService: Model file not found at $modelPath');
        return false;
      }

      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });

      _isModelLoaded = result == true;
      debugPrint('LlmService: Model loaded: $_isModelLoaded');
      return _isModelLoaded;
    } on PlatformException catch (e) {
      debugPrint('LlmService: Platform error: $e');
      return false;
    } catch (e) {
      debugPrint('LlmService: Init error: $e');
      return false;
    }
  }

  Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/$modelName';
  }

  /// Check if the model file exists on disk.
  Future<bool> isModelAvailable() async {
    final modelPath = await _getModelPath();
    return File(modelPath).exists();
  }

  /// Generate a response grounded in retrieved context.
  Future<GenerationResult> generate({
    required String query,
    required RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory = const [],
    StreamCallback? onToken,
  }) async {
    if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
      return GenerationResult.error(
        'No relevant information found in the document.',
      );
    }

    // Build the grounded prompt
    final prompt = _buildPrompt(
      query: query,
      context: retrievalResult.context,
      citations: retrievalResult.citations,
      history: conversationHistory,
    );

    if (!_isModelLoaded) {
      final initialized = await initialize();
      if (!initialized) {
        return GenerationResult.error(
          'AI model is not available. Please download the model first.',
        );
      }
    }

    try {
      debugPrint('LlmService: Generating response...');

      final completer = Completer<String>();
      final responseBuffer = StringBuffer();

      // Listen to the EventChannel for streamed tokens
      _streamSubscription = _streamChannel.receiveBroadcastStream().listen(
        (event) {
          final token = event as String;
          if (token == '[DONE]') {
            if (!completer.isCompleted) {
              completer.complete(responseBuffer.toString());
            }
          } else if (token.startsWith('[ERROR]')) {
            if (!completer.isCompleted) {
              completer.completeError(token.substring(7));
            }
          } else {
            responseBuffer.write(token);
            onToken?.call(token);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error.toString());
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(responseBuffer.toString());
          }
        },
      );

      // Start generation via MethodChannel
      await _channel.invokeMethod('startGeneration', {
        'prompt': prompt,
        'maxTokens': maxOutputTokens,
        'temperature': temperature,
        'topP': topP,
        'repeatPenalty': 1.1,
      });

      // Wait for generation to complete
      final responseText = await completer.future;

      // Clean up stream
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      if (responseText.isEmpty) {
        return GenerationResult.error('Model returned empty response');
      }

      // Parse citations from response and clean up
      final parsed = _parseResponse(responseText, retrievalResult.citations);

      return GenerationResult(
        response: parsed.cleanedText,
        citations: parsed.matchedCitations,
      );
    } on PlatformException catch (e) {
      debugPrint('LlmService: Generation error: $e');
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      return GenerationResult.error('Model inference failed: ${e.message}');
    } catch (e) {
      debugPrint('LlmService: Error: $e');
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      return GenerationResult.error('Failed to generate response: $e');
    }
  }

  /// Stop an in-progress generation.
  Future<void> stopGeneration() async {
    try {
      await _channel.invokeMethod('stopGeneration');
    } catch (_) {}
    await _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Build a citation-grounded prompt for Gemma 2B.
  String _buildPrompt({
    required String query,
    required String context,
    required List<Citation> citations,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer();

    // System instruction for Gemma format
    buffer.writeln('<start_of_turn>user');
    buffer.writeln('You are CiteCoach, a document analysis assistant. '
        'Answer questions ONLY using the provided document excerpts. '
        'Always cite your sources using [Page X] format. '
        'If the answer is not in the excerpts, say "I could not find this information in the document."');
    buffer.writeln();
    buffer.writeln('--- DOCUMENT EXCERPTS ---');
    buffer.writeln(context);
    buffer.writeln('--- END EXCERPTS ---');
    buffer.writeln();

    // Add recent conversation history (last 4 exchanges)
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    for (final msg in recentHistory) {
      if (msg.isUser) {
        buffer.writeln('Previous question: ${msg.content}');
      } else if (msg.isAssistant) {
        buffer.writeln('Previous answer: ${msg.content}');
      }
    }

    buffer.writeln();
    buffer.writeln('Question: $query');
    buffer.writeln();
    buffer.writeln(
        'Answer the question using ONLY the document excerpts above. '
        'Include [Page X] citations for every claim.');
    buffer.writeln('<end_of_turn>');
    buffer.writeln('<start_of_turn>model');

    return buffer.toString();
  }

  /// Parse model response to extract and validate citations.
  _ParsedResponse _parseResponse(
    String responseText,
    List<Citation> availableCitations,
  ) {
    // Extract page references from the response text
    final pageRefs = RegExp(r'\[Page\s*(\d+)\]');
    final matches = pageRefs.allMatches(responseText);
    final referencedPages = <int>{};

    for (final match in matches) {
      final pageNum = int.tryParse(match.group(1) ?? '');
      if (pageNum != null) referencedPages.add(pageNum);
    }

    // Match to available citations
    final matched = availableCitations
        .where((c) => referencedPages.contains(c.pageNumber))
        .toList();

    // If model didn't cite but we have citations, add them
    if (matched.isEmpty && availableCitations.isNotEmpty) {
      matched.addAll(availableCitations.take(3));
    }

    // Clean up response text
    var cleaned = responseText.trim();
    cleaned = cleaned.replaceAll('<end_of_turn>', '');
    cleaned = cleaned.replaceAll('<start_of_turn>', '');

    return _ParsedResponse(cleanedText: cleaned, matchedCitations: matched);
  }

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (_isModelLoaded) {
      try {
        _channel.invokeMethod('unloadModel');
      } catch (_) {}
    }
    _isModelLoaded = false;
    debugPrint('LlmService: Disposed');
  }
}

class _ParsedResponse {
  final String cleanedText;
  final List<Citation> matchedCitations;
  _ParsedResponse({required this.cleanedText, required this.matchedCitations});
}
