import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/rag_service.dart';
import '../domain/evidence_assessment.dart';

final evidenceAssessmentServiceProvider = Provider<EvidenceAssessmentService>(
  (ref) => const EvidenceAssessmentService(),
);

final verifyClaimProvider =
    FutureProvider.autoDispose.family<EvidenceAssessment, ({int documentId, String claim})>(
  (ref, request) async {
    final retrieval = await ref.read(ragServiceProvider)
        .retrieve(request.documentId, request.claim);
    if (retrieval.error != null) {
      return EvidenceAssessment(
        claim: request.claim,
        status: EvidenceStatus.insufficientEvidence,
        explanation: 'Could not inspect document evidence: ${retrieval.error}',
      );
    }
    return ref.read(evidenceAssessmentServiceProvider)
        .assess(request.claim, retrieval.citations);
  },
);
