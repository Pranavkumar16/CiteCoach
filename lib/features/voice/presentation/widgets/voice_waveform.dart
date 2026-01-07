import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Animated waveform visualization for voice input.
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({
    super.key,
    required this.isActive,
    this.soundLevel = 0.0,
    this.barCount = 5,
    this.height = 55,
    this.color,
    this.minBarHeight = 8,
    this.maxBarHeight = 40,
    this.barWidth = 4,
    this.barSpacing = 6,
  });

  /// Whether the waveform is active (listening).
  final bool isActive;

  /// Current sound level (0.0 to 1.0).
  final double soundLevel;

  /// Number of bars in the waveform.
  final int barCount;

  /// Height of the waveform container.
  final double height;

  /// Color of the bars.
  final Color? color;

  /// Minimum bar height.
  final double minBarHeight;

  /// Maximum bar height.
  final double maxBarHeight;

  /// Width of each bar.
  final double barWidth;

  /// Spacing between bars.
  final double barSpacing;

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<double> _barHeights = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Initialize bar heights
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(widget.minBarHeight);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _resetBars();
      }
    }
  }

  void _updateBars() {
    if (!widget.isActive) return;

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        // Base height influenced by sound level
        final baseHeight = widget.minBarHeight +
            (widget.soundLevel * (widget.maxBarHeight - widget.minBarHeight) * 0.7);

        // Add some randomness for natural look
        final randomFactor = 0.3 + (_random.nextDouble() * 0.7);

        // Calculate target height
        final targetHeight = baseHeight * randomFactor;

        // Smooth transition
        _barHeights[i] = _barHeights[i] + (targetHeight - _barHeights[i]) * 0.3;
        _barHeights[i] = _barHeights[i].clamp(widget.minBarHeight, widget.maxBarHeight);
      }
    });
  }

  void _resetBars() {
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = widget.minBarHeight;
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
    final color = widget.color ?? Colors.white;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.barSpacing / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              width: widget.barWidth,
              height: _barHeights[index],
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Pulsing circle animation for voice button.
class VoicePulse extends StatefulWidget {
  const VoicePulse({
    super.key,
    required this.isActive,
    this.size = 120,
    this.color,
    this.pulseCount = 3,
  });

  /// Whether the pulse is active.
  final bool isActive;

  /// Size of the pulse.
  final double size;

  /// Color of the pulse.
  final Color? color;

  /// Number of pulse rings.
  final int pulseCount;

  @override
  State<VoicePulse> createState() => _VoicePulseState();
}

class _VoicePulseState extends State<VoicePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoicePulse oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primaryIndigo;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(widget.pulseCount, (index) {
              final delay = index / widget.pulseCount;
              final value = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (value * 0.5);
              final opacity = (1.0 - value) * 0.5;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(widget.isActive ? opacity : 0),
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Animated microphone button.
class VoiceMicButton extends StatelessWidget {
  const VoiceMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.size = 80,
  });

  /// Whether currently listening.
  final bool isListening;

  /// Callback when button is pressed.
  final VoidCallback onPressed;

  /// Size of the button.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse animation
        VoicePulse(
          isActive: isListening,
          size: size * 1.5,
          color: Colors.white,
        ),
        // Main button
        GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isListening ? AppColors.micActive : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: size * 0.4,
              color: isListening ? Colors.white : AppColors.primaryIndigo,
            ),
          ),
        ),
      ],
    );
  }
}
