import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/compare/domain/document_comparison.dart';

void main() {
  const analyzer = DocumentComparisonAnalyzer();

  Citation citation(String text, {int page = 1}) =>
      Citation(pageNumber: page, chunkIndex: 0, text: text);

  test('abstains if either document has no readable evidence', () {
    final result = analyzer.compare(
      question: 'deadline',
      left: [citation('Deadline is Friday')],
      right: [],
    );
    expect(result.status, ComparisonStatus.missingEvidence);
  });

  test('detects identical retrieved wording', () {
    final result = analyzer.compare(
      question: 'deadline',
      left: [citation('The deadline is Friday 12 June.')],
      right: [citation('The deadline is Friday 12 June.', page: 2)],
    );
    expect(result.status, ComparisonStatus.sharedWording);
    expect(result.rightCitations.single.pageNumber, 2);
  });

  test('flags differing wording without claiming contradiction', () {
    final result = analyzer.compare(
      question: 'policy',
      left: [citation('Customers receive refunds within thirty days.')],
      right: [citation('The delivery address may be updated online.')],
    );
    expect(result.status, ComparisonStatus.differingWording);
    expect(result.explanation, contains('Inspect both sources'));
  });

  test('does not treat blank citation text as evidence', () {
    final result = analyzer.compare(
      question: 'policy',
      left: [citation('  ')],
      right: [citation('A cancellation policy exists.')],
    );
    expect(result.status, ComparisonStatus.missingEvidence);
  });
}
