import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../setup/providers/setup_provider.dart';

class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final isDownloaded = setupState.isModelDownloaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            context,
            icon: Icons.psychology,
            title: 'TinyLlama 1.1B',
            subtitle: 'Quantized (Q4_0)',
            description: 'A compact 1.1 billion parameter language model optimized for mobile devices. It runs completely offline.',
          ),
          const SizedBox(height: 16),
          _buildStatusCard(context, isDownloaded),
          const SizedBox(height: 24),
          if (!isDownloaded)
            ElevatedButton.icon(
              onPressed: () {
                // Retry download
                ref.read(setupProvider.notifier).retryDownload();
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Model'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDownloaded) {
    final color = isDownloaded ? Colors.green : Colors.orange;
    final icon = isDownloaded ? Icons.check_circle : Icons.warning_amber_rounded;
    final text = isDownloaded ? 'Model Ready' : 'Model Missing';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
