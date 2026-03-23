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
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _buildCelebration(context),
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
              color: AppColors.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: AppDimensions.iconSizeLg,
              color: AppColors.textOnPrimary,
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
                height: 1.7,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    return GradientButton(
      text: AppStrings.getStarted,
      onPressed: () async {
        await ref.read(setupProvider.notifier).completeSetup();
        if (context.mounted) {
          context.go('/library');
        }
      },
    );
  }
}
