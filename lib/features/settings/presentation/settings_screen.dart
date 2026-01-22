import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../routing/app_router.dart';
import '../../setup/providers/setup_provider.dart';
import '../providers/settings_provider.dart';

/// Application settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        children: [
          _SectionHeader(title: AppStrings.offlineStatus),
          _StatusTile(
            icon: Icons.cloud_off_rounded,
            title: AppStrings.offlineMode,
            subtitle: setupState.isModelDownloaded
                ? AppStrings.alwaysActive
                : AppStrings.downloadRequiredTitle,
            trailing: setupState.isModelDownloaded ? 'Ready' : 'Limited',
          ),
          _NavigationTile(
            icon: Icons.info_outline_rounded,
            title: AppStrings.modelInfo,
            subtitle: setupState.isModelDownloaded
                ? AppStrings.ready
                : AppStrings.downloadRequiredTitle,
            onTap: () => context.push(AppRoutes.modelInfo),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _SectionHeader(title: AppStrings.performance),
          SwitchListTile(
            value: settingsState.lowPowerMode,
            onChanged: settingsNotifier.setLowPowerMode,
            title: const Text(AppStrings.lowPowerMode),
            subtitle: const Text('Reduce background processing to save battery'),
          ),
          SwitchListTile(
            value: settingsState.cacheEnabled,
            onChanged: settingsNotifier.setCacheEnabled,
            title: const Text('Answer cache'),
            subtitle: const Text('Reuse recent answers for faster responses'),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _SectionHeader(title: AppStrings.voice),
          _SpeechSpeedTile(
            value: settingsState.speechSpeed,
            onChanged: settingsNotifier.previewSpeechSpeed,
            onChangeEnd: settingsNotifier.setSpeechSpeed,
          ),
          SwitchListTile(
            value: settingsState.hapticFeedback,
            onChanged: settingsNotifier.setHapticFeedback,
            title: const Text('Haptic feedback'),
            subtitle: const Text('Vibrate on key actions'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacingXxs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryIndigo,
                ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryIndigo),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SpeechSpeedTile extends StatelessWidget {
  const _SpeechSpeedTile({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.speechSpeed,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${value.toStringAsFixed(1)}x',
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${value.toStringAsFixed(1)}x',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
