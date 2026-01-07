import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../domain/processing_state.dart';
import '../providers/processing_provider.dart';

/// Screen showing document processing progress.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.documentId,
  });

  final int documentId;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Start processing when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    final notifier = ref.read(processingProvider(widget.documentId).notifier);
    await notifier.startProcessing();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(processingProvider(widget.documentId));

    // Listen for completion to navigate
    ref.listen<ProcessingState>(
      processingProvider(widget.documentId),
      (previous, next) {
        if (next.isComplete) {
          // Navigate to document ready screen
          context.go('/document/${widget.documentId}/ready');
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBackButton(context),
              const Spacer(),
              _buildHeader(context, state),
              const SizedBox(height: AppDimensions.spacing3xl),
              _buildProgressSection(context, state),
              const SizedBox(height: AppDimensions.spacingXl),
              _buildStepsIndicator(context, state),
              const Spacer(),
              if (state.hasError) _buildErrorActions(context),
              const SizedBox(height: AppDimensions.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () {
          ref.read(processingProvider(widget.documentId).notifier).cancel();
          context.go(AppRoutes.library);
        },
        icon: const Icon(Icons.close_rounded),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProcessingState state) {
    return Column(
      children: [
        _AnimatedProcessingIcon(isProcessing: state.isProcessing),
        const SizedBox(height: AppDimensions.spacingXl),
        Text(
          state.hasError
              ? 'Processing Failed'
              : AppStrings.processingTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: state.hasError
                    ? AppColors.errorRed
                    : AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          state.hasError
              ? state.errorMessage ?? 'An error occurred'
              : state.stepDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, ProcessingState state) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                state.progressPercent,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryIndigo,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GradientProgressBar(
            progress: state.overallProgress,
            height: 12,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.pageCount > 0)
                Text(
                  '${state.pagesProcessed}/${state.pageCount} pages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                const SizedBox.shrink(),
              if (state.chunksCreated > 0)
                Text(
                  '${state.chunksCreated} chunks',
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

  Widget _buildStepsIndicator(BuildContext context, ProcessingState state) {
    final phases = [
      ProcessingPhase.extractingText,
      ProcessingPhase.chunking,
      ProcessingPhase.embedding,
      ProcessingPhase.finalizing,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: phases.map((phase) {
        final isActive = phase == state.currentPhase;
        final isCompleted = phase.isBefore(state.currentPhase);
        
        return _StepIndicator(
          label: phase.label,
          isActive: isActive,
          isCompleted: isCompleted,
          hasError: state.hasError && isActive,
        );
      }).toList(),
    );
  }

  Widget _buildErrorActions(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          text: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () {
            ref.read(processingProvider(widget.documentId).notifier).retry();
          },
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SecondaryButton(
          text: 'Back to Library',
          onPressed: () => context.go(AppRoutes.library),
        ),
      ],
    );
  }
}

class _AnimatedProcessingIcon extends StatefulWidget {
  const _AnimatedProcessingIcon({required this.isProcessing});

  final bool isProcessing;

  @override
  State<_AnimatedProcessingIcon> createState() => _AnimatedProcessingIconState();
}

class _AnimatedProcessingIconState extends State<_AnimatedProcessingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    if (widget.isProcessing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedProcessingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isProcessing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: AppDimensions.iconSizeSetup,
        height: AppDimensions.iconSizeSetup,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Icon(
          Icons.settings_rounded,
          size: AppDimensions.iconSizeLg,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.hasError = false,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Color textColor;
    IconData? icon;

    if (hasError) {
      circleColor = AppColors.errorRed;
      textColor = AppColors.errorRed;
      icon = Icons.close_rounded;
    } else if (isCompleted) {
      circleColor = AppColors.successGreen;
      textColor = AppColors.successGreen;
      icon = Icons.check_rounded;
    } else if (isActive) {
      circleColor = AppColors.primaryIndigo;
      textColor = AppColors.primaryIndigo;
    } else {
      circleColor = AppColors.slate300;
      textColor = AppColors.textTertiary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || hasError
                ? circleColor
                : circleColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: isActive && !isCompleted && !hasError
                ? Border.all(color: circleColor, width: 2)
                : null,
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.white, size: 16)
                : isActive
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: circleColor,
                        ),
                      )
                    : null,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
