import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/preferences/user_preferences.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../../library/domain/document.dart';
import '../../library/providers/library_provider.dart';
import '../domain/chat_message.dart';
import '../providers/chat_provider.dart';
import 'widgets/citation_badge.dart';
import 'widgets/document_dna_strip.dart';
import 'widgets/empty_chat_view.dart';
import 'widgets/living_chat_input.dart';
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
    ref.read(appHapticsProvider).light();
    ref.read(chatProvider.notifier).sendMessage(message);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _handleCitationTap(Citation citation, Document document) {
    ref.read(appHapticsProvider).medium();
    // Show citation details in a bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: CitationCard(
          citation: citation,
          onNavigate: () {
            Navigator.pop(context);
            context.push(
              '${AppRoutes.documentReader(document.id.toString())}?page=${citation.pageNumber}',
            );
          },
        ),
      ),
    );
  }

  void _handleDnaPageTap(int page, Document document) {
    ref.read(appHapticsProvider).light();
    context.push(
      '${AppRoutes.documentReader(document.id.toString())}?page=$page',
    );
  }

  void _handleVoiceStart() async {
    ref.read(appHapticsProvider).medium();
    final result = await context.push<String>(
      '${AppRoutes.voiceInput}?documentId=${widget.documentId}',
    );

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
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(appHapticsProvider).heavy();
      ref.read(chatProvider.notifier).clearConversation();
    }
  }

  /// Build a map of pageNumber → citation count from all AI messages.
  Map<int, int> _computeCitationCounts(List<ChatMessage> messages) {
    final counts = <int, int>{};
    for (final msg in messages) {
      if (!msg.isAssistant) continue;
      for (final c in msg.citations) {
        counts[c.pageNumber] = (counts[c.pageNumber] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Generate smart conversation starters based on the document.
  List<String> _suggestedQuestions(Document? doc) {
    if (doc == null) return const [];
    return [
      'What is this document about?',
      'Summarize the key points.',
      'What are the main arguments?',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final libraryState = ref.watch(libraryProvider);
    final theme = Theme.of(context).extension<AppThemeData>()!;

    final document = libraryState.documents
        .where((d) => d.id == widget.documentId)
        .firstOrNull;

    final citationCounts = _computeCitationCounts(chatState.messages);

    // Listen for new messages to scroll
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, document),
      body: SafeArea(
        child: Row(
          children: [
            // Main chat column
            Expanded(
              child: Column(
                children: [
                  if (chatState.error != null)
                    _buildErrorBanner(theme, chatState.error!),
                  Expanded(
                    child: chatState.isLoading
                        ? const Center(
                            child: LoadingIndicator(useGradient: true))
                        : chatState.messages.isEmpty
                            ? EmptyChatView(
                                documentTitle: document?.title ?? 'Document',
                                onSampleQuestion: _handleSend,
                              )
                            : _buildMessageList(chatState, document),
                  ),
                  LivingChatInput(
                    onSend: _handleSend,
                    onVoiceStart: _handleVoiceStart,
                    suggestions: chatState.messages.isEmpty
                        ? _suggestedQuestions(document)
                        : const [],
                    isDisabled: chatState.isInputDisabled,
                  ),
                ],
              ),
            ),
            // Document DNA strip — only if the document has pages and
            // there's at least one citation.
            if (document != null &&
                document.pageCount > 0 &&
                citationCounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: DocumentDnaStrip(
                  pageCount: document.pageCount,
                  citationCounts: citationCounts,
                  onPageTap: (p) => _handleDnaPageTap(p, document),
                ),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          tooltip: 'Open in Reader',
          onPressed: document != null
              ? () {
                  ref.read(appHapticsProvider).light();
                  context.push(
                      AppRoutes.documentReader(document.id.toString()));
                }
              : null,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'clear') _handleClearChat();
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

  Widget _buildErrorBanner(AppThemeData theme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: theme.error,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: state.messages.length + (state.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
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
