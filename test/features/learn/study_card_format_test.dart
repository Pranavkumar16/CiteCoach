import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/learn/domain/study_card.dart';
void main() {
  test('tolerates compact pipes, markdown and wrapped answers', () {
    final cards = const StudyCardParser().parse('**Q:** What is learning?|A:Finding patterns\nfrom data|PAGE: [Page 2]', {2});
    expect(cards.length, 1);
    expect(cards.first.page, 2);
  });
  test('rejects generic page recall prompts', () {
    expect(const StudyCardParser().parse('Q: Recall the source passage on page 2 | A: Text | PAGE: 2', {2}), isEmpty);
  });
  test('still rejects invented source pages', () {
    expect(const StudyCardParser().parse('Q: What?|A: Answer|PAGE: 99', {2}), isEmpty);
  });
}
