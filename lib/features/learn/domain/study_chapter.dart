class StudyChapter {
  const StudyChapter({required this.title, required this.startPage, required this.endPage});
  final String title;
  final int startPage;
  final int endPage;
  String get id => '$startPage:$endPage';
  String get label => '$title · PDF pages $startPage–$endPage';
}

typedef StudyRequest = ({int documentId, String topic, int? startPage, int? endPage});

List<StudyChapter> detectChapters(List<({int page, String text})> pages, int totalPages) {
  final headings = <({int page, String title})>[];
  final seen = <String>{};
  final pattern = RegExp(r'^(?:chapter|unit|part)\s+([0-9]+|[ivxlcdm]+)\b[.:\s-]*(.*)$', caseSensitive: false);
  final sorted = [...pages]..sort((a, b) => a.page.compareTo(b.page));
  for (final page in sorted) {
    final lines = page.text.split(RegExp(r'[\r\n]+'))
        .map((s) => s.trim()).where((s) => s.isNotEmpty).take(12).toList();
    final matches = lines.where((line) => pattern.hasMatch(line)).toList();
    if (matches.length != 1) continue;
    final line = matches.single;
    if (line.length > 120 || RegExp(r'\.{3,}').hasMatch(line)) continue;
    final match = pattern.firstMatch(line)!;
    final key = '${line.split(RegExp(r'\s+')).first.toLowerCase()}:${match.group(1)!.toLowerCase()}';
    if (!seen.add(key)) continue;
    final position = lines.indexOf(line);
    var title = line;
    if (match.group(2)!.trim().isEmpty && position + 1 < lines.length &&
        lines[position + 1].length < 90) title = '$line — ${lines[position + 1]}';
    headings.add((page: page.page, title: title));
  }
  return [
    for (var i = 0; i < headings.length; i++)
      StudyChapter(title: headings[i].title, startPage: headings[i].page,
        endPage: i + 1 < headings.length ? headings[i + 1].page - 1 : totalPages),
  ].where((c) => c.startPage >= 1 && c.endPage >= c.startPage).toList();
}
