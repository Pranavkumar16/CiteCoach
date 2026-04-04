import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_theme_data.dart';

/// CiteCoach app theme configuration — Dark & Modern.
abstract final class AppTheme {
  /// Build a [ThemeData] from the given theme extension.
  /// This replaces the static [light] getter for theme-aware screens.
  static ThemeData fromExtension(AppThemeData ext) {
    final brightness = ext.isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: ext.accentSolid,
      onPrimary: ext.isDark ? Colors.white : Colors.white,
      secondary: ext.accentEnd,
      onSecondary: Colors.white,
      surface: ext.surface,
      onSurface: ext.textPrimary,
      error: ext.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Lexend',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ext.background,
      extensions: [ext],

      appBarTheme: AppBarTheme(
        backgroundColor: ext.surface,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ext.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: ext.textSecondary, size: 24),
        systemOverlayStyle: ext.isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
      ),

      cardTheme: CardThemeData(
        color: ext.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXl,
          side: BorderSide(color: ext.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: ext.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ext.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ext.textSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.surface,
        selectedItemColor: ext.accentSolid,
        unselectedItemColor: ext.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: ext.border,
        thickness: 1,
        space: 0,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: ext.textSecondary,
        textColor: ext.textPrimary,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return ext.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ext.accentSolid;
          }
          return ext.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: ext.accentSolid,
        inactiveTrackColor: ext.border,
        thumbColor: ext.accentSolid,
        overlayColor: ext.accentSolid.withOpacity(0.2),
        valueIndicatorColor: ext.accentSolid,
      ),

      textTheme: _buildTextTheme(ext.textPrimary, ext.textSecondary),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Lexend', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: primary),
      displayMedium: TextStyle(fontFamily: 'Lexend', fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, color: primary),
      displaySmall: TextStyle(fontFamily: 'Lexend', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: primary),
      headlineLarge: TextStyle(fontFamily: 'Lexend', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: primary),
      headlineMedium: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: primary),
      headlineSmall: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleMedium: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: TextStyle(fontFamily: 'Lexend', fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.6),
      bodyMedium: TextStyle(fontFamily: 'Lexend', fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.6),
      bodySmall: TextStyle(fontFamily: 'Lexend', fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Lexend', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: primary),
      labelMedium: TextStyle(fontFamily: 'Lexend', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: secondary),
      labelSmall: TextStyle(fontFamily: 'Lexend', fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: secondary),
    );
  }

  /// Legacy: The original dark theme (kept for backward compat).
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Lexend',

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.zinc900,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textSecondary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXl,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXl,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadiusPrimary),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXl,
            vertical: AppDimensions.spacingMd,
          ),
          side: const BorderSide(color: AppColors.zinc600, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadiusPrimary),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.zinc800,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusXxl,
          borderSide: BorderSide(color: AppColors.zinc600, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusXxl,
          borderSide: BorderSide(color: AppColors.zinc600, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusXxl,
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusXxl,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Lexend',
          color: AppColors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.zinc900,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.zinc700,
        thickness: 1,
        space: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textOnPrimary;
          }
          return AppColors.zinc400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.zinc700;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.zinc700,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withOpacity(0.2),
        valueIndicatorColor: AppColors.accent,
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Lexend',
          color: AppColors.textOnPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.zinc800,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      // PopupMenu
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.zinc800,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.zinc800,
        surfaceTintColor: Colors.transparent,
      ),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.zinc700,
        contentTextStyle: TextStyle(
          fontFamily: 'Lexend',
          color: AppColors.textPrimary,
        ),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  /// System UI overlay style for dark screens.
  static const SystemUiOverlayStyle lightSystemUI = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.zinc950,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// System UI overlay style for accent/gradient screens.
  static const SystemUiOverlayStyle darkSystemUI = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.zinc950,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
