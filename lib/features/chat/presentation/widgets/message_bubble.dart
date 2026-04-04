import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/user_preferences.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../domain/chat_message.dart';
import 'citation_badge.dart';

/// A chat message bubble that adapts to the user's chat style and
/// citation display preferences, and the current theme.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onCitationTap,
    this.streamingContent,
  });

  final ChatMessage message;
  final void Function(Citation citation)? onCitationTap;
  final String? streamingContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final content = streamingContent ?? message.content;
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final prefs = ref.watch(userPreferencesProvider);
    final style = prefs.chatStyle;
    final citationMode = prefs.citationDisplay;

    final padding = _paddingForStyle(style);
    final radius = _radiusForStyle(style, isUser: isUser);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: style == ChatStyle.compact ? 4 : 8,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && style != ChatStyle.compact) ...[
            _buildAvatar(theme, isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sidebar citation mode: citations on the left of AI messages
                if (!isUser &&
                    citationMode == CitationDisplay.sidebar &&
                    message.hasCitations &&
                    onCitationTap != null)
                  _buildSidebarLayout(
                    theme: theme,
                    style: style,
                    content: content,
                    padding: padding,
                    radius: radius,
                    isUser: isUser,
                  )
                else
                  _buildBubble(
                    theme: theme,
                    style: style,
                    content: content,
                    padding: padding,
                    radius: radius,
                    isUser: isUser,
                    // Inline: render citations inside the bubble
                    inlineCitations: !isUser &&
                        citationMode == CitationDisplay.inline &&
                        message.hasCitations &&
                        onCitationTap != null,
                  ),

                // Footer citation mode: citations below the bubble
                if (!isUser &&
                    citationMode == CitationDisplay.footer &&
                    message.hasCitations &&
                    onCitationTap != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: CitationRow(
                      citations: message.citations,
                      onCitationTap: onCitationTap!,
                    ),
                  ),

                const SizedBox(height: 4),
                _buildMetadata(theme),
              ],
            ),
          ),
          if (isUser && style != ChatStyle.compact) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, isUser: true),
          ],
        ],
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildBubble({
    required AppThemeData theme,
    required ChatStyle style,
    required String content,
    required EdgeInsets padding,
    required BorderRadius radius,
    required bool isUser,
    required bool inlineCitations,
  }) {
    final useGradient = isUser && style == ChatStyle.modern;
    final bgColor = _bgColor(theme, isUser: isUser, style: style);
    final borderColor = _borderColor(theme, isUser: isUser, style: style);
    final textColor = _textColor(theme, isUser: isUser);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: useGradient ? null : bgColor,
        gradient: useGradient ? theme.accentGradient : null,
        borderRadius: radius,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isStreaming && content.isEmpty)
            _buildTypingIndicator(theme)
          else
            Text(
              content,
              style: TextStyle(
                fontSize: style == ChatStyle.compact ? 14 : 15,
                height: 1.4,
                color: textColor,
              ),
            ),
          if (inlineCitations)
            CitationRow(
              citations: message.citations,
              onCitationTap: onCitationTap!,
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarLayout({
    required AppThemeData theme,
    required ChatStyle style,
    required String content,
    required EdgeInsets padding,
    required BorderRadius radius,
    required bool isUser,
  }) {
    final uniquePages = <int>{};
    for (final c in message.citations) {
      uniquePages.add(c.pageNumber);
    }
    final pages = uniquePages.toList()..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical citation strip
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.only(top: 4, right: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pages.take(5).map((page) {
              final citation =
                  message.citations.firstWhere((c) => c.pageNumber == page);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () => onCitationTap!(citation),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.citation.withOpacity(0.15),
                      border: Border.all(
                        color: theme.citation.withOpacity(0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'p.$page',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.citation,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Flexible(
          child: _buildBubble(
            theme: theme,
            style: style,
            content: content,
            padding: padding,
            radius: radius,
            isUser: isUser,
            inlineCitations: false,
          ),
        ),
      ],
    );
  }

  // ==================== STYLE HELPERS ====================

  EdgeInsets _paddingForStyle(ChatStyle style) {
    switch (style) {
      case ChatStyle.modern:
        return const EdgeInsets.all(12);
      case ChatStyle.classic:
        return const EdgeInsets.all(12);
      case ChatStyle.compact:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
    }
  }

  BorderRadius _radiusForStyle(ChatStyle style, {required bool isUser}) {
    switch (style) {
      case ChatStyle.modern:
        return BorderRadius.only(
          topLeft: Radius.circular(isUser ? 12 : 4),
          topRight: Radius.circular(isUser ? 4 : 12),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        );
      case ChatStyle.classic:
        return BorderRadius.circular(6);
      case ChatStyle.compact:
        return BorderRadius.circular(4);
    }
  }

  Color _bgColor(
    AppThemeData theme, {
    required bool isUser,
    required ChatStyle style,
  }) {
    if (isUser) {
      // Classic and Compact: flat user bg
      if (style == ChatStyle.classic || style == ChatStyle.compact) {
        return theme.surfaceElevated;
      }
      return theme.userMessageBg; // only used if gradient disabled
    }
    return theme.aiMessageBg;
  }

  Color? _borderColor(
    AppThemeData theme, {
    required bool isUser,
    required ChatStyle style,
  }) {
    if (!isUser) return theme.aiMessageBorder;
    if (style == ChatStyle.classic || style == ChatStyle.compact) {
      return theme.border;
    }
    return null;
  }

  Color _textColor(AppThemeData theme, {required bool isUser}) {
    if (isUser) return Colors.white;
    return theme.textPrimary;
  }

  // ==================== SUB-WIDGETS ====================

  Widget _buildAvatar(AppThemeData theme, {required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? theme.surfaceElevated
            : theme.accentSolid.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser ? theme.textSecondary : theme.accentSolid,
      ),
    );
  }

  Widget _buildTypingIndicator(AppThemeData theme) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0, color: theme.accentSolid),
          const SizedBox(width: 4),
          _TypingDot(delay: 200, color: theme.accentSolid),
          const SizedBox(width: 4),
          _TypingDot(delay: 400, color: theme.accentSolid),
        ],
      ),
    );
  }

  Widget _buildMetadata(AppThemeData theme) {
    final time = _formatTime(message.createdAt);
    final showVoiceIcon = message.inputMethod == InputMethod.voice;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVoiceIcon) ...[
          Icon(Icons.mic, size: 12, color: theme.textTertiary),
          const SizedBox(width: 4),
        ],
        Text(
          time,
          style: TextStyle(fontSize: 11, color: theme.textTertiary),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animated typing dot.
class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay, required this.color});

  final int delay;
  final Color color;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 + (_controller.value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
