import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/setup_provider.dart';

/// Model setup screen explaining the one-time download.
class ModelSetupScreen extends ConsumerWidget {
  const ModelSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                _buildBackButton(context),
                const Spacer(),
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing3xl),
                _buildInfoCard(context),
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
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: AppDimensions.iconSizeLg,
            color: AppColors.accent,
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
                height: 1.7,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
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
          _InfoRow(label: 'Size:', value: AppStrings.modelSize),
          const SizedBox(height: AppDimensions.spacingMd),
          _InfoRow(label: 'Network:', value: AppStrings.modelNetwork),
          const SizedBox(height: AppDimensions.spacingMd),
          _InfoRow(label: 'Time:', value: AppStrings.modelTime),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GradientButton(
          text: AppStrings.downloadNowButton,
          onPressed: () async {
            await ref.read(setupProvider.notifier).startDownload();
            if (context.mounted) {
              context.go('/setup/download');
            }
          },
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SecondaryButton(
          text: AppStrings.downloadLaterButton,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
