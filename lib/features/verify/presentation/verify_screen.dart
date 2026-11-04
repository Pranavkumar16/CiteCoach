import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/evidence_assessment.dart';
import '../domain/claim_verification.dart';
import '../providers/verify_provider.dart';

/// Phase 1 evidence inspection: inspect retrieved passages without
/// claiming automated truth verification.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _controller = TextEditingController();
  int? _documentId;
  String? _submittedClaim;
  bool _useAi = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    final documents = HomeScreen.recentDocuments(ref.watch(libraryProvider).readyDocuments, limit: ref.watch(libraryProvider).readyDocuments.length);
    final selected = documents.any((document) => document.id == _documentId)
        ? _documentId
        : (documents.isEmpty ? null : documents.first.id);
    final disabledReason = selected == null ? 'Choose a document to start' : _controller.text.trim().isEmpty ? 'Enter a claim to inspect' : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify'), leading: BackButton(onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.home); } })),
      backgroundColor: theme.background,
      body: GlassBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const GlassPageHeader(
                eyebrow: 'Verify',
                title: 'Challenge my answer',
                subtitle:
                    'Check claims against your PDF.',
              ),
              const SizedBox(height: 22),
              if (documents.isEmpty) ...[
                GlassSurface(
                  blur: false,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlassIconBadge(icon: Icons.fact_check_outlined),
                      const SizedBox(height: 14),
                      Text('Import and process a PDF before checking a claim.',
                          style: TextStyle(color: theme.textSecondary)),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.library),
                        child: const Text('Open Library'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                GlassSurface(
                  blur: false,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Source document',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select a document'),
                        items: documents
                            .map((document) => DropdownMenuItem(
                                  value: document.id,
                                  child: Text(document.title,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _documentId = value;
                          _submittedClaim = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                        maxLines: 4,
                        maxLength: 1500,
                        decoration: const InputDecoration(
                          labelText: 'Answer or claims to challenge',
                          hintText: 'Paste a sentence from an answer...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('AI evidence assessment'),
                        subtitle:
                            Text(_useAi ? 'AI checks each claim against the passages' : 'Keyword match only, faster'),
                        value: _useAi,
                        onChanged: (value) => setState(() {
                          _useAi = value;
                          _submittedClaim = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: disabledReason != null
                            ? null
                            : () {
                                final claim = _controller.text.trim();
                                if (claim.isEmpty) return;
                                setState(() => _submittedClaim = claim);
                              },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Inspect evidence'),
                      ),
                      if (disabledReason != null) Text(disabledReason, style: TextStyle(color: theme.textSecondary)),
                    ],
                  ),
                ),
                if (_submittedClaim != null && selected != null) ...[
                  const SizedBox(height: 24),
                  Text('AI can be wrong. Check the cited passages.', style: TextStyle(color: theme.textSecondary)),
                  const SizedBox(height: 12),
                  (_useAi
                      ? ref
                          .watch(verifyAnswerProvider((
                            documentId: selected,
                            answer: _submittedClaim!,
                          )))
                          .when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (error, stack) => Text(
                                'AI assessment failed. Please retry.',
                                style: TextStyle(color: theme.error)),
                            data: (results) => Column(
                              children: [
                                for (final result in results)
                                  _ClaimResultCard(
                                      result: result, documentId: selected),
                              ],
                            ),
                          )
                      : ref
                          .watch(verifyClaimProvider((
                            documentId: selected,
                            claim: _submittedClaim!,
                          )))
                          .when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (error, stack) => Text(
                              'Evidence inspection failed. Please try again.',
                              style: TextStyle(color: theme.error),
                            ),
                            data: (assessment) => _AssessmentView(
                              assessment: assessment,
                              documentId: selected,
                            ),
                          )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssessmentView extends StatelessWidget {
  const _AssessmentView({
    required this.assessment,
    required this.documentId,
  });

  final EvidenceAssessment assessment;
  final int documentId;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    final label = switch (assessment.status) {
      EvidenceStatus.matchingPassage => 'Matching passage found',
      EvidenceStatus.relatedPassage => 'Related passage found',
      EvidenceStatus.insufficientEvidence => 'Insufficient evidence',
    };
    final color = switch (assessment.status) {
      EvidenceStatus.matchingPassage => theme.success,
      EvidenceStatus.relatedPassage => theme.warning,
      EvidenceStatus.insufficientEvidence => theme.error,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(assessment.explanation,
            style: TextStyle(color: theme.textSecondary)),
        const SizedBox(height: 16),
        for (final citation in assessment.citations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              blur: false,
              radius: 20,
              child: ListTile(
                title: Text('Page ${citation.pageNumber}',
                    style: TextStyle(
                        color: theme.textPrimary, fontWeight: FontWeight.w700)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(citation.text,
                      style: TextStyle(color: theme.textSecondary)),
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => context.push(
                  '${AppRoutes.documentReader(documentId.toString())}?page=${citation.pageNumber}',
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
            'Evidence screening is based on text matching and retrieval, not fact-checking or entailment analysis.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: theme.textTertiary)),
      ],
    );
  }
}

class _ClaimResultCard extends StatelessWidget {
  const _ClaimResultCard({required this.result, required this.documentId});

  final ClaimVerification result;
  final int documentId;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    final label = switch (result.verdict) {
      ClaimVerdict.supported => 'Supported by retrieved evidence',
      ClaimVerdict.contradicted => 'Contradicted by retrieved evidence',
      ClaimVerdict.insufficientEvidence => 'Insufficient evidence',
    };
    final color = switch (result.verdict) {
      ClaimVerdict.supported => theme.success,
      ClaimVerdict.contradicted => theme.error,
      ClaimVerdict.insufficientEvidence => theme.warning,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassSurface(
        blur: false,
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.claim,
                style: TextStyle(
                    color: theme.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(result.explanation,
                style: TextStyle(color: theme.textSecondary)),
            for (final citation in result.citations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Page ${citation.pageNumber}',
                    style: TextStyle(color: theme.textPrimary)),
                subtitle: Text(citation.text,
                    style: TextStyle(color: theme.textSecondary)),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => context.push(
                  '${AppRoutes.documentReader(documentId.toString())}?page=${citation.pageNumber}',
                ),
              ),
            Text('AI-generated assessment — check the cited source.',
                style: TextStyle(fontSize: 12, color: theme.textTertiary)),
          ],
        ),
      ),
    );
  }
}
