class QuizQuestion {
  const QuizQuestion({required this.question, required this.options, required this.correctIndex, required this.explanation, required this.page});
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int page;
}

class QuizParser {
  const QuizParser();

  List<QuizQuestion> parse(String output, Set<int> pages) {
    final questions = <QuizQuestion>[];
    final pattern = RegExp(r'Q:\s*(.*?)\|\s*A:\s*(.*?)\|\s*B:\s*(.*?)\|\s*C:\s*(.*?)\|\s*KEY:\s*([ABC])\s*\|\s*WHY:\s*(.*?)\|\s*PAGE:\s*(\d+)', caseSensitive: false, dotAll: true);
    for (final match in pattern.allMatches(output.replaceAll('**', ''))) {
      final question = match[1]!.trim();
      final options = [match[2]!.trim(), match[3]!.trim(), match[4]!.trim()];
      final explanation = match[6]!.trim();
      final page = int.parse(match[7]!);
      if (question.isEmpty || explanation.isEmpty || options.any((o) => o.isEmpty) || options.map((o) => o.toLowerCase()).toSet().length != 3 || !pages.contains(page)) continue;
      if (questions.any((q) => q.question.toLowerCase() == question.toLowerCase())) continue;
      questions.add(QuizQuestion(question: question, options: options, correctIndex: 'ABC'.indexOf(match[5]!.toUpperCase()), explanation: explanation, page: page));
      if (questions.length == 2) break;
    }
    return questions;
  }
}
