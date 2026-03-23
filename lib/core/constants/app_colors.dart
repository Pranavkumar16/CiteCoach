import 'package:flutter/material.dart';

/// CiteCoach dark theme color palette.
/// Inspired by ChatGPT/Slack dark mode with teal accent.
abstract final class AppColors {
  // Primary Accent — Emerald/Teal for a modern dark theme
  static const Color accent = Color(0xFF10B981); // Emerald-500
  static const Color accentLight = Color(0xFF6EE7B7); // Emerald-300
  static const Color accentDark = Color(0xFF059669); // Emerald-600

  // Secondary accent — Cyan for gradient pairing
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan-500

  // Gradient definitions — Emerald → Cyan
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentCyan],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accent, accentCyan],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentCyan],
  );

  // Dark Neutrals (Zinc scale)
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Keep old names as aliases for backward compat in non-UI code
  static const Color slate50 = zinc50;
  static const Color slate100 = zinc100;
  static const Color slate200 = zinc200;
  static const Color slate300 = zinc300;
  static const Color slate400 = zinc400;
  static const Color slate500 = zinc500;
  static const Color slate600 = zinc600;
  static const Color slate700 = zinc700;
  static const Color slate800 = zinc800;
  static const Color slate900 = zinc900;

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Base colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // UI Colors — Dark surfaces
  static const Color background = zinc950;
  static const Color backgroundPrimary = zinc950;
  static const Color backgroundSecondary = zinc900;
  static const Color surface = zinc900;
  static const Color surfacePrimary = zinc800;
  static const Color surfaceVariant = zinc700;
  static const Color border = zinc700;
  static const Color borderLight = zinc700;

  // Semantic colors with specific names
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Text Colors — Light on dark
  static const Color textPrimary = Color(0xFFF4F4F5); // zinc100
  static const Color textSecondary = Color(0xFFA1A1AA); // zinc400
  static const Color textTertiary = Color(0xFF71717A); // zinc500
  static const Color textOnPrimary = Color(0xFF09090B); // dark text on accent

  // Alias for backward compat
  static const Color primaryIndigo = accent;
  static const Color primaryPurple = accentLight;

  // Chat specific colors
  static const Color userMessageBackground = Color(0xFF1A3A2F); // dark teal
  static const Color aiMessageBackground = zinc800;
  static const Color citationBadge = accent;

  // Voice overlay colors
  static const Color voiceOverlayStart = zinc950;
  static const Color voiceOverlayEnd = Color(0xFF0D2818); // very dark green
  static const LinearGradient voiceOverlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF809090B), // 97% zinc950
      Color(0xF80D2818), // 97% dark green
    ],
  );

  // Mic button color
  static const Color micActive = Color(0xFFEF4444);
  static const Color micInactive = zinc500;

  // Shadow colors
  static const Color shadowPrimary = Color(0x3310B981); // 20% accent
  static const Color shadowDark = Color(0x33000000); // 20% black

  // Accent variations for UI elements
  static const Color indigo50 = Color(0xFF0D2818); // dark accent bg
  static const Color indigo100 = Color(0xFF103D24);
  static const Color indigo200 = Color(0xFF166534);
  static const Color indigo600 = Color(0xFF059669);

  // Highlight color for citations in PDF
  static const Color highlightYellow = Color(0xFF422006);
}
