import '../../chat/domain/chat_message.dart';

/// Conservative evidence labels. Lexical matches are not proof of truth.
enum EvidenceStatus { matchingPassage, relatedPassage, insufficientEvidence }

class EvidenceAssessment {
  const EvidenceAssessment({
    required this.claim,
    required this.status,
    required this.explanation,
    this.citations = const [],
  });

  final String claim;
  final EvidenceStatus status;
  final String explanation;
  final List<Citation> citations;
}

/// Deterministic, offline evidence screening.
/// Does not infer entailment or contradiction from keyword overlap.
class EvidenceAssessmentService {
  const EvidenceAssessmentService();

  static final RegExp _tokens = RegExp(r'[a-z0-9]+');
  static const _stopWords = <String>{
    'the', 'and', 'for', 'with', 'that', 'this', 'from', 'are',
    'was', 'were', 'has', 'have', 'had', 'into', 'its', 'but',
    'not', 'can', 'will', 'which', 'about', 'than', 'then',
  };

  List<String> _terms(String value) => _tokens
      .allMatches(value.toLowerCase())
      .map((match) => match.group(0)!)
      .where((term) => term.length > 2 && !_stopWords.contains(term))
      .toSet()
      .toList();

  EvidenceAssessment assess(String claim, List<Citation> passages) {
    final normalized = claim.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) {
      return const EvidenceAssessment(
        claim: '',
        status: EvidenceStatus.insufficientEvidence,
        explanation: 'Enter a claim to inspect its source evidence.',
      );
    }

    final usable = passages.where((citation) => citation.text.trim().isNotEmpty).toList();
    // Never treat a citation without its source text as evidence.
    if (usable.isEmpty) {
      return EvidenceAssessment(
        claim: claim,
        status: EvidenceStatus.insufficientEvidence,
        explanation: 'No readable source passages were retrieved.',
      );
    }

    final exact = usable.where((citation) =>
        citation.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ')
            .contains(normalized)).toList();
    if (exact.isNotEmpty) {
      return EvidenceAssessment(
        claim: claim,
        status: EvidenceStatus.matchingPassage,
        explanation: 'The claim wording appears in the cited passage. This does not independently establish that the claim is true.',
        citations: exact,
      );
    }

    final terms = _terms(claim);
    if (terms.length < 2) {
      return EvidenceAssessment(
        claim: claim,
        status: EvidenceStatus.insufficientEvidence,
        explanation: 'Not enough distinctive claim terms to assess source relevance.',
      );
    }

    final ranked = usable.map((citation) {
      final sourceTerms = _terms(citation.text).toSet();
      final overlap = terms.where(sourceTerms.contains).length;
      return (citation: citation, overlap: overlap);
    }).where((item) => item.overlap >= 2 &&
        item.overlap / terms.length >= 0.5).toList()
      ..sort((a, b) => b.overlap.compareTo(a.overlap));

    if (ranked.isNotEmpty) {
      return EvidenceAssessment(
        claim: claim,
        status: EvidenceStatus.relatedPassage,
        explanation: 'Related wording was found, but support or contradiction has not been established. Read the passage before relying on the claim.',
        citations: ranked.take(3).map((item) => item.citation).toList(),
      );
    }

    return EvidenceAssessment(
      claim: claim,
      status: EvidenceStatus.insufficientEvidence,
      explanation: 'No sufficiently related source passage was found. This is not proof that the claim is false.',
    );
  }
}
