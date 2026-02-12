import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../routing/app_router.dart';
import '../providers/setup_provider.dart';

class DownloadRequiredScreen extends ConsumerWidget {
  const DownloadRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_download_outlined,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              'Model Download Required',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'To use this feature, the AI model needs to be downloaded to your device. This happens only once.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            GradientButton(
              text: 'Download Now',
              onPressed: () {
                // Navigate to model setup screen to start download
                ref.read(setupProvider.notifier).goBackToModelSetup();
                context.go(AppRoutes.modelSetup);
              },
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
