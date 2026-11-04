import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String formatGenerationTime(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

class GenerationProgress extends StatefulWidget {
  const GenerationProgress({super.key, required this.running, required this.activity});
  final bool running;
  final ValueListenable<String> activity;
  @override
  State<GenerationProgress> createState() => _GenerationProgressState();
}

class _GenerationProgressState extends State<GenerationProgress> {
  final Stopwatch _watch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  void _start() {
    _watch..reset()..start();
    _elapsed = Duration.zero;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _watch.elapsed);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.running) _start();
  }

  @override
  void didUpdateWidget(covariant GenerationProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !oldWidget.running) _start();
    if (!widget.running && oldWidget.running) {
      _watch.stop();
      _elapsed = _watch.elapsed;
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.running) ...[
        const LinearProgressIndicator(),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(valueListenable: widget.activity,
          builder: (_, value, __) => Text(value)),
      ],
      Text('${widget.running ? 'Elapsed' : 'Finished in'}: ${formatGenerationTime(_elapsed)}',
        style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
