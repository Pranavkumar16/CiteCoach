import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/storage_service.dart';
import '../../setup/domain/setup_state.dart';
import '../../setup/providers/setup_provider.dart';

/// Settings screen with app configuration options.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _speechSpeed = 1.0;
  bool _lowPowerMode = false;
  bool _hapticFeedback = true;
  bool _cacheEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _speechSpeed = storage.speechSpeed;
      _lowPowerMode = storage.isLowPowerMode;
      _hapticFeedback = storage.isHapticFeedback;
      _cacheEnabled = storage.isCacheEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final isModelDownloaded = setupState.isModelDownloaded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        children: [
          // Offline Status Section
          _buildSectionHeader('OFFLINE STATUS'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.lock_outline,
              iconColor: AppColors.success,
              title: 'Offline Mode',
              subtitle: 'Always active - your data never leaves your device',
              trailing: Switch(
                value: true,
                onChanged: null, // Locked ON
                activeColor: AppColors.primaryIndigo,
              ),
            ),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // AI Model Section
          _buildSectionHeader('AI MODEL'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: isModelDownloaded ? Icons.check_circle : Icons.download,
              iconColor: isModelDownloaded ? AppColors.success : AppColors.warning,
              title: 'Intelligence Engine',
              subtitle: isModelDownloaded 
                  ? 'Gemma 2B ready (1.5 GB)'
                  : 'Download required for chat',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
              onTap: () => context.push('/model-info'),
            ),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // Performance Section
          _buildSectionHeader('PERFORMANCE'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.bolt,
              iconColor: AppColors.warning,
              title: 'Low-Power Mode',
              subtitle: 'Shorter answers to save battery',
              trailing: Switch(
                value: _lowPowerMode,
                onChanged: (value) async {
                  setState(() => _lowPowerMode = value);
                  final storage = ref.read(storageServiceProvider);
                  await storage.setLowPowerMode(value);
                },
                activeColor: AppColors.primaryIndigo,
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              icon: Icons.cached,
              iconColor: AppColors.primaryIndigo,
              title: 'Answer Cache',
              subtitle: 'Cache responses for faster repeat questions',
              trailing: Switch(
                value: _cacheEnabled,
                onChanged: (value) async {
                  setState(() => _cacheEnabled = value);
                  final storage = ref.read(storageServiceProvider);
                  await storage.setCacheEnabled(value);
                },
                activeColor: AppColors.primaryIndigo,
              ),
            ),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // Voice Section
          _buildSectionHeader('VOICE'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.volume_up,
              iconColor: AppColors.primaryPurple,
              title: 'Speech Speed',
              subtitle: '${_speechSpeed.toStringAsFixed(1)}x',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _speechSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  onChanged: (value) async {
                    setState(() => _speechSpeed = value);
                    final storage = ref.read(storageServiceProvider);
                    await storage.setSpeechSpeed(value);
                  },
                ),
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              icon: Icons.vibration,
              iconColor: AppColors.primaryIndigo,
              title: 'Haptic Feedback',
              subtitle: 'Vibration on interactions',
              trailing: Switch(
                value: _hapticFeedback,
                onChanged: (value) async {
                  setState(() => _hapticFeedback = value);
                  final storage = ref.read(storageServiceProvider);
                  await storage.setHapticFeedback(value);
                },
                activeColor: AppColors.primaryIndigo,
              ),
            ),
          ]),

          const SizedBox(height: AppDimensions.spacingLg),

          // About Section
          _buildSectionHeader('ABOUT'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.textSecondary,
              title: 'Version',
              subtitle: '1.0.0',
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              iconColor: AppColors.textSecondary,
              title: 'Privacy Policy',
              trailing: const Icon(
                Icons.open_in_new,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onTap: () {
                // Open privacy policy
              },
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              icon: Icons.gavel_outlined,
              iconColor: AppColors.textSecondary,
              title: 'Terms of Service',
              trailing: const Icon(
                Icons.open_in_new,
                size: 18,
                color: AppColors.textTertiary,
              ),
              onTap: () {
                // Open terms
              },
            ),
          ]),

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

  Widget _buildSettingsCard(List<Widget> children) {
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryIndigo).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primaryIndigo,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingXs,
      ),
    );
  }
}
