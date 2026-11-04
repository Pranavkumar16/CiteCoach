class StudyCard {
  const StudyCard({required this.question, required this.answer, required this.page, this.isSourceRecall = false});
  final String question;
  final String answer;
  final int page;
  final bool isSourceRecall;
}

/// Parses a constrained LLM format, dropping invalid or fabricated references.
class StudyCardParser {
  const StudyCardParser();

  List<StudyCard> parse(String output, Set<int> allowedPages) {
    final cards = <StudyCard>[];
    final cleaned = output.replaceAll('**', '').replaceAll('`', '');
    final pattern = RegExp(r'Q:\s*(.*?)\s*\|\s*A:\s*(.*?)\s*\|\s*PAGE:\s*(?:\[?Page\s*)?(\d+)', caseSensitive: false, dotAll: true);
    for (final match in pattern.allMatches(cleaned)) {
      final question = match.group(1)!.trim();
      final answer = match.group(2)!.trim();
      final page = int.tryParse(match.group(3)!);
      if (question.isEmpty || answer.isEmpty || page == null ||
          !allowedPages.contains(page)) continue;
      cards.add(StudyCard(question: question, answer: answer, page: page));
      if (cards.length == 5) break;
    }
    return cards;
  }
}
