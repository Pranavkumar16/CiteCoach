import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

/// Displayed when a chat session has no messages.
class EmptyChatView extends StatelessWidget {
  const EmptyChatView({
    super.key,
    required this.documentTitle,
    this.onSampleQuestion,
  });

  /// The title of the document.
  final String documentTitle;

  /// Callback when a sample question is tapped.
  final void Function(String question)? onSampleQuestion;

  static const _sampleQuestions = [
    'What is the main topic?',
    'Summarize this document',
    'What are the key points?',
    'Explain the conclusions',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const KineticLogo(
            size: AppDimensions.logoSizeSm,
          ),
          SizedBox(height: AppDimensions.spacingLg),
          Text(
            'Ask about your document',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          Text(
            'I can help you understand, summarize, and find specific information in your document.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
          _buildFeatures(context),
          const SizedBox(height: 32),
          Text(
            'Try asking',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          _buildSampleQuestions(context),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureItem(
          context,
          icon: Icons.search_rounded,
          label: 'Find Info',
        ),
        SizedBox(width: AppDimensions.spacingLg),
        _buildFeatureItem(
          context,
          icon: Icons.summarize_rounded,
          label: 'Summarize',
        ),
        SizedBox(width: AppDimensions.spacingLg),
        _buildFeatureItem(
          context,
          icon: Icons.lightbulb_outline_rounded,
          label: 'Explain',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryIndigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryIndigo,
            size: 24,
          ),
        ),
        SizedBox(height: AppDimensions.spacingSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildSampleQuestions(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDimensions.spacingSm,
      runSpacing: AppDimensions.spacingSm,
      children: _sampleQuestions.map((question) {
        return _SampleQuestionChip(
          question: question,
          onTap: onSampleQuestion != null ? () => onSampleQuestion!(question) : null,
        );
      }).toList(),
    );
  }
}

class _SampleQuestionChip extends StatelessWidget {
  const _SampleQuestionChip({
    required this.question,
    this.onTap,
  });

  final String question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: AppColors.slate200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          question,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
