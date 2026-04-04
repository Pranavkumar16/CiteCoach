import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/preferences/user_preferences.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../routing/app_router.dart';
import '../../setup/data/model_downloader.dart';
import '../../setup/providers/setup_provider.dart';
import 'widgets/theme_selector.dart';

/// Full settings screen with appearance, model management, and preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lowPowerMode = false;
  double _speechSpeed = 1.0;
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
    } else if (key == StorageKeys.cacheEnabled && value is bool) {
      await storage.setCacheEnabled(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);
    final haptics = ref.read(appHapticsProvider);
    final appTheme = Theme.of(context).extension<AppThemeData>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ========== APPEARANCE ==========
          _buildSectionHeader('Appearance'),
          const ThemeSelector(),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Slider(
              value: prefs.fontScale.index.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              label: prefs.fontScale.label,
              onChanged: (v) {
                haptics.selection();
                prefsNotifier.setFontScale(FontScale.values[v.toInt()]);
              },
            ),
          ),
          _buildChoiceTile<ChatStyle>(
            icon: Icons.chat_bubble_outline,
            title: 'Chat Style',
            currentLabel: prefs.chatStyle.label,
            options: ChatStyle.values,
            getLabel: (s) => s.label,
            getSubtitle: (s) => s.description,
            selected: prefs.chatStyle,
            onSelect: (v) {
              haptics.selection();
              prefsNotifier.setChatStyle(v);
            },
          ),
          _buildChoiceTile<CitationDisplay>(
            icon: Icons.format_quote,
            title: 'Citation Display',
            currentLabel: prefs.citationDisplay.label,
            options: CitationDisplay.values,
            getLabel: (s) => s.label,
            getSubtitle: (s) => s.description,
            selected: prefs.citationDisplay,
            onSelect: (v) {
              haptics.selection();
              prefsNotifier.setCitationDisplay(v);
            },
          ),

          const Divider(height: 1),

          // ========== AI MODEL ==========
          _buildSectionHeader('AI Model'),
          _buildTile(
            icon: Icons.smart_toy_outlined,
            title: 'Model Status',
            subtitle: setupState.isModelDownloaded
                ? 'Qwen 2.5 — Ready'
                : 'Not downloaded',
            trailing: setupState.isModelDownloaded
                ? Icon(Icons.check_circle,
                    color: appTheme?.success ?? AppColors.success, size: 20)
                : TextButton(
                    onPressed: () => context.push(AppRoutes.downloadRequired),
                    child: const Text('Download'),
                  ),
            onTap: () {
              haptics.light();
              context.push(AppRoutes.modelInfo);
            },
          ),
          _buildTile(
            icon: Icons.storage_outlined,
            title: 'Model Storage',
            subtitle: _modelSizeBytes > 0
                ? '${(_modelSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
                : 'No models downloaded',
          ),

          const Divider(height: 1),

          // ========== PERFORMANCE ==========
          _buildSectionHeader('Performance'),
          SwitchListTile(
            secondary: const Icon(Icons.battery_saver),
            title: const Text('Low Power Mode'),
            subtitle: const Text('Reduce model quality for longer battery life'),
            value: _lowPowerMode,
            onChanged: (v) {
              haptics.selection();
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
              haptics.selection();
              setState(() => _cacheEnabled = v);
              _saveSetting(StorageKeys.cacheEnabled, v);
            },
          ),

          const Divider(height: 1),

          // ========== VOICE ==========
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
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Auto-read Responses'),
            subtitle: const Text('Read AI answers aloud automatically'),
            value: prefs.autoReadResponses,
            onChanged: (v) {
              haptics.selection();
              prefsNotifier.setAutoReadResponses(v);
            },
          ),

          const Divider(height: 1),

          // ========== ACCESSIBILITY ==========
          _buildSectionHeader('Accessibility'),
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: const Text('High Contrast'),
            subtitle: const Text('Stronger borders and text contrast'),
            value: prefs.highContrast,
            onChanged: (v) {
              haptics.selection();
              prefsNotifier.setHighContrast(v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.motion_photos_off_outlined),
            title: const Text('Reduce Motion'),
            subtitle: const Text('Disable animations and transitions'),
            value: prefs.reduceMotion,
            onChanged: (v) {
              haptics.selection();
              prefsNotifier.setReduceMotion(v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on taps and actions'),
            value: prefs.hapticFeedback,
            onChanged: (v) {
              prefsNotifier.setHapticFeedback(v);
            },
          ),

          const Divider(height: 1),

          // ========== ABOUT ==========
          _buildSectionHeader('About'),
          _buildTile(
            icon: Icons.info_outline,
            title: 'CiteCoach',
            subtitle: 'Version ${AppStrings.appVersion}',
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: '100% offline — your data never leaves your device',
            onTap: () => _showPrivacyInfo(context),
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Open Source Licenses',
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
              icon: Icon(Icons.restart_alt,
                  color: appTheme?.error ?? AppColors.errorRed),
              label: Text('Reset App',
                  style: TextStyle(
                      color: appTheme?.error ?? AppColors.errorRed)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: appTheme?.error ?? AppColors.errorRed),
              ),
              onPressed: () {
                haptics.medium();
                _confirmReset(context);
              },
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final appTheme = Theme.of(context).extension<AppThemeData>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: appTheme?.textSecondary ?? AppColors.textSecondary,
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
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  Widget _buildChoiceTile<T>({
    required IconData icon,
    required String title,
    required String currentLabel,
    required List<T> options,
    required String Function(T) getLabel,
    required String Function(T) getSubtitle,
    required T selected,
    required void Function(T) onSelect,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(currentLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showChoiceSheet<T>(
        title: title,
        options: options,
        getLabel: getLabel,
        getSubtitle: getSubtitle,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }

  void _showChoiceSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) getLabel,
    required String Function(T) getSubtitle,
    required T selected,
    required void Function(T) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ...options.map((opt) {
                final isSelected = opt == selected;
                return ListTile(
                  title: Text(getLabel(opt)),
                  subtitle: Text(getSubtitle(opt)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

