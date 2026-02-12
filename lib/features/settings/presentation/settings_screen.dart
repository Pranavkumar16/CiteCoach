import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/battery_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routing/app_router.dart';
import '../../setup/providers/setup_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowPowerMode = ref.watch(lowPowerModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Model & AI'),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('AI Model Info'),
            subtitle: const Text('Manage the embedded LLM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.modelInfo),
          ),
          
          const Divider(),
          _buildSectionHeader(context, 'Performance'),
          SwitchListTile(
            secondary: Icon(Icons.bolt, color: Theme.of(context).primaryColor),
            title: const Text('Low-Power Mode'),
            subtitle: const Text('Shorter answers, saves battery'),
            value: lowPowerMode,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (value) {
              ref.read(lowPowerModeProvider.notifier).toggle(value);
            },
          ),

          const Divider(),
          _buildSectionHeader(context, 'App'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Re-show privacy screen
              context.push(AppRoutes.privacy);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset App'),
            subtitle: const Text('Clear all data and setup'),
            onTap: () => _showResetConfirmation(context, ref),
          ),
          
          const Divider(),
          _buildAppVersion(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAppVersion(BuildContext context) {
    // Hardcoded version since we don't have package_info_plus dependency
    // and cannot run flutter pub add
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'CiteCoach v1.0.0',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
            'This will delete all your documents and reset the app to its initial state. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(setupProvider.notifier).resetSetup();
              // Navigation will handle redirect to splash
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
