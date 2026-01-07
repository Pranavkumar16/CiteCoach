import 'package:flutter/material.dart';

/// CiteCoach color palette based on the Kinetic Identity design system.
/// Primary gradient: Indigo (#6366f1) → Purple (#a855f7)
abstract final class AppColors {
  // Primary Brand Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFFA855F7);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, primaryPurple],
  );
  
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryIndigo, primaryPurple],
  );
  
  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryIndigo, primaryPurple],
  );

  // Slate Gray Scale (from Tailwind)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Semantic Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF0071E3);

  // Base colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // UI Colors
  static const Color background = slate50;
  static const Color backgroundPrimary = slate50;
  static const Color backgroundSecondary = slate100;
  static const Color surface = Colors.white;
  static const Color surfacePrimary = Colors.white;
  static const Color surfaceVariant = slate100;
  static const Color border = slate200;
  static const Color borderLight = Color(0xFFE2E8F0);
  
  // Semantic colors with more specific names
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color infoBlue = Color(0xFF0071E3);
  
  // Text Colors
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate500;
  static const Color textTertiary = slate400;
  static const Color textOnPrimary = Colors.white;
  
  // Chat specific colors
  static const Color userMessageBackground = primaryIndigo;
  static const Color aiMessageBackground = Colors.white;
  static const Color citationBadge = primaryIndigo;
  
  // Voice overlay colors
  static const Color voiceOverlayStart = primaryIndigo;
  static const Color voiceOverlayEnd = primaryPurple;
  static const LinearGradient voiceOverlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF86366F1), // 97% opacity indigo
      Color(0xF8A855F7), // 97% opacity purple
    ],
  );
  
  // Mic button color
  static const Color micActive = Color(0xFFEF4444);
  static const Color micInactive = slate400;
  
  // Shadow colors
  static const Color shadowPrimary = Color(0x1A6366F1); // 10% indigo
  static const Color shadowDark = Color(0x1A0F172A); // 10% slate900
  
  // Indigo variations for UI elements
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo600 = Color(0xFF4F46E5);
  
  // Highlight color for citations in PDF
  static const Color highlightYellow = Color(0xFFFEF3C7);
}
