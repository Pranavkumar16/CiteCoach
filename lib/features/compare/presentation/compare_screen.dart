import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../routing/app_router.dart';
import '../../chat/domain/chat_message.dart';
import '../../library/providers/library_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/document_comparison.dart';
import '../providers/compare_provider.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final _question = TextEditingController();
  int? _leftId;
  int? _rightId;
  ({int leftId, int rightId, String question})? _request;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    final documents = HomeScreen.recentDocuments(ref.watch(libraryProvider).readyDocuments, limit: ref.watch(libraryProvider).readyDocuments.length);
    final ids = documents.map((d) => d.id).toSet();
    final leftId = ids.contains(_leftId) ? _leftId : (documents.isEmpty ? null : documents.first.id);
    final rightId = ids.contains(_rightId) ? _rightId : (documents.length < 2 ? null : documents[1].id);
    final disabledReason = leftId == null || rightId == null ? 'Choose two documents to start' : leftId == rightId ? 'Choose two different documents' : _question.text.trim().isEmpty ? 'Enter a question to compare' : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare'), leading: BackButton(onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.home); } })),
      backgroundColor: theme.background,
      body: GlassBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const GlassPageHeader(
                eyebrow: 'Compare',
                title: 'Two sources.\nOne question.',
                subtitle:
                    'Compare PDF passages side by side.',
              ),
              const SizedBox(height: 22),
              if (documents.length < 2)
                GlassSurface(
                  blur: false,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlassIconBadge(icon: Icons.layers_outlined),
                      const SizedBox(height: 14),
                      Text('You need at least two processed PDFs to compare.',
                          style: TextStyle(color: theme.textSecondary)),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.library),
                        child: const Text('Open Library'),
                      ),
                    ],
                  ),
                )
              else ...[
                GlassSurface(
                  blur: false,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final isLeft in [true, false]) ...[
                        DropdownButtonFormField<int>(
                          initialValue: isLeft ? leftId : rightId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText:
                                isLeft ? 'First document' : 'Second document',
                            border: const OutlineInputBorder(),
                          ),
                          items: documents
                              .map((doc) => DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(doc.title,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (id) => setState(() {
                            if (isLeft) {
                              _leftId = id;
                            } else {
                              _rightId = id;
                            }
                            _request = null;
                          }),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _question,
                        onChanged: (_) => setState(() {}),
                        maxLines: 3,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'What should we compare?',
                          hintText: 'e.g. What is the cancellation policy?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Compare evidence'),
                        onPressed: disabledReason != null
                            ? null
                            : () {
                                final question = _question.text.trim();
                                if (question.isEmpty) return;
                                setState(() => _request = (
                                      leftId: leftId!,
                                      rightId: rightId!,
                                      question: question,
                                    ));
                              },
                      ),
                      if (disabledReason != null) Text(disabledReason, style: TextStyle(color: theme.textSecondary)),
                    ],
                  ),
                ),
                if (_request != null) ...[
                  const SizedBox(height: 24),
                  ref.watch(compareDocumentsProvider(_request!)).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            const Text('Comparison failed. Please try again.'),
                        data: (result) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Different wording does not prove a factual conflict. Check the sources.', style: TextStyle(color: theme.textSecondary)),
                            const SizedBox(height: 12),
                            Text(
                                switch (result.status) {
                                  ComparisonStatus.sharedWording =>
                                    'Similar wording',
                                  ComparisonStatus.differingWording =>
                                    'Different wording',
                                  ComparisonStatus.missingEvidence =>
                                    'Insufficient evidence',
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(result.explanation,
                                style: TextStyle(color: theme.textSecondary)),
                            const SizedBox(height: 16),
                            _SourcePassages(
                                title: 'First document',
                                documentId: _request!.leftId,
                                citations: result.leftCitations),
                            _SourcePassages(
                                title: 'Second document',
                                documentId: _request!.rightId,
                                citations: result.rightCitations),
                          ],
                        ),
                      ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePassages extends StatelessWidget {
  const _SourcePassages({
    required this.title,
    required this.documentId,
    required this.citations,
  });

  final String title;
  final int documentId;
  final List<Citation> citations;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassSurface(
        blur: false,
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: theme.textPrimary, fontWeight: FontWeight.bold)),
            if (citations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No matching passages retrieved.',
                    style: TextStyle(color: theme.textSecondary)),
              ),
            for (final citation in citations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Page ${citation.pageNumber}',
                    style: TextStyle(
                        color: theme.citation, fontWeight: FontWeight.w700)),
                subtitle: Text(citation.text,
                    style: TextStyle(color: theme.textSecondary)),
                trailing:
                    Icon(Icons.open_in_new_rounded, color: theme.textTertiary),
                onTap: () => context.push(
                  '${AppRoutes.documentReader(documentId.toString())}?page=${citation.pageNumber}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
