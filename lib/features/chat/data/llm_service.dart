import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import '../../setup/data/model_downloader.dart';
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

/// A task can cancel only its own generation, without stopping another tool.
class GenerationCancellation {
  bool isCancelled = false;
  Future<void> Function()? _onCancel;

  void cancel() {
    isCancelled = true;
    final handler = _onCancel;
    if (handler != null) unawaited(handler());
  }
}

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
  LlmService({Duration generationTimeout = const Duration(seconds: 120)})
    : _generationTimeout = generationTimeout;

  final Duration _generationTimeout;
  final activity = ValueNotifier<String>('Finding evidence in your PDF…');

  static const _channel = MethodChannel('com.citecoach/llm');
  static const _streamChannel = EventChannel('com.citecoach/llm_stream');

  /// Must match the package selected by the downloader.
  static const String modelName = ModelDownloader.modelFileName;
  static const int maxOutputTokens = 192;
  static const double temperature = 0.3;
  static const double topP = 0.9;

  String? _initializationError;
  bool _isModelLoaded = false;
  Future<bool>? _initializationFuture;
  bool get isModelLoaded => _isModelLoaded;

  StreamSubscription<dynamic>? _streamSubscription;
  Completer<String>? _pendingResponse;
  int _requestId = 0;
  Future<void>? _stopping;
  Completer<void>? _generationFinished;

  /// Initialize the LLM model via platform channel.
  Future<bool> initialize() {
    if (_isModelLoaded) return Future.value(true);
    return _initializationFuture ??= _initializeModel().whenComplete(() {
      _initializationFuture = null;
    });
  }

  void warmUp() {
    unawaited(initialize().timeout(const Duration(seconds: 60), onTimeout: () => false)
        .catchError((Object _) => false));
  }

  Future<bool> _initializeModel() async {
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
      _initializationError = e.code == 'LOW_MEMORY'
          ? 'Not enough available memory for offline AI. Close other apps and try again.'
          : 'CiteCoach AI could not start. Try again from Settings.';
      return false;
    } catch (e) {
      debugPrint('LlmService: Init error: $e');
      return false;
    }
  }

  Future<String> _getModelPath() async {
    // Use the variant selected by ModelDownloader (RAM-aware).
    final appDir = await getApplicationDocumentsDirectory();
    final variant = await ModelDownloader().selectedVariant();
    return '${appDir.path}/models/${variant.fileName}';
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
    String? responseInstructions,
    GenerationCancellation? cancellation,
  }) async {
    await _stopping;
    if (_pendingResponse?.isCompleted == true) {
      await _generationFinished?.future;
    }
    if (cancellation?.isCancelled == true) {
      return GenerationResult.error('Answer cancelled.');
    }
    if (_pendingResponse != null) {
      return GenerationResult.error(
        'Another answer is still running. Please wait.',
      );
    }
    final requestId = ++_requestId;
    if (!retrievalResult.isSuccess || retrievalResult.context.isEmpty) {
      return GenerationResult.error(
        'No relevant information found in the document.',
      );
    }

    final shortDefinition = responseInstructions == null && isShortDefinition(query);
    final outputTokens = shortDefinition ? 96 : maxOutputTokens;

    // Build the grounded prompt
    final prompt = buildGroundedPrompt(
      query: shortDefinition ? '$query Answer in at most two short sentences.' : query,
      context: retrievalResult.context,
      citations: retrievalResult.citations,
      history: conversationHistory,
      responseInstructions: responseInstructions,
    );

    if (!_isModelLoaded) {
      activity.value = 'Loading offline model…';
      final initialized = await initialize().timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );
      if (!initialized) {
        return GenerationResult.error(
          _initializationError ??
              'Offline AI is not available. Download CiteCoach AI in Settings.',
        );
      }
    }

    if (requestId != _requestId || cancellation?.isCancelled == true) {
      return GenerationResult.error('Answer cancelled.');
    }
    try {
      activity.value = 'Generating on your device…';
      debugPrint('LlmService: Generating response...');

      final completer = Completer<String>();
      _generationFinished = Completer<void>();
      _pendingResponse = completer;
      if (cancellation != null) cancellation._onCancel = stopGeneration;
      final responseBuffer = StringBuffer();

      // Listen to the EventChannel for streamed tokens
      _streamSubscription = _streamChannel.receiveBroadcastStream().listen(
        (event) {
          if (completer.isCompleted || requestId != _requestId) return;
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
            activity.value = 'Writing the response…';
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
      final start = _channel.invokeMethod('startGeneration', {
        'prompt': prompt,
        'maxTokens': outputTokens,
        'temperature': temperature,
        'topP': topP,
        'repeatPenalty': 1.1,
      });
      // Attach the completion listener immediately, including start failures.
      unawaited(
        start.catchError((Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        }),
      );

      // Wait for generation to complete
      final responseText = await completer.future.timeout(_generationTimeout);

      // Clean up stream
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      if (responseText.isEmpty) {
        return GenerationResult.error(
          'CiteCoach AI returned no answer. Please try again.',
        );
      }

      // Parse citations from response and clean up
      final parsed = _parseResponse(responseText, retrievalResult.citations);

      return GenerationResult(
        response: parsed.cleanedText,
        citations: parsed.matchedCitations,
      );
    } on TimeoutException {
      await stopGeneration();
      return GenerationResult.error(
        'The on-device model took too long. Try a shorter question.',
      );
    } on PlatformException catch (e) {
      debugPrint('LlmService: Generation error: $e');
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      return GenerationResult.error(
        e.code == 'CONTEXT'
            ? 'The question and evidence are too long. Try a shorter question.'
            : 'CiteCoach AI could not finish this answer. Please try again.',
      );
    } catch (e) {
      debugPrint('LlmService: Error: $e');
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      return GenerationResult.error(
        'CiteCoach AI could not finish this answer. Please try again.',
      );
    } finally {
      if (cancellation != null) cancellation._onCancel = null;
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      _pendingResponse = null;
      _generationFinished?.complete();
      _generationFinished = null;
    }
  }

  /// Stop an in-progress generation.
  Future<void> stopGeneration() async {
    final existing = _stopping;
    if (existing != null) {
      await existing;
      return;
    }
    final stopping = _stopNativeGeneration();
    _stopping = stopping;
    try {
      await stopping;
    } finally {
      if (identical(_stopping, stopping)) _stopping = null;
    }
  }

  Future<void> _stopNativeGeneration() async {
    ++_requestId;
    final pending = _pendingResponse;
    try {
      await _channel
          .invokeMethod<void>('stopGeneration')
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Always settle the caller, including if the platform channel is silent.
    } finally {
      if (pending != null && !pending.isCompleted) pending.complete('');
    }
  }

  @visibleForTesting
  static bool isShortDefinition(String query) {
    final q = query.trim().toLowerCase();
    return q.length <= 140 &&
        RegExp(r'^(what is|define|what does .+ mean)\b').hasMatch(q) &&
        !RegExp(r'\b(and|compare|difference|examples?|steps?|why|how)\b').hasMatch(q);
  }

  /// Build a citation-grounded prompt for the on-device LLM.
  @visibleForTesting
  String buildGroundedPrompt({
    required String query,
    required String context,
    required List<Citation> citations,
    required List<ChatMessage> history,
    String? responseInstructions,
  }) {
    // Qwen3 ChatML with explicit non-thinking assistant prefill.
    // Keep each question self-contained so excerpt grounding is unambiguous.
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>user');
    buffer.writeln(
      responseInstructions ??
      'You are CiteCoach. Answer briefly using ONLY the document excerpts. '
      'Cite every claim using [Page X]. If the excerpts do not answer the '
      'question, say "I could not find this information in the document."',
    );
    buffer.writeln('--- DOCUMENT EXCERPTS ---');
    buffer.writeln(context);
    buffer.writeln('--- END EXCERPTS ---');
    final recentHistory = history.length > 2
        ? history.sublist(history.length - 2)
        : history;
    if (recentHistory.isNotEmpty) {
      buffer.writeln('Previous conversation (context only):');
      for (final msg in recentHistory) {
        final text = msg.content.length > 200
            ? msg.content.substring(0, 200)
            : msg.content;
        buffer.writeln('${msg.isUser ? "Question" : "Answer"}: $text');
      }
    }

    buffer.writeln('Question: $query');
    buffer.writeln(responseInstructions ?? 'Give a short answer with [Page X] citations.');
    buffer.writeln('/no_think');
    buffer.writeln('<|im_end|>');
    buffer.writeln('<|im_start|>assistant');
    buffer.write('<think>\n\n</think>\n\n');

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

    // Do not attach uncited excerpts as though the answer cited them.

    // Clean up response text
    var cleaned = responseText.trim();
    cleaned = cleaned.replaceAll('<|im_end|>', '');
    cleaned = cleaned.replaceAll('<|im_start|>', '');
    cleaned = cleaned.replaceAll('<|endoftext|>', '');

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
