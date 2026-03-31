import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';

/// Screen showing AI model details, storage usage, and management options.
class ModelInfoScreen extends ConsumerStatefulWidget {
  const ModelInfoScreen({super.key});

  @override
  ConsumerState<ModelInfoScreen> createState() => _ModelInfoScreenState();
}

class _ModelInfoScreenState extends ConsumerState<ModelInfoScreen> {
  int _modelSizeBytes = 0;
  bool _modelExists = false;

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
  }

  Future<void> _loadModelInfo() async {
    final downloader = ref.read(modelDownloaderProvider);
    final size = await downloader.getDownloadedSize();
    final exists = await downloader.isModelDownloaded();
    if (mounted) {
      setState(() {
        _modelSizeBytes = size;
        _modelExists = exists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Model Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.smart_toy, color: AppColors.textOnPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Offline Engine',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _modelExists ? 'Downloaded & Ready' : 'Not Downloaded',
                              style: TextStyle(
                                color: _modelExists
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_modelExists)
                        const Icon(Icons.check_circle, color: AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Details
          Card(
            child: Column(
              children: [
                _infoRow('Type', 'Offline Intelligence Engine'),
                const Divider(height: 1),
                _infoRow('Storage Used',
                    _modelSizeBytes > 0
                        ? '${(_modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
                        : '—'),
                const Divider(height: 1),
                _infoRow('Version', ModelDownloader.modelVersion),
                const Divider(height: 1),
                _infoRow('Processing', '100% On-Device'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Capabilities
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capabilities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _capabilityRow(Icons.question_answer, 'Document Q&A with citations'),
                  _capabilityRow(Icons.summarize, 'Context-aware answers'),
                  _capabilityRow(Icons.security, 'Fully offline & private'),
                  _capabilityRow(Icons.speed, 'Optimized for mobile devices'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Delete model
          if (_modelExists)
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              label: const Text('Delete Model',
                  style: TextStyle(color: AppColors.errorRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorRed),
              ),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _capabilityRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete AI Model?'),
        content: const Text(
          'This will delete the downloaded model and disable chat functionality. '
          'You can re-download it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final downloader = ref.read(modelDownloaderProvider);
              await downloader.deleteModels();
              await _loadModelInfo();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
