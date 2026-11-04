import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';
import '../domain/quiz_question.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _topic = TextEditingController();
  int? _documentId;
  ({int documentId, String topic})? _request;
  int _index = 0;
  final Map<int, int> _answers = {};
  bool _finished = false;

  void _reset() {
    _index = 0;
    _answers.clear();
    _finished = false;
  }

  @override
  void dispose() { _topic.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(libraryProvider).readyDocuments;
    final selected = docs.any((d) => d.id == _documentId) ? _documentId : (docs.length == 1 ? docs.first.id : null);
    final busy = _request != null && ref.watch(quizProvider(_request!)).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz yourself')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Put your knowledge to the test', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('AI questions from your PDF, with explanations and source pages. Your score is for practice.'),
        const SizedBox(height: 24),
        if (docs.isEmpty) FilledButton(onPressed: () => context.go(AppRoutes.library), child: const Text('Import a PDF'))
        else ...[
          DropdownButtonFormField<int>(value: selected, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Quiz document', border: OutlineInputBorder()),
            items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.title, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: busy ? null : (id) => setState(() { _documentId = id; _request = null; _reset(); })),
          const SizedBox(height: 16),
          TextField(controller: _topic, maxLength: 150, decoration: const InputDecoration(labelText: 'Topic', hintText: 'For example: supervised learning', border: OutlineInputBorder())),
          FilledButton.icon(onPressed: selected == null || busy ? null : () => setState(() {
            _reset();
            _request = (documentId: selected, topic: _topic.text.trim().isEmpty ? 'Summarize this document' : _topic.text.trim());
            ref.invalidate(quizProvider(_request!));
          }), icon: const Icon(Icons.quiz_outlined), label: const Text('Create quiz')),
        ],
        if (_request != null) ...[
          const SizedBox(height: 24),
          ref.watch(quizProvider(_request!)).when(
            loading: () => const Column(children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Creating questions from your PDF…')]),
            error: (error, stack) => Column(children: [Text(error.toString().replaceFirst('Bad state: ', '')), TextButton(onPressed: () => ref.invalidate(quizProvider(_request!)), child: const Text('Try again'))]),
            data: (questions) => _finished ? _results(questions) : _question(questions),
          ),
        ],
      ]),
    );
  }

  Widget _results(List<QuizQuestion> questions) {
    final score = _answers.entries.where((e) => questions[e.key].correctIndex == e.value).length;
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Icon(Icons.emoji_events_outlined, size: 48),
      const SizedBox(height: 16),
      Text('$score / ${questions.length}', style: Theme.of(context).textTheme.displaySmall),
      const Text('Quiz complete. Keep practising!'),
      TextButton(onPressed: () => setState(_reset), child: const Text('Practise these questions again')),
    ])));
  }

  Widget _question(List<QuizQuestion> questions) {
    final q = questions[_index];
    final answer = _answers[_index];
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('QUESTION ${_index + 1} OF ${questions.length}'),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: _answers.length / questions.length),
      const SizedBox(height: 24),
      Text(q.question, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      for (var i = 0; i < q.options.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: OutlinedButton(
        onPressed: answer == null ? () => setState(() => _answers[_index] = i) : null,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
          Text('${'ABC'[i]}. '), Expanded(child: Text(q.options[i])),
          if (answer != null && i == q.correctIndex) const Icon(Icons.check_circle_outline, semanticLabel: 'Correct answer'),
          if (answer == i && i != q.correctIndex) const Icon(Icons.cancel_outlined, semanticLabel: 'Your answer'),
        ])),
      )),
      if (answer != null) ...[
        Text(answer == q.correctIndex ? 'Correct!' : 'Correct answer: ${q.options[q.correctIndex]}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8), Text(q.explanation),
        TextButton.icon(onPressed: () => context.push('${AppRoutes.documentReader(_request!.documentId.toString())}?page=${q.page}'), icon: const Icon(Icons.menu_book_outlined), label: Text('Check source · page ${q.page}')),
        FilledButton(onPressed: () => setState(() { if (_index + 1 < questions.length) { _index++; } else { _finished = true; } }), child: Text(_index + 1 < questions.length ? 'Next question' : 'See results')),
      ],
      const SizedBox(height: 12), const Text('AI questions may contain mistakes. Check the cited pages.'),
    ])));
  }
}
