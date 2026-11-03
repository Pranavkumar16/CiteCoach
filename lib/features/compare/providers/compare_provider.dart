import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/rag_service.dart';
import '../domain/document_comparison.dart';

final documentComparisonAnalyzerProvider = Provider<DocumentComparisonAnalyzer>(
  (ref) => const DocumentComparisonAnalyzer(),
);

final compareDocumentsProvider = FutureProvider.autoDispose.family<
    DocumentComparison, ({int leftId, int rightId, String question})>(
  (ref, request) async {
    if (request.leftId == request.rightId) {
      return DocumentComparison(
        question: request.question,
        status: ComparisonStatus.missingEvidence,
        explanation: 'Choose two different documents.',
      );
    }
    final rag = ref.read(ragServiceProvider);
    final left = await rag.retrieve(request.leftId, request.question);
    final right = await rag.retrieve(request.rightId, request.question);
    if (left.error != null || right.error != null) {
      return DocumentComparison(
        question: request.question,
        status: ComparisonStatus.missingEvidence,
        explanation: 'Retrieval could not complete for both documents. Check that both PDFs have been processed.',
      );
    }
    return ref.read(documentComparisonAnalyzerProvider).compare(
      question: request.question,
      left: left.citations,
      right: right.citations,
    );
  },
);
