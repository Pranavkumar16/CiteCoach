import '../../chat/data/rag_service.dart';
import '../../chat/domain/chat_message.dart';

/// An evidence candidate is not a factual verification.
enum EvidenceStatus { possibleSupport, insufficientEvidence, retrievalError }

class ClaimEvidenceResult {
  const ClaimEvidenceResult({
    required this.claim,
    required this.status,
    required this.citations,
    required this.explanation,
  });

  final String claim;
  final EvidenceStatus status;
  final List<Citation> citations;
  final String explanation;
}

/// Conservative first-stage claim evidence discovery.
///
/// BM25 measures lexical relevance, not truth or contradiction. Never label a
/// claim "verified" solely because the retrieval system found a match.
class ClaimEvidenceService {
  const ClaimEvidenceService(this._rag);

  final RagService _rag;

  Future<ClaimEvidenceResult> inspect(int documentId, String claim) async {
    final trimmed = claim.trim();
    if (trimmed.isEmpty) {
      return const ClaimEvidenceResult(
        claim: '',
        status: EvidenceStatus.insufficientEvidence,
        citations: [],
        explanation: 'Enter a claim to search for supporting passages.',
      );
    }

    final retrieval = await _rag.retrieve(documentId, trimmed);
    if (retrieval.error != null) {
      return ClaimEvidenceResult(
        claim: trimmed,
        status: EvidenceStatus.retrievalError,
        citations: const [],
        explanation: retrieval.error!,
      );
    }
    if (retrieval.citations.isEmpty) {
      return ClaimEvidenceResult(
        claim: trimmed,
        status: EvidenceStatus.insufficientEvidence,
        citations: const [],
        explanation: 'No relevant passages were found in this document. '
            'This does not establish whether the claim is true or false.',
      );
    }

    return ClaimEvidenceResult(
      claim: trimmed,
      status: EvidenceStatus.possibleSupport,
      citations: retrieval.citations,
      explanation: 'These passages may be relevant to your claim. '
          'Read them in context before deciding whether the claim is '
          'supported, contradicted, or still unverified.',
    );
  }
}
