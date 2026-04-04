import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';

// ==================== ENUMS ====================

/// Global font size scaler.
enum FontScale {
  small(0.85, 'Small'),
  medium(1.0, 'Medium'),
  large(1.15, 'Large'),
  extraLarge(1.3, 'Extra Large');

  const FontScale(this.value, this.label);
  final double value;
  final String label;

  static FontScale fromValue(double v) {
    // Snap to the closest bucket.
    return FontScale.values
        .reduce((a, b) => (a.value - v).abs() < (b.value - v).abs() ? a : b);
  }
}

/// Chat bubble rendering style.
enum ChatStyle {
  modern('Modern', 'Rounded bubbles with gradient'),
  classic('Classic', 'Flat cards, no gradient'),
  compact('Compact', 'Denser, less padding');

  const ChatStyle(this.label, this.description);
  final String label;
  final String description;
}

/// How citations are displayed within an AI message.
enum CitationDisplay {
  inline('Inline badges', 'Amber pills in the message'),
  footer('Footer', 'Grouped at bottom of each answer'),
  sidebar('Sidebar', 'Vertical strip on the left');

  const CitationDisplay(this.label, this.description);
  final String label;
  final String description;
}

// ==================== PREFERENCE KEYS ====================
const String _kFontScale = 'font_scale';
const String _kChatStyle = 'chat_style';
const String _kCitationDisplay = 'citation_display';
const String _kHapticFeedback = 'haptic_feedback';
const String _kHighContrast = 'high_contrast';
const String _kReduceMotion = 'reduce_motion';
const String _kAutoReadResponses = 'auto_read_responses';

// ==================== STATE ====================

class UserPreferences {
  const UserPreferences({
    this.fontScale = FontScale.medium,
    this.chatStyle = ChatStyle.modern,
    this.citationDisplay = CitationDisplay.inline,
    this.hapticFeedback = true,
    this.highContrast = false,
    this.reduceMotion = false,
    this.autoReadResponses = false,
  });

  final FontScale fontScale;
  final ChatStyle chatStyle;
  final CitationDisplay citationDisplay;
  final bool hapticFeedback;
  final bool highContrast;
  final bool reduceMotion;
  final bool autoReadResponses;

  UserPreferences copyWith({
    FontScale? fontScale,
    ChatStyle? chatStyle,
    CitationDisplay? citationDisplay,
    bool? hapticFeedback,
    bool? highContrast,
    bool? reduceMotion,
    bool? autoReadResponses,
  }) {
    return UserPreferences(
      fontScale: fontScale ?? this.fontScale,
      chatStyle: chatStyle ?? this.chatStyle,
      citationDisplay: citationDisplay ?? this.citationDisplay,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      autoReadResponses: autoReadResponses ?? this.autoReadResponses,
    );
  }
}

// ==================== NOTIFIER ====================

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static UserPreferences _load(SharedPreferences p) {
    return UserPreferences(
      fontScale: FontScale.fromValue(p.getDouble(_kFontScale) ?? 1.0),
      chatStyle: _enumFromName(
        ChatStyle.values,
        p.getString(_kChatStyle),
        ChatStyle.modern,
      ),
      citationDisplay: _enumFromName(
        CitationDisplay.values,
        p.getString(_kCitationDisplay),
        CitationDisplay.inline,
      ),
      hapticFeedback: p.getBool(_kHapticFeedback) ?? true,
      highContrast: p.getBool(_kHighContrast) ?? false,
      reduceMotion: p.getBool(_kReduceMotion) ?? false,
      autoReadResponses: p.getBool(_kAutoReadResponses) ?? false,
    );
  }

  static T _enumFromName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  Future<void> setFontScale(FontScale v) async {
    state = state.copyWith(fontScale: v);
    await _prefs.setDouble(_kFontScale, v.value);
  }

  Future<void> setChatStyle(ChatStyle v) async {
    state = state.copyWith(chatStyle: v);
    await _prefs.setString(_kChatStyle, v.name);
  }

  Future<void> setCitationDisplay(CitationDisplay v) async {
    state = state.copyWith(citationDisplay: v);
    await _prefs.setString(_kCitationDisplay, v.name);
  }

  Future<void> setHapticFeedback(bool v) async {
    state = state.copyWith(hapticFeedback: v);
    await _prefs.setBool(_kHapticFeedback, v);
  }

  Future<void> setHighContrast(bool v) async {
    state = state.copyWith(highContrast: v);
    await _prefs.setBool(_kHighContrast, v);
  }

  Future<void> setReduceMotion(bool v) async {
    state = state.copyWith(reduceMotion: v);
    await _prefs.setBool(_kReduceMotion, v);
  }

  Future<void> setAutoReadResponses(bool v) async {
    state = state.copyWith(autoReadResponses: v);
    await _prefs.setBool(_kAutoReadResponses, v);
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>(
  (ref) => UserPreferencesNotifier(ref.watch(sharedPreferencesProvider)),
);

// ==================== HAPTIC HELPER ====================

/// Centralised haptic feedback that respects the user's `haptic_feedback`
/// preference and the system's reduce-motion setting.
class AppHaptics {
  const AppHaptics._(this._enabled);

  final bool _enabled;

  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }
}

/// Provider for the haptic helper. Automatically reflects the user's
/// `hapticFeedback` preference.
final appHapticsProvider = Provider<AppHaptics>((ref) {
  final enabled = ref.watch(userPreferencesProvider).hapticFeedback;
  return AppHaptics._(enabled);
});
