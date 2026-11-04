import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/data/llm_service.dart';
import '../../chat/data/rag_service.dart';
import '../domain/quiz_question.dart';

final quizProvider = FutureProvider.autoDispose.family<List<QuizQuestion>, ({int documentId, String topic})>((ref, request) async {
  final retrieval = await ref.read(ragServiceProvider).retrieve(request.documentId, request.topic);
  if (!retrieval.isSuccess || retrieval.citations.isEmpty) {
    throw StateError('No matching PDF text found. Choose a topic covered in the document.');
  }
  final pages = retrieval.citations.map((c) => c.pageNumber).toSet();
  final result = await ref.read(llmServiceProvider).generate(
    query: '''Create two short multiple-choice questions about "${request.topic}" from the excerpts.
Use this exact format for each question:
Q: question | A: option | B: option | C: option | KEY: A | WHY: explanation | PAGE: number
KEY must identify the single correct option, A, B or C. Use three distinct, plausible options. Keep options under 5 words and explanations under 15 words.
Use only supplied facts and these source pages: ${pages.join(', ')}. No headings.''',
    retrievalResult: retrieval,
  );
  final questions = result.isSuccess ? const QuizParser().parse(result.response, pages) : <QuizQuestion>[];
  if (questions.isEmpty) throw StateError('Could not create a quiz. Try a specific topic and check that offline AI is ready.');
  return questions;
});
