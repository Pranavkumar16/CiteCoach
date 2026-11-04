import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass_surface.dart';
import '../providers/setup_provider.dart';

const introductionSeenKey = 'introduction.seen.v1';

class IntroductionScreen extends ConsumerStatefulWidget {
  const IntroductionScreen({super.key});
  @override
  ConsumerState<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends ConsumerState<IntroductionScreen> {
  int _step = 0;
  bool _saving = false;
  String? _error;
  static const _pages = [
    (icon: Icons.menu_book_outlined, title: 'Your PDFs. A clearer understanding.', body: 'Import a PDF into your library. Once processing finishes, open it to read or ask questions.'),
    (icon: Icons.chat_bubble_outline_rounded, title: 'Ask. Then check the evidence.', body: 'Chat with your document and follow source-page links to check answers against the original text. AI can make mistakes.'),
    (icon: Icons.school_outlined, title: 'Learn a little. Remember more.', body: 'Create flashcards, reveal answers, and track what you remember. Take a quiz for instant feedback and cited explanations.'),
    (icon: Icons.offline_bolt_outlined, title: 'Set up once. Study offline.', body: 'Internet is needed to download the AI package. After setup, document chat, flashcards, and quizzes run on your device. You can also skip the download and browse your library.'),
  ];

  Future<void> _finish() async {
    setState(() { _saving = true; _error = null; });
    try {
      final saved = await ref.read(sharedPreferencesProvider).setBool(introductionSeenKey, true);
      if (!saved) throw StateError('Unable to save');
      if (!mounted) return;
      ref.read(setupProvider.notifier).completeSplash();
      context.go('/setup/privacy');
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save your choice. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_step];
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to CiteCoach'), actions: [TextButton(onPressed: _saving ? null : _finish, child: const Text('Skip'))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
        GlassSurface(radius: 28, child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
          Icon(page.icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(page.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text(page.body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ]))),
        const SizedBox(height: 24),
        Semantics(liveRegion: true, child: Text('Step ${_step + 1} of ${_pages.length}', textAlign: TextAlign.center)),
        const SizedBox(height: 12), LinearProgressIndicator(value: (_step + 1) / _pages.length),
        const SizedBox(height: 24),
        if (_error != null) Text(_error!),
        FilledButton(onPressed: _saving ? null : () { if (_step == _pages.length - 1) { _finish(); } else { setState(() => _step++); } }, child: Text(_saving ? 'Saving…' : _step == _pages.length - 1 ? 'Get started' : 'Continue')),
        if (_step > 0) TextButton(onPressed: _saving ? null : () => setState(() => _step--), child: const Text('Back')),
      ])))),
    );
  }
}
