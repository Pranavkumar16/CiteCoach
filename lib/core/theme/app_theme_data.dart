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

  /// Premium dark theme — the default CiteCoach look.
  factory AppThemeData.midnight() {
    return const AppThemeData(
      variant: ThemeVariant.midnight,
      isDark: true,
      background: Color(0xFF0A0A0F),
      surface: Color(0xFF12121A),
      surfaceElevated: Color(0xFF1A1A2E),
      textPrimary: Color(0xFFF1F0F5),
      textSecondary: Color(0xFF8B8A95),
      textTertiary: Color(0xFF6A6A75),
      border: Color(0xFF252540),
      borderStrong: Color(0xFF3A3A55),
      accentStart: Color(0xFF6366F1), // Indigo-500
      accentEnd: Color(0xFFA855F7), // Purple-500
      accentSolid: Color(0xFF6366F1),
      citation: Color(0xFFF59E0B), // Amber-500
      success: Color(0xFF10B981),
      warning: Color(0xFFF59E0B),
      error: Color(0xFFEF4444),
      userMessageBg: Color(0xFF6366F1),
      aiMessageBg: Color(0xFF1A1A2E),
      aiMessageBorder: Color(0xFF252540),
      chipBg: Color(0xFF1A1A2E),
      chipBorder: Color(0xFF252540),
      overlay: Color(0xCC0A0A0F),
      shadow: Color(0x80000000),
    );
  }

  /// Clean light theme with warm off-white surfaces.
  factory AppThemeData.daylight() {
    return const AppThemeData(
      variant: ThemeVariant.daylight,
      isDark: false,
      background: Color(0xFFF8F7FC),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF0EEF6),
      textPrimary: Color(0xFF1A1A2E),
      textSecondary: Color(0xFF6B6A7A),
      textTertiary: Color(0xFF9A9AA5),
      border: Color(0xFFE2E0EE),
      borderStrong: Color(0xFFCBC8DC),
      accentStart: Color(0xFF6366F1),
      accentEnd: Color(0xFFA855F7),
      accentSolid: Color(0xFF6366F1),
      citation: Color(0xFFD97706), // Darker amber for light bg contrast
      success: Color(0xFF059669),
      warning: Color(0xFFD97706),
      error: Color(0xFFDC2626),
      userMessageBg: Color(0xFF6366F1),
      aiMessageBg: Color(0xFFFFFFFF),
      aiMessageBorder: Color(0xFFE2E0EE),
      chipBg: Color(0xFFF0EEF6),
      chipBorder: Color(0xFFE2E0EE),
      overlay: Color(0xCCF8F7FC),
      shadow: Color(0x1A000000),
    );
  }

  /// True-black AMOLED theme for OLED battery saving.
  factory AppThemeData.amoled() {
    return const AppThemeData(
      variant: ThemeVariant.amoled,
      isDark: true,
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0A),
      surfaceElevated: Color(0xFF141414),
      textPrimary: Color(0xFFE8E8E8),
      textSecondary: Color(0xFF777777),
      textTertiary: Color(0xFF555555),
      border: Color(0xFF1E1E1E),
      borderStrong: Color(0xFF2A2A2A),
      accentStart: Color(0xFF6366F1),
      accentEnd: Color(0xFFA855F7),
      accentSolid: Color(0xFF6366F1),
      citation: Color(0xFFF59E0B),
      success: Color(0xFF10B981),
      warning: Color(0xFFF59E0B),
      error: Color(0xFFEF4444),
      userMessageBg: Color(0xFF6366F1),
      aiMessageBg: Color(0xFF141414),
      aiMessageBorder: Color(0xFF1E1E1E),
      chipBg: Color(0xFF141414),
      chipBorder: Color(0xFF1E1E1E),
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
