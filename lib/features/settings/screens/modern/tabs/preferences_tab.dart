import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/glassmorphism.dart';
import '../../../../dashboard/dashboard_screen.dart';
import '../../../providers/extended_settings_provider.dart';

/// Preferences Tab
class PreferencesTab extends ConsumerWidget {
  const PreferencesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(extendedSettingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: [
        GlassCard(
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'Notifications',
                subtitle: 'Get notified about automation events',
                icon: Icons.notifications,
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  // TODO: Toggle
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Auto-refresh Metrics',
                subtitle: 'Automatically update system metrics',
                icon: Icons.refresh,
                value: settings.autoRefreshMetrics,
                onChanged: (value) {
                  // TODO: Toggle
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Automation Enabled',
                subtitle: 'Allow automations to run',
                icon: Icons.auto_awesome,
                value: settings.automationEnabled,
                onChanged: (value) {
                  // TODO: Toggle
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Retry Failed Tasks',
                subtitle: 'Automatically retry failed automations',
                icon: Icons.replay,
                value: settings.retryFailedTasks,
                onChanged: (value) {
                  // TODO: Toggle
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.systemGreen,
          ),
        ],
      ),
    );
  }
}
