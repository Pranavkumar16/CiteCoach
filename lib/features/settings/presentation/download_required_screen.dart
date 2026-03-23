import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';

/// Screen shown when user tries to access chat without the model downloaded.
/// Part of the "Download Later" flow.
class DownloadRequiredScreen extends ConsumerWidget {
  const DownloadRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_download_outlined,
                  color: AppColors.accent,
                  size: 48,
                ),
              ),
              SizedBox(height: AppDimensions.spacingXl),

              // Title
              Text(
                'AI Model Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingMd),

              // Description
              Text(
                'To chat with your documents, CiteCoach needs to download '
                'the AI model (1.5 GB). This is a one-time download and '
                'all processing will happen offline on your device.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingMd),

              // Storage info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storage, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '~1.5 GB storage required',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Download button
              if (setupState.isDownloading) ...[
                // Show progress
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: setupState.downloadProgress,
                      backgroundColor: AppColors.zinc700,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                    SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Downloading... ${setupState.downloadProgressPercent}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Download Now',
                    onPressed: () async {
                      await ref.read(setupProvider.notifier).startDownload();
                      // After download completes, go back
                      if (context.mounted) {
                        final state = ref.read(setupProvider);
                        if (state.isModelDownloaded) {
                          context.pop();
                        }
                      }
                    },
                    icon: Icons.download,
                  ),
                ),
              ],

              SizedBox(height: AppDimensions.spacingMd),

              // Back button
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),

              SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
