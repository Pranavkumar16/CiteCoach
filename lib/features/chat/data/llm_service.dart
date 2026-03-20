import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// Service for on-device LLM inference using llama.cpp via platform channels.
///
/// Communicates with native Android (Kotlin) and iOS (Swift) code that
/// runs llama.cpp for local model inference. All processing happens
/// on-device with zero network calls.
///
/// Architecture:
/// - Dart ↔ MethodChannel → Native llama.cpp
/// - Token streaming via EventChannel
/// - Model lifecycle managed natively for memory efficiency
class LlmService {
  LlmService();

  static const _methodChannel = MethodChannel('com.citecoach/llm');
  static const _streamChannel = EventChannel('com.citecoach/llm_stream');

  /// Whether the model is loaded and ready for inference.
  bool _isModelLoaded = false;

  /// Check if model is ready.
  bool get isModelLoaded => _isModelLoaded;

  /// Stream subscription for token streaming.
  StreamSubscription<dynamic>? _streamSubscription;

  /// Initialize the LLM model from the given path.
  ///
  /// Loads the GGUF model file into memory on the native side.
  /// This is a heavy operation (~2-5 seconds) and should be called
  /// once during app startup after model download.
  Future<bool> initialize({String? modelPath}) async {
    if (_isModelLoaded) return true;

    try {
      debugPrint('LlmService: Loading model...');
      final result = await _methodChannel.invokeMethod<bool>(
        'loadModel',
        {'modelPath': modelPath},
      );
      _isModelLoaded = result ?? false;
      debugPrint('LlmService: Model loaded: $_isModelLoaded');
      return _isModelLoaded;
    } on PlatformException catch (e) {
      debugPrint('LlmService: Failed to load model: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('LlmService: Native plugin not available');
      return false;
    }
  }

  /// Generate a response to a query given retrieved context.
  ///
  /// Builds a prompt from the context and query, sends it to the
  /// native LLM, and streams tokens back via EventChannel.
  Future<GenerationResult> generate({
    required String query,
    required RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory = const [],
    StreamCallback? onToken,
  }) async {
    if (!_isModelLoaded) {
      final loaded = await initialize();
      if (!loaded) {
        return GenerationResult.error(
          'AI model not loaded. Please download the model in Settings.',
        );
      }
    }

    try {
      if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
        return GenerationResult.error(
          'No relevant information found in the document.',
        );
      }

      // Build the prompt
      final prompt = _buildPrompt(
        query: query,
        context: retrievalResult.context,
        history: conversationHistory,
      );

      debugPrint('LlmService: Generating response (prompt: ${prompt.length} chars)');

      // Generate with streaming
      final response = await _generateWithStreaming(prompt, onToken);

      if (response.isEmpty) {
        return GenerationResult.error('Model returned empty response.');
      }

      return GenerationResult(
        response: response,
        citations: retrievalResult.citations,
      );
    } catch (e) {
      debugPrint('LlmService: Generation error: $e');
      return GenerationResult.error(
          'Failed to generate response: ${e.toString()}');
    }
  }

  /// Build a structured prompt for Phi-3.5 Mini (ChatML format).
  ///
  /// Phi-3.5 uses the ChatML template:
  /// <|system|>\n{system}<|end|>\n<|user|>\n{user}<|end|>\n<|assistant|>\n
  ///
  /// Instructs the model to:
  /// - Only answer from the provided context
  /// - Cite page numbers
  /// - Say "I don't know" if the answer isn't in the context
  String _buildPrompt({
    required String query,
    required String context,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer();

    // System message
    buffer.writeln('<|system|>');
    buffer.writeln(
        'You are a helpful study assistant. Answer questions ONLY using the '
        'provided document context below. If the answer is not in the context, '
        'say "I couldn\'t find information about that in this document."'
        '\nAlways reference which page the information comes from (e.g., "According to page 3...").'
        '\nBe concise, accurate, and helpful.');
    buffer.writeln('<|end|>');

    // Document context as a user message
    buffer.writeln('<|user|>');
    buffer.writeln('Here is the document context to answer from:');
    buffer.writeln();
    buffer.writeln(context);
    buffer.writeln('<|end|>');

    // Recent conversation history (last 4 turns for context window efficiency)
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    for (final msg in recentHistory) {
      if (msg.isUser) {
        buffer.writeln('<|user|>');
        buffer.writeln(msg.content);
        buffer.writeln('<|end|>');
      } else {
        buffer.writeln('<|assistant|>');
        buffer.writeln(msg.content);
        buffer.writeln('<|end|>');
      }
    }

    // Current question
    buffer.writeln('<|user|>');
    buffer.writeln(query);
    buffer.writeln('<|end|>');

    // Start assistant response
    buffer.writeln('<|assistant|>');

    return buffer.toString();
  }

  /// Generate response with token streaming via EventChannel.
  Future<String> _generateWithStreaming(
    String prompt,
    StreamCallback? onToken,
  ) async {
    final completer = Completer<String>();
    final responseBuffer = StringBuffer();

    try {
      // Start generation on native side
      await _methodChannel.invokeMethod('startGeneration', {
        'prompt': prompt,
        'maxTokens': 512,
        'temperature': 0.7,
        'topP': 0.9,
        'repeatPenalty': 1.1,
      });

      // Listen for streamed tokens
      _streamSubscription?.cancel();
      _streamSubscription = _streamChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is String) {
            if (event == '[DONE]') {
              if (!completer.isCompleted) {
                completer.complete(responseBuffer.toString().trim());
              }
            } else if (event.startsWith('[ERROR]')) {
              if (!completer.isCompleted) {
                completer.completeError(
                    event.replaceFirst('[ERROR]', '').trim());
              }
            } else {
              responseBuffer.write(event);
              onToken?.call(event);
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(responseBuffer.toString().trim());
          }
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _streamSubscription?.cancel();
          _stopGeneration();
          return responseBuffer.toString().trim();
        },
      );
    } catch (e) {
      _streamSubscription?.cancel();
      if (e is PlatformException || e is MissingPluginException) {
        rethrow;
      }
      return responseBuffer.toString().trim();
    }
  }

  /// Stop current generation.
  Future<void> _stopGeneration() async {
    try {
      await _methodChannel.invokeMethod('stopGeneration');
    } catch (_) {}
  }

  /// Unload the model from memory.
  Future<void> unloadModel() async {
    try {
      await _methodChannel.invokeMethod('unloadModel');
      _isModelLoaded = false;
      debugPrint('LlmService: Model unloaded');
    } catch (e) {
      debugPrint('LlmService: Error unloading model: $e');
    }
  }

  /// Get model info (name, size, quantization).
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final result =
          await _methodChannel.invokeMapMethod<String, dynamic>('getModelInfo');
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Dispose of model resources.
  void dispose() {
    _streamSubscription?.cancel();
    unloadModel();
  }
}
