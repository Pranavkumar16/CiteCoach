import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../data/study_progress_store.dart';
import '../domain/study_card.dart';
import '../providers/learn_provider.dart';
import '../providers/quiz_provider.dart';
import 'quiz_session.dart';

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
  bool _quiz = false;

  String _cardKey(StudyCard card) => '${card.page}:${card.question}';

  Future<void> _start(int documentId, String topic) async {
    FocusScope.of(context).unfocus();
    ref.invalidate(generateStudyCardsProvider((documentId: documentId, topic: topic)));
    ref.invalidate(generateQuizProvider((documentId: documentId, topic: topic)));
    setState(() {
      _request = (documentId: documentId, topic: topic);
      _revealed.clear();
      _known = {};
      _progressLoading = true;
    });
    try {
      final saved = await _store.load(documentId, topic).timeout(
        const Duration(seconds: 5), onTimeout: () => <String>{});
      if (!mounted ||
          _request?.documentId != documentId ||
          _request?.topic != topic) {
        return;
      }
      setState(() => _known = saved);
    } finally {
      if (mounted &&
          _request?.documentId == documentId &&
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
    final docs = HomeScreen.recentDocuments(ref.watch(libraryProvider).readyDocuments, limit: ref.watch(libraryProvider).readyDocuments.length);
    final selected = docs.any((d) => d.id == _documentId) ? _documentId : (docs.isEmpty ? null : docs.first.id);
    final busy = _request != null && (_quiz
        ? ref.watch(generateQuizProvider(_request!)).isLoading
        : _progressLoading || ref.watch(generateStudyCardsProvider(_request!)).isLoading);
    final disabledReason = selected == null ? 'Choose a document to start' : _topic.text.trim().isEmpty ? 'Enter a topic to study' : null;
    final theme =
        Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
    return Scaffold(
      appBar: AppBar(title: const Text('Learn'), leading: BackButton(onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.home); } })),
      backgroundColor: theme.background,
      body: GlassBackdrop(
        child: SafeArea(
          bottom: true,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const GlassPageHeader(
                eyebrow: 'Learn',
                title: 'Make knowledge stick',
                subtitle:
                    'Study offline with flashcards and quizzes.',
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(label: const Text('Flashcards'), selected: !_quiz,
                  onSelected: busy ? null : (_) => setState(() { _quiz = false; _request = null; })),
                ChoiceChip(label: const Text('Quiz'), selected: _quiz,
                  onSelected: (_) => setState(() { _quiz = true; _request = null; })),
              ]),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                GlassSurface(
                  blur: false,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GlassIconBadge(icon: Icons.school_outlined),
                      const SizedBox(height: 14),
                      Text('Import and process a PDF to start studying.',
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
                      DropdownButtonFormField<int>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Study document',
                            border: OutlineInputBorder()),
                        items: docs
                            .map((d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.title, maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (id) => setState(() {
                          _documentId = id;
                          _request = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _topic,
                        onChanged: (_) => setState(() {}),
                        maxLength: 150,
                        decoration: const InputDecoration(
                          labelText: 'Study topic',
                          hintText: 'e.g. key definitions',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: disabledReason != null || busy
                            ? null
                            : () {
                                final topic = _topic.text.trim();
                                if (topic.isNotEmpty) _start(selected!, topic);
                              },
                        icon: const Icon(Icons.auto_stories),
                        label: Text(_quiz ? 'Generate quiz' : 'Generate flashcards'),
                      ),
                      if (disabledReason != null) Text(disabledReason, style: TextStyle(color: theme.textSecondary)),
                      if (busy) TextButton.icon(
                        onPressed: () => setState(() { _request = null; _progressLoading = false; }),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Stop generation'),
                      ),
                    ],
                  ),
                ),
                if (_request != null) ...[
                  const SizedBox(height: 20),
                  if (_quiz)
                    ref.watch(generateQuizProvider(_request!)).when(
                      loading: () => const Column(children: [
                        CircularProgressIndicator(), SizedBox(height: 12),
                        Text('Creating your quiz with offline AI…'),
                      ]),
                      error: (error, stack) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(error.toString().replaceFirst('Exception: ', '')),
                          TextButton(onPressed: () => ref.invalidate(generateQuizProvider(_request!)),
                            child: const Text('Retry quiz')),
                        ],
                      ),
                      data: (questions) => QuizSession(
                        key: ValueKey((_request, questions)),
                        questions: questions,
                        onSource: (page) => context.push(
                          '${AppRoutes.documentReader(_request!.documentId.toString())}?page=$page'),
                      ),
                    )
                  else if (_progressLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ref.watch(generateStudyCardsProvider(_request!)).when(
                          loading: () =>
                              const Center(child: Column(children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Reading your PDF and running offline AI…'),
                              ])),
                          error: (error, stack) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(error.toString().replaceFirst('Exception: ', '')),
                              TextButton(
                                onPressed: () => ref.invalidate(generateStudyCardsProvider(_request!)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                          data: (cards) => cards.isEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('The AI could not format valid cards. Retry, or choose a more specific topic from this PDF.'),
                                    TextButton(
                                      onPressed: () => ref.invalidate(generateStudyCardsProvider(_request!)),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${cards.where((c) => _known.contains(_cardKey(c))).length} of ${cards.length} remembered'),
                                    TextButton(
                                      onPressed: _clear,
                                      child: const Text(
                                          'Reset progress for this topic'),
                                    ),
                                    for (var i = 0; i < cards.length; i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: GlassSurface(
                                          blur: false,
                                          radius: 20,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(cards[i].question,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 10),
                                              if (_revealed.contains(i)) ...[
                                                Text(cards[i].answer),
                                                TextButton.icon(
                                                  onPressed: () => context.push(
                                                    '${AppRoutes.documentReader(_request!.documentId.toString())}?page=${cards[i].page}',
                                                  ),
                                                  icon: const Icon(
                                                      Icons.menu_book),
                                                  label: Text(
                                                      'Source · page ${cards[i].page}'),
                                                ),
                                                CheckboxListTile(
                                                  value: _known.contains(
                                                      _cardKey(cards[i])),
                                                  title: const Text(
                                                      'I remembered this'),
                                                  onChanged: (value) => _toggle(
                                                      cards[i], value == true),
                                                ),
                                              ] else
                                                TextButton(
                                                  onPressed: () => setState(
                                                      () => _revealed.add(i)),
                                                  child: const Text(
                                                      'Reveal answer'),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const Text(
                                        'AI-generated cards may contain mistakes. Check the cited pages.'),
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
