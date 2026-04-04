import 'package:flutter/material.dart';

/// User-selectable theme variants.
///
/// - [system]: follows the OS light/dark setting (Midnight when dark, Daylight when light).
/// - [midnight]: premium dark theme (default).
/// - [daylight]: clean light theme.
/// - [amoled]: true-black OLED-friendly variant.
enum ThemeVariant {
  system,
  midnight,
  daylight,
  amoled;

  String get label {
    switch (this) {
      case ThemeVariant.system:
        return 'System';
      case ThemeVariant.midnight:
        return 'Midnight';
      case ThemeVariant.daylight:
        return 'Daylight';
      case ThemeVariant.amoled:
        return 'AMOLED';
    }
  }

  String get description {
    switch (this) {
      case ThemeVariant.system:
        return 'Follow device setting';
      case ThemeVariant.midnight:
        return 'Premium dark';
      case ThemeVariant.daylight:
        return 'Clean light';
      case ThemeVariant.amoled:
        return 'True black for OLED';
    }
  }

  /// Whether this variant is a dark theme (for dark-mode-dependent APIs).
  /// For [system], we return null so callers can check platform brightness.
  bool? get isDarkExplicit {
    switch (this) {
      case ThemeVariant.midnight:
      case ThemeVariant.amoled:
        return true;
      case ThemeVariant.daylight:
        return false;
      case ThemeVariant.system:
        return null;
    }
  }

  /// Resolve the effective variant for the current platform brightness.
  /// Used to convert [system] into [midnight] or [daylight] at runtime.
  ThemeVariant resolve(Brightness platformBrightness) {
    if (this != ThemeVariant.system) return this;
    return platformBrightness == Brightness.dark
        ? ThemeVariant.midnight
        : ThemeVariant.daylight;
  }

  /// Persist-safe name (for SharedPreferences).
  String get key => name;

  static ThemeVariant fromKey(String? key) {
    if (key == null) return ThemeVariant.system;
    return ThemeVariant.values.firstWhere(
      (v) => v.name == key,
      orElse: () => ThemeVariant.system,
    );
  }
}
