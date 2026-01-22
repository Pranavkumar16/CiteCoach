import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../../library/domain/document.dart';
import '../../library/providers/library_provider.dart';
import '../domain/chat_message.dart';
import '../providers/chat_provider.dart';
import 'widgets/chat_input.dart';
import 'widgets/citation_badge.dart';
import 'widgets/empty_chat_view.dart';
import 'widgets/message_bubble.dart';

/// Main chat screen for document Q&A.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.documentId,
  });

  /// The ID of the document to chat about.
  final int documentId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize chat when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initialize(widget.documentId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend(String message) {
    ref.read(chatProvider.notifier).sendMessage(message);
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _handleCitationTap(Citation citation, Document document) {
    // Show citation details in a bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(AppDimensions.spacingLg),
        child: CitationCard(
          citation: citation,
          onNavigate: () {
            Navigator.pop(context);
            // Navigate to reader at specific page
            context.push(AppRoutes.documentReader(
              document.id.toString(),
              page: citation.pageNumber,
              highlight: citation.text.isNotEmpty ? citation.text : null,
              fromChat: true,
            ));
          },
        ),
      ),
    );
  }

  void _handleVoiceStart() async {
    // Navigate to voice input screen and wait for result
    final result = await context.push<String>(
      '${AppRoutes.voiceInput}?documentId=${widget.documentId}',
    );
    
    // If we got transcribed text, send it as a message
    if (result != null && result.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(
        result,
        inputMethod: InputMethod.voice,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _handleClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
          'This will delete all messages in this conversation. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(chatProvider.notifier).clearConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final libraryState = ref.watch(libraryProvider);
    
    // Get the document
    final document = libraryState.documents.where((d) => d.id == widget.documentId).firstOrNull;

    // Listen for new messages to scroll
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, document),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner
            if (chatState.error != null)
              _buildErrorBanner(chatState.error!),
            
            // Messages list
            Expanded(
              child: chatState.isLoading
                  ? const Center(child: LoadingIndicator(useGradient: true))
                  : chatState.messages.isEmpty
                      ? EmptyChatView(
                          documentTitle: document?.title ?? 'Document',
                          onSampleQuestion: _handleSend,
                        )
                      : _buildMessageList(chatState, document),
            ),
            
            // Input area
            ChatInput(
              onSend: _handleSend,
              onVoiceStart: _handleVoiceStart,
              isDisabled: chatState.isInputDisabled,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Document? document) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document?.title ?? 'Chat',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'Ask questions about this document',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Open in reader
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Open in Reader',
          onPressed: document != null
              ? () => context.push(AppRoutes.documentReader(
                    document.id.toString(),
                    fromChat: true,
                  ))
              : null,
        ),
        // Clear chat
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'clear') {
              _handleClearChat();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Clear conversation'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      color: AppColors.errorRed.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 20,
          ),
          SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.errorRed,
            onPressed: () => ref.read(chatProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state, Document? document) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      itemCount: state.messages.length + (state.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        // Show streaming indicator as last item
        if (index == state.messages.length && state.isGenerating) {
          return MessageBubble(
            message: ChatMessage.streaming(widget.documentId),
            streamingContent: state.streamingContent,
          );
        }

        final message = state.messages[index];
        return MessageBubble(
          message: message,
          onCitationTap: document != null
              ? (citation) => _handleCitationTap(citation, document)
              : null,
        );
      },
    );
  }
}
