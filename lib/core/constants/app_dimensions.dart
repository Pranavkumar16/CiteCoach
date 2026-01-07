import 'package:flutter/material.dart';

/// Consistent spacing, sizing, and radius values for CiteCoach UI.
abstract final class AppDimensions {
  // Base spacing unit (8px grid system)
  static const double spacingUnit = 8.0;
  
  // Spacing values
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacing3xl = 40.0;
  static const double spacing4xl = 48.0;
  
  // Padding presets
  static const EdgeInsets paddingAllXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(spacingXl);
  
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: spacingMd);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: spacingLg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: spacingXl);
  
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: spacingMd);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: spacingLg);
  
  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacingLg,
    vertical: spacingMd,
  );
  
  // Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radius3xl = 28.0;
  static const double radius4xl = 38.0;
  static const double radiusFull = 999.0;
  
  // BorderRadius presets
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderRadius3xl = BorderRadius.all(Radius.circular(radius3xl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  
  // Button sizes
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  static const double buttonHeightXl = 60.0;
  
  static const double buttonRadiusPrimary = radius3xl;
  static const double buttonRadiusSecondary = radiusLg;
  
  // Icon sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 28.0;
  static const double iconSizeXl = 32.0;
  static const double iconSizeXxl = 40.0;
  
  // Avatar/thumbnail sizes
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 40.0;
  static const double avatarSizeLg = 48.0;
  
  // Document card thumbnail
  static const double docThumbnailWidth = 75.0;
  static const double docThumbnailHeight = 100.0;
  
  // Chat
  static const double messageMaxWidthFactor = 0.8;
  static const double messageBorderRadius = radiusXl;
  static const double messageCornerRadius = 6.0;
  static const double micButtonSize = 40.0;
  static const double citationBadgeRadius = radiusMd;
  
  // FAB
  static const double fabSize = 60.0;
  static const double fabIconSize = 28.0;
  
  // Bottom Navigation
  static const double bottomNavHeight = 64.0;
  static const double bottomNavIconSize = 24.0;
  
  // App Header
  static const double appBarHeight = 56.0;
  static const double headerTitleSize = 28.0;
  
  // Progress bar
  static const double progressBarHeight = 10.0;
  static const double progressBarRadius = 10.0;
  
  // Setup screen
  static const double setupIconSize = 80.0;
  static const double setupMaxWidth = 280.0;
  static const double logoSizeLarge = 180.0;
  static const double logoSizeMedium = 120.0;
  static const double logoSizeSmall = 64.0;
  
  // PDF Reader
  static const double pageIndicatorHeight = 48.0;
  static const double pdfPageMargin = 20.0;
  static const double pdfPagePadding = 28.0;
  
  // Voice overlay
  static const double voiceWaveformHeight = 55.0;
  static const double voiceTranscriptMaxWidth = 300.0;
  
  // Card
  static const double cardBorderRadius = radiusXl;
  static const double cardElevation = 0.0;
  
  // Shadows
  static const double shadowBlurRadius = 20.0;
  static const double shadowSpreadRadius = 0.0;
  static const Offset shadowOffset = Offset(0, 4);
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Max content width for tablets
  static const double maxContentWidth = 600.0;
  
  // Safe area insets (will be updated at runtime)
  static const double defaultTopSafeArea = 44.0;
  static const double defaultBottomSafeArea = 34.0;
}
