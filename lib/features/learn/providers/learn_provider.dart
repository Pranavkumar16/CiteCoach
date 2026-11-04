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
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'learn.cards.v2.${request.documentId}.${Uri.encodeComponent(request.topic.trim().toLowerCase())}';
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final decoded = jsonDecode(cached) as List<dynamic>;
      final cards = decoded.map((item) {
        final row = item as Map<String, dynamic>;
        return StudyCard(question: row['question'] as String,
            answer: row['answer'] as String, page: row['page'] as int, isSourceRecall: row['sourceRecall'] == true);
      }).toList();
      if (cards.isNotEmpty) return cards;
    } catch (_) {
      await prefs.remove(cacheKey);
    }
  }
  final retrieval = await ref.read(ragServiceProvider)
      .retrieve(request.documentId, request.topic);
  if (!retrieval.isSuccess || retrieval.citations.isEmpty) {
    throw StateError('No matching PDF text was found. Try a topic present in the document, or use Document overview.');
  }
  final pages = retrieval.citations.map((c) => c.pageNumber).toSet();
  final result = await ref.read(llmServiceProvider).generate(
    query: '''
Create two short study flashcards about "${request.topic}" using ONLY the supplied excerpts.
Each card must be exactly one line in this format:
Q: question | A: short answer | PAGE: number
Use only these page numbers: ${pages.join(', ')}.
Do not include headings, markdown or invented facts.
''',
    retrievalResult: retrieval,
  );
  var cards = result.isSuccess ? ref.read(studyCardParserProvider).parse(result.response, pages) : <StudyCard>[];
  // A clearly labelled extractive fallback, never invented Q&A or fake citations.
  if (cards.isEmpty) {
    final seenPages = <int>{};
    cards = retrieval.citations.where((c) => c.text.trim().isNotEmpty && seenPages.add(c.pageNumber)).take(5)
      .map((c) => StudyCard(question: 'Recall the source passage on page ${c.pageNumber}',
        answer: c.text, page: c.pageNumber, isSourceRecall: true)).toList();
  }
  if (cards.isEmpty) throw StateError(result.error ?? 'No usable source passages were found in the PDF.');
  if (cards.isNotEmpty) {
    await prefs.setString(cacheKey, jsonEncode(cards.map((card) => {
      'question': card.question, 'answer': card.answer, 'page': card.page, 'sourceRecall': card.isSourceRecall,
    }).toList()));
  }
  return cards;
});
