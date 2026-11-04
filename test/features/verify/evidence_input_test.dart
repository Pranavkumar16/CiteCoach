import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/verify/presentation/verify_screen.dart';
void main() {
  test('definition questions are directed to chat', () {
    expect(looksLikeEvidenceQuestion('What is machine learning'), isTrue);
    expect(looksLikeEvidenceQuestion('How does learning work?'), isTrue);
    expect(looksLikeEvidenceQuestion('Machine learning learns patterns from data.'), isFalse);
  });
}
