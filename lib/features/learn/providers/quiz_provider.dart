import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/data/llm_service.dart';
import '../../chat/data/rag_service.dart';
import '../domain/quiz_question.dart';

final generateQuizProvider = FutureProvider.autoDispose.family<
    List<QuizQuestion>, ({int documentId, String topic})>((ref, request) async {
  final evidence = await ref.read(ragServiceProvider)
      .retrieve(request.documentId, request.topic).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('PDF search took too long. Please retry.'),
      );
  if (!evidence.isSuccess || evidence.citations.isEmpty) {
    throw Exception('No matching passages found. Choose a topic covered in this PDF.');
  }
  final pages = evidence.citations.map((c) => c.pageNumber).toSet();
  final result = await ref.read(llmServiceProvider).generate(
    query: 'Create two short multiple-choice questions about "${request.topic}". '
        'Each has four distinct options, one correct answer, and a source page. '
        'Use only pages ${pages.join(', ')}. '
        'One question per line: Q: question | A: option | B: option | C: option | D: option | KEY: letter | PAGE: number. '
        'Keep each option under six words. Use only supplied evidence for the correct answer.',
    retrievalResult: evidence,
    responseInstructions: 'Create a multiple-choice quiz using ONLY the document excerpts. '
        'Output only the requested Q: | A: | B: | C: | D: | KEY: | PAGE: format. '
        'No headings or prose. Exactly one option must be correct.',
  );
  if (!result.isSuccess) {
    throw Exception(result.error ?? 'Offline AI returned no quiz. Please retry.');
  }
  final questions = const QuizParser().parse(result.response, pages);
  if (questions.isEmpty) {
    throw Exception('The AI could not create a valid quiz. Retry with a specific topic.');
  }
  return questions;
});
