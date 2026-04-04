import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/preferences/user_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routing/app_router.dart';

/// The root widget of the CiteCoach application.
class CiteCoachApp extends ConsumerWidget {
  const CiteCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appThemeData = ref.watch(appThemeDataProvider);
    final prefs = ref.watch(userPreferencesProvider);

    // Sync the system UI overlay to the current theme so status-bar and
    // nav-bar icons have proper contrast.
    SystemChrome.setSystemUIOverlayStyle(
      appThemeData.isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: appThemeData.background,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: appThemeData.background,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromExtension(appThemeData),
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
      builder: (context, child) {
        // Apply user-chosen font scale (and respect system reduce-animations).
        final systemScale =
            MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              systemScale * prefs.fontScale.value,
            ),
            disableAnimations: prefs.reduceMotion ||
                MediaQuery.of(context).disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
