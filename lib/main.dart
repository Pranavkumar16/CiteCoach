import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

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

  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: CiteCoachApp(),
    ),
  );
}
