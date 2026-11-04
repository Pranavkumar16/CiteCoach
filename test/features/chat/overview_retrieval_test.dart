import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';
import 'package:citecoach/features/processing/data/bm25_service.dart';

void main() {
  test(
    'suggested overview questions do not depend on matching generic keywords',
    () {
      for (final question in [
        'What is the main topic?',
        'What is this document about?',
        'Summarize the key points.',
        'What are the main arguments?',
      ]) {
        expect(RagService.isOverviewQuery(question), isTrue);
      }
      expect(
        RagService.isOverviewQuery('What is the termination fee?'),
        isFalse,
      );
      expect(RagService.isOverviewQuery('Summarize section 3'), isFalse);
    },
  );
  test(
    'overview uses bounded evidence across source pages without invented content',
    () {
      final chunks = List.generate(
        10,
        (i) => IndexableChunk(
          id: i,
          text: List.filled(1000, 'evidence$i ').join(),
          pageNumber: i + 1,
          chunkIndex: i,
          startOffset: 0,
          endOffset: 10000,
        ),
      );
      final bm25 = BM25Service();
      final result = RagService(
        null,
        bm25,
      ).buildOverview(bm25.buildIndex(chunks));
      expect(result.isSuccess, isTrue);
      expect(
        result.context.length,
        lessThanOrEqualTo(RagService.maxContextTokens * 4),
      );
      expect(result.citations.first.pageNumber, 1);
      expect(result.citations.last.pageNumber, 10);
      expect(result.citations.length, 5);
      for (final citation in result.citations) {
        expect(result.context, contains('[Page ${citation.pageNumber}]'));
        expect(
          chunks[citation.pageNumber - 1].text,
          contains(citation.text.replaceAll('...', '')),
        );
      }
    },
  );
}
