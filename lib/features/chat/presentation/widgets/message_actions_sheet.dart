import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme_data.dart';
import '../../domain/chat_message.dart';

/// Long-press action sheet for chat messages.
///
/// Offers: Copy, Copy with citations, Share, Regenerate (user message only).
class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    super.key,
    required this.message,
    this.onRegenerate,
  });

  final ChatMessage message;
  final VoidCallback? onRegenerate;

  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    VoidCallback? onRegenerate,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => MessageActionsSheet(
        message: message,
        onRegenerate: onRegenerate,
      ),
    );
  }

  String _formatForCopy({required bool withCitations}) {
    if (!withCitations || !message.hasCitations) return message.content;
    final pages = message.citations
        .map((c) => c.pageNumber)
        .toSet()
        .toList()
      ..sort();
    return '${message.content}\n\nSources: ${pages.map((p) => 'Page $p').join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final isAi = message.isAssistant;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _ActionTile(
            icon: Icons.copy_rounded,
            title: 'Copy text',
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: _formatForCopy(withCitations: false)),
              );
              if (context.mounted) {
                Navigator.pop(context);
                _showSnack(context, 'Copied');
              }
            },
          ),
          if (isAi && message.hasCitations)
            _ActionTile(
              icon: Icons.format_quote_rounded,
              title: 'Copy with citations',
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: _formatForCopy(withCitations: true)),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack(context, 'Copied with sources');
                }
              },
            ),
          _ActionTile(
            icon: Icons.share_rounded,
            title: 'Share',
            onTap: () {
              Navigator.pop(context);
              Share.share(_formatForCopy(withCitations: isAi));
            },
          ),
          if (!isAi && onRegenerate != null)
            _ActionTile(
              icon: Icons.refresh_rounded,
              title: 'Regenerate answer',
              onTap: () {
                Navigator.pop(context);
                onRegenerate!();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
