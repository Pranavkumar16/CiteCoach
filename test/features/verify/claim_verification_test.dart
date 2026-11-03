import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/verify/domain/claim_verification.dart';

void main() {
  const extractor = ClaimExtractor();
  const parser = ClaimVerdictParser();
  const citation = Citation(pageNumber: 4, chunkIndex: 0,
      text: 'The deadline is 12 June.');

  test('extracts multiple sentences and removes inline citations', () {
    expect(extractor.extract('Deadline is June. [Page 4] Budget is fixed.'),
        ['Deadline is June.', 'Budget is fixed.']);
  });

  test('limits the number of claims', () {
    final input = List.generate(12, (index) => 'Claim $index.').join(' ');
    expect(extractor.extract(input), hasLength(ClaimExtractor.maxClaims));
  });

  test('parses a supported claim with a retrieved citation', () {
    final result = parser.parse(
      claim: 'The deadline is 12 June.',
      modelOutput: 'VERDICT: SUPPORTED\nREASON: The source states this date.\nPAGES: 4',
      availableCitations: [citation],
    );
    expect(result.verdict, ClaimVerdict.supported);
    expect(result.citations.single.pageNumber, 4);
  });

  test('parses a contradiction with retrieved evidence', () {
    final result = parser.parse(
      claim: 'The deadline is 13 June.',
      modelOutput: 'VERDICT: CONTRADICTED\nREASON: The source says 12 June.\nPAGES: 4',
      availableCitations: [citation],
    );
    expect(result.verdict, ClaimVerdict.contradicted);
  });

  test('rejects fabricated citation pages', () {
    final result = parser.parse(
      claim: 'A claim',
      modelOutput: 'VERDICT: SUPPORTED\nREASON: Stated.\nPAGES: 99',
      availableCitations: [citation],
    );
    expect(result.verdict, ClaimVerdict.insufficientEvidence);
    expect(result.citations, isEmpty);
  });

  test('abstains on malformed model output', () {
    final result = parser.parse(
      claim: 'A claim', modelOutput: 'Definitely true!',
      availableCitations: [citation],
    );
    expect(result.verdict, ClaimVerdict.insufficientEvidence);
  });

  test('abstains when positive verdict lacks citations', () {
    final result = parser.parse(
      claim: 'A claim',
      modelOutput: 'VERDICT: SUPPORTED\nREASON: Yes.\nPAGES: NONE',
      availableCitations: [citation],
    );
    expect(result.verdict, ClaimVerdict.insufficientEvidence);
  });
}
