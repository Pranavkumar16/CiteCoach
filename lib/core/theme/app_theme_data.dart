import 'package:flutter/material.dart';

import 'theme_variant.dart';

/// CiteCoach's custom theme extension.
///
/// Contains every semantically-meaningful color the app uses.
/// Widgets access these via `Theme.of(context).extension<AppThemeData>()!`
/// so they adapt automatically to Midnight / Daylight / AMOLED / System.
@immutable
class AppThemeData extends ThemeExtension<AppThemeData> {
  const AppThemeData({
    required this.variant,
    required this.isDark,
    // Surfaces
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    // Borders / dividers
    required this.border,
    required this.borderStrong,
    // Brand / accent
    required this.accentStart,
    required this.accentEnd,
    required this.accentSolid,
    // Semantic
    required this.citation,
    required this.success,
    required this.warning,
    required this.error,
    // Message bubbles
    required this.userMessageBg,
    required this.aiMessageBg,
    required this.aiMessageBorder,
    // Chips / pills
    required this.chipBg,
    required this.chipBorder,
    // Overlays / shadows
    required this.overlay,
    required this.shadow,
  });

  /// The variant that produced this theme.
  final ThemeVariant variant;

  /// True for dark variants (Midnight/AMOLED).
  final bool isDark;

  // ==================== SURFACES ====================
  final Color background;
  final Color surface;
  final Color surfaceElevated;

  // ==================== TEXT ====================
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ==================== BORDERS ====================
  final Color border;
  final Color borderStrong;

  // ==================== BRAND GRADIENT ====================
  /// Start color of the primary brand gradient (indigo).
  final Color accentStart;

  /// End color of the primary brand gradient (purple).
  final Color accentEnd;

  /// Solid version of the brand color for single-color use-cases.
  final Color accentSolid;

  // ==================== SEMANTIC ====================
  /// Citation amber (darker on light themes for contrast).
  final Color citation;
  final Color success;
  final Color warning;
  final Color error;

  // ==================== MESSAGE BUBBLES ====================
  /// User message background (typically the brand gradient-start color).
  final Color userMessageBg;

  /// AI message background.
  final Color aiMessageBg;

  /// AI message border (visible on light themes).
  final Color aiMessageBorder;

  // ==================== CHIPS ====================
  final Color chipBg;
  final Color chipBorder;

  // ==================== OVERLAYS ====================
  final Color overlay;
  final Color shadow;

  /// The primary brand gradient.
  LinearGradient get accentGradient => LinearGradient(
        colors: [accentStart, accentEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  AppThemeData copyWith({
    ThemeVariant? variant,
    bool? isDark,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderStrong,
    Color? accentStart,
    Color? accentEnd,
    Color? accentSolid,
    Color? citation,
    Color? success,
    Color? warning,
    Color? error,
    Color? userMessageBg,
    Color? aiMessageBg,
    Color? aiMessageBorder,
    Color? chipBg,
    Color? chipBorder,
    Color? overlay,
    Color? shadow,
  }) {
    return AppThemeData(
      variant: variant ?? this.variant,
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      accentStart: accentStart ?? this.accentStart,
      accentEnd: accentEnd ?? this.accentEnd,
      accentSolid: accentSolid ?? this.accentSolid,
      citation: citation ?? this.citation,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      userMessageBg: userMessageBg ?? this.userMessageBg,
      aiMessageBg: aiMessageBg ?? this.aiMessageBg,
      aiMessageBorder: aiMessageBorder ?? this.aiMessageBorder,
      chipBg: chipBg ?? this.chipBg,
      chipBorder: chipBorder ?? this.chipBorder,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeData lerp(ThemeExtension<AppThemeData>? other, double t) {
    if (other is! AppThemeData) return this;
    return AppThemeData(
      variant: t < 0.5 ? variant : other.variant,
      isDark: t < 0.5 ? isDark : other.isDark,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      accentStart: Color.lerp(accentStart, other.accentStart, t)!,
      accentEnd: Color.lerp(accentEnd, other.accentEnd, t)!,
      accentSolid: Color.lerp(accentSolid, other.accentSolid, t)!,
      citation: Color.lerp(citation, other.citation, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      userMessageBg: Color.lerp(userMessageBg, other.userMessageBg, t)!,
      aiMessageBg: Color.lerp(aiMessageBg, other.aiMessageBg, t)!,
      aiMessageBorder: Color.lerp(aiMessageBorder, other.aiMessageBorder, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Premium dark theme using the CiteCoach Ink & Signal palette.
  factory AppThemeData.midnight() {
    return const AppThemeData(
      variant: ThemeVariant.midnight,
      isDark: true,
      background: Color(0xFF1A1117),
      surface: Color(0xFF271B21),
      surfaceElevated: Color(0xFF35262E),
      textPrimary: Color(0xFFF1E9D8),
      textSecondary: Color(0xFFCDBFAF),
      textTertiary: Color(0xFFB7A99A),
      border: Color(0xFF493840),
      borderStrong: Color(0xFF66545A),
      accentStart: Color(0xFFD9EF57),
      accentEnd: Color(0xFFD85B43),
      accentSolid: Color(0xFFD9EF57),
      citation: Color(0xFFD85B43),
      success: Color(0xFFB4CF45),
      warning: Color(0xFFD9A441),
      error: Color(0xFFD85B43),
      userMessageBg: Color(0xFF493840),
      aiMessageBg: Color(0xFF271B21),
      aiMessageBorder: Color(0xFF493840),
      chipBg: Color(0xFF35262E),
      chipBorder: Color(0xFF493840),
      overlay: Color(0xCC1A1117),
      shadow: Color(0x80000000),
    );
  }

  /// Warm daylight theme with ink typography and an accessible olive accent.
  factory AppThemeData.daylight() {
    return const AppThemeData(
      variant: ThemeVariant.daylight,
      isDark: false,
      background: Color(0xFFF1E9D8),
      surface: Color(0xFFFBF8F1),
      surfaceElevated: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF271B21),
      textSecondary: Color(0xFF66545A),
      textTertiary: Color(0xFF928477),
      border: Color(0xFFE5DACC),
      borderStrong: Color(0xFFB7A99A),
      accentStart: Color(0xFF71851F),
      accentEnd: Color(0xFFB94D38),
      accentSolid: Color(0xFF71851F),
      citation: Color(0xFFB94D38),
      success: Color(0xFF667A19),
      warning: Color(0xFF986A20),
      error: Color(0xFFB74733),
      userMessageBg: Color(0xFF493840),
      aiMessageBg: Color(0xFFFFFFFF),
      aiMessageBorder: Color(0xFFE5DACC),
      chipBg: Color(0xFFF1E9D8),
      chipBorder: Color(0xFFE5DACC),
      overlay: Color(0xCCF1E9D8),
      shadow: Color(0x1A271B21),
    );
  }

  /// True-black AMOLED theme retaining the CiteCoach brand accents.
  factory AppThemeData.amoled() {
    return const AppThemeData(
      variant: ThemeVariant.amoled,
      isDark: true,
      background: Color(0xFF000000),
      surface: Color(0xFF1A1117),
      surfaceElevated: Color(0xFF271B21),
      textPrimary: Color(0xFFF1E9D8),
      textSecondary: Color(0xFFCDBFAF),
      textTertiary: Color(0xFF928477),
      border: Color(0xFF35262E),
      borderStrong: Color(0xFF493840),
      accentStart: Color(0xFFD9EF57),
      accentEnd: Color(0xFFD85B43),
      accentSolid: Color(0xFFD9EF57),
      citation: Color(0xFFD85B43),
      success: Color(0xFFB4CF45),
      warning: Color(0xFFD9A441),
      error: Color(0xFFD85B43),
      userMessageBg: Color(0xFF35262E),
      aiMessageBg: Color(0xFF1A1117),
      aiMessageBorder: Color(0xFF35262E),
      chipBg: Color(0xFF271B21),
      chipBorder: Color(0xFF35262E),
      overlay: Color(0xCC000000),
      shadow: Color(0xCC000000),
    );
  }

  /// Build from variant, resolving [system] via platform brightness.
  factory AppThemeData.fromVariant(
    ThemeVariant variant, {
    Brightness platformBrightness = Brightness.dark,
  }) {
    final resolved = variant.resolve(platformBrightness);
    switch (resolved) {
      case ThemeVariant.midnight:
        return AppThemeData.midnight();
      case ThemeVariant.daylight:
        return AppThemeData.daylight();
      case ThemeVariant.amoled:
        return AppThemeData.amoled();
      case ThemeVariant.system:
        return AppThemeData.midnight(); // unreachable — resolve() expands it
    }
  }
}
