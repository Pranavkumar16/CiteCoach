import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/core/theme/app_theme_data.dart';
import 'package:citecoach/features/setup/presentation/introduction_screen.dart';

void main() {
  testWidgets('introduction explains features and supports backward navigation', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      theme: ThemeData(extensions: [AppThemeData.midnight()]),
      home: const IntroductionScreen(),
    )));
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Ask. Then check the evidence.'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 4'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Internet is needed'), findsOneWidget);
  });
}
