import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/processing/data/pdf_processor.dart';

void main() {
  group('PDF page chunking terminates and preserves coverage', () {
    for (final length in [0, 99, 100, 255, 256, 257, 2048, 2049, 4096, 10000]) {
      test('page with $length characters', () async {
        final text = List.filled(length, 'x').join();
        final result = await PdfProcessor().chunkText({1: text});

        expect(result.isSuccess, isTrue);
        expect(result.chunks, isNotEmpty);
        expect(result.chunks.first.startOffset, 0);
        expect(result.chunks.last.endOffset, length);
        expect(result.chunks.length, lessThanOrEqualTo(length ~/ 100 + 1));
        for (var i = 0; i < result.chunks.length; i++) {
          final chunk = result.chunks[i];
          expect(chunk.text, text.substring(chunk.startOffset, chunk.endOffset));
          expect(chunk.pageNumber, 1);
          if (i > 0) {
            final previous = result.chunks[i - 1];
            expect(chunk.startOffset, greaterThan(previous.startOffset));
            expect(chunk.startOffset, lessThanOrEqualTo(previous.endOffset));
          }
        }
      });
    }

    test('sentence boundaries and multiple pages retain the final text', () async {
      final text = List.filled(200, 'A sentence with evidence. ').join();
      final result = await PdfProcessor().chunkText({1: text, 2: 'Short page'});

      expect(result.isSuccess, isTrue);
      final firstPage = result.chunks.where((chunk) => chunk.pageNumber == 1).toList();
      expect(firstPage.last.endOffset, text.length);
      expect(result.chunks.last.pageNumber, 2);
      expect(result.chunks.last.text, 'Short page');
      for (var i = 1; i < firstPage.length; i++) {
        expect(firstPage[i].startOffset, greaterThan(firstPage[i - 1].startOffset));
        expect(firstPage[i].startOffset, lessThanOrEqualTo(firstPage[i - 1].endOffset));
      }
    });
  });
}
