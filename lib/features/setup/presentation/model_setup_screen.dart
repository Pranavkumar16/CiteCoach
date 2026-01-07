import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../data/model_downloader.dart';
import '../providers/setup_provider.dart';

/// Model setup screen explaining the AI model download.
class ModelSetupScreen extends ConsumerWidget {
  const ModelSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackButton(context),
                const Spacer(),
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing3xl),
                _buildModelInfo(context),
                const SizedBox(height: AppDimensions.spacingXl),
                _buildRequirements(context),
                const Spacer(),
                _buildButtons(context, ref),
                const SizedBox(height: AppDimensions.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => context.go('/setup/privacy'),
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
        Container(
          width: AppDimensions.iconSizeSetup,
          height: AppDimensions.iconSizeSetup,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            size: AppDimensions.iconSizeLg,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        Text(
          AppStrings.modelSetupTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          AppStrings.modelSetupSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModelInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: AppDimensions.iconSizeMd,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.modelName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      AppStrings.modelDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ModelStat(
                label: AppStrings.downloadSizeLabel,
                value: '${(ModelDownloader.modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
              ),
              const _ModelStat(
                label: AppStrings.storageNeededLabel,
                value: '~1.7 GB',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.requirementsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        const _RequirementItem(
          icon: Icons.wifi_rounded,
          text: AppStrings.requirement1,
        ),
        const _RequirementItem(
          icon: Icons.storage_rounded,
          text: AppStrings.requirement2,
        ),
        const _RequirementItem(
          icon: Icons.battery_charging_full_rounded,
          text: AppStrings.requirement3,
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GradientButton(
          text: AppStrings.downloadNowButton,
          icon: Icons.download_rounded,
          onPressed: () async {
            await ref.read(setupProvider.notifier).startDownload();
            if (context.mounted) {
              context.go('/setup/download');
            }
          },
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
}

class _ModelStat extends StatelessWidget {
  const _ModelStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryIndigo,
              ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
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
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
