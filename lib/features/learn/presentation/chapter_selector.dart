import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/study_chapter.dart';
import '../providers/chapter_provider.dart';

class ChapterSelector extends ConsumerStatefulWidget {
  const ChapterSelector({super.key, required this.documentId, required this.pageCount,
    required this.onChanged, this.enabled = true});
  final int documentId;
  final int pageCount;
  final ValueChanged<StudyChapter?> onChanged;
  final bool enabled;
  @override
  ConsumerState<ChapterSelector> createState() => _ChapterSelectorState();
}

class _ChapterSelectorState extends ConsumerState<ChapterSelector> {
  StudyChapter? _selected;
  int _revision = 0;

  Future<StudyChapter?> _custom() async {
    final start = TextEditingController(text: '${_selected?.startPage ?? 1}');
    final end = TextEditingController(text: '${_selected?.endPage ?? widget.pageCount}');
    final form = GlobalKey<FormState>();
    try {
      return await showDialog<StudyChapter>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose PDF pages'),
          content: SingleChildScrollView(child: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Use PDF page numbers, which may differ from printed textbook numbers.'),
              TextFormField(controller: start, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'First PDF page'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 || n > widget.pageCount ? 'Enter a valid PDF page' : null;
                }),
              TextFormField(controller: end, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Last PDF page'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  final first = int.tryParse(start.text) ?? 1;
                  return n == null || n < first || n > widget.pageCount ? 'Enter a page from $first to ${widget.pageCount}' : null;
                }),
            ]),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, StudyChapter(
                title: 'Custom selection', startPage: int.parse(start.text),
                endPage: int.parse(end.text)));
            }, child: const Text('Use pages')),
          ],
        ),
      );
    } finally {
      Future<void>.delayed(const Duration(seconds: 1), () { start.dispose(); end.dispose(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapters = ref.watch(chaptersProvider(widget.documentId));
    final options = chapters.asData?.value ?? <StudyChapter>[];
    final selected = _selected;
    final available = [...options];
    if (selected != null && !available.any((c) => c.id == selected.id)) available.add(selected);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<String>(
        key: ValueKey((selected?.id ?? 'all', _revision)),
        initialValue: selected?.id ?? 'all',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Chapter / PDF pages', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Whole document')),
          for (final chapter in available)
            DropdownMenuItem(value: chapter.id,
              child: Text(chapter.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const DropdownMenuItem(value: 'custom', child: Text('Choose a PDF page range…')),
        ],
        onChanged: !widget.enabled ? null : (value) async {
          StudyChapter? chapter;
          if (value == 'custom') {
            chapter = await _custom();
            if (!mounted) return;
            if (chapter == null) { setState(() => _revision++); return; }
          } else if (value != 'all') {
            chapter = available.firstWhere((c) => c.id == value);
          }
          setState(() => _selected = chapter);
          widget.onChanged(chapter);
        },
      ),
      const SizedBox(height: 6),
      if (selected != null) Text(selected.label)
      else Text(chapters.isLoading ? 'Finding chapter headings…'
          : options.isEmpty ? 'No chapter headings detected. You can choose PDF pages manually.'
          : 'Chapter headings are detected automatically. Check the PDF page range.'),
    ]);
  }
}
