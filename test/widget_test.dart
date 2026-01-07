import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:citecoach/app.dart';

void main() {
  testWidgets('CiteCoach app starts correctly', (WidgetTester tester) async {
    // Set a larger test window size to accommodate layouts
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CiteCoachApp(),
      ),
    );

    // Verify the app renders without error
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Advance past the splash screen timer to avoid pending timers
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
