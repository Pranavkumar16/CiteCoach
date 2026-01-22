import 'package:flutter_test/flutter_test.dart';

import 'package:citecoach/routing/app_router.dart';

void main() {
  test('documentReader builds uri with query parameters', () {
    final uri = AppRoutes.documentReader(
      '42',
      page: 3,
      highlight: 'Key passage',
      fromChat: true,
    );

    final parsed = Uri.parse(uri);
    expect(parsed.path, '/document/42/reader');
    expect(parsed.queryParameters['page'], '3');
    expect(parsed.queryParameters['highlight'], 'Key passage');
    expect(parsed.queryParameters['fromChat'], '1');
  });
}
