import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_data.dart';

/// Static ambient colour behind the glass. No continuously animated shaders.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    return ColoredBox(
      color: theme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(top: -120, right: -150, child: _glow(theme.accentStart)),
          Positioned(bottom: -180, left: -170, child: _glow(theme.accentEnd)),
          child,
        ],
      ),
    );
  }

  Widget _glow(Color colour) => IgnorePointer(
    child: RepaintBoundary(
      child: Container(
        width: 430,
        height: 430,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [colour.withOpacity(0.12), colour.withOpacity(0)],
          ),
        ),
      ),
    ),
  );
}

/// Blur only bounded, stationary panels; scrolling cards use tint alone.
/// High contrast mode replaces transparency with a solid readable surface.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = true,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double radius;
  final bool blur;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final solid = MediaQuery.highContrastOf(context);
    final tint = Color.alphaBlend(
      Colors.white.withOpacity(theme.isDark ? 0.035 : 0.32),
      theme.surface,
    );
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withOpacity(solid ? 1 : (theme.isDark ? 0.86 : 0.92)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: solid
              ? theme.borderStrong
              : Color.alphaBlend(
                  Colors.white.withOpacity(theme.isDark ? 0.12 : 0.55),
                  theme.border,
                ),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur && !solid
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: panel,
            )
          : panel,
    );
  }
}
