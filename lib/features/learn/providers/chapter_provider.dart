import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/tables/document_pages_table.dart';
import '../domain/study_chapter.dart';

final chaptersProvider = FutureProvider.autoDispose.family<List<StudyChapter>, int>((ref, documentId) async {
  final db = await ref.watch(databaseProvider.future);
  final pages = await DocumentPagesTable(db).getPageTexts(documentId)
      .timeout(const Duration(seconds: 10));
  if (pages.isEmpty) return [];
  return detectChapters([
    for (final page in pages)
      (page: page['page_number'] as int, text: page['page_text'] as String),
  ], pages.last['page_number'] as int);
});
