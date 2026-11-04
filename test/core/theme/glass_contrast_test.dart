import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/core/theme/app_theme_data.dart';

double contrast(Color a, Color b) {
  final values = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (values.last + .05) / (values.first + .05);
}

void main() {
  for (final theme in [AppThemeData.midnight(), AppThemeData.daylight(), AppThemeData.amoled()]) {
    test('${theme.variant} glass text and warning meet AA', () {
      // Includes the alpha-composited panel used by GlassSurface and solid HC panels.
      final tint = Color.alphaBlend(Colors.white.withValues(alpha: theme.isDark ? .035 : .32), theme.surface);
      final panel = Color.alphaBlend(tint.withValues(alpha: theme.isDark ? .86 : .92), theme.background);
      for (final bg in [theme.background, theme.surface, theme.surfaceElevated, panel]) {
        for (final fg in [theme.textPrimary, theme.textSecondary, theme.warning]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        }
      }
      for (final bg in [theme.background, theme.surface, panel]) {
        expect(contrast(theme.textTertiary, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(theme.accentSolid, bg), greaterThanOrEqualTo(3));
      }
      // Lavender warnings must not drift back into the amber accent hue.
      final distance = (HSLColor.fromColor(theme.warning).hue - HSLColor.fromColor(theme.accentSolid).hue).abs();
      expect(distance, greaterThan(60));
    });
  }
}
