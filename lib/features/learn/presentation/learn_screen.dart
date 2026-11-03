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
  Set<String> _known = {};
  bool _progressLoading = false;

  String _cardKey(StudyCard card) => '${card.page}:${card.question}';

  Future<void> _start(int documentId, String topic) async {
    setState(() {
      _request = (documentId: documentId, topic: topic);
      _revealed.clear();
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

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(libraryProvider).readyDocuments;
    final selected = docs.any((d) => d.id == _documentId) ? _documentId : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Learn from evidence')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Make knowledge stick',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Generate cited flashcards using your offline AI model. Your remembered cards are saved on this device.'),
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
                hintText: 'e.g. key definitions',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton.icon(
              onPressed: selected == null ? null : () {
                final topic = _topic.text.trim();
                if (topic.isNotEmpty) _start(selected, topic);
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const Text(
                      'Could not generate cards. Check the local AI model.'),
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
                            for (var i = 0; i < cards.length; i++)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cards[i].question,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      if (_revealed.contains(i)) ...[
                                        Text(cards[i].answer),
                                        TextButton.icon(
                                          onPressed: () => context.push(
                                            '${AppRoutes.documentReader(_request!.documentId.toString())}?page=${cards[i].page}',
                                          ),
                                          icon: const Icon(Icons.menu_book),
                                          label: Text('Source · page ${cards[i].page}'),
                                        ),
                                        CheckboxListTile(
                                          value: _known.contains(_cardKey(cards[i])),
                                          title: const Text('I remembered this'),
                                          onChanged: (value) =>
                                              _toggle(cards[i], value == true),
                                        ),
                                      ] else
                                        TextButton(
                                          onPressed: () =>
                                              setState(() => _revealed.add(i)),
                                          child: const Text('Reveal answer'),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
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
