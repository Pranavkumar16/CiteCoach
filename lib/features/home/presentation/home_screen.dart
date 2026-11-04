import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';

/// The evidence-first landing screen for CiteCoach.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).extension<AppThemeData>() ??
        AppThemeData.midnight();
    final library = ref.watch(libraryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
          children: [
            Text('CiteCoach',
                style: textTheme.headlineMedium?.copyWith(
                  color: theme.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Every answer. Backed by evidence.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary)),
            const SizedBox(height: 36),
            Text('What would you like to do?',
                style: textTheme.headlineSmall?.copyWith(
                  color: theme.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.94,
              children: [
                _FeatureCard(
                  title: 'Ask',
                  subtitle: 'Get answers from your documents',
                  icon: Icons.chat_bubble_outline_rounded,
                  background: theme.accentSolid,
                  foreground: Theme.of(context).colorScheme.onPrimary,
                  onTap: () => context.go(AppRoutes.library),
                ),
                _FeatureCard(
                  title: 'Verify',
                  subtitle: 'Challenge claims with evidence',
                  icon: Icons.verified_user_outlined,
                  background: theme.surface,
                  foreground: theme.textPrimary,
                  border: theme.border,
                  onTap: () => context.go(AppRoutes.verify),
                ),
                _FeatureCard(
                  title: 'Compare',
                  subtitle: 'Find changes and differences',
                  icon: Icons.layers_outlined,
                  background: theme.surface,
                  foreground: theme.textPrimary,
                  border: theme.border,
                  onTap: () => context.go(AppRoutes.compare),
                ),
                _FeatureCard(
                  title: 'Learn',
                  subtitle: 'Flashcards and practice quizzes',
                  icon: Icons.school_outlined,
                  background: theme.surface,
                  foreground: theme.textPrimary,
                  border: theme.border,
                  onTap: () => context.go(AppRoutes.learn),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your library',
                    style: textTheme.titleLarge?.copyWith(
                      color: theme.textPrimary, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => context.go(AppRoutes.library),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.surface,
              child: ListTile(
                leading: Icon(Icons.menu_book_outlined,
                    color: theme.accentSolid),
                title: Text(library.documents.isEmpty
                    ? 'No documents yet'
                    : '${library.documentCount} documents ready to explore'),
                subtitle: Text(library.documents.isEmpty
                    ? 'Import a PDF to ask your first question.'
                    : 'Open your library to read or ask questions.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.library),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
    this.onTap,
    this.isPlanned = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onTap;
  final bool isPlanned;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 30),
              const Spacer(),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground)),
              if (isPlanned) ...[
                const SizedBox(height: 6),
                Text('Coming soon',
                    style: TextStyle(color: foreground, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
