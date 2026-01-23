import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../domain/setup_state.dart';
import '../providers/setup_provider.dart';

/// Screen shown when chat is locked because the model isn't downloaded.
class DownloadRequiredScreen extends ConsumerWidget {
  const DownloadRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppDimensions.spacing2xl),
              _buildBody(context),
              const SizedBox(height: AppDimensions.spacingXl),
              if (setupState.downloadProgress > 0)
                _buildProgressCard(context, setupState.downloadProgress),
              const Spacer(),
              _buildActions(context, ref, setupState),
              const SizedBox(height: AppDimensions.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppDimensions.iconSizeLg,
          height: AppDimensions.iconSizeLg,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Text(
            AppStrings.downloadRequiredTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.downloadRequiredDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          AppStrings.downloadRequiredNote,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, double progress) {
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
            'Download progress',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          GradientProgressBar(
            progress: progress,
            height: 10,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    SetupState setupState,
  ) {
    final notifier = ref.read(setupProvider.notifier);
    final isDownloading = setupState.isDownloading;
    final isPaused = setupState.isPaused;

    String primaryLabel = AppStrings.downloadNowButton;
    VoidCallback? primaryAction;

    if (isDownloading) {
      primaryLabel = AppStrings.downloadInProgress;
      primaryAction = () => context.go(AppRoutes.downloadProgress);
    } else if (isPaused) {
      primaryLabel = AppStrings.resumeButton;
      primaryAction = () {
        notifier.resumeDownload();
        context.go(AppRoutes.downloadProgress);
      };
    } else {
      primaryAction = () async {
        await notifier.startDownload();
        if (context.mounted) {
          context.go(AppRoutes.downloadProgress);
        }
      };
    }

    return Column(
      children: [
        GradientButton(
          text: primaryLabel,
          icon: Icons.download_rounded,
          onPressed: primaryAction,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SecondaryButton(
          text: AppStrings.importModelFile,
          icon: Icons.upload_file_rounded,
          onPressed: () async {
            await notifier.importModelFile();
            if (context.mounted &&
                ref.read(setupProvider).currentStep == SetupStep.complete) {
              context.go('/setup/complete');
            }
          },
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SecondaryButton(
          text: AppStrings.backToLibrary,
          onPressed: () => context.go(AppRoutes.library),
        ),
      ],
    );
  }
}
