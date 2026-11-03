import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../routing/app_router.dart';
import '../../chat/domain/chat_message.dart';
import '../../library/providers/library_provider.dart';
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
    final theme = Theme.of(context).extension<AppThemeData>() ??
        AppThemeData.midnight();
    final documents = ref.watch(libraryProvider).readyDocuments;
    final ids = documents.map((d) => d.id).toSet();
    final leftId = ids.contains(_leftId) ? _leftId : null;
    final rightId = ids.contains(_rightId) ? _rightId : null;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('Compare documents')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Two sources. One question.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Compare retrieved passages side by side. Differences in wording are not automatically factual conflicts.',
              style: TextStyle(color: theme.textSecondary)),
          const SizedBox(height: 20),
          if (documents.length < 2)
            FilledButton(
              onPressed: () => context.go(AppRoutes.library),
              child: const Text('Import at least two processed PDFs'),
            )
          else ...[
            for (final isLeft in [true, false]) ...[
              DropdownButtonFormField<int>(
                value: isLeft ? leftId : rightId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isLeft ? 'First document' : 'Second document',
                  border: const OutlineInputBorder(),
                ),
                items: documents.map((doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc.title, overflow: TextOverflow.ellipsis),
                )).toList(),
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
              onPressed: leftId == null || rightId == null ||
                  leftId == rightId ? null : () {
                final question = _question.text.trim();
                if (question.isEmpty) return;
                setState(() => _request = (
                  leftId: leftId,
                  rightId: rightId,
                  question: question,
                ));
              },
            ),
            if (_request != null) ...[
              const SizedBox(height: 24),
              ref.watch(compareDocumentsProvider(_request!)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Text(
                    'Comparison failed. Please try again.'),
                data: (result) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (result.status) {
                      ComparisonStatus.sharedWording => 'Similar wording',
                      ComparisonStatus.differingWording => 'Different wording',
                      ComparisonStatus.missingEvidence => 'Insufficient evidence',
                    }, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: theme.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(result.explanation,
                        style: TextStyle(color: theme.textSecondary)),
                    const SizedBox(height: 16),
                    _SourcePassages(title: 'First document',
                        documentId: _request!.leftId,
                        citations: result.leftCitations),
                    _SourcePassages(title: 'Second document',
                        documentId: _request!.rightId,
                        citations: result.rightCitations),
                  ],
                ),
              ),
            ],
          ],
        ],
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
    final theme = Theme.of(context).extension<AppThemeData>() ??
        AppThemeData.midnight();
    return Card(
      color: theme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: theme.textPrimary,
                fontWeight: FontWeight.bold)),
            if (citations.isEmpty)
              const Text('No matching passages retrieved.'),
            for (final citation in citations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Page ${citation.pageNumber}'),
                subtitle: Text(citation.text),
                trailing: const Icon(Icons.open_in_new),
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
