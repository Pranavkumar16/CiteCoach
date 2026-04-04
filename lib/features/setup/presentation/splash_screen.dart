import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../providers/setup_provider.dart';

/// Splash screen shown on app launch.
///
/// Design: App icon with a pulsing gradient ring, wordmark below,
/// three loading dots, and a tagline at the bottom.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _advanceToPrivacy();
    });
  }

  void _advanceToPrivacy() {
    ref.read(setupProvider.notifier).completeSplash();
    context.go('/setup/privacy');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              const Spacer(flex: 3),
              _buildIconWithRing(theme),
              const SizedBox(height: 24),
              Text(
                'CiteCoach',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chat with any document',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: theme.textTertiary,
                ),
              ),
              const Spacer(flex: 4),
              _buildLoadingDots(theme),
              const SizedBox(height: 16),
              Text(
                '100% offline intelligence',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// App icon (88×88) with animated gradient ring pulsing outward.
  Widget _buildIconWithRing(AppThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Two staggered pulsing rings
              for (int i = 0; i < 2; i++)
                _buildPulseRing(theme, phase: i * 0.5),
              // The icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: theme.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentStart.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // The "C" letterform
                    Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    // Citation dot (amber)
                    Positioned(
                      top: 14,
                      right: 16,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Single pulsing gradient ring around the icon.
  Widget _buildPulseRing(AppThemeData theme, {required double phase}) {
    final t = ((_pulseController.value + phase) % 1.0);
    final scale = 1.0 + 0.5 * t;
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity * 0.4,
        child: CustomPaint(
          size: const Size(88, 88),
          painter: _GradientRingPainter(
            gradient: theme.accentGradient,
            radius: 20,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// Three pulsing dots with gradient color.
  Widget _buildLoadingDots(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final t = ((_pulseController.value * 3 + i * 0.33) % 1.0);
              final s = 0.5 + 0.5 * (1 - ((t - 0.5).abs() * 2));
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: theme.accentGradient,
                ),
                transform: Matrix4.identity()..scale(s),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Custom painter that draws a rounded rect outline with a gradient stroke.
class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({
    required this.gradient,
    required this.radius,
    required this.strokeWidth,
  });

  final Gradient gradient;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
