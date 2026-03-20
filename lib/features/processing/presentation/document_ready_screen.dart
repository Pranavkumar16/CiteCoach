import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../providers/processing_provider.dart';

/// Screen shown when document processing is complete.
class DocumentReadyScreen extends ConsumerStatefulWidget {
  const DocumentReadyScreen({
    super.key,
    required this.documentId,
  });

  final int documentId;

  @override
  ConsumerState<DocumentReadyScreen> createState() => _DocumentReadyScreenState();
}

class _DocumentReadyScreenState extends ConsumerState<DocumentReadyScreen>
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
    final documentAsync = ref.watch(documentProvider(widget.documentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
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
                child: _buildDocumentInfo(context, documentAsync),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildActions(context),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
            ],
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
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
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
          AppStrings.documentReadyTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          AppStrings.documentReadyDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDocumentInfo(BuildContext context, AsyncValue documentAsync) {
    return documentAsync.when(
      data: (document) {
        if (document == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.zinc800,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.zinc700,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.description_rounded,
                          label: '${document.pageCount} ${AppStrings.pages}',
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        const _InfoChip(
                          icon: Icons.check_circle_rounded,
                          label: AppStrings.processed,
                          color: AppColors.successGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          text: AppStrings.startChatting,
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () {
            context.goToChat(widget.documentId.toString());
          },
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SecondaryButton(
          text: AppStrings.read,
          icon: Icons.menu_book_rounded,
          onPressed: () {
            context.goToReader(widget.documentId.toString());
          },
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        TextButton(
          onPressed: () => context.go(AppRoutes.library),
          child: Text(
            AppStrings.backToLibrary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: effectiveColor,
              ),
        ),
      ],
    );
  }
}
