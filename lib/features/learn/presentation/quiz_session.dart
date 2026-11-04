import 'package:flutter/material.dart';
import '../../../core/widgets/glass_surface.dart';
import '../domain/quiz_question.dart';

class QuizSession extends StatefulWidget {
  const QuizSession({super.key, required this.questions, required this.onSource});
  final List<QuizQuestion> questions;
  final ValueChanged<int> onSource;

  @override
  State<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends State<QuizSession> {
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    final score = _answers.entries.where(
      (e) => widget.questions[e.key].correctIndex == e.value).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quiz · ${_answers.length} of ${widget.questions.length} answered',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < widget.questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassSurface(
              blur: false,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${i + 1}. ${widget.questions[i].question}',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (var option = 0; option < 4; option++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: ValueKey('quiz-$i-option-$option'),
                        onPressed: _answers.containsKey(i) ? null
                            : () => setState(() => _answers[i] = option),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          '${'ABCD'[option]}. ${widget.questions[i].options[option]}',
                          softWrap: true,
                        ),
                      ),
                    ),
                  if (_answers.containsKey(i)) ...[
                    Text(_answers[i] == widget.questions[i].correctIndex
                        ? 'Correct'
                        : 'Incorrect. Correct answer: ${'ABCD'[widget.questions[i].correctIndex]}. ${widget.questions[i].options[widget.questions[i].correctIndex]}'),
                    TextButton(
                      onPressed: () => widget.onSource(widget.questions[i].page),
                      child: Text('Check source · page ${widget.questions[i].page}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (_answers.length == widget.questions.length) ...[
          Text('Your score: $score / ${widget.questions.length}',
              style: Theme.of(context).textTheme.titleLarge),
          TextButton(
            onPressed: () => setState(_answers.clear),
            child: const Text('Retake quiz'),
          ),
        ],
        const Text('AI-generated questions can contain mistakes. Check the cited PDF pages.'),
      ],
    );
  }
}
