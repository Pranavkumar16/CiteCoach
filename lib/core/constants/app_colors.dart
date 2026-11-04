import 'package:flutter/material.dart';

/// CiteCoach Ink & Signal brand palette.
/// Oxblood ink, warm parchment, acid citron and signal vermilion.
abstract final class AppColors {
  // Primary Accent — Acid Citron
  static const Color accent = Color(0xFF83D6CE); // Signature citron
  static const Color accentLight = Color(0xFFB8E9E5); // Soft citron
  static const Color accentDark = Color(0xFF39A99E); // Deep citron

  // Secondary accent — Signal Vermilion
  static const Color accentCyan = Color(0xFF5D91C7); // Signal vermilion

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
  static const Color zinc50 = Color(0xFFF4F7FB);
  static const Color zinc100 = Color(0xFFE9F0F7);
  static const Color zinc200 = Color(0xFFD9E3EF);
  static const Color zinc300 = Color(0xFFC1CDDD);
  static const Color zinc400 = Color(0xFF9BADBF);
  static const Color zinc500 = Color(0xFF8398AF);
  static const Color zinc600 = Color(0xFF526A83);
  static const Color zinc700 = Color(0xFF344B63);
  static const Color zinc800 = Color(0xFF233448);
  static const Color zinc900 = Color(0xFF182638);
  static const Color zinc950 = Color(0xFF101B2A);

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
  static const Color success = Color(0xFF79D3B3);
  static const Color warning = Color(0xFFD9A441);
  static const Color error = Color(0xFFEA7180);
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
  static const Color successGreen = Color(0xFF79D3B3);
  static const Color warningOrange = Color(0xFFD9A441);
  static const Color errorRed = Color(0xFFEA7180);
  static const Color infoBlue = Color(0xFF8A7770);

  // Text Colors — Warm parchment on dark
  static const Color textPrimary = Color(0xFFE9F0F7); // zinc100
  static const Color textSecondary = Color(0xFF9BADBF); // zinc400
  static const Color textTertiary = Color(0xFF8398AF); // zinc500
  static const Color textOnPrimary = Color(0xFF182638); // oxblood text on citron

  // Alias for backward compat
  static const Color primaryIndigo = accent;
  static const Color primaryPurple = accentLight;

  // Chat specific colors
  static const Color userMessageBackground = Color(0xFF344B63); // deep oxblood
  static const Color aiMessageBackground = zinc800;
  static const Color citationBadge = accent;

  // Voice overlay colors
  static const Color voiceOverlayStart = zinc950;
  static const Color voiceOverlayEnd = Color(0xFF182638); // warm oxblood
  static const LinearGradient voiceOverlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF8101B2A), // 97% zinc950
      Color(0xF8182638), // 97% dark green
    ],
  );

  // Mic button color
  static const Color micActive = Color(0xFFEA7180);
  static const Color micInactive = zinc500;

  // Shadow colors
  static const Color shadowPrimary = Color(0x3383D6CE); // 20% citron
  static const Color shadowDark = Color(0x33000000); // 20% black

  // Accent variations for UI elements
  static const Color indigo50 = Color(0xFF182638); // dark accent bg
  static const Color indigo100 = Color(0xFF233448);
  static const Color indigo200 = Color(0xFF344B63);
  static const Color indigo600 = Color(0xFF39A99E);

  // Highlight color for citations in PDF
  static const Color highlightYellow = Color(0x6683D6CE);
}
