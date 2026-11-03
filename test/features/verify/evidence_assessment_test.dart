import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/verify/domain/evidence_assessment.dart';

void main() {
  const service = EvidenceAssessmentService();
  const passage = Citation(
    pageNumber: 3,
    chunkIndex: 1,
    text: 'The project deadline is Friday 12 June.',
  );

  test('exact source wording is labelled a matching passage, not verified truth', () {
    final result = service.assess('project deadline is Friday 12 June', [passage]);
    expect(result.status, EvidenceStatus.matchingPassage);
    expect(result.citations.single.pageNumber, 3);
    expect(result.explanation, contains('does not independently'));
  });

  test('overlap alone cannot assert a claim is supported', () {
    final result = service.assess(
      'The project deadline is Monday 12 June.', [passage]);
    expect(result.status, EvidenceStatus.relatedPassage);
    expect(result.explanation, contains('not been established'));
  });

  test('no source text means insufficient evidence', () {
    final result = service.assess('The project deadline is Friday', [
      const Citation(pageNumber: 3, chunkIndex: 0, text: ''),
    ]);
    expect(result.status, EvidenceStatus.insufficientEvidence);
    expect(result.citations, isEmpty);
  });

  test('unrelated claim cannot be declared false', () {
    final result = service.assess('Saturn has thirty rings', [passage]);
    expect(result.status, EvidenceStatus.insufficientEvidence);
    expect(result.explanation, contains('not proof'));
  });

  test('empty claim is handled safely', () {
    expect(service.assess('   ', [passage]).status,
        EvidenceStatus.insufficientEvidence);
  });
}
