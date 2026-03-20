import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../data/model_downloader.dart';
import '../domain/setup_state.dart';
import '../providers/setup_provider.dart';

/// Download progress screen showing model download status.
class DownloadProgressScreen extends ConsumerStatefulWidget {
  const DownloadProgressScreen({super.key});

  @override
  ConsumerState<DownloadProgressScreen> createState() =>
      _DownloadProgressScreenState();
}

class _DownloadProgressScreenState
    extends ConsumerState<DownloadProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for setup state changes to navigate on completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSetupState();
    });
  }

  void _checkSetupState() {
    final setupState = ref.read(setupProvider);
    if (setupState.currentStep == SetupStep.complete) {
      context.go('/setup/complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);

    // Navigate to complete screen when download finishes
    ref.listen<SetupState>(setupProvider, (previous, next) {
      if (next.currentStep == SetupStep.complete) {
        context.go('/setup/complete');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackButton(context, ref),
                const Spacer(),
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing3xl),
                _buildProgressSection(context, setupState),
                const SizedBox(height: AppDimensions.spacingXl),
                if (setupState.hasError) _buildErrorSection(context, ref),
                _buildStatusInfo(context, setupState),
                const Spacer(),
                _buildControls(context, ref, setupState),
                const SizedBox(height: AppDimensions.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () {
          ref.read(setupProvider.notifier).goBackToModelSetup();
          context.go('/setup/model');
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const _AnimatedDownloadIcon(),
        const SizedBox(height: AppDimensions.spacingXl),
        Text(
          AppStrings.downloadingTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          AppStrings.downloadingSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, SetupState setupState) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.zinc800,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.zinc700,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                setupState.isPaused
                    ? AppStrings.downloadPaused
                    : AppStrings.downloadInProgress,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: setupState.isPaused
                          ? AppColors.warningOrange
                          : AppColors.textPrimary,
                    ),
              ),
              Text(
                setupState.downloadProgressPercent,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GradientProgressBar(
            progress: setupState.downloadProgress,
            height: 12,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                setupState.downloadedSizeMb,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                '${(ModelDownloader.modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: AppDimensions.iconSizeMd,
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.downloadError,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorRed,
                      ),
                ),
                Text(
                  setupState.downloadError ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(BuildContext context, SetupState setupState) {
    return Column(
      children: [
        _StatusItem(
          icon: Icons.folder_rounded,
          label: AppStrings.modelName,
          status: setupState.isDownloading
              ? AppStrings.downloading
              : (setupState.isPaused ? AppStrings.paused : AppStrings.ready),
        ),
        _StatusItem(
          icon: Icons.storage_rounded,
          label: AppStrings.storageUsed,
          status: setupState.downloadedSizeMb,
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    SetupState setupState,
  ) {
    if (setupState.hasError) {
      return Column(
        children: [
          GradientButton(
            text: AppStrings.retryButton,
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(setupProvider.notifier).retryDownload(),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          SecondaryButton(
            text: AppStrings.skipForNowButton,
            onPressed: () async {
              await ref.read(setupProvider.notifier).skipDownload();
              if (context.mounted) {
                context.go('/library');
              }
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        if (setupState.isDownloading)
          Expanded(
            child: SecondaryButton(
              text: AppStrings.pauseButton,
              icon: Icons.pause_rounded,
              onPressed: () => ref.read(setupProvider.notifier).pauseDownload(),
            ),
          )
        else if (setupState.isPaused)
          Expanded(
            child: GradientButton(
              text: AppStrings.resumeButton,
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  ref.read(setupProvider.notifier).resumeDownload(),
            ),
          ),
      ],
    );
  }
}

class _AnimatedDownloadIcon extends StatefulWidget {
  const _AnimatedDownloadIcon();

  @override
  State<_AnimatedDownloadIcon> createState() => _AnimatedDownloadIconState();
}

class _AnimatedDownloadIconState extends State<_AnimatedDownloadIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Container(
        width: AppDimensions.iconSizeSetup,
        height: AppDimensions.iconSizeSetup,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Icon(
          Icons.download_rounded,
          size: AppDimensions.iconSizeLg,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSizeSm,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
