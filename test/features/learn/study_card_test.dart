import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/learn/domain/study_card.dart';

void main() {
  const parser = StudyCardParser();
  test('accepts sourced flashcard', () {
    final cards = parser.parse(
        'Q: What is RAG? | A: Retrieval augmented generation | PAGE: 3', {3});
    expect(cards.single.page, 3);
  });
  test('rejects fabricated page', () {
    expect(parser.parse('Q: What? | A: Answer | PAGE: 99', {3}), isEmpty);
  });
  test('rejects malformed output', () {
    expect(parser.parse('A card without source', {1}), isEmpty);
  });
  test('limits cards to five', () {
    final lines = List.generate(9,
        (i) => 'Q: Question $i | A: Answer $i | PAGE: 1').join('\n');
    expect(parser.parse(lines, {1}), hasLength(5));
  });
}
