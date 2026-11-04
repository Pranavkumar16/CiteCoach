import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/widgets/glass_surface.dart';

/// One quiet welcome, with conversation starters kept in the composer.
class EmptyChatView extends StatelessWidget {
  const EmptyChatView({
    super.key,
    required this.documentTitle,
    this.onSampleQuestion,
  });
  final String documentTitle;
  final ValueChanged<String>? onSampleQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassSurface(
              blur: false,
              radius: 26,
              padding: const EdgeInsets.all(22),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 38,
                color: theme.accentSolid,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your document.\nA little clearer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              documentTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: theme.textSecondary,
                ),
                Text(
                  'Private · Offline · Sources you can open',
                  style: TextStyle(color: theme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
