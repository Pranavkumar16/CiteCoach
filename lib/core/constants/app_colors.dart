import 'package:flutter/material.dart';

/// CiteCoach Ink & Signal brand palette.
/// Oxblood ink, warm parchment, warm amber and signal coral.
abstract final class AppColors {
  // Primary Accent — Acid Citron
  static const Color accent = Color(0xFFF5B544); // Signature amber
  static const Color accentLight = Color(0xFFFAD58A); // Soft amber
  static const Color accentDark = Color(0xFFC98A22); // Deep amber

  // Secondary accent — Signal Vermilion
  static const Color accentCyan = Color(0xFFD85B43); // Signal vermilion

  // Brand gradient — Citron → Vermilion (use sparingly)
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

  // Warm neutrals mapped to the legacy zinc scale
  static const Color zinc50 = Color(0xFFFBF8F1);
  static const Color zinc100 = Color(0xFFF1E9D8);
  static const Color zinc200 = Color(0xFFE5DACC);
  static const Color zinc300 = Color(0xFFCDBFAF);
  static const Color zinc400 = Color(0xFFB7A99A);
  static const Color zinc500 = Color(0xFF928477);
  static const Color zinc600 = Color(0xFF66545A);
  static const Color zinc700 = Color(0xFF493840);
  static const Color zinc800 = Color(0xFF35262E);
  static const Color zinc900 = Color(0xFF271B21);
  static const Color zinc950 = Color(0xFF1A1117);

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
  static const Color success = Color(0xFFB4CF45);
  static const Color warning = Color(0xFFD9A441);
  static const Color error = Color(0xFFD85B43);
  static const Color info = Color(0xFF8A7770);

  // Base colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // UI Colors — Oxblood surfaces
  static const Color background = zinc950;
  static const Color backgroundPrimary = zinc950;
  static const Color backgroundSecondary = zinc900;
  static const Color surface = zinc900;
  static const Color surfacePrimary = zinc800;
  static const Color surfaceVariant = zinc700;
  static const Color border = zinc700;
  static const Color borderLight = zinc700;

  // Semantic colors with specific names
  static const Color successGreen = Color(0xFFB4CF45);
  static const Color warningOrange = Color(0xFFD9A441);
  static const Color errorRed = Color(0xFFD85B43);
  static const Color infoBlue = Color(0xFF8A7770);

  // Text Colors — Warm parchment on dark
  static const Color textPrimary = Color(0xFFF1E9D8); // zinc100
  static const Color textSecondary = Color(0xFFB7A99A); // zinc400
  static const Color textTertiary = Color(0xFF928477); // zinc500
  static const Color textOnPrimary = Color(0xFF271B21); // oxblood text on amber

  // Alias for backward compat
  static const Color primaryIndigo = accent;
  static const Color primaryPurple = accentLight;

  // Chat specific colors
  static const Color userMessageBackground = Color(0xFF493840); // deep oxblood
  static const Color aiMessageBackground = zinc800;
  static const Color citationBadge = accent;

  // Voice overlay colors
  static const Color voiceOverlayStart = zinc950;
  static const Color voiceOverlayEnd = Color(0xFF271B21); // warm oxblood
  static const LinearGradient voiceOverlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF81A1117), // 97% zinc950
      Color(0xF8271B21), // 97% dark green
    ],
  );

  // Mic button color
  static const Color micActive = Color(0xFFD85B43);
  static const Color micInactive = zinc500;

  // Shadow colors
  static const Color shadowPrimary = Color(0x33F5B544); // 20% amber
  static const Color shadowDark = Color(0x33000000); // 20% black

  // Accent variations for UI elements
  static const Color indigo50 = Color(0xFF271B21); // dark accent bg
  static const Color indigo100 = Color(0xFF35262E);
  static const Color indigo200 = Color(0xFF493840);
  static const Color indigo600 = Color(0xFFA6BC32);

  // Highlight color for citations in PDF
  static const Color highlightYellow = Color(0x66F5B544);
}
