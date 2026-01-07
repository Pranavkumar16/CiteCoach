import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// The root widget of the CiteCoach application.
class CiteCoachApp extends ConsumerWidget {
  const CiteCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSystemUI);

    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        // Apply global error handling and accessibility settings
        return MediaQuery(
          // Prevent system text scaling from breaking layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
