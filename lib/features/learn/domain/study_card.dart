class StudyCard {
  const StudyCard({required this.question, required this.answer, required this.page});
  final String question;
  final String answer;
  final int page;
}

/// Parses a constrained LLM format, dropping invalid or fabricated references.
class StudyCardParser {
  const StudyCardParser();

  List<StudyCard> parse(String output, Set<int> allowedPages) {
    final cards = <StudyCard>[];
    final pattern = RegExp(
      r'(?:^|\n)\s*(?:[-*]|\d+[.)])?\s*Q(?:uestion)?\s*:\s*(.*?)\s*(?:\|\s*|\n\s*)A(?:nswer)?\s*:\s*(.*?)\s*(?:\|\s*|\n\s*)(?:PAGE\s*:\s*|\[Page\s*)(\d+)\]?(?:[^\n]*)',
      caseSensitive: false,
      dotAll: true,
    );
    final clean = output.replaceAll('**', '');
    final seen = <String>{};
    for (final match in pattern.allMatches(clean)) {
      final question = match.group(1)!.trim();
      final answer = match.group(2)!.trim();
      final page = int.tryParse(match.group(3)!);
      if (question.isEmpty || answer.isEmpty || page == null ||
          !allowedPages.contains(page) || !seen.add(question.toLowerCase())) {
        continue;
      }
      cards.add(StudyCard(question: question, answer: answer, page: page));
      if (cards.length == 5) break;
    }
    return cards;
  }
}
