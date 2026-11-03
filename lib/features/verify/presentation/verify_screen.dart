import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../routing/app_router.dart';
import '../../chat/data/rag_service.dart';
import '../../library/providers/library_provider.dart';
import '../domain/claim_evidence_service.dart';

/// Source-first claim inspection. Retrieval candidates are not verdicts.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _controller = TextEditingController();
  int? _selectedDocumentId;
  ClaimEvidenceResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _inspect() async {
    final documentId = _selectedDocumentId;
    if (documentId == null || _controller.text.trim().isEmpty || _loading) {
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final result = await ClaimEvidenceService(
        ref.read(ragServiceProvider),
      ).inspect(documentId, _controller.text);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(() => _result = ClaimEvidenceResult(
          claim: _controller.text.trim(),
          status: EvidenceStatus.retrievalError,
          citations: const [],
          explanation: 'Unable to inspect this claim: $error',
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppThemeData>() ??
        AppThemeData.midnight();
    final documents = ref.watch(libraryProvider).documents
        .where((document) => document.isReady)
        .toList();
    final selectedId = documents.any((d) => d.id == _selectedDocumentId)
        ? _selectedDocumentId
        : null;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Challenge My Answer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Inspect the evidence',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                )),
            const SizedBox(height: 8),
            Text('Find passages relevant to a claim. A matching passage '
                'is not proof: you make the final judgement.',
                style: TextStyle(color: palette.textSecondary)),
            const SizedBox(height: 24),
            if (documents.isEmpty)
              Card(
                child: ListTile(
                  title: const Text('Import a document first'),
                  subtitle: const Text('Verify searches your indexed PDFs.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.library),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                value: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Source document',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final doc in documents)
                    DropdownMenuItem(value: doc.id,
                        child: Text(doc.title, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (id) => setState(() {
                  _selectedDocumentId = id;
                  _result = null;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Claim to inspect',
                  hintText: 'Paste a statement you want to check...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _result = null),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _inspect,
                icon: _loading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.manage_search_rounded),
                label: Text(_loading ? 'Searching...' : 'Find evidence'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 28),
              Card(
                color: palette.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (_result!.status) {
                          EvidenceStatus.possibleSupport => 'Relevant passages',
                          EvidenceStatus.insufficientEvidence =>
                            'Insufficient evidence',
                          EvidenceStatus.retrievalError => 'Search unavailable',
                        },
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_result!.explanation,
                          style: TextStyle(color: palette.textSecondary)),
                    ],
                  ),
                ),
              ),
              for (final citation in _result!.citations)
                Card(
                  color: palette.surface,
                  child: ListTile(
                    title: Text('Page ${citation.pageNumber}',
                        style: TextStyle(color: palette.textPrimary,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(citation.text,
                        style: TextStyle(color: palette.textSecondary)),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: selectedId == null ? null : () =>
                        context.push('${AppRoutes.documentReader(
                          selectedId.toString(),
                        )}?page=${citation.pageNumber}'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
