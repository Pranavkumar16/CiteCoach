import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_variant.dart';

/// Row of 4 circular theme swatches — Midnight / Daylight / AMOLED / System.
///
/// Each swatch shows the theme's background with the accent gradient arc.
/// The currently-selected swatch gets a gradient ring border.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ThemeVariant.values.map((variant) {
          return _ThemeSwatch(
            variant: variant,
            isSelected: variant == selected,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setVariant(variant);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeVariant variant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = _previewData(variant);
    final currentTheme = Theme.of(context).extension<AppThemeData>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                      colors: [preview.accentStart, preview.accentEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: isSelected
                  ? null
                  : Border.all(
                      color: currentTheme.border,
                      width: 1.5,
                    ),
            ),
            child: _SwatchCircle(preview: preview),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? currentTheme.textPrimary
                : currentTheme.textSecondary,
          ),
          child: Text(variant.label),
        ),
      ],
    );
  }

  _SwatchPreview _previewData(ThemeVariant v) {
    switch (v) {
      case ThemeVariant.midnight:
        return _SwatchPreview.fromTheme(AppThemeData.midnight());
      case ThemeVariant.daylight:
        return _SwatchPreview.fromTheme(AppThemeData.daylight());
      case ThemeVariant.amoled:
        return _SwatchPreview.fromTheme(AppThemeData.amoled());
      case ThemeVariant.system:
        // Split swatch: half light, half dark with shared accent.
        final dark = AppThemeData.midnight();
        final light = AppThemeData.daylight();
        return _SwatchPreview(
          background: dark.background,
          secondBackground: light.background,
          isSplit: true,
          accentStart: dark.accentStart,
          accentEnd: dark.accentEnd,
        );
    }
  }
}

class _SwatchPreview {
  const _SwatchPreview({
    required this.background,
    required this.accentStart,
    required this.accentEnd,
    this.secondBackground,
    this.isSplit = false,
  });

  factory _SwatchPreview.fromTheme(AppThemeData t) {
    return _SwatchPreview(
      background: t.background,
      accentStart: t.accentStart,
      accentEnd: t.accentEnd,
    );
  }

  final Color background;
  final Color? secondBackground;
  final bool isSplit;
  final Color accentStart;
  final Color accentEnd;
}

class _SwatchCircle extends StatelessWidget {
  const _SwatchCircle({required this.preview});

  final _SwatchPreview preview;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        children: [
          // Background (split for System variant)
          if (preview.isSplit)
            Row(
              children: [
                Expanded(
                  child: Container(color: preview.secondBackground),
                ),
                Expanded(
                  child: Container(color: preview.background),
                ),
              ],
            )
          else
            Container(color: preview.background),

          // Accent gradient arc (bottom-right quadrant)
          Positioned(
            right: -12,
            bottom: -12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [preview.accentStart, preview.accentEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
