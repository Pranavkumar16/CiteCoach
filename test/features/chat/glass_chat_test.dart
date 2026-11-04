import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citecoach/core/theme/app_theme.dart';
import 'package:citecoach/core/theme/app_theme_data.dart';
import 'package:citecoach/core/theme/theme_provider.dart';
import 'package:citecoach/core/widgets/glass_surface.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/chat/presentation/widgets/generation_status.dart';
import 'package:citecoach/features/chat/presentation/widgets/living_chat_input.dart';
import 'package:citecoach/features/chat/presentation/widgets/message_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    final font = FontLoader('Lexend')
      ..addFont(rootBundle.load('assets/fonts/Lexend-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Widget wrap(
    Widget child, {
    AppThemeData? theme,
    bool highContrast = false,
    double scale = 1,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        theme: AppTheme.fromExtension(theme ?? AppThemeData.midnight()),
        home: MediaQuery(
          data: MediaQueryData(
            highContrast: highContrast,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: GlassBackdrop(child: child)),
        ),
      ),
    );
  }

  testWidgets('empty suggestion list stays empty and composer sends once', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: LivingChatInput(onSend: sent.add),
        ),
      ),
    );
    expect(find.byType(ActionChip), findsNothing);
    await tester.enterText(find.byType(TextField), 'Summarize this');
    await tester.pump();
    await tester.tap(find.byTooltip('Send question'));
    await tester.pump();
    expect(sent, ['Summarize this']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.byType(ActionChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy composer accepts a draft without submitting it', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: LivingChatInput(
            onSend: sent.add,
            isDisabled: true,
            suggestions: const ['Summary'],
          ),
        ),
      ),
    );
    expect(find.byType(ActionChip), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    await tester.enterText(find.byType(TextField), 'My next question');
    await tester.pump();
    await tester.tap(find.byTooltip('Send question'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'My next question',
    );
    expect(sent, isEmpty);
  });

  testWidgets('high contrast disables glass blur', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Center(child: GlassSurface(child: Text('Readable'))),
        highContrast: true,
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Readable'), findsOneWidget);
  });

  testWidgets('progress exposes Stop and updates the activity', (tester) async {
    var stopped = false;
    await tester.pumpWidget(
      wrap(
        GenerationStatus(
          label: 'Finding evidence…',
          onStop: () {
            stopped = true;
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Finding evidence…'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  for (final dark in [true, false]) {
    testWidgets(
      'modern bubble uses readable text in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        final theme = dark ? AppThemeData.midnight() : AppThemeData.daylight();
        await tester.pumpWidget(
          wrap(
            MessageBubble(
              message: ChatMessage.user(documentId: 1, content: 'My question'),
            ),
            theme: theme,
          ),
        );
        final text = tester.widget<Text>(find.text('My question'));
        final foreground = text.style!.color!;
        final background = dark
            ? const Color(0xFFE3F39B)
            : const Color(0xFF3B2932);
        final a = foreground.computeLuminance();
        final b = background.computeLuminance();
        final contrast = ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      },
    );
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('glass chat renders at $width with large text', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        wrap(
          RepaintBoundary(
            key: key,
            child: GlassBackdrop(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 36, 12, 12),
                    child: GlassSurface(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_rounded),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Introduction to Machine Learning',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.menu_book_outlined),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        MessageBubble(
                          message: ChatMessage.user(
                            documentId: 1,
                            content: 'What is the main topic?',
                          ),
                        ),
                        MessageBubble(
                          message: ChatMessage.assistant(
                            documentId: 1,
                            content:
                                'The document introduces machine learning: how systems learn patterns from data and apply them to new examples. [Page 1]',
                          ),
                        ),
                      ],
                    ),
                  ),
                  LivingChatInput(onSend: (_) {}, suggestions: const []),
                ],
              ),
            ),
          ),
          scale: width == 320 ? 1.6 : 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/ui-previews')
          ..createSync(recursive: true);
        File(
          '${directory.path}/glass-chat-${width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
