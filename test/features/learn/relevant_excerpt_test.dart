import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';

void main() {
  test('keeps supervised learning evidence beyond long chunk prefix', () {
    final text = '${List.filled(300, 'Introduction. ').join()}'
        'Supervised learning uses labelled examples to learn predictions. '
        '${List.filled(100, 'Other topics. ').join()}';
    final excerpt = RagService.relevantExcerpt(
        text, 'What is supervised learning?', 400);
    expect(excerpt, contains('Supervised learning uses labelled examples'));
    expect(excerpt.length, 400);
  });
  test('preserves short text and bounds unmatched long text', () {
    expect(RagService.relevantExcerpt('Short evidence', 'ML', 100),
        'Short evidence');
    expect(RagService.relevantExcerpt('abcdefghij', 'xyz', 4), 'abcd');
  });
}
