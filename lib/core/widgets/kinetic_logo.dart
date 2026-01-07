import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// The CiteCoach Kinetic Logo - a speech bubble with "C" cutout and eye accent.
/// 
/// This logo represents:
/// - The "Eye": AI constantly watching and verifying sources
/// - The Bubble: Communication and assistance
/// - Asymmetry: Forward motion and tech-agility
class KineticLogo extends StatelessWidget {
  const KineticLogo({
    super.key,
    this.size = 120,
    this.variant = KineticLogoVariant.gradient,
    this.showSpeedLines = false,
    this.showEye = true,
  });

  /// The size of the logo (width and height are equal).
  final double size;

  /// The color variant of the logo.
  final KineticLogoVariant variant;

  /// Whether to show the speed lines accent.
  final bool showSpeedLines;

  /// Whether to show the eye accent.
  final bool showEye;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _KineticLogoPainter(
          variant: variant,
          showSpeedLines: showSpeedLines,
          showEye: showEye,
        ),
      ),
    );
  }
}

/// Logo color variants for different contexts.
enum KineticLogoVariant {
  /// Primary gradient (indigo to purple).
  gradient,

  /// White fill for dark backgrounds.
  white,

  /// Indigo monochrome.
  indigo,

  /// Inverted - white bubble with indigo C.
  inverted,
}

class _KineticLogoPainter extends CustomPainter {
  _KineticLogoPainter({
    required this.variant,
    required this.showSpeedLines,
    required this.showEye,
  });

  final KineticLogoVariant variant;
  final bool showSpeedLines;
  final bool showEye;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 120;

    // Get colors based on variant
    final (bubbleShader, cStrokeColor, eyeFillColor, eyePupilColor) =
        _getColors(size);

    // Draw the background bubble
    _drawBubble(canvas, scale, bubbleShader);

    // Draw the "C" cutout
    _drawCShape(canvas, scale, cStrokeColor);

    // Draw the eye accent
    if (showEye) {
      _drawEye(canvas, scale, eyeFillColor, eyePupilColor);
    }

    // Draw speed lines
    if (showSpeedLines) {
      _drawSpeedLines(canvas, scale, cStrokeColor);
    }
  }

  (Shader?, Color, Color, Color) _getColors(Size size) {
    switch (variant) {
      case KineticLogoVariant.gradient:
        const gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryIndigo, AppColors.primaryPurple],
        );
        return (
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
          Colors.white,
          Colors.white,
          AppColors.primaryIndigo,
        );

      case KineticLogoVariant.white:
        return (
          null,
          AppColors.primaryIndigo,
          AppColors.primaryIndigo,
          Colors.white,
        );

      case KineticLogoVariant.indigo:
        return (
          null,
          Colors.white,
          Colors.white,
          AppColors.primaryIndigo,
        );

      case KineticLogoVariant.inverted:
        return (
          null,
          AppColors.primaryIndigo,
          AppColors.primaryIndigo,
          Colors.white,
        );
    }
  }

  void _drawBubble(Canvas canvas, double scale, Shader? shader) {
    final path = Path();

    // The asymmetric bubble shape (speech bubble with rounded corners)
    // Starting from top-left, going clockwise
    // Path: M20 40C20 23.4315 33.4315 10 50 10H90C95.5228 10 100 14.4772 100 20V80C100 96.5685 86.5685 110 70 110H30C24.4772 110 20 105.523 20 100V40Z

    path.moveTo(20 * scale, 40 * scale);

    // Top-left curve (large radius)
    path.cubicTo(
      20 * scale,
      23.4315 * scale,
      33.4315 * scale,
      10 * scale,
      50 * scale,
      10 * scale,
    );

    // Top edge
    path.lineTo(90 * scale, 10 * scale);

    // Top-right curve (small radius)
    path.cubicTo(
      95.5228 * scale,
      10 * scale,
      100 * scale,
      14.4772 * scale,
      100 * scale,
      20 * scale,
    );

    // Right edge
    path.lineTo(100 * scale, 80 * scale);

    // Bottom-right curve (large radius)
    path.cubicTo(
      100 * scale,
      96.5685 * scale,
      86.5685 * scale,
      110 * scale,
      70 * scale,
      110 * scale,
    );

    // Bottom edge
    path.lineTo(30 * scale, 110 * scale);

    // Bottom-left curve (small radius)
    path.cubicTo(
      24.4772 * scale,
      110 * scale,
      20 * scale,
      105.523 * scale,
      20 * scale,
      100 * scale,
    );

    // Left edge back to start
    path.lineTo(20 * scale, 40 * scale);

    path.close();

    final paint = Paint()..style = PaintingStyle.fill;

    if (shader != null) {
      paint.shader = shader;
    } else {
      paint.color = variant == KineticLogoVariant.white
          ? Colors.white
          : AppColors.primaryIndigo;
    }

    canvas.drawPath(path, paint);
  }

  void _drawCShape(Canvas canvas, double scale, Color strokeColor) {
    // The "C" shape path:
    // M75 45C75 35 65 30 50 30C35 30 25 40 25 55C25 70 35 80 50 80C65 80 75 75 75 65

    final path = Path();

    path.moveTo(75 * scale, 45 * scale);

    // First curve (top of C)
    path.cubicTo(
      75 * scale,
      35 * scale,
      65 * scale,
      30 * scale,
      50 * scale,
      30 * scale,
    );

    // Second curve (left side going down)
    path.cubicTo(
      35 * scale,
      30 * scale,
      25 * scale,
      40 * scale,
      25 * scale,
      55 * scale,
    );

    // Third curve (bottom left going right)
    path.cubicTo(
      25 * scale,
      70 * scale,
      35 * scale,
      80 * scale,
      50 * scale,
      80 * scale,
    );

    // Fourth curve (bottom of C)
    path.cubicTo(
      65 * scale,
      80 * scale,
      75 * scale,
      75 * scale,
      75 * scale,
      65 * scale,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.round
      ..color = strokeColor;

    canvas.drawPath(path, paint);
  }

  void _drawEye(Canvas canvas, double scale, Color fillColor, Color pupilColor) {
    final center = Offset(75 * scale, 45 * scale);

    // Outer eye circle (white or indigo)
    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawCircle(center, 8 * scale, outerPaint);

    // Inner pupil (indigo or white)
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pupilColor;
    canvas.drawCircle(center, 4 * scale, innerPaint);
  }

  void _drawSpeedLines(Canvas canvas, double scale, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.6);

    // First speed line
    canvas.drawLine(
      Offset(85 * scale, 90 * scale),
      Offset(95 * scale, 90 * scale),
      paint,
    );

    // Second speed line (shorter, more transparent)
    paint.color = color.withOpacity(0.4);
    canvas.drawLine(
      Offset(88 * scale, 98 * scale),
      Offset(93 * scale, 98 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _KineticLogoPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.showSpeedLines != showSpeedLines ||
        oldDelegate.showEye != showEye;
  }
}

/// Animated version of the Kinetic Logo with subtle pulsing effect.
class KineticLogoAnimated extends StatefulWidget {
  const KineticLogoAnimated({
    super.key,
    this.size = 120,
    this.variant = KineticLogoVariant.gradient,
  });

  final double size;
  final KineticLogoVariant variant;

  @override
  State<KineticLogoAnimated> createState() => _KineticLogoAnimatedState();
}

class _KineticLogoAnimatedState extends State<KineticLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: KineticLogo(
            size: widget.size,
            variant: widget.variant,
            showSpeedLines: false,
            showEye: true,
          ),
        );
      },
    );
  }
}
