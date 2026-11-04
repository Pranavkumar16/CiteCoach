import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/core/widgets/generation_progress.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';
import 'package:citecoach/features/processing/data/bm25_service.dart';
import 'package:citecoach/features/learn/domain/study_chapter.dart';
import 'package:citecoach/features/learn/presentation/chapter_selector.dart';
import 'package:citecoach/features/learn/providers/chapter_provider.dart';

void main() {
  test('detects chapter boundaries and ignores contents and repeated headers', () {
    final chapters = detectChapters([
      (page: 1, text: 'Contents\nChapter 1 Introduction\nChapter 2 Classification'),
      (page: 3, text: 'CHAPTER 1\nIntroduction\nMachine learning'),
      (page: 4, text: 'CHAPTER 1\nRepeated running header'),
      (page: 10, text: 'Chapter 2 Classification\nLabels and prediction'),
    ], 20);
    expect(chapters, hasLength(2));
    expect(chapters.first.startPage, 3);
    expect(chapters.first.endPage, 9);
    expect(chapters.last.endPage, 20);
  });
  test('chapter restriction excludes evidence outside selected pages', () {
    final bm25 = BM25Service();
    final index = bm25.buildIndex([
      const IndexableChunk(id: 1, text: 'Supervised learning labels', pageNumber: 3, chunkIndex: 0),
      const IndexableChunk(id: 2, text: 'Supervised learning predictions', pageNumber: 11, chunkIndex: 0),
    ]);
    final scoped = RagService(null, bm25).restrictToPages(index, 10, 20);
    final results = bm25.search(scoped, 'supervised learning');
    expect(results.single.chunk.pageNumber, 11);
    expect(formatGenerationTime(const Duration(seconds: 75)), '1:15');
  });
  testWidgets('chapter dropdown applies PDF page boundaries', (tester) async {
    StudyChapter? selected;
    await tester.pumpWidget(ProviderScope(overrides: [
      chaptersProvider.overrideWith((ref, id) async => [
        const StudyChapter(title: 'Chapter 2 Classification', startPage: 10, endPage: 20),
      ]),
    ], child: MaterialApp(home: Scaffold(body: ChapterSelector(
      documentId: 1, pageCount: 20, onChanged: (value) => selected = value,
    )))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Chapter 2 Classification').last);
    await tester.pumpAndSettle();
    expect(selected?.startPage, 10);
    expect(selected?.endPage, 20);
    expect(tester.takeException(), isNull);
  });
  testWidgets('progress shows real stages and elapsed time without a percentage', (tester) async {
    final activity = ValueNotifier<String>('Finding evidence…');
    var running = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (_, setState) {
        update = setState;
        return GenerationProgress(running: running, activity: activity);
      },
    ))));
    expect(find.text('Finding evidence…'), findsOneWidget);
    expect(find.textContaining('Elapsed:'), findsOneWidget);
    activity.value = 'Loading offline model…';
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loading offline model…'), findsOneWidget);
    update(() => running = false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Finished in:'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    activity.dispose();
  });
}
