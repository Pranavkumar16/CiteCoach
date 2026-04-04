import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_data.dart';
import 'theme_variant.dart';

/// SharedPreferences key for the persisted theme choice.
const String _kThemePrefKey = 'app_theme';

/// SharedPreferences instance — provided at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  ),
);

/// State notifier that persists the user's theme choice.
class ThemeNotifier extends StateNotifier<ThemeVariant> {
  ThemeNotifier(this._prefs)
      : super(ThemeVariant.fromKey(_prefs.getString(_kThemePrefKey)));

  final SharedPreferences _prefs;

  Future<void> setVariant(ThemeVariant variant) async {
    if (state == variant) return;
    state = variant;
    await _prefs.setString(_kThemePrefKey, variant.key);
  }
}

/// Provider for the user's selected theme variant.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeVariant>(
  (ref) => ThemeNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Provider that resolves the current [AppThemeData] based on the selected
/// variant and the current platform brightness.
///
/// The platform brightness is looked up via [WidgetsBinding.instance] so the
/// provider doesn't need a BuildContext. Widgets using this should also
/// wrap in MediaQuery and re-watch on platform brightness changes.
final appThemeDataProvider = Provider<AppThemeData>((ref) {
  final variant = ref.watch(themeProvider);
  final platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  return AppThemeData.fromVariant(
    variant,
    platformBrightness: platformBrightness,
  );
});
