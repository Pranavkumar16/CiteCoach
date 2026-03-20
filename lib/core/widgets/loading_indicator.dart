import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Circular loading indicator with CiteCoach brand colors.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
    this.useGradient = false,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    if (useGradient) {
      return _GradientLoadingIndicator(
        size: size,
        strokeWidth: strokeWidth,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.accent,
        ),
      ),
    );
  }
}

class _GradientLoadingIndicator extends StatefulWidget {
  const _GradientLoadingIndicator({
    required this.size,
    required this.strokeWidth,
  });

  final double size;
  final double strokeWidth;

  @override
  State<_GradientLoadingIndicator> createState() =>
      _GradientLoadingIndicatorState();
}

class _GradientLoadingIndicatorState extends State<_GradientLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GradientCirclePainter(
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _GradientCirclePainter extends CustomPainter {
  _GradientCirclePainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = SweepGradient(
      colors: [
        AppColors.accent.withOpacity(0),
        AppColors.accent,
        AppColors.accentLight,
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      5.5, // ~315 degrees
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-screen loading overlay.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
    this.child,
  });

  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: AppDimensions.paddingAllXl,
          decoration: BoxDecoration(
            color: AppColors.zinc800,
            borderRadius: AppDimensions.borderRadiusXl,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child ??
                  const LoadingIndicator(
                    size: 48,
                    strokeWidth: 4,
                    useGradient: true,
                  ),
              if (message != null) ...[
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress bar with accent fill.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = AppDimensions.progressBarHeight,
    this.backgroundColor,
    this.showLabel = false,
  });

  final double progress;
  final double height;
  final Color? backgroundColor;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.zinc700,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: AppDimensions.animationNormal,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '${(progress * 100).toInt()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Processing step indicator with checkmark, spinner, or pending state.
class ProcessingStep extends StatelessWidget {
  const ProcessingStep({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final ProcessingStepStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: _buildStatusIcon(),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    status == ProcessingStepStatus.inProgress
                        ? FontWeight.w700
                        : FontWeight.w600,
                color: _getTextColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case ProcessingStepStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 22,
        );
      case ProcessingStepStatus.inProgress:
        return const LoadingIndicator(
          size: 22,
          strokeWidth: 2.5,
          color: AppColors.accent,
        );
      case ProcessingStepStatus.pending:
        return Icon(
          Icons.circle_outlined,
          color: AppColors.zinc600,
          size: 22,
        );
    }
  }

  Color _getTextColor() {
    switch (status) {
      case ProcessingStepStatus.completed:
        return AppColors.textPrimary;
      case ProcessingStepStatus.inProgress:
        return AppColors.accent;
      case ProcessingStepStatus.pending:
        return AppColors.textTertiary;
    }
  }
}

enum ProcessingStepStatus {
  pending,
  inProgress,
  completed,
}

/// Skeleton loading placeholder for content.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusSm,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const <Color>[
                AppColors.zinc800,
                AppColors.zinc700,
                AppColors.zinc800,
              ],
            ),
          ),
        );
      },
    );
  }
}
