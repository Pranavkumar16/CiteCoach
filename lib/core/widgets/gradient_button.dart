import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Primary accent button used throughout the app.
/// Solid accent color with subtle glow on dark backgrounds.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = AppDimensions.buttonHeightLg,
    this.gradient = AppColors.primaryGradient,
    this.textStyle,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final LinearGradient gradient;
  final TextStyle? textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;
    final opacity = isEnabled ? 1.0 : 0.4;

    return AnimatedOpacity(
      duration: AppDimensions.animationFast,
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppColors.textOnPrimary, size: 20),
                          const SizedBox(width: AppDimensions.spacingXs),
                        ],
                        Text(
                          text,
                          style: textStyle ??
                              const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outline button with subtle border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = AppDimensions.buttonHeightLg,
    this.textStyle,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;
    final opacity = isEnabled ? 1.0 : 0.4;

    return AnimatedOpacity(
      duration: AppDimensions.animationFast,
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.zinc800,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.zinc600,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            splashColor: AppColors.accent.withOpacity(0.1),
            highlightColor: AppColors.accent.withOpacity(0.05),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textSecondary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.spacingXs),
                        ],
                        Text(
                          text,
                          style: textStyle ??
                              const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed border button for "Add" actions.
class DashedButton extends StatelessWidget {
  const DashedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isEnabled = true,
    this.isLoading = false,
    this.width,
    this.height = AppDimensions.buttonHeightLg,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isEnabled;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = isEnabled && !isLoading;
    final opacity = effectiveEnabled ? 1.0 : 0.4;

    return AnimatedOpacity(
      duration: AppDimensions.animationFast,
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: AppColors.zinc800,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            onTap: effectiveEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            splashColor: AppColors.accent.withOpacity(0.1),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.zinc600,
                strokeWidth: 1.5,
                dashWidth: 8,
                dashSpace: 4,
                radius: AppDimensions.radiusMd,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textSecondary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.spacingXs),
                          ],
                          Text(
                            text,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}

/// Small action button used in document cards.
class SmallActionButton extends StatelessWidget {
  const SmallActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = false,
    this.isEnabled = true,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isPrimary;
  final bool isEnabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: AppColors.textOnPrimary, size: 16),
                      const SizedBox(width: AppDimensions.spacingXs),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.zinc800,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.zinc600),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: AppDimensions.spacingXs),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
