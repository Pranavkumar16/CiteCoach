import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';

/// Screen showing model details and download status.
class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final storage = ref.watch(storageServiceProvider);
    final modelVersion = storage.modelVersion ?? ModelDownloader.modelVersion;
    final downloader = ref.watch(modelDownloaderProvider);
    final hasDownloadUrl = downloader.hasDownloadUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.modelInfo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              title: AppStrings.modelName,
              subtitle: AppStrings.modelDescription,
              items: [
                _InfoRow(label: 'Version', value: modelVersion),
                _InfoRow(
                  label: AppStrings.downloadSizeLabel,
                  value:
                      '${(ModelDownloader.modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                ),
                _InfoRow(
                  label: 'Status',
                  value:
                      setupState.isModelDownloaded ? AppStrings.ready : 'Not downloaded',
                ),
                _InfoRow(
                  label: 'Download source',
                  value: hasDownloadUrl ? 'Configured' : 'Not configured',
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            if (hasDownloadUrl)
              GradientButton(
                text: AppStrings.downloadNowButton,
                icon: Icons.download_rounded,
                onPressed: () async {
                  await ref.read(setupProvider.notifier).startDownload();
                  if (context.mounted) {
                    context.go(AppRoutes.downloadProgress);
                  }
                },
              ),
            if (hasDownloadUrl) const SizedBox(height: AppDimensions.spacingMd),
            SecondaryButton(
              text: setupState.isModelDownloaded
                  ? AppStrings.replaceModelFile
                  : AppStrings.importModelFile,
              icon: Icons.upload_file_rounded,
              onPressed: () async {
                await ref.read(setupProvider.notifier).importModelFile();
              },
            ),
            if (!hasDownloadUrl)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
                child: Text(
                  'Set MODEL_DOWNLOAD_URL to enable downloads, or import a model file.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            const Spacer(),
            Text(
              'The model runs fully offline and never uploads your documents.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_InfoRow> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
