import '../../chat/domain/chat_message.dart';

enum ClaimVerdict { supported, contradicted, insufficientEvidence }

class ClaimVerification {
  const ClaimVerification({
    required this.claim,
    required this.verdict,
    required this.explanation,
    this.citations = const [],
  });

  final String claim;
  final ClaimVerdict verdict;
  final String explanation;
  final List<Citation> citations;
}

/// Splits user-supplied answers into bounded, reviewable sentences.
/// This is a deterministic first pass, not semantic atomic-claim extraction.
class ClaimExtractor {
  const ClaimExtractor();

  static const int maxClaims = 6;

  List<String> extract(String answer) {
    final cleaned = answer
        .replaceAll(RegExp(r'\[Page\s*\d+\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '')
        .trim();
    if (cleaned.isEmpty) return const [];

    final parts = cleaned.split(RegExp(r'(?<=[.!?])\s+|\n+'));
    return parts.map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(maxClaims)
        .toList();
  }
}

/// Strict parser for a bounded local-model response.
/// Only exact verdict tokens are accepted, and only retrieved pages can
/// become citations. Invalid output abstains rather than inventing evidence.
class ClaimVerdictParser {
  const ClaimVerdictParser();

  ClaimVerification parse({
    required String claim,
    required String modelOutput,
    required List<Citation> availableCitations,
  }) {
    final lines = modelOutput.trim().split('\n');
    final verdictLine = lines.where((line) =>
        line.trim().startsWith('VERDICT:')).toList();
    if (verdictLine.length != 1) {
      return _abstain(claim, 'The local model did not return a valid verdict.');
    }
    final token = verdictLine.single.trim().substring('VERDICT:'.length).trim();
    final verdict = switch (token) {
      'SUPPORTED' => ClaimVerdict.supported,
      'CONTRADICTED' => ClaimVerdict.contradicted,
      'INSUFFICIENT_EVIDENCE' => ClaimVerdict.insufficientEvidence,
      _ => null,
    };
    if (verdict == null) {
      return _abstain(claim, 'The local model returned an unrecognized verdict.');
    }

    final explanations = lines.where((line) =>
        line.trim().startsWith('REASON:')).toList();
    final reason = explanations.length == 1
        ? explanations.single.trim().substring('REASON:'.length).trim()
        : '';
    final pageLines = lines.where((line) =>
        line.trim().startsWith('PAGES:')).toList();
    if (reason.isEmpty || pageLines.length != 1) {
      return _abstain(claim, 'The local model did not provide a complete explanation.');
    }

    final rawPages = pageLines.single.trim().substring('PAGES:'.length).trim();
    final pages = <int>{};
    if (rawPages != 'NONE') {
      for (final part in rawPages.split(',')) {
        final page = int.tryParse(part.trim());
        if (page == null) {
          return _abstain(claim, 'The local model returned invalid page references.');
        }
        pages.add(page);
      }
    }

    final matched = availableCitations.where((citation) =>
        pages.contains(citation.pageNumber) &&
        citation.text.trim().isNotEmpty).toList();
    if (pages.length != matched.map((citation) => citation.pageNumber).toSet().length) {
      return _abstain(claim, 'The local model cited a page outside the retrieved evidence.');
    }
    if (verdict != ClaimVerdict.insufficientEvidence && matched.isEmpty) {
      return _abstain(claim, 'No source passage was cited for the model verdict.');
    }
    return ClaimVerification(
      claim: claim,
      verdict: verdict,
      explanation: reason,
      citations: matched,
    );
  }

  ClaimVerification _abstain(String claim, String reason) =>
      ClaimVerification(
        claim: claim,
        verdict: ClaimVerdict.insufficientEvidence,
        explanation: reason,
      );
}
