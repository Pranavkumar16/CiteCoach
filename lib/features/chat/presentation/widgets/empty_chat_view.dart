import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

/// Displayed when a chat session has no messages.
class EmptyChatView extends StatelessWidget {
  const EmptyChatView({
    super.key,
    required this.documentTitle,
    this.onSampleQuestion,
  });

  final String documentTitle;
  final void Function(String question)? onSampleQuestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: AppColors.textTertiary.withOpacity(0.3),
            ),
            SizedBox(height: AppDimensions.spacingLg),
            Text(
              AppStrings.askQuestion,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: AppDimensions.spacingMd),
            Text(
              AppStrings.askQuestionDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
