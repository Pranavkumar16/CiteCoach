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

/// Large in-page title used by glass screens instead of an opaque AppBar.
/// Keeps the ambient backdrop visible right up to the status bar.
class GlassPageHeader extends StatelessWidget {
  const GlassPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    color: theme.accentSolid,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: text.headlineMedium?.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: text.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Rounded icon chip. [filled] uses the brand gradient for primary actions.
class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({
    super.key,
    required this.icon,
    this.filled = false,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final bool filled;
  final double size;

  /// Tint for an unfilled badge; defaults to the solid accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final tint = color ?? theme.accentSolid;
    final onFilled = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: filled ? theme.accentGradient : null,
        color: filled ? null : tint.withOpacity(theme.isDark ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: filled
            ? null
            : Border.all(color: tint.withOpacity(theme.isDark ? 0.28 : 0.24)),
      ),
      child: Icon(icon, size: size * 0.5, color: filled ? onFilled : tint),
    );
  }
}

/// Small uppercase label above a group of glass panels.
class GlassSectionLabel extends StatelessWidget {
  const GlassSectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
