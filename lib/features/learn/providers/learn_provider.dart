import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/data/llm_service.dart';
import '../../chat/data/rag_service.dart';
import '../domain/study_card.dart';

final studyCardParserProvider = Provider<StudyCardParser>(
    (ref) => const StudyCardParser());

final generateStudyCardsProvider = FutureProvider.autoDispose.family<
    List<StudyCard>, ({int documentId, String topic})>((ref, request) async {
  final retrieval = await ref.read(ragServiceProvider)
      .retrieve(request.documentId, request.topic);
  if (!retrieval.isSuccess || retrieval.citations.isEmpty) return [];
  final pages = retrieval.citations.map((c) => c.pageNumber).toSet();
  final result = await ref.read(llmServiceProvider).generate(
    query: '''
Create up to five study flashcards about "${request.topic}" using ONLY the supplied excerpts.
Each card must be exactly one line in this format:
Q: question | A: short answer | PAGE: number
Use only these page numbers: ${pages.join(', ')}.
Do not include headings, markdown or invented facts.
''',
    retrievalResult: retrieval,
  );
  if (!result.isSuccess) return [];
  return ref.read(studyCardParserProvider).parse(result.response, pages);
});
