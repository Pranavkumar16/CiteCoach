import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../routing/app_router.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';

/// Full settings screen with model management, storage, and app info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lowPowerMode = false;
  double _speechSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _cacheEnabled = true;
  int _modelSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final downloader = ref.read(modelDownloaderProvider);
    final size = await downloader.getDownloadedSize();
    setState(() {
      _lowPowerMode = storage.isLowPowerMode;
      _speechSpeed = storage.speechSpeed;
      _hapticFeedback = storage.isHapticFeedback;
      _cacheEnabled = storage.isCacheEnabled;
      _modelSizeBytes = size;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final storage = ref.read(storageServiceProvider);
    if (key == StorageKeys.lowPowerMode && value is bool) {
      await storage.setLowPowerMode(value);
    } else if (key == StorageKeys.speechSpeed && value is double) {
      await storage.setSpeechSpeed(value);
    } else if (key == StorageKeys.hapticFeedback && value is bool) {
      await storage.setHapticFeedback(value);
    } else if (key == StorageKeys.cacheEnabled && value is bool) {
      await storage.setCacheEnabled(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // AI Model Section
          _buildSectionHeader('AI Model'),
          _buildTile(
            icon: Icons.smart_toy_outlined,
            title: 'Model Status',
            subtitle: setupState.isModelDownloaded
                ? 'AI Engine — Ready'
                : 'Not downloaded',
            trailing: setupState.isModelDownloaded
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                : TextButton(
                    onPressed: () => context.push(AppRoutes.downloadRequired),
                    child: const Text('Download'),
                  ),
            onTap: () => context.push(AppRoutes.modelInfo),
          ),
          _buildTile(
            icon: Icons.storage_outlined,
            title: 'Model Storage',
            subtitle: _modelSizeBytes > 0
                ? '${(_modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
                : 'No models downloaded',
          ),

          const Divider(height: 1),

          // Performance Section
          _buildSectionHeader('Performance'),
          SwitchListTile(
            secondary: const Icon(Icons.battery_saver),
            title: const Text('Low Power Mode'),
            subtitle: const Text('Reduce model quality for longer battery life'),
            value: _lowPowerMode,
            onChanged: (v) {
              setState(() => _lowPowerMode = v);
              _saveSetting(StorageKeys.lowPowerMode, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.cached),
            title: const Text('Response Cache'),
            subtitle: const Text('Cache answers for instant repeat queries'),
            value: _cacheEnabled,
            onChanged: (v) {
              setState(() => _cacheEnabled = v);
              _saveSetting(StorageKeys.cacheEnabled, v);
            },
          ),

          const Divider(height: 1),

          // Voice Section
          _buildSectionHeader('Voice'),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Speech Speed'),
            subtitle: Slider(
              value: _speechSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${_speechSpeed.toStringAsFixed(1)}x',
              onChanged: (v) {
                setState(() => _speechSpeed = v);
                _saveSetting(StorageKeys.speechSpeed, v);
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on voice recording events'),
            value: _hapticFeedback,
            onChanged: (v) {
              setState(() => _hapticFeedback = v);
              _saveSetting(StorageKeys.hapticFeedback, v);
            },
          ),

          const Divider(height: 1),

          // About Section
          _buildSectionHeader('About'),
          _buildTile(
            icon: Icons.info_outline,
            title: 'CiteCoach',
            subtitle: 'Version ${AppStrings.appVersion}',
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: '100% offline — your data never leaves your device',
            onTap: () => _showPrivacyInfo(context),
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppStrings.appName,
              applicationVersion: AppStrings.appVersion,
            ),
          ),

          const SizedBox(height: 32),

          // Reset option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt, color: AppColors.errorRed),
              label: const Text('Reset App',
                  style: TextStyle(color: AppColors.errorRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorRed),
              ),
              onPressed: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Data'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CiteCoach is designed with privacy as the foundation.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text('• All AI processing happens on your device'),
              SizedBox(height: 4),
              Text('• No documents are uploaded to any server'),
              SizedBox(height: 4),
              Text('• No internet required after model download'),
              SizedBox(height: 4),
              Text('• No analytics or tracking'),
              SizedBox(height: 4),
              Text('• Your conversations stay on your device'),
              SizedBox(height: 12),
              Text('The only network request CiteCoach makes is the '
                  'initial one-time AI model download.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset CiteCoach?'),
        content: const Text(
          'This will delete all documents, conversations, cached responses, '
          'and downloaded models. This cannot be undone.',
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
              await ref.read(setupProvider.notifier).resetSetup();
              if (mounted) context.go(AppRoutes.splash);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}
