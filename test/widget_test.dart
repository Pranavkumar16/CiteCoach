import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:citecoach/app.dart';

void main() {
  testWidgets('CiteCoach app starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CiteCoachApp(),
      ),
    );

    // Verify the app renders without error
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
