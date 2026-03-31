import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../routing/app_router.dart';
import '../../setup/providers/setup_provider.dart';

/// Settings screen matching wireframe: Offline Status, Performance, Voice.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lowPowerMode = false;
  double _speechSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _lowPowerMode = storage.isLowPowerMode;
      _speechSpeed = storage.speechSpeed;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final storage = ref.read(storageServiceProvider);
    if (key == StorageKeys.lowPowerMode && value is bool) {
      await storage.setLowPowerMode(value);
    } else if (key == StorageKeys.speechSpeed && value is double) {
      await storage.setSpeechSpeed(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // Offline Status Section
          _buildSectionHeader(AppStrings.offlineStatus),
          ListTile(
            leading: const Icon(Icons.lock_outlined),
            title: const Text(AppStrings.offlineMode),
            subtitle: const Text(AppStrings.alwaysActive),
            trailing: Switch(
              value: true,
              onChanged: null, // Always on, disabled
              activeColor: AppColors.accent,
            ),
          ),

          const Divider(height: 1),

          // Performance Section
          _buildSectionHeader(AppStrings.performance),
          SwitchListTile(
            secondary: const Icon(Icons.bolt_outlined),
            title: const Text(AppStrings.lowPowerMode),
            value: _lowPowerMode,
            onChanged: (v) {
              setState(() => _lowPowerMode = v);
              _saveSetting(StorageKeys.lowPowerMode, v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text(AppStrings.modelInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.modelInfo),
          ),

          const Divider(height: 1),

          // Voice Section
          _buildSectionHeader(AppStrings.voice),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text(AppStrings.speechSpeed),
            subtitle: Text(_speedLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSpeedPicker(context),
          ),
        ],
      ),
    );
  }

  String get _speedLabel {
    if (_speechSpeed == 1.0) return 'Normal (1.0x)';
    return '${_speechSpeed.toStringAsFixed(1)}x';
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

  void _showSpeedPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Speech Speed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _speechSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${_speechSpeed.toStringAsFixed(1)}x',
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _speechSpeed = v);
                  _saveSetting(StorageKeys.speechSpeed, v);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.5x', style: TextStyle(color: AppColors.textSecondary)),
                  Text('2.0x', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
