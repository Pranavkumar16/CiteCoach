import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../setup/domain/setup_state.dart';
import '../../setup/providers/setup_provider.dart';

/// Model information and management screen.
class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final isModelDownloaded = setupState.isModelDownloaded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Model'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        children: [
          // Model Status Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              gradient: isModelDownloaded
                  ? LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.1),
                        AppColors.success.withValues(alpha: 0.05),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.warning.withValues(alpha: 0.1),
                        AppColors.warning.withValues(alpha: 0.05),
                      ],
                    ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: isModelDownloaded
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isModelDownloaded ? Icons.check_circle : Icons.cloud_download,
                  size: 64,
                  color: isModelDownloaded ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  isModelDownloaded ? 'Model Ready' : 'Download Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isModelDownloaded ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  isModelDownloaded
                      ? 'The AI engine is installed and ready to use'
                      : 'Download the AI engine to enable chat features',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!isModelDownloaded) ...[
                  const SizedBox(height: AppDimensions.spacingLg),
                  GradientButton(
                    text: 'Download Now',
                    onPressed: () => context.go('/setup/download'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingLg),

          // Model Details
          _buildSectionHeader('MODEL DETAILS'),
          _buildInfoCard([
            _buildInfoRow('Name', 'Gemma 2B Instruct'),
            _buildInfoRow('Version', 'Q4 Quantized'),
            _buildInfoRow('Size', '1.5 GB'),
            _buildInfoRow('Context Window', '8,192 tokens'),
            _buildInfoRow('Used Context', '3,000 tokens'),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // Embedding Model
          _buildSectionHeader('EMBEDDING MODEL'),
          _buildInfoCard([
            _buildInfoRow('Name', 'TinyBERT'),
            _buildInfoRow('Size', '25 MB'),
            _buildInfoRow('Dimensions', '384'),
            _buildInfoRow('Purpose', 'Semantic search'),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // Performance Stats
          _buildSectionHeader('PERFORMANCE'),
          _buildInfoCard([
            _buildInfoRow('Speed', '2-5 tokens/second'),
            _buildInfoRow('First Token', '~500ms'),
            _buildInfoRow('Battery Usage', '0.5-2% per answer'),
            _buildInfoRow('Cache Hit Rate', '50-60%'),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // Privacy Note
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.primaryIndigo.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.primaryIndigo,
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '100% Offline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All AI processing happens on your device. Your documents never leave your phone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingSm,
        bottom: AppDimensions.spacingSm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryIndigo.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
