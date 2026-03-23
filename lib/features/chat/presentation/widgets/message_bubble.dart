import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/chat_message.dart';
import 'citation_badge.dart';

/// A chat message bubble.
class MessageBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final content = streamingContent ?? message.content;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: AppDimensions.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser),
            SizedBox(width: AppDimensions.spacingSm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.userMessageBackground
                        : AppColors.aiMessageBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isUser ? AppDimensions.radiusMd : AppDimensions.radiusSm,
                      ),
                      topRight: Radius.circular(
                        isUser ? AppDimensions.radiusSm : AppDimensions.radiusMd,
                      ),
                      bottomLeft: const Radius.circular(AppDimensions.radiusMd),
                      bottomRight: const Radius.circular(AppDimensions.radiusMd),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.zinc700,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isStreaming && content.isEmpty)
                        _buildTypingIndicator()
                      else
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isUser ? AppColors.accentLight : AppColors.textPrimary,
                          ),
                        ),
                      if (!isUser && message.hasCitations && onCitationTap != null)
                        CitationRow(
                          citations: message.citations,
                          onCitationTap: onCitationTap!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildMetadata(context),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: AppDimensions.spacingSm),
            _buildAvatar(isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppColors.zinc700 : AppColors.accent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser ? AppColors.zinc400 : AppColors.accent,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0),
          SizedBox(width: 4),
          _TypingDot(delay: 200),
          SizedBox(width: 4),
          _TypingDot(delay: 400),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final time = _formatTime(message.createdAt);
    final showVoiceIcon = message.inputMethod == InputMethod.voice;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVoiceIcon) ...[
          const Icon(
            Icons.mic,
            size: 12,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
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
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.3 + (_animation.value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
