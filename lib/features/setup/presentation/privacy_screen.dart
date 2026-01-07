import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/setup_provider.dart';

/// Privacy notice screen explaining offline-first architecture.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

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
                const Spacer(),
                _buildHeader(context),
                const SizedBox(height: AppDimensions.spacing3xl),
                _buildPrivacyFeatures(context),
                const Spacer(),
                _buildContinueButton(context, ref),
                const SizedBox(height: AppDimensions.spacingMd),
              ],
            ),
          ),
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
            Icons.shield_outlined,
            size: AppDimensions.iconSizeLg,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        Text(
          AppStrings.privacyTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          AppStrings.privacySubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrivacyFeatures(BuildContext context) {
    final features = [
      const _PrivacyFeature(
        icon: Icons.wifi_off_rounded,
        title: AppStrings.privacyFeature1Title,
        description: AppStrings.privacyFeature1Desc,
      ),
      const _PrivacyFeature(
        icon: Icons.phone_android_rounded,
        title: AppStrings.privacyFeature2Title,
        description: AppStrings.privacyFeature2Desc,
      ),
      const _PrivacyFeature(
        icon: Icons.cloud_off_rounded,
        title: AppStrings.privacyFeature3Title,
        description: AppStrings.privacyFeature3Desc,
      ),
    ];

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                child: feature,
              ))
          .toList(),
    );
  }

  Widget _buildContinueButton(BuildContext context, WidgetRef ref) {
    return GradientButton(
      text: AppStrings.continueButton,
      onPressed: () async {
        await ref.read(setupProvider.notifier).acceptPrivacy();
        if (context.mounted) {
          context.go('/setup/model');
        }
      },
    );
  }
}

class _PrivacyFeature extends StatelessWidget {
  const _PrivacyFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.iconContainerSm,
            height: AppDimensions.iconContainerSm,
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconSizeMd,
              color: AppColors.primaryIndigo,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  description,
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
}
