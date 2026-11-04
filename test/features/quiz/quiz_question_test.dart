import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/quiz/domain/quiz_question.dart';

void main() {
  const parser = QuizParser();
  const valid = 'Q: Which method uses labels? | A: Clustering | B: Supervised learning | C: Random search | KEY: B | WHY: Training uses labelled examples. | PAGE: 2';
  test('parses a source-cited question and correct option', () {
    final q = parser.parse(valid, {2}).single;
    expect(q.correctIndex, 1);
    expect(q.options[q.correctIndex], 'Supervised learning');
    expect(q.page, 2);
  });
  test('rejects unknown pages, invalid answer keys and duplicate options', () {
    expect(parser.parse(valid, {3}), isEmpty);
    expect(parser.parse(valid.replaceFirst('KEY: B', 'KEY: D'), {2}), isEmpty);
    expect(parser.parse(valid.replaceFirst('A: Clustering', 'A: Random search'), {2}), isEmpty);
  });
  test('drops truncated output and duplicate questions', () {
    expect(parser.parse('Q: Missing answer', {2}), isEmpty);
    expect(parser.parse('$valid\n$valid', {2}), hasLength(1));
  });
}
