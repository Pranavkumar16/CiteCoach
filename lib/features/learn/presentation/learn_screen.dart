import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';
import '../data/study_progress_store.dart';
import '../domain/study_card.dart';
import '../providers/learn_provider.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  final _topic = TextEditingController();
  final _store = const StudyProgressStore();
  int? _documentId;
  ({int documentId, String topic})? _request;
  final Set<int> _revealed = {};
  int _activeCard = 0;
  Set<String> _known = {};
  bool _progressLoading = false;

  String _cardKey(StudyCard card) => '${card.page}:${card.question}';

  Future<void> _start(int documentId, String topic) async {
    setState(() {
      _request = (documentId: documentId, topic: topic);
      _revealed.clear();
      _activeCard = 0;
      _known = {};
      _progressLoading = true;
    });
    try {
      final saved = await _store.load(documentId, topic);
      if (!mounted || _request?.documentId != documentId ||
          _request?.topic != topic) return;
      setState(() => _known = saved);
    } finally {
      if (mounted && _request?.documentId == documentId &&
          _request?.topic == topic) {
        setState(() => _progressLoading = false);
      }
    }
  }

  Future<void> _toggle(StudyCard card, bool remembered) async {
    final request = _request;
    if (request == null) return;
    setState(() {
      if (remembered) {
        _known.add(_cardKey(card));
      } else {
        _known.remove(_cardKey(card));
      }
    });
    await _store.save(request.documentId, request.topic, _known);
  }

  Future<void> _clear() async {
    final request = _request;
    if (request == null) return;
    await _store.clear(request.documentId, request.topic);
    if (mounted && _request == request) {
      setState(() => _known.clear());
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Widget _buildStudyCard(BuildContext context, StudyCard card, int index, int total) {
    final revealed = _revealed.contains(index);
    final remembered = _known.contains(_cardKey(card));
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(revealed ? Icons.lightbulb_outline : Icons.psychology_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text('QUESTION ${index + 1} OF $total', style: theme.textTheme.labelLarge),
            const Spacer(),
            if (remembered) const Icon(Icons.check_circle_outline, semanticLabel: 'Remembered'),
          ]),
          const SizedBox(height: 28),
          Semantics(header: true, child: Text(card.question, style: theme.textTheme.headlineSmall)),
          const SizedBox(height: 28),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: revealed ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Divider(),
              const SizedBox(height: 12),
              Text('ANSWER', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 12),
              Text(card.answer, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('${AppRoutes.documentReader(_request!.documentId.toString())}?page=${card.page}'),
                icon: const Icon(Icons.menu_book_outlined), label: Text('Check source · page ${card.page}')),
              const SizedBox(height: 12),
              Text('How did you do?', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(label: const Text('Study again'), selected: !remembered, onSelected: (_) => _toggle(card, false)),
                ChoiceChip(label: const Text('Got it'), selected: remembered, onSelected: (_) => _toggle(card, true)),
              ]),
              TextButton(onPressed: () => setState(() => _revealed.remove(index)), child: const Text('Hide answer')),
            ]) : Column(children: [
              const Text('Try answering before you reveal.'),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => setState(() => _revealed.add(index)),
                icon: const Icon(Icons.visibility_outlined), label: const Text('Reveal answer'))),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(libraryProvider).readyDocuments;
    final selected = docs.any((d) => d.id == _documentId) ? _documentId : (docs.length == 1 ? docs.first.id : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Make knowledge stick',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Turn your PDF into AI-generated questions. Think of your answer, reveal it, then check the source. Works offline after AI setup.'),
          const SizedBox(height: 20),
          if (docs.isEmpty)
            FilledButton(
              onPressed: () => context.go(AppRoutes.library),
              child: const Text('Import a processed PDF'),
            )
          else ...[
            DropdownButtonFormField<int>(
              value: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Study document', border: OutlineInputBorder()),
              items: docs.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text(d.title, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (id) => setState(() {
                _documentId = id;
                _request = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topic,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Study topic',
                hintText: 'Leave blank for a document overview',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton.icon(
              onPressed: selected == null ? null : () {
                final topic = _topic.text.trim();
                _start(selected, topic.isEmpty ? 'Summarize this document' : topic);
              },
              icon: const Icon(Icons.auto_stories),
              label: const Text('Generate flashcards'),
            ),
            if (_request != null) ...[
              const SizedBox(height: 20),
              if (_progressLoading)
                const Center(child: CircularProgressIndicator())
              else
                ref.watch(generateStudyCardsProvider(_request!)).when(
                  loading: () => const Padding(padding: EdgeInsets.all(32), child: Column(children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Creating questions from your PDF…'), SizedBox(height: 8), Text('You can study offline once AI setup is complete.')])),
                  error: (error, stack) => Column(children: [Text(error.toString().replaceFirst('Bad state: ', '')), TextButton(onPressed: () => ref.invalidate(generateStudyCardsProvider(_request!)), child: const Text('Try again'))]),
                  data: (cards) => cards.isEmpty
                      ? const Text('No valid cited cards generated. Try another topic.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${cards.where((c) => _known.contains(_cardKey(c))).length} of ${cards.length} remembered'),
                            TextButton(
                              onPressed: _clear,
                              child: const Text('Reset progress for this topic'),
                            ),
                            LinearProgressIndicator(value: cards.where((c) => _known.contains(_cardKey(c))).length / cards.length),
                            const SizedBox(height: 20),
                            _buildStudyCard(context, cards[_activeCard.clamp(0, cards.length - 1)], _activeCard.clamp(0, cards.length - 1), cards.length),
                            const SizedBox(height: 16),
                            Row(children: [
                              OutlinedButton.icon(
                                onPressed: _activeCard > 0 ? () => setState(() => _activeCard--) : null,
                                icon: const Icon(Icons.arrow_back), label: const Text('Previous')),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: _activeCard < cards.length - 1 ? () => setState(() => _activeCard++) : null,
                                icon: const Icon(Icons.arrow_forward), label: const Text('Next')),
                            ]),
                            const SizedBox(height: 20),
                            const Text('AI-generated cards may contain mistakes. Check the cited pages.'),
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
