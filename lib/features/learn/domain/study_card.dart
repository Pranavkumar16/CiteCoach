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
    for (final line in output.split('\n')) {
      final fields = line.trim().split(' | ');
      if (fields.length != 3 || !fields[0].startsWith('Q:') ||
          !fields[1].startsWith('A:') || !fields[2].startsWith('PAGE:')) {
        continue;
      }
      final question = fields[0].substring(2).trim();
      final answer = fields[1].substring(2).trim();
      final page = int.tryParse(fields[2].substring(5).trim());
      if (question.isEmpty || answer.isEmpty || page == null ||
          !allowedPages.contains(page)) continue;
      cards.add(StudyCard(question: question, answer: answer, page: page));
      if (cards.length == 5) break;
    }
    return cards;
  }
}
