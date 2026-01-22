import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/chat_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/processing/presentation/document_ready_screen.dart';
import '../features/processing/presentation/processing_screen.dart';
import '../features/setup/domain/setup_state.dart';
import '../features/setup/presentation/download_progress_screen.dart';
import '../features/setup/presentation/download_required_screen.dart';
import '../features/setup/presentation/model_setup_screen.dart';
import '../features/setup/presentation/privacy_screen.dart';
import '../features/setup/presentation/setup_complete_screen.dart';
import '../features/setup/presentation/splash_screen.dart';
import '../features/setup/providers/setup_provider.dart';
import '../features/voice/presentation/voice_overlay_screen.dart';

/// Route paths as constants for type-safe navigation.
abstract final class AppRoutes {
  // Setup flow
  static const String splash = '/';
  static const String privacy = '/setup/privacy';
  static const String modelSetup = '/setup/model';
  static const String downloadProgress = '/setup/download';
  static const String setupComplete = '/setup/complete';

  // Main app
  static const String library = '/library';
  static const String settings = '/settings';
  static const String modelInfo = '/settings/model-info';

  // Document specific
  static const String processing = '/document/:id/processing';
  static const String documentReady = '/document/:id/ready';
  static const String reader = '/document/:id/reader';
  static const String chat = '/document/:id/chat';

  // Voice overlay (shown as dialog/overlay)
  static const String voice = '/voice';
  static const String voiceInput = '/voice-input';

  // Download required (when user chose "Download Later")
  static const String downloadRequired = '/download-required';

  // Helper to build document routes
  static String documentProcessing(String documentId) =>
      '/document/$documentId/processing';
  static String documentReader(String documentId) =>
      '/document/$documentId/reader';
  static String documentChat(String documentId) =>
      '/document/$documentId/chat';
}

/// Provider for the GoRouter instance.
/// This allows us to access the router from anywhere using Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});

/// Creates the app router with all routes and guards.
GoRouter createRouter(Ref ref) {
  final setupState = ref.watch(setupProvider);
  final setupNotifier = ref.watch(setupProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(setupNotifier.stream),
    redirect: (context, state) {
      final currentPath = state.uri.path;
      
      // List of setup paths
      final setupPaths = [
        AppRoutes.splash,
        AppRoutes.privacy,
        AppRoutes.modelSetup,
        AppRoutes.downloadProgress,
        AppRoutes.setupComplete,
      ];
      
      final isSetupPath = setupPaths.contains(currentPath);
      final isSetupCompleted = setupState.currentStep == SetupStep.done;
      final isChatPath =
          RegExp(r'^/document/\d+/chat$').hasMatch(currentPath);
      
      // If setup is completed and user tries to access setup screens,
      // redirect to library
      if (isSetupCompleted && isSetupPath) {
        return AppRoutes.library;
      }
      
      // If setup is not completed and user tries to access main app,
      // redirect to current setup step
      if (!isSetupCompleted && !isSetupPath) {
        return setupState.currentStep.routePath;
      }

      // If chat is locked, redirect to download required screen
      if (isSetupCompleted &&
          !setupState.canUseChat &&
          isChatPath &&
          currentPath != AppRoutes.downloadRequired) {
        return AppRoutes.downloadRequired;
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Setup Flow
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.modelSetup,
        name: 'modelSetup',
        builder: (context, state) => const ModelSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.downloadProgress,
        name: 'downloadProgress',
        builder: (context, state) => const DownloadProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupComplete,
        name: 'setupComplete',
        builder: (context, state) => const SetupCompleteScreen(),
      ),

      // Main App - Shell Route for bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Settings'),
          ),
        ],
      ),

      // Settings sub-routes
      GoRoute(
        path: AppRoutes.modelInfo,
        name: 'modelInfo',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Model Info'),
      ),

      // Document routes
      GoRoute(
        path: '/document/:id/processing',
        name: 'processing',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['id']!);
          return ProcessingScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/document/:id/ready',
        name: 'documentReady',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['id']!);
          return DocumentReadyScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/document/:id/reader',
        name: 'reader',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['id']!);
          final pageStr = state.uri.queryParameters['page'];
          final initialPage = pageStr != null ? int.tryParse(pageStr) : null;
          return _PlaceholderScreen(
            name: 'Reader',
            extra: 'Document: $documentId, Page: ${initialPage ?? 1}',
          );
        },
      ),
      GoRoute(
        path: '/document/:id/chat',
        name: 'chat',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['id']!);
          return ChatScreen(documentId: documentId);
        },
      ),

      // Voice Input
      GoRoute(
        path: AppRoutes.voiceInput,
        name: 'voiceInput',
        builder: (context, state) {
          final documentIdStr = state.uri.queryParameters['documentId'];
          final documentId = documentIdStr != null 
              ? int.tryParse(documentIdStr) ?? 0 
              : 0;
          return VoiceOverlayScreen(documentId: documentId);
        },
      ),

      // Download Required
      GoRoute(
        path: AppRoutes.downloadRequired,
        name: 'downloadRequired',
        builder: (context, state) => const DownloadRequiredScreen(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Shell widget for main app screens with bottom navigation.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Determine current index based on location
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = location.startsWith('/settings') ? 1 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.go(AppRoutes.library);
          } else {
            context.go(AppRoutes.settings);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Temporary placeholder screen for routes not yet implemented.
/// This will be removed as screens are implemented in subsequent commits.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.name,
    this.extra,
  });

  final String name;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (extra != null) ...[
              const SizedBox(height: 8),
              Text(
                extra!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Screen implementation coming in next commit',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for unknown routes.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.library),
              child: const Text('Go to Library'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension methods for easier navigation.
extension GoRouterExtension on BuildContext {
  /// Navigate to document chat screen.
  void goToChat(String documentId) {
    go(AppRoutes.documentChat(documentId));
  }

  /// Navigate to document reader screen with optional page.
  void goToReader(String documentId, {int? page}) {
    final uri = page != null
        ? '${AppRoutes.documentReader(documentId)}?page=$page'
        : AppRoutes.documentReader(documentId);
    go(uri);
  }

  /// Navigate to document processing screen.
  void goToProcessing(String documentId) {
    go(AppRoutes.documentProcessing(documentId));
  }
}
