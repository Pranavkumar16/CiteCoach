import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/core/theme/app_theme.dart';
import 'package:citecoach/core/theme/app_theme_data.dart';
import 'package:citecoach/core/widgets/adaptive_page_column.dart';
import 'package:citecoach/core/widgets/gradient_button.dart';
import 'package:citecoach/features/learn/domain/quiz_question.dart';
import 'package:citecoach/features/learn/presentation/quiz_session.dart';

void main() {
  const line = 'Q: What is supervised learning? | A: Learning from labels | B: Clustering | C: Random guessing | D: Compression | KEY: A | PAGE: 3';
  test('quiz parser validates options, answer keys and evidence pages', () {
    const parser = QuizParser();
    expect(parser.parse(line, {3}).single.correctIndex, 0);
    expect(parser.parse(line, {2}), isEmpty);
    expect(parser.parse(line.replaceFirst('KEY: A', 'KEY: E'), {3}), isEmpty);
    expect(parser.parse(line.replaceFirst('B: Clustering', 'B: Learning from labels'), {3}), isEmpty);
  });
  testWidgets('quiz gives feedback, score and permits retake on small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sourcePage = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromExtension(AppThemeData.midnight()),
      home: Scaffold(body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [QuizSession(
          questions: const QuizParser().parse(line, {3}),
          onSource: (page) => sourcePage = page,
        )],
      ))),
    ));
    await tester.tap(find.byKey(const ValueKey('quiz-0-option-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Incorrect. Correct answer: A.'), findsOneWidget);
    await tester.ensureVisible(find.text('Check source · page 3'));
    await tester.tap(find.text('Check source · page 3'));
    expect(sourcePage, 3);
    await tester.ensureVisible(find.text('Retake quiz'));
    expect(find.text('Your score: 0 / 1'), findsOneWidget);
    await tester.tap(find.text('Retake quiz'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('quiz-0-option-0')));
    await tester.tap(find.byKey(const ValueKey('quiz-0-option-0')));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Your score: 1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('short pages and shared buttons scroll at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 400), textScaler: TextScaler.linear(2)),
        child: Scaffold(body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(20),
          child: AdaptivePageColumn(children: [
            const Spacer(),
            const Text('Offline AI setup. This content must remain reachable on a short screen at large text sizes.'),
            const SizedBox(height: 200),
            const Spacer(),
            GradientButton(onPressed: () {}, text: 'Continue to offline learning'),
          ]),
        ))),
      ),
    ));
    await tester.ensureVisible(find.text('Continue to offline learning'));
    expect(tester.takeException(), isNull);
  });
}
