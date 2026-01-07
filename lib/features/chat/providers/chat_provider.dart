import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../data/llm_service.dart';
import '../data/rag_service.dart';
import '../domain/chat_message.dart';

/// State for a chat session.
class ChatState extends Equatable {
  const ChatState({
    this.documentId,
    this.messages = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.streamingContent = '',
    this.error,
  });

  /// The document being chatted about.
  final int? documentId;

  /// All messages in the conversation.
  final List<ChatMessage> messages;

  /// Whether initial messages are loading.
  final bool isLoading;

  /// Whether a response is being generated.
  final bool isGenerating;

  /// Content being streamed (for display during generation).
  final String streamingContent;

  /// Error message if something went wrong.
  final String? error;

  /// Check if chat is ready.
  bool get isReady => documentId != null && !isLoading;

  /// Check if input should be disabled.
  bool get isInputDisabled => isLoading || isGenerating;

  /// Get the last user message.
  ChatMessage? get lastUserMessage {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) return messages[i];
    }
    return null;
  }

  /// Copy with updated fields.
  ChatState copyWith({
    int? documentId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isGenerating,
    String? streamingContent,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      documentId: documentId ?? this.documentId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      streamingContent: streamingContent ?? this.streamingContent,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        documentId,
        messages,
        isLoading,
        isGenerating,
        streamingContent,
        error,
      ];
}

/// Provider for the chat notifier, scoped to a document.
final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final ragService = ref.watch(ragServiceProvider);
  final llmService = ref.watch(llmServiceProvider);

  return ChatNotifier(
    repository: repository,
    ragService: ragService,
    llmService: llmService,
  );
});

/// Notifier for managing chat state and interactions.
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required ChatRepository repository,
    required RagService ragService,
    required LlmService llmService,
  })  : _repository = repository,
        _ragService = ragService,
        _llmService = llmService,
        super(const ChatState());

  final ChatRepository _repository;
  final RagService _ragService;
  final LlmService _llmService;

  /// Initialize chat for a document.
  Future<void> initialize(int documentId) async {
    debugPrint('ChatNotifier: Initializing for document $documentId');
    
    state = state.copyWith(
      documentId: documentId,
      isLoading: true,
      clearError: true,
    );

    try {
      // Load existing messages
      final messages = await _repository.getMessages(documentId);
      
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );

      debugPrint('ChatNotifier: Loaded ${messages.length} messages');
    } catch (e) {
      debugPrint('ChatNotifier: Failed to load messages: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: ${e.toString()}',
      );
    }
  }

  /// Send a message and get a response.
  Future<void> sendMessage(
    String content, {
    InputMethod inputMethod = InputMethod.text,
  }) async {
    final documentId = state.documentId;
    if (documentId == null || content.trim().isEmpty) return;

    debugPrint('ChatNotifier: Sending message: "${content.substring(0, content.length.clamp(0, 50))}..."');

    // Create and save user message
    final userMessage = ChatMessage.user(
      documentId: documentId,
      content: content.trim(),
      inputMethod: inputMethod,
    );

    final savedUserMessage = await _repository.saveMessage(userMessage);
    if (savedUserMessage == null) {
      state = state.copyWith(error: 'Failed to save message');
      return;
    }

    // Add user message to state
    state = state.copyWith(
      messages: [...state.messages, savedUserMessage],
      isGenerating: true,
      streamingContent: '',
      clearError: true,
    );

    try {
      // Check cache first
      final cachedAnswer = await _repository.getCachedAnswer(
        documentId,
        content.trim(),
      );

      if (cachedAnswer != null) {
        debugPrint('ChatNotifier: Cache hit!');
        
        // Convert page numbers to Citation objects
        final citations = cachedAnswer.citations
            .map((pageNum) => Citation(
                  pageNumber: pageNum,
                  chunkIndex: 0,
                  text: '',
                ))
            .toList();

        final assistantMessage = ChatMessage.assistant(
          documentId: documentId,
          content: cachedAnswer.answer,
          citations: citations,
        );

        final savedAssistant = await _repository.saveMessage(assistantMessage);
        if (savedAssistant != null) {
          state = state.copyWith(
            messages: [...state.messages, savedAssistant],
            isGenerating: false,
          );
        }
        return;
      }

      // Retrieve relevant context
      debugPrint('ChatNotifier: Retrieving context...');
      final retrievalResult = await _ragService.retrieve(
        documentId,
        content.trim(),
      );

      if (!retrievalResult.isSuccess) {
        debugPrint('ChatNotifier: Retrieval failed: ${retrievalResult.error}');
        state = state.copyWith(
          isGenerating: false,
          error: retrievalResult.error ?? 'No relevant content found',
        );
        return;
      }

      // Generate response
      debugPrint('ChatNotifier: Generating response...');
      final generationResult = await _llmService.generate(
        query: content.trim(),
        retrievalResult: retrievalResult,
        conversationHistory: state.messages,
        onToken: (token) {
          state = state.copyWith(
            streamingContent: state.streamingContent + token,
          );
        },
      );

      if (!generationResult.isSuccess) {
        debugPrint('ChatNotifier: Generation failed: ${generationResult.error}');
        state = state.copyWith(
          isGenerating: false,
          error: generationResult.error ?? 'Failed to generate response',
        );
        return;
      }

      // Save assistant message
      final assistantMessage = ChatMessage.assistant(
        documentId: documentId,
        content: generationResult.response,
        citations: generationResult.citations,
      );

      final savedAssistant = await _repository.saveMessage(assistantMessage);
      if (savedAssistant != null) {
        state = state.copyWith(
          messages: [...state.messages, savedAssistant],
          isGenerating: false,
          streamingContent: '',
        );

        // Cache the response
        await _repository.cacheAnswer(
          documentId: documentId,
          question: content.trim(),
          answer: generationResult.response,
          context: retrievalResult.context,
          citations: generationResult.citations.map((c) => c.toJson()).toList(),
        );
      }

      debugPrint('ChatNotifier: Response generated successfully');
    } catch (e) {
      debugPrint('ChatNotifier: Error during message processing: $e');
      state = state.copyWith(
        isGenerating: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Clear the conversation.
  Future<void> clearConversation() async {
    final documentId = state.documentId;
    if (documentId == null) return;

    debugPrint('ChatNotifier: Clearing conversation');

    await _repository.clearMessages(documentId);
    state = state.copyWith(
      messages: [],
      streamingContent: '',
      clearError: true,
    );
  }

  /// Clear the current error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Retry the last failed message.
  Future<void> retryLastMessage() async {
    final lastUser = state.lastUserMessage;
    if (lastUser == null) return;

    // Remove the last user message and retry
    final messages = state.messages.toList();
    if (messages.isNotEmpty && messages.last.isUser) {
      messages.removeLast();
      state = state.copyWith(
        messages: messages,
        clearError: true,
      );
    }

    await sendMessage(lastUser.content, inputMethod: lastUser.inputMethod);
  }
}
