import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../routing/app_router.dart';
import '../../library/domain/document.dart';
import '../../library/providers/library_provider.dart';

/// The evidence-first landing screen for CiteCoach.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Most recently touched documents first: opened beats merely imported.
  static List<Document> recentDocuments(List<Document> documents,
      {int limit = 6}) {
    final sorted = [...documents]..sort((a, b) =>
        (b.lastOpenedAt ?? b.importedAt)
            .compareTo(a.lastOpenedAt ?? a.importedAt));
    return sorted.take(limit).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    final library = ref.watch(libraryProvider);
    final recent = recentDocuments(library.documents);

    void open(Document document) {
      final id = document.id.toString();
      if (document.isReady) {
        ref.read(libraryProvider.notifier).markDocumentOpened(document.id);
        context.goToChat(id);
      } else if (document.isPending || document.hasError) {
        context.goToProcessing(id);
      } else {
        context.go(AppRoutes.library);
      }
    }

    return Scaffold(
      backgroundColor: theme.background,
      body: GlassBackdrop(
        child: SafeArea(
          bottom: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              GlassPageHeader(
                eyebrow: 'CiteCoach',
                title: 'Every answer,\nbacked by evidence.',
                trailing: GlassIconBadge(
                  icon: Icons.lock_outline_rounded,
                  size: 40,
                  color: theme.success,
                ),
              ),
              const SizedBox(height: 22),
              _AskHero(
                readyCount: library.readyDocuments.length,
                onSubmit: (question) {
                  final ready = recentDocuments(library.readyDocuments, limit: 1);
                  if (ready.isEmpty) {
                    context.go(AppRoutes.library);
                    return;
                  }
                  final document = ready.first;
                  ref.read(libraryProvider.notifier).markDocumentOpened(document.id);
                  context.push(Uri(path: AppRoutes.documentChat(document.id.toString()), queryParameters: {'question': question}).toString());
                },
              ),
              const SizedBox(height: 28),
              GlassSectionLabel(
                'Recent',
                trailing: recent.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => context.go(AppRoutes.library),
                        child: const Text('View all'),
                      ),
              ),
              if (recent.isEmpty)
                _EmptyRecent(onTap: () => context.go(AppRoutes.library))
              else
                SizedBox(
                  height: 148 + 85 * (MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5) - 1),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _RecentCard(
                      document: recent[i],
                      onTap: () => open(recent[i]),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              const GlassSectionLabel('Tools'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 190 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.5),
                children: [
                  _ToolTile(
                    title: 'Verify',
                    subtitle: 'Challenge claims with evidence',
                    icon: Icons.verified_user_outlined,
                    onTap: () => context.push(AppRoutes.verify),
                  ),
                  _ToolTile(
                    title: 'Compare',
                    subtitle: 'Find changes and differences',
                    icon: Icons.layers_outlined,
                    onTap: () => context.push(AppRoutes.compare),
                  ),
                  _ToolTile(
                    title: 'Learn',
                    subtitle: 'Flashcards and offline quizzes',
                    icon: Icons.school_outlined,
                    onTap: () => context.push(AppRoutes.learn),
                  ),
                  _ToolTile(
                    title: 'Library',
                    subtitle: library.documents.isEmpty
                        ? 'Import your first PDF'
                        : '${library.documentCount} document'
                            '${library.documentCount == 1 ? '' : 's'}',
                    icon: Icons.menu_book_outlined,
                    onTap: () => context.go(AppRoutes.library),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary call to action. It scrolls with the page, so it follows the
/// GlassSurface rule and uses tint plus an accent glow instead of blur.
class _AskHero extends StatefulWidget {
  const _AskHero({required this.readyCount, required this.onSubmit});
  final int readyCount;
  final ValueChanged<String> onSubmit;

  @override
  State<_AskHero> createState() => _AskHeroState();
}

class _AskHeroState extends State<_AskHero> {
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _question.text.trim();
    if (question.isNotEmpty) widget.onSubmit(question);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final text = Theme.of(context).textTheme;
    return GlassSurface(
      blur: false,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const GlassIconBadge(icon: Icons.chat_bubble_outline_rounded, filled: true, size: 48),
        const SizedBox(height: 18),
        Text('Ask your documents', style: text.titleLarge?.copyWith(color: theme.textPrimary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(widget.readyCount == 0 ? 'Import a PDF to ask your first question.' : 'Ask your most recent ready document.', style: text.bodyMedium?.copyWith(color: theme.textSecondary)),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('home-question'),
          controller: _question,
          textInputAction: TextInputAction.send,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Your question',
            hintText: 'What is this document about?',
            hintStyle: TextStyle(color: theme.textTertiary),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Open question in chat',
              onPressed: _question.text.trim().isEmpty ? null : _submit,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.document, required this.onTap});
  final Document document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final text = Theme.of(context).textTheme;
    final (label, colour) = document.isReady
        ? ('Ready', theme.success)
        : document.isProcessing
            ? ('Processing', theme.textSecondary)
            : document.hasError
                ? ('Needs attention', theme.error)
                : ('Queued', theme.textTertiary);
    final meta = [
      if (document.pageCount > 0)
        '${document.pageCount} page${document.pageCount == 1 ? '' : 's'}',
      document.addedTimeAgo,
    ].join(' · ');

    return SizedBox(
      width: 200,
      child: GlassSurface(
        blur: false,
        radius: 22,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const GlassIconBadge(
                          icon: Icons.description_outlined, size: 36),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colour.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colour,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: theme.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    return GlassSurface(
      blur: false,
      radius: 22,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading:
            const GlassIconBadge(icon: Icons.upload_file_rounded, size: 40),
        title: Text('No documents yet',
            style: TextStyle(
                color: theme.textPrimary, fontWeight: FontWeight.w700)),
        subtitle: Text('Import a PDF to ask your first question.',
            style: TextStyle(color: theme.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.textTertiary),
        onTap: onTap,
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    final text = Theme.of(context).textTheme;
    return GlassSurface(
      blur: false,
      radius: 22,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassIconBadge(icon: icon, size: 40),
                const Spacer(),
                Text(title,
                    style: text.titleMedium?.copyWith(
                        color: theme.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.bodySmall?.copyWith(color: theme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
