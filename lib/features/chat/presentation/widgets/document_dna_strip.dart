import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// **Document DNA** — a 24px vertical heat-map showing citation density
/// across a document's pages. Each segment represents one page; its
/// color intensity reflects how many times that page has been cited.
///
/// - Tap a segment to jump to that page in the reader.
/// - Hot pages pulse briefly when a new citation is added.
class DocumentDnaStrip extends StatefulWidget {
  const DocumentDnaStrip({
    super.key,
    required this.pageCount,
    required this.citationCounts,
    required this.onPageTap,
    this.currentPage,
    this.width = 24,
  });

  /// Total number of pages in the document.
  final int pageCount;

  /// Map of pageNumber (1-based) → citation count.
  final Map<int, int> citationCounts;

  /// Called when a segment is tapped.
  final void Function(int pageNumber) onPageTap;

  /// Highlights the currently-viewed page (if any).
  final int? currentPage;

  /// Strip width in logical pixels.
  final double width;

  @override
  State<DocumentDnaStrip> createState() => _DocumentDnaStripState();
}

class _DocumentDnaStripState extends State<DocumentDnaStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _previousMaxCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _previousMaxCount = _maxCount(widget.citationCounts);
  }

  @override
  void didUpdateWidget(covariant DocumentDnaStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMax = _maxCount(widget.citationCounts);
    if (newMax > _previousMaxCount) {
      _pulseController.forward(from: 0);
      _previousMaxCount = newMax;
    }
  }

  int _maxCount(Map<int, int> counts) {
    if (counts.isEmpty) return 0;
    return counts.values.reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount <= 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition),
          child: CustomPaint(
            size: Size(widget.width, double.infinity),
            painter: _DnaPainter(
              pageCount: widget.pageCount,
              counts: widget.citationCounts,
              currentPage: widget.currentPage,
              pulse: _pulseController.value,
              maxCount: _maxCount(widget.citationCounts),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final segmentHeight = box.size.height / widget.pageCount;
    final page = (localPos.dy / segmentHeight).floor() + 1;
    final clamped = page.clamp(1, widget.pageCount);
    widget.onPageTap(clamped);
  }
}

class _DnaPainter extends CustomPainter {
  _DnaPainter({
    required this.pageCount,
    required this.counts,
    required this.currentPage,
    required this.pulse,
    required this.maxCount,
  });

  final int pageCount;
  final Map<int, int> counts;
  final int? currentPage;
  final double pulse;
  final int maxCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (pageCount <= 0) return;

    // Subtle track background so the strip is visible even with no citations.
    final trackPaint = Paint()..color = AppColors.zinc800;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      trackPaint,
    );

    final segmentHeight = size.height / pageCount;

    for (int page = 1; page <= pageCount; page++) {
      final count = counts[page] ?? 0;
      if (count == 0 && currentPage != page) continue;

      final intensity = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

      final color = _colorForIntensity(intensity, page);
      final top = (page - 1) * segmentHeight;

      // Each segment leaves a 0.5px gap for separation, and current page gets
      // a brighter strip plus a small left marker.
      final rect = Rect.fromLTWH(
        2,
        top + 0.5,
        size.width - 4,
        (segmentHeight - 1).clamp(1.0, double.infinity),
      );

      canvas.drawRect(rect, Paint()..color = color);

      if (currentPage == page) {
        // Left-edge marker for current page.
        canvas.drawRect(
          Rect.fromLTWH(0, top, 2.5, segmentHeight),
          Paint()..color = AppColors.accentCyan,
        );
      }
    }
  }

  Color _colorForIntensity(double t, int page) {
    if (t <= 0) {
      // Barely-visible base for pages with no citations (only painted if
      // it's the current page).
      return AppColors.zinc700.withOpacity(0.4);
    }
    // Accent gradient: emerald → cyan, with opacity from intensity.
    final hot = currentPage == page ? 1.0 : (0.4 + 0.6 * t);

    // Add a pulse to the hottest segment(s) when citations change.
    final isPeak = maxCount > 0 && (counts[page] ?? 0) == maxCount;
    final pulseBoost = isPeak ? (pulse * 0.3) : 0.0;

    final emerald = AppColors.accent;
    final cyan = AppColors.accentCyan;
    final lerped = Color.lerp(emerald, cyan, t) ?? emerald;

    return lerped.withOpacity((hot + pulseBoost).clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant _DnaPainter oldDelegate) {
    return oldDelegate.pageCount != pageCount ||
        oldDelegate.counts != counts ||
        oldDelegate.currentPage != currentPage ||
        oldDelegate.pulse != pulse ||
        oldDelegate.maxCount != maxCount;
  }
}
