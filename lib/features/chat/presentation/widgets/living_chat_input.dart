import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/widgets/glass_surface.dart';

/// A persistent composer: focus and draft survive every interaction state.
class LivingChatInput extends StatefulWidget {
  const LivingChatInput({
    super.key,
    required this.onSend,
    this.onVoiceStart,
    this.initialDraft,
    this.suggestions = const [],
    this.isDisabled = false,
    this.isRecording = false,
    this.placeholder = 'Ask about this document…',
  });
  final String? initialDraft;
  final ValueChanged<String> onSend;
  final VoidCallback? onVoiceStart;
  final List<String> suggestions;
  final bool isDisabled;
  final bool isRecording;
  final String placeholder;

  @override
  State<LivingChatInput> createState() => _LivingChatInputState();
}

class _LivingChatInputState extends State<LivingChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialDraft ?? '';
    _controller.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isDisabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final hasText = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GlassSurface(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Empty means empty: do not resurrect default suggestions after send.
            if (widget.suggestions.isNotEmpty &&
                !widget.isDisabled &&
                !hasText) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.suggestions
                      .take(3)
                      .map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              question,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            avatar: Icon(
                              Icons.north_east_rounded,
                              size: 16,
                              color: theme.accentSolid,
                            ),
                            backgroundColor: theme.chipBg,
                            side: BorderSide(color: theme.chipBorder),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            onPressed: () => widget.onSend(question),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (widget.isRecording)
              const SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Icon(Icons.mic_rounded),
                    SizedBox(width: 12),
                    Expanded(child: _VoiceWaveform()),
                    SizedBox(width: 12),
                    Text('Listening…'),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat-composer'),
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: true,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isDisabled
                            ? 'Type your next question…'
                            : widget.placeholder,
                        hintStyle: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (hasText)
                    IconButton.filled(
                      tooltip: 'Send question',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: widget.isDisabled ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.accentSolid,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    )
                  else if (widget.onVoiceStart != null)
                    IconButton(
                      tooltip: 'Ask with your voice',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: widget.isDisabled ? null : widget.onVoiceStart,
                      color: theme.textSecondary,
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                ],
              ),
          ],
        ),
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
