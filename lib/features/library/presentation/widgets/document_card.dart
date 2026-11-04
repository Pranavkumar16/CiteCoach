import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/database/tables/documents_table.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../domain/document.dart';

/// Card widget displaying a document in the library.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onChatTap,
    this.onReadTap,
    this.onDeleteTap,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onReadTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        child: GlassSurface(
          blur: false,
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContent(context),
              if (document.isReady) _buildActions(context),
              if (document.isProcessing) _buildProgressBar(context),
              if (document.hasError) _buildErrorBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(context),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(child: _buildInfo(context)),
          if (onDeleteTap != null && !document.isProcessing)
            _buildMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: AppDimensions.docThumbnailWidth,
      height: AppDimensions.docThumbnailHeight,
      decoration: BoxDecoration(
        color: document.isReady
            ? _theme(context).accentSolid.withOpacity(0.15)
            : _theme(context).border,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: document.isReady
            ? Border.all(
                color: _theme(context).accentSolid.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: AppDimensions.iconSizeXxl,
              color: document.isReady
                  ? _theme(context).accentSolid
                  : _theme(context).textTertiary,
            ),
          ),
          if (document.pageCount > 0)
            Positioned(
              bottom: AppDimensions.spacingXs,
              right: AppDimensions.spacingXs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingXs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _theme(context).surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
                child: Text(
                  '${document.pageCount}p',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _theme(context).textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _theme(context).textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Row(
          children: [
            _buildStatusBadge(context),
            const SizedBox(width: AppDimensions.spacingSm),
            Text(
              document.addedTimeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _theme(context).textTertiary,
              ),
            ),
          ],
        ),
        if (document.fileSize > 0) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            document.fileSizeFormatted,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _theme(context).textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (document.status) {
      case DocumentStatus.ready:
        badgeColor = _theme(context).success;
        badgeText = 'Ready';
        badgeIcon = Icons.check_circle_rounded;
        break;
      case DocumentStatus.processing:
        badgeColor = _theme(context).accentSolid;
        badgeText = 'Processing';
        badgeIcon = Icons.hourglass_top_rounded;
        break;
      case DocumentStatus.pending:
        badgeColor = _theme(context).warning;
        badgeText = 'Pending';
        badgeIcon = Icons.schedule_rounded;
        break;
      case DocumentStatus.error:
        badgeColor = _theme(context).error;
        badgeText = 'Error';
        badgeIcon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: _theme(context).textTertiary),
      onSelected: (value) {
        if (value == 'delete') {
          onDeleteTap?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: _theme(context).error),
              const SizedBox(width: AppDimensions.spacingSm),
              const Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        0,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: SmallActionButton(
              text: AppStrings.chat,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onChatTap,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: SmallActionButton(
              text: AppStrings.read,
              icon: Icons.menu_book_rounded,
              onPressed: onReadTap,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        0,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientProgressBar(progress: document.processingProgress, height: 6),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '${(document.processingProgress * 100).toInt()}% processed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _theme(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        0,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: _theme(context).error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: _theme(context).error,
            size: AppDimensions.iconSizeSm,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              document.errorMessage ?? 'Processing failed',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _theme(context).error),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

AppThemeData _theme(BuildContext context) =>
    Theme.of(context).extension<AppThemeData>() ?? AppThemeData.midnight();
