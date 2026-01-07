import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

/// Empty state view for when the library has no documents.
class EmptyLibraryView extends StatelessWidget {
  const EmptyLibraryView({
    super.key,
    required this.onImportPressed,
    this.isImporting = false,
  });

  final VoidCallback onImportPressed;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(context),
            const SizedBox(height: AppDimensions.spacingXl),
            _buildTitle(context),
            const SizedBox(height: AppDimensions.spacingSm),
            _buildDescription(context),
            const SizedBox(height: AppDimensions.spacing3xl),
            _buildImportButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppDimensions.iconSizeSetup,
      height: AppDimensions.iconSizeSetup,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: const Icon(
        Icons.library_books_rounded,
        size: AppDimensions.iconSizeLg + 8,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      AppStrings.noDocumentsTitle,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXl,
      ),
      child: Text(
        AppStrings.noDocumentsDescription,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return DashedButton(
      text: AppStrings.importPdf,
      icon: Icons.add_rounded,
      onPressed: isImporting ? null : onImportPressed,
      isLoading: isImporting,
    );
  }
}
