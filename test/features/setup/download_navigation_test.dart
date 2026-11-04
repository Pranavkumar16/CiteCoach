import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:citecoach/core/constants/app_strings.dart';
import 'package:citecoach/core/services/storage_service.dart';
import 'package:citecoach/features/setup/data/model_downloader.dart';
import 'package:citecoach/features/setup/data/setup_repository.dart';
import 'package:citecoach/features/setup/domain/setup_state.dart';
import 'package:citecoach/features/setup/presentation/download_progress_screen.dart';
import 'package:citecoach/features/setup/providers/setup_provider.dart';

class _Downloader extends Fake implements ModelDownloader {
  bool cancelled = false;
  @override
  void cancelDownload() { cancelled = true; }
  @override
  void dispose() {}
}
class _Repository extends SetupRepository {
  _Repository() : super(StorageService(null));
  bool skipped = false;
  @override
  SetupState loadSetupState() => const SetupState(currentStep: SetupStep.downloading, isDownloading: true, downloadProgress: .64);
  @override
  Future<void> saveSetupCompleted(bool value) async { skipped = value; }
}

void main() {
  for (final useSystemBack in [true, false]) {
    testWidgets('${useSystemBack ? 'System' : 'Toolbar'} back returns to setup from root download route', (tester) async {
      final downloader = _Downloader();
      final router = GoRouter(initialLocation: '/setup/download', routes: [
        GoRoute(path: '/setup/download', builder: (_, __) => const DownloadProgressScreen()),
        GoRoute(path: '/setup/model', builder: (_, __) => const Scaffold(body: Text('AI setup'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [setupProvider.overrideWith((ref) => SetupNotifier(_Repository(), downloader))], child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      if (useSystemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byTooltip('Back to AI setup'));
      }
      await tester.pumpAndSettle();
      expect(find.text('AI setup'), findsOneWidget);
      expect(downloader.cancelled, isTrue);
    });
  }
  testWidgets('Skip remains reachable during an active download on a small screen', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final downloader = _Downloader();
    final router = GoRouter(initialLocation: '/setup/download', routes: [
      GoRoute(path: '/setup/download', builder: (_, __) => const DownloadProgressScreen()),
      GoRoute(path: '/library', builder: (_, __) => const Scaffold(body: Text('Your library'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [setupProvider.overrideWith((ref) => SetupNotifier(repository, downloader))], child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    await tester.tap(find.text(AppStrings.skipForNowButton));
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);
    expect(repository.skipped, isTrue);
    expect(downloader.cancelled, isTrue);
  });
}
