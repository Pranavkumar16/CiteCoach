import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citecoach/core/database/tables/documents_table.dart';
import 'package:citecoach/core/services/storage_service.dart' as storage;
import 'package:citecoach/core/theme/app_theme.dart';
import 'package:citecoach/core/theme/app_theme_data.dart';
import 'package:citecoach/core/theme/theme_provider.dart';
import 'package:citecoach/features/chat/presentation/widgets/living_chat_input.dart';
import 'package:citecoach/features/compare/presentation/compare_screen.dart';
import 'package:citecoach/features/home/presentation/home_screen.dart';
import 'package:citecoach/features/learn/presentation/learn_screen.dart';
import 'package:citecoach/features/library/data/document_repository.dart';
import 'package:citecoach/features/library/data/pdf_import_service.dart';
import 'package:citecoach/features/library/domain/document.dart';
import 'package:citecoach/features/library/providers/library_provider.dart';
import 'package:citecoach/features/verify/presentation/verify_screen.dart';
import 'package:citecoach/routing/app_router.dart';

class _Repository extends Fake implements DocumentRepository {}
class _TrackingRepository extends Fake implements DocumentRepository {
  @override
  Future<List<Document>> getAllDocuments({DocumentSortOption sort = DocumentSortOption.addedNewest}) async => _docs;
  @override
  Future<bool> updateLastOpened(int id) async => true;
}
class _ImportService extends Fake implements DocumentImportService {}
class _Library extends LibraryNotifier {
  _Library(List<Document> docs) : super(_Repository(), _ImportService()) {
    state = LibraryState(documents: docs);
  }
  int? opened;
  @override
  Future<void> loadDocuments() async {}
  @override
  Future<void> markDocumentOpened(int id) async { opened = id; }
}

Document doc(int id, int imported, {int? opened, bool ready = true}) => Document(
  id: id, title: 'Document $id', filePath: '/test/$id.pdf',
  status: ready ? DocumentStatus.ready : DocumentStatus.processing,
  importedAt: DateTime(2026, 1, imported),
  lastOpenedAt: opened == null ? null : DateTime(2026, 1, opened),
  pageCount: 24,
);
final _docs = [doc(1, 1, opened: 12), doc(2, 3, opened: 9), doc(3, 20, ready: false), doc(4, 5)];

void main() {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({storage.StorageKeys.setupCompleted: true});
    prefs = await SharedPreferences.getInstance();
    await (FontLoader('Lexend')..addFont(rootBundle.load('assets/fonts/Lexend-Regular.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> wrap(WidgetTester tester, Widget screen, {List<Document>? docs, AppThemeData? theme, GlobalKey? boundary, bool highContrast = false, double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      libraryProvider.overrideWith((ref) => _Library(docs ?? _docs)),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ], child: MaterialApp(theme: AppTheme.fromExtension(theme ?? AppThemeData.midnight()),
      home: MediaQuery(data: MediaQueryData(size: const Size(390, 844), highContrast: highContrast, textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(key: boundary, child: screen)),
    )));
    await tester.pumpAndSettle();
  }

  test('opening a source updates recency without restarting the app', () async {
    final library = LibraryNotifier(_TrackingRepository(), _ImportService());
    addTearDown(library.dispose);
    await library.loadDocuments();
    await library.markDocumentOpened(2);
    expect(HomeScreen.recentDocuments(library.state.readyDocuments).first.id, 2);
  });

  testWidgets('Home submits an encoded draft to the most recent ready document', (tester) async {
    final library = _Library(_docs);
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/document/:id/chat', builder: (_, state) => Scaffold(body: Column(children: [Text('Chat for document ${state.pathParameters['id']}'), LivingChatInput(initialDraft: state.uri.queryParameters['question'] ?? '', onSend: (_) {})]))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [libraryProvider.overrideWith((ref) => library)], child: MaterialApp.router(theme: AppTheme.fromExtension(AppThemeData.midnight()), routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('home-question')), '  What about A & B?  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Chat for document 1'), findsOneWidget);
    expect(router.canPop(), isTrue);
    expect(library.opened, 1);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('chat-composer'))).controller!.text, 'What about A & B?');
  });

  testWidgets('Home sends users without a ready document to Library', (tester) async {
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/library', builder: (_, __) => const Scaffold(body: Text('Import here'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [libraryProvider.overrideWith((ref) => _Library([doc(3, 20, ready: false)]))], child: MaterialApp.router(theme: AppTheme.fromExtension(AppThemeData.midnight()), routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('home-question')), 'My question');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Import here'), findsOneWidget);
  });

  testWidgets('Verify and Learn preselect the most recent ready document', (tester) async {
    for (final screen in [const VerifyScreen(), const LearnScreen()]) {
      await wrap(tester, screen);
      final field = tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>));
      expect(field.initialValue, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Compare defaults to two recent ready sources and explains same-source selection', (tester) async {
    await wrap(tester, const CompareScreen());
    final fields = tester.widgetList<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>)).toList();
    expect(fields.map((f) => f.initialValue), [1, 2]);
    expect(find.text('Enter a question to compare'), findsOneWidget);
    final second = find.byType(DropdownButtonFormField<int>).last;
    await tester.tap(second);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document 1').last);
    await tester.pumpAndSettle();
    expect(find.text('Choose two different documents'), findsOneWidget);
  });

  testWidgets('Verify switch copy follows its state and blank claims are disabled', (tester) async {
    await wrap(tester, const VerifyScreen());
    expect(find.text('AI checks each claim against the passages'), findsOneWidget);
    expect(find.text('Enter a claim to inspect'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Keyword match only, faster'), findsOneWidget);
  });

  testWidgets('pushed tools hide the tab bar and system back returns Home', (tester) async {
    final container = ProviderContainer(overrides: [
      libraryProvider.overrideWith((ref) => _Library(_docs)),
      sharedPreferencesProvider.overrideWithValue(prefs),
      storage.storageServiceProvider.overrideWithValue(storage.StorageService(prefs)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    router.go(AppRoutes.home);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(theme: AppTheme.fromExtension(AppThemeData.midnight()), routerConfig: router)));
    await tester.pumpAndSettle();
    for (final route in [AppRoutes.verify, AppRoutes.compare, AppRoutes.learn]) {
      router.push(route);
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    }
  });

  final themes = {'midnight': AppThemeData.midnight(), 'daylight': AppThemeData.daylight(), 'amoled': AppThemeData.amoled()};
  final screens = {'home': const HomeScreen(), 'verify': const VerifyScreen(), 'compare': const CompareScreen(), 'learn': const LearnScreen()};
  for (final theme in themes.entries) {
    for (final screen in screens.entries) {
      testWidgets('render ${screen.key} ${theme.key} at 390x844', (tester) async {
        final key = GlobalKey();
        await wrap(tester, screen.value, theme: theme.value, boundary: key);
        expect(tester.takeException(), isNull);
        Future<void> capture(String suffix) async {
          await tester.runAsync(() async {
            final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 1);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            Directory('build/ui-previews').createSync(recursive: true);
            File('build/ui-previews/${screen.key}-${theme.key}$suffix.png').writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await capture('');
        await tester.drag(find.byType(ListView).first, const Offset(0, -420));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture('-scrolled');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('tool forms remain usable at 200 percent text and high contrast', (tester) async {
    for (final screen in [const VerifyScreen(), const CompareScreen(), const LearnScreen()]) {
      await wrap(tester, screen, highContrast: true, scale: 2);
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
