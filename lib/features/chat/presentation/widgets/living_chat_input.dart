import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// The input's current interaction mode.
enum InputMode {
  /// No text yet — shows suggested questions.
  idle,

  /// User is typing — shows text field.
  typing,

  /// Voice recording active — shows waveform.
  voice,
}

/// **Living Input** — a chat input that morphs between three modes:
///
/// - IDLE: shows 2-3 suggested questions as tappable chips.
/// - TYPING: shows the text field with a send button.
/// - VOICE: shows a breathing waveform while recording.
///
/// Transitions between modes are animated via [AnimatedSwitcher].
class LivingChatInput extends StatefulWidget {
  const LivingChatInput({
    super.key,
    required this.onSend,
    this.onVoiceStart,
    this.suggestions = const [],
    this.isDisabled = false,
    this.isRecording = false,
    this.placeholder = 'Ask about this document...',
  });

  /// Called when the user sends a message.
  final void Function(String message) onSend;

  /// Called when the user taps the mic icon.
  final VoidCallback? onVoiceStart;

  /// Suggested questions shown in IDLE mode.
  final List<String> suggestions;

  /// Disables all input (e.g. while the model is generating).
  final bool isDisabled;

  /// Whether voice recording is active (forces VOICE mode).
  final bool isRecording;

  /// Placeholder text for the text field.
  final String placeholder;

  @override
  State<LivingChatInput> createState() => _LivingChatInputState();
}

class _LivingChatInputState extends State<LivingChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  InputMode get _currentMode {
    if (widget.isRecording) return InputMode.voice;
    if (_hasText || _focusNode.hasFocus) return InputMode.typing;
    return InputMode.idle;
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isDisabled) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleSuggestionTap(String suggestion) {
    if (widget.isDisabled) return;
    widget.onSend(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final mode = _currentMode;

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
          top: BorderSide(color: AppColors.zinc700, width: 0.5),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: _buildForMode(mode),
      ),
    );
  }

  Widget _buildForMode(InputMode mode) {
    switch (mode) {
      case InputMode.idle:
        return KeyedSubtree(
          key: const ValueKey('idle'),
          child: _buildIdleMode(),
        );
      case InputMode.typing:
        return KeyedSubtree(
          key: const ValueKey('typing'),
          child: _buildTypingMode(),
        );
      case InputMode.voice:
        return KeyedSubtree(
          key: const ValueKey('voice'),
          child: _buildVoiceMode(),
        );
    }
  }

  // ==================== IDLE MODE ====================

  Widget _buildIdleMode() {
    final suggestions = widget.suggestions.isNotEmpty
        ? widget.suggestions
        : const [
            'What is this document about?',
            'Summarize the key points.',
            'List the main arguments.',
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.spacingXs,
            bottom: AppDimensions.spacingXs,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 12,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'SUGGESTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        ...suggestions.take(3).map(_buildSuggestionChip),
        SizedBox(height: AppDimensions.spacingSm),
        _buildCollapsedTextRow(),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.spacingXs),
      child: InkWell(
        onTap: () => _handleSuggestionTap(suggestion),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.zinc800,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.accent.withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTextRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Container(
              height: 44,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
              ),
              decoration: BoxDecoration(
                color: AppColors.zinc800,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.zinc600, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.placeholder,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingXs),
        if (widget.onVoiceStart != null)
          _buildMicButton()
        else
          const SizedBox.shrink(),
      ],
    );
  }

  // ==================== TYPING MODE ====================

  Widget _buildTypingMode() {
    return Row(
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
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
                border: _inputBorder(AppColors.zinc600),
                enabledBorder: _inputBorder(AppColors.zinc600),
                focusedBorder: _inputBorder(AppColors.accent, width: 1.5),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm + 2,
                ),
                filled: true,
                fillColor: AppColors.zinc800,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingXs),
        _hasText ? _buildSendButton() : _buildMicButton(),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ==================== VOICE MODE ====================

  Widget _buildVoiceMode() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic,
              color: AppColors.errorRed,
              size: 22,
            ),
          ),
          SizedBox(width: AppDimensions.spacingMd),
          const Expanded(child: _VoiceWaveform()),
          SizedBox(width: AppDimensions.spacingXs),
          Text(
            'Listening...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUTTONS ====================

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

  Widget _buildMicButton() {
    return IconButton(
      onPressed: widget.isDisabled ? null : widget.onVoiceStart,
      icon: const Icon(Icons.mic_none_rounded),
      iconSize: 24,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
      ),
    );
  }
}

/// A breathing waveform animation for voice mode.
class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform();

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
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
        return CustomPaint(
          painter: _WaveformPainter(phase: _controller.value),
          size: const Size(double.infinity, 40),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 24;
    final barWidth = size.width / (barCount * 2 - 1);
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final t = (phase + i / barCount) * 2 * math.pi;
      final amp = 0.35 + 0.65 * ((math.sin(t) + 1) / 2);
      final h = size.height * amp;
      final x = i * (barWidth * 2);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
