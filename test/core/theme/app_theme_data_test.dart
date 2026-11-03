import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citecoach/core/theme/app_theme_data.dart';

void main() {
  group('CiteCoach Ink & Signal theme', () {
    test('midnight theme uses the approved brand palette', () {
      final theme = AppThemeData.midnight();

      expect(theme.background, const Color(0xFF1A1117));
      expect(theme.surface, const Color(0xFF271B21));
      expect(theme.accentSolid, const Color(0xFFD9EF57));
      expect(theme.citation, const Color(0xFFD85B43));
      expect(theme.textPrimary, const Color(0xFFF1E9D8));
      expect(theme.isDark, isTrue);
    });

    test('daylight theme keeps warm paper and readable ink', () {
      final theme = AppThemeData.daylight();

      expect(theme.background, const Color(0xFFF1E9D8));
      expect(theme.textPrimary, const Color(0xFF271B21));
      expect(theme.isDark, isFalse);
    });

    test('AMOLED theme keeps a true-black background and brand accents', () {
      final theme = AppThemeData.amoled();

      expect(theme.background, Colors.black);
      expect(theme.accentSolid, const Color(0xFFD9EF57));
      expect(theme.citation, const Color(0xFFD85B43));
      expect(theme.isDark, isTrue);
    });
  });
}
