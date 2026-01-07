import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/chat_message.dart';

/// A tappable badge showing a page citation.
class CitationBadge extends StatelessWidget {
  const CitationBadge({
    super.key,
    required this.citation,
    required this.index,
    this.onTap,
  });

  /// The citation to display.
  final Citation citation;

  /// The citation index (1-based for display).
  final int index;

  /// Callback when badge is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryIndigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: AppColors.primaryIndigo.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 14,
              color: AppColors.primaryIndigo,
            ),
            const SizedBox(width: 4),
            Text(
              'p.${citation.pageNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of citation badges with "See sources" label.
class CitationRow extends StatelessWidget {
  const CitationRow({
    super.key,
    required this.citations,
    required this.onCitationTap,
  });

  /// The citations to display.
  final List<Citation> citations;

  /// Callback when a citation is tapped.
  final void Function(Citation citation) onCitationTap;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();

    // Get unique pages
    final uniquePages = <int>{};
    final uniqueCitations = <Citation>[];
    for (final citation in citations) {
      if (!uniquePages.contains(citation.pageNumber)) {
        uniquePages.add(citation.pageNumber);
        uniqueCitations.add(citation);
      }
    }

    return Padding(
      padding: EdgeInsets.only(top: AppDimensions.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sources',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: AppDimensions.spacingXxs),
          Wrap(
            spacing: AppDimensions.spacingXxs,
            runSpacing: AppDimensions.spacingXxs,
            children: [
              for (int i = 0; i < uniqueCitations.length; i++)
                CitationBadge(
                  citation: uniqueCitations[i],
                  index: i + 1,
                  onTap: () => onCitationTap(uniqueCitations[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An expanded citation card shown in a modal.
class CitationCard extends StatelessWidget {
  const CitationCard({
    super.key,
    required this.citation,
    this.onNavigate,
  });

  /// The citation to display.
  final Citation citation;

  /// Callback to navigate to the page.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingSm,
                    vertical: AppDimensions.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    'Page ${citation.pageNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (citation.relevanceScore > 0)
                  Text(
                    '${(citation.relevanceScore * 100).toStringAsFixed(0)}% match',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: AppColors.slate200,
                  width: 1,
                ),
              ),
              child: Text(
                citation.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: AppDimensions.spacingMd),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Go to page'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryIndigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
