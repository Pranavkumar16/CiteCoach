import '../../chat/domain/chat_message.dart';

enum ComparisonStatus { sharedWording, differingWording, missingEvidence }

class DocumentComparison {
  const DocumentComparison({
    required this.question,
    required this.status,
    required this.explanation,
    this.leftCitations = const [],
    this.rightCitations = const [],
  });

  final String question;
  final ComparisonStatus status;
  final String explanation;
  final List<Citation> leftCitations;
  final List<Citation> rightCitations;
}

/// A transparent lexical comparison of two sets of retrieved passages.
/// Different wording does not necessarily imply a contradiction or change.
class DocumentComparisonAnalyzer {
  const DocumentComparisonAnalyzer();

  static final RegExp _words = RegExp(r'[a-z0-9]+');
  static const _stopWords = <String>{
    'the', 'and', 'for', 'with', 'that', 'this', 'from', 'are',
    'was', 'were', 'has', 'have', 'had', 'into', 'its', 'but',
    'can', 'will', 'which', 'about', 'than', 'then', 'not',
  };

  Set<String> _terms(String text) => _words.allMatches(text.toLowerCase())
      .map((match) => match.group(0)!)
      .where((term) => term.length > 2 && !_stopWords.contains(term))
      .toSet();

  DocumentComparison compare({
    required String question,
    required List<Citation> left,
    required List<Citation> right,
  }) {
    final a = left.where((c) => c.text.trim().isNotEmpty).take(3).toList();
    final b = right.where((c) => c.text.trim().isNotEmpty).take(3).toList();
    if (a.isEmpty || b.isEmpty) {
      return DocumentComparison(
        question: question,
        status: ComparisonStatus.missingEvidence,
        explanation: 'Readable passages were not retrieved from both documents. No conclusion about differences can be drawn.',
        leftCitations: a,
        rightCitations: b,
      );
    }
    final leftTerms = _terms(a.map((c) => c.text).join(' '));
    final rightTerms = _terms(b.map((c) => c.text).join(' '));
    final union = leftTerms.union(rightTerms);
    final overlap = leftTerms.intersection(rightTerms);
    final similarity = union.isEmpty ? 0.0 : overlap.length / union.length;
    return DocumentComparison(
      question: question,
      status: similarity >= 0.65
          ? ComparisonStatus.sharedWording
          : ComparisonStatus.differingWording,
      explanation: similarity >= 0.65
          ? 'The retrieved passages share much of their distinctive wording. This does not prove the documents agree.'
          : 'The retrieved passages use different wording. Inspect both sources to determine whether a substantive change or contradiction exists.',
      leftCitations: a,
      rightCitations: b,
    );
  }
}
