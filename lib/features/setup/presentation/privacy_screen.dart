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
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _buildHeader(context),
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
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: const Icon(
            Icons.lock_outlined,
            size: AppDimensions.iconSizeLg,
            color: AppColors.accent,
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
                height: 1.7,
              ),
          textAlign: TextAlign.center,
        ),
      ],
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
