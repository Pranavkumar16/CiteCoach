import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/theme_provider.dart';

/// Entry point for the CiteCoach application.
///
/// CiteCoach is an offline document intelligence app that provides
/// evidence-based answers with citations from your PDFs.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI mode for edge-to-edge display
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // Eagerly initialize SharedPreferences so the theme provider is ready.
  final prefs = await SharedPreferences.getInstance();

  // Run the app with Riverpod provider scope
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CiteCoachApp(),
    ),
  );
}
