import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Chat input widget with text field and send button.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onVoiceStart,
    this.isDisabled = false,
    this.placeholder = 'Ask about this document...',
  });

  final void Function(String message) onSend;
  final VoidCallback? onVoiceStart;
  final bool isDisabled;
  final String placeholder;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isDisabled) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.spacingMd,
        right: AppDimensions.spacingSm,
        top: AppDimensions.spacingSm,
        bottom: bottomPadding + AppDimensions.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.zinc900,
        border: Border(
          top: BorderSide(
            color: AppColors.zinc700,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isDisabled,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.zinc600,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.zinc600,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.zinc700,
                      width: 1,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                    vertical: AppDimensions.spacingSm + 2,
                  ),
                  filled: true,
                  fillColor: widget.isDisabled ? AppColors.zinc800 : AppColors.zinc800,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.spacingXs),
          if (widget.onVoiceStart != null && !_hasText)
            _buildIconButton(
              icon: Icons.mic_none_rounded,
              onPressed: widget.isDisabled ? null : widget.onVoiceStart,
              isActive: false,
            )
          else
            _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && !widget.isDisabled;

    return GestureDetector(
      onTap: canSend ? _handleSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: canSend ? AppColors.accent : AppColors.zinc700,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: canSend ? AppColors.textOnPrimary : AppColors.zinc500,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isActive,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 24,
      style: IconButton.styleFrom(
        foregroundColor: isActive ? AppColors.accent : AppColors.textSecondary,
        backgroundColor: isActive
            ? AppColors.accent.withOpacity(0.1)
            : Colors.transparent,
      ),
    );
  }
}
