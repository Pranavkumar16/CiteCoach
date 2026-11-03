import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/verify/domain/claim_evidence_service.dart';

class _FakeRag implements RagService {
  _FakeRag(this.result);
  final RetrievalResult result;
  @override
  Future<RetrievalResult> retrieve(int documentId, String query) async => result;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('blank claim never gets verified', () async {
    final service = ClaimEvidenceService(_FakeRag(RetrievalResult.empty()));
    final result = await service.inspect(1, '  ');
    expect(result.status, EvidenceStatus.insufficientEvidence);
    expect(result.citations, isEmpty);
  });

  test('no retrieved passages means insufficient evidence', () async {
    final service = ClaimEvidenceService(_FakeRag(RetrievalResult.empty()));
    final result = await service.inspect(1, 'Water boils at 100C');
    expect(result.status, EvidenceStatus.insufficientEvidence);
  });

  test('retrieved passage is only possible support, never verified', () async {
    final service = ClaimEvidenceService(_FakeRag(const RetrievalResult(
      context: '[Page 2] Water boils at 100C at sea level.',
      citations: [
        Citation(pageNumber: 2, chunkIndex: 0,
            text: 'Water boils at 100C at sea level.'),
      ],
    )));
    final result = await service.inspect(1, 'Water boils at 100C');
    expect(result.status, EvidenceStatus.possibleSupport);
    expect(result.citations.single.pageNumber, 2);
  });

  test('retrieval failure is surfaced rather than claimed as verified', () async {
    final service = ClaimEvidenceService(
      _FakeRag(RetrievalResult.error('Database unavailable')),
    );
    final result = await service.inspect(1, 'Some claim');
    expect(result.status, EvidenceStatus.retrievalError);
    expect(result.explanation, contains('Database unavailable'));
  });
}
