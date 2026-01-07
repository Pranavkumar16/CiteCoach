import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/setup_provider.dart';

/// Setup complete celebration screen.
class SetupCompleteScreen extends ConsumerStatefulWidget {
  const SetupCompleteScreen({super.key});

  @override
  ConsumerState<SetupCompleteScreen> createState() =>
      _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends ConsumerState<SetupCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildCelebration(context),
                const SizedBox(height: AppDimensions.spacing3xl),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCapabilities(context),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStartButton(context, ref),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: AppDimensions.iconSizeSetup,
            height: AppDimensions.iconSizeSetup,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryIndigo.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: AppDimensions.iconSizeLg,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        Text(
          AppStrings.setupCompleteTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          AppStrings.setupCompleteSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCapabilities(BuildContext context) {
    final capabilities = [
      const _CapabilityItem(
        icon: Icons.menu_book_rounded,
        title: AppStrings.capability1Title,
        description: AppStrings.capability1Desc,
      ),
      const _CapabilityItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: AppStrings.capability2Title,
        description: AppStrings.capability2Desc,
      ),
      const _CapabilityItem(
        icon: Icons.mic_rounded,
        title: AppStrings.capability3Title,
        description: AppStrings.capability3Desc,
      ),
    ];

    return Column(
      children: capabilities
          .map((capability) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                child: capability,
              ))
          .toList(),
    );
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    return GradientButton(
      text: AppStrings.startUsingApp,
      icon: Icons.arrow_forward_rounded,
      onPressed: () async {
        await ref.read(setupProvider.notifier).completeSetup();
        if (context.mounted) {
          context.go('/library');
        }
      },
    );
  }
}

class _CapabilityItem extends StatelessWidget {
  const _CapabilityItem({
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
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconSizeMd,
              color: AppColors.white,
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
