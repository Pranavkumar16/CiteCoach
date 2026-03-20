import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';

/// Settings screen with model management and app info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _modelSizeBytes = 0;
  bool _isModelDownloaded = false;
  bool _isCheckingModel = true;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final downloader = ref.read(modelDownloaderProvider);
    final downloaded = await downloader.isModelDownloaded();
    final size = await downloader.getDownloadedModelSize();
    if (mounted) {
      setState(() {
        _isModelDownloaded = downloaded;
        _modelSizeBytes = size;
        _isCheckingModel = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showDeleteModelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Model'),
        content: const Text(
          'This will remove the downloaded AI model. You will need to '
          'download it again to use the chat feature. Your documents '
          'and chat history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final downloader = ref.read(modelDownloaderProvider);
              await downloader.deleteModel();
              await _checkModelStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI model deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
          'This will reset the app to its initial state. All documents, '
          'chat history, and the AI model will be deleted. This action '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(setupProvider.notifier).resetSetup();
              if (mounted) {
                context.go('/');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
        children: [
          // AI Model section
          _buildSectionHeader('AI Model'),
          _buildModelCard(),
          SizedBox(height: AppDimensions.spacingLg),

          // Privacy section
          _buildSectionHeader('Privacy'),
          _buildPrivacyCard(),
          SizedBox(height: AppDimensions.spacingLg),

          // About section
          _buildSectionHeader('About'),
          _buildAboutCard(),
          SizedBox(height: AppDimensions.spacingLg),

          // Danger zone
          _buildSectionHeader('Advanced'),
          _buildDangerCard(),
          SizedBox(height: AppDimensions.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingXs,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildModelCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            title: const Text(
              'Phi-3.5 Mini',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _isCheckingModel
                  ? 'Checking...'
                  : _isModelDownloaded
                      ? 'Downloaded (${_formatBytes(_modelSizeBytes)})'
                      : 'Not downloaded',
              style: TextStyle(
                color: _isModelDownloaded
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const SizedBox(width: 40),
            title: const Text('Model Version'),
            trailing: Text(
              ModelDownloader.modelVersion,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ListTile(
            leading: const SizedBox(width: 40),
            title: const Text('Quantization'),
            trailing: const Text(
              'Q4_K_M (4-bit)',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (_isModelDownloaded)
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.errorRed, size: 20),
              title: const Text(
                'Delete Model',
                style: TextStyle(color: AppColors.errorRed),
              ),
              onTap: _showDeleteModelDialog,
            )
          else
            ListTile(
              leading: const Icon(Icons.download_rounded,
                  color: AppColors.primaryIndigo, size: 20),
              title: const Text(
                'Download Model',
                style: TextStyle(color: AppColors.primaryIndigo),
              ),
              onTap: () => context.go('/setup/download'),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.shield_outlined,
                color: AppColors.successGreen),
            title: const Text('100% Offline'),
            subtitle: const Text(
                'All processing happens on your device. No data leaves your phone.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_off_outlined,
                color: AppColors.primaryIndigo),
            title: const Text('No Cloud Upload'),
            subtitle: const Text(
                'Your documents are stored locally and never uploaded.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline,
                color: AppColors.primaryIndigo),
            title: const Text('Private by Design'),
            subtitle: const Text(
                'No analytics, no tracking, no user accounts required.'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('CiteCoach'),
            subtitle: const Text('Version 1.0.0'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Offline Document Intelligence'),
            subtitle: Text(
                'Upload textbooks, ask questions, get answers with citations '
                'that link back to the source.'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      child: ListTile(
        leading: const Icon(Icons.restart_alt, color: AppColors.errorRed),
        title: const Text(
          'Reset App',
          style: TextStyle(color: AppColors.errorRed),
        ),
        subtitle: const Text('Delete all data and start fresh'),
        onTap: _showResetDialog,
      ),
    );
  }
}
