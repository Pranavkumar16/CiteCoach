import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../chat/data/llm_service.dart';
import '../../chat/data/rag_service.dart';
import '../domain/study_card.dart';

final studyCardParserProvider = Provider<StudyCardParser>(
    (ref) => const StudyCardParser());

final generateStudyCardsProvider = FutureProvider.autoDispose.family<
    List<StudyCard>, ({int documentId, String topic})>((ref, request) async {
  final cancellation = GenerationCancellation();
  ref.onDispose(cancellation.cancel);
  final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
  final cacheKey = 'learn.cards.v2.${request.documentId}.${Uri.encodeComponent(request.topic.trim().toLowerCase())}';
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final decoded = jsonDecode(cached) as List<dynamic>;
      final cards = decoded.map((item) {
        final row = item as Map<String, dynamic>;
        return StudyCard(question: row['question'] as String,
            answer: row['answer'] as String, page: row['page'] as int);
      }).toList();
      if (cards.isNotEmpty) return cards;
    } catch (_) {
      await prefs.remove(cacheKey);
    }
  }
  final retrieval = await ref.read(ragServiceProvider)
      .retrieve(request.documentId, request.topic).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('PDF search took too long. Retry with a specific topic.'),
      );
  if (cancellation.isCancelled) return [];
  if (!retrieval.isSuccess || retrieval.citations.isEmpty) {
    throw Exception('No matching passages found. Choose a topic covered in this PDF.');
  }
  final pages = retrieval.citations.map((c) => c.pageNumber).toSet();
  final result = await ref.read(llmServiceProvider).generate(
    query: '''
Create three short study flashcards about "${request.topic}" using ONLY the supplied excerpts.
Each card must be exactly one line in this format:
Q: question | A: short answer | PAGE: number
Use only these page numbers: ${pages.join(', ')}.
Do not include headings, markdown or invented facts.
''',
    retrievalResult: retrieval,
    cancellation: cancellation,
    responseInstructions: 'You are CiteCoach. Create flashcards using ONLY the supplied excerpts. '
        'Follow the requested Q: question | A: answer | PAGE: number format exactly. '
        'Keep each answer under 20 words. Do not add prose or [Page X] citations.',
  );
  if (!result.isSuccess) {
    throw Exception(result.error ?? 'The AI returned no cards. Please retry.');
  }
  final cards = ref.read(studyCardParserProvider).parse(result.response, pages);
  if (cards.isNotEmpty) {
    await prefs.setString(cacheKey, jsonEncode(cards.map((card) => {
      'question': card.question, 'answer': card.answer, 'page': card.page,
    }).toList()));
  }
  return cards;
});
