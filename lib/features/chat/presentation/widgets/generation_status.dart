import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_data.dart';

/// Honest activity and elapsed time, without an invented completion percentage.
class GenerationStatus extends StatefulWidget {
  const GenerationStatus({
    super.key,
    required this.label,
    required this.onStop,
  });
  final String label;
  final VoidCallback onStop;
  @override
  State<GenerationStatus> createState() => _GenerationStatusState();
}

class _GenerationStatusState extends State<GenerationStatus> {
  final _watch = Stopwatch()..start();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeData>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 18, color: theme.accentSolid),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'On your device · ${_watch.elapsed.inSeconds}s',
                  style: TextStyle(color: theme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: widget.onStop,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
