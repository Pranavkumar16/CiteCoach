class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.page,
  });
  final String question;
  final List<String> options;
  final int correctIndex;
  final int page;
}

class QuizParser {
  const QuizParser();

  List<QuizQuestion> parse(String output, Set<int> allowedPages) {
    final questions = <QuizQuestion>[];
    final clean = output.replaceAll('**', '');
    final pattern = RegExp(
      r'(?:^|\n)\s*(?:\d+[.)]\s*)?Q\s*:\s*(.*?)\s*\|\s*A\s*:\s*(.*?)\s*\|\s*B\s*:\s*(.*?)\s*\|\s*C\s*:\s*(.*?)\s*\|\s*D\s*:\s*(.*?)\s*\|\s*KEY\s*:\s*([A-D])\s*\|\s*PAGE\s*:\s*(\d+)',
      caseSensitive: false,
      dotAll: true,
    );
    final seen = <String>{};
    for (final match in pattern.allMatches(clean)) {
      final question = match.group(1)!.trim();
      final options = [for (var i = 2; i <= 5; i++) match.group(i)!.trim()];
      final page = int.tryParse(match.group(7)!);
      if (question.isEmpty || options.any((o) => o.isEmpty) ||
          options.map((o) => o.toLowerCase()).toSet().length != 4 ||
          !allowedPages.contains(page) ||
          !seen.add(question.toLowerCase())) continue;
      questions.add(QuizQuestion(
        question: question,
        options: options,
        correctIndex: 'ABCD'.indexOf(match.group(6)!.toUpperCase()),
        page: page!,
      ));
      if (questions.length == 2) break;
    }
    return questions;
  }
}
