import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/theme/app_icons.dart';
import '../../dashboard/dashboard_screen.dart'; // For kBottomNavHeight
import '../controllers/settings_controller.dart';
import '../models/app_settings.dart';
import '../../../core/services/instagram_oauth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _higgsfieldKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  
  // TODO: Get from environment or config
  final _instagramOAuth = InstagramOAuthService(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
  );

  @override
  void dispose() {
    _higgsfieldKeyController.dispose();
    _openaiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavHeight),
                  children: [
                    _buildSection(
                      title: 'API Keys',
                      icon: AppIcons.key,
                      children: [
                        _buildApiKeyField(
                          label: 'Higgsfield API Key',
                          controller: _higgsfieldKeyController,
                          hasKey: settings.hasHiggsfieldKey,
                          onSave: () => _saveHiggsfieldKey(),
                        ),
                        const SizedBox(height: 16),
                        _buildApiKeyField(
                          label: 'OpenAI API Key (Optional)',
                          controller: _openaiKeyController,
                          hasKey: settings.openaiApiKey != null,
                          onSave: () => _saveOpenAIKey(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Instagram',
                      icon: AppIcons.instagram,
                      children: [
                        if (settings.hasInstagramAuth)
                          _buildConnectedAccount(settings)
                        else
                          _buildConnectButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Preferences',
                      icon: AppIcons.settings,
                      children: [
                        _buildSwitch(
                          title: 'Notifications',
                          value: settings.notificationsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleNotifications(v),
                        ),
                        _buildSwitch(
                          title: 'Auto-refresh Metrics',
                          value: settings.autoRefreshMetrics,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleAutoRefresh(v),
                        ),
                        _buildSlider(
                          title: 'Refresh Interval',
                          value: settings.refreshInterval.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '${settings.refreshInterval}s',
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .setRefreshInterval(v.toInt()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Setup & Configuration',
                      icon: Icons.settings_suggest,
                      children: [
                        _buildActionTile(
                          title: 'Riavvia Setup Guidato',
                          subtitle: 'Riconfigura i servizi social',
                          icon: Icons.restart_alt,
                          onTap: () => _resetSetup(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Automation',
                      icon: AppIcons.automation,
                      children: [
                        _buildSwitch(
                          title: 'Enable Automation',
                          value: settings.automationEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleAutomation(v),
                        ),
                        _buildSwitch(
                          title: 'Retry Failed Tasks',
                          value: settings.retryFailedTasks,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleRetry(v),
                        ),
                        _buildSlider(
                          title: 'Max Retries',
                          value: settings.maxRetries.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${settings.maxRetries}',
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .setMaxRetries(v.toInt()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(AppIcons.settings, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.systemBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required TextEditingController controller,
    required bool hasKey,
    required VoidCallback onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: hasKey ? '••••••••••••' : 'Enter API key',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            suffixIcon: hasKey
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasKey ? Colors.green : Colors.white30,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.systemBlue),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.systemBlue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedAccount(AppSettings settings) {
    final isExpired = settings.isInstagramTokenExpired;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isExpired
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isExpired ? Colors.red : Colors.green,
                child: Text(
                  settings.instagramUsername![0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${settings.instagramUsername}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isExpired ? 'Token expired' : 'Connected',
                      style: TextStyle(
                        color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpired)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _refreshInstagramToken(),
                ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _disconnectInstagram(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _connectInstagram(),
        icon: const Icon(Icons.login),
        label: const Text('Connect Instagram'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      activeColor: AppColors.systemBlue,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.systemBlue),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: $label',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          activeColor: AppColors.systemBlue,
          inactiveColor: Colors.white30,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _clearAllSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear All Settings'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveHiggsfieldKey() async {
    final key = _higgsfieldKeyController.text.trim();
    if (key.isEmpty) return;

    await ref.read(settingsControllerProvider.notifier).saveHiggsfieldKey(key);
    _higgsfieldKeyController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Higgsfield API key saved')),
    );
  }

  void _saveOpenAIKey() async {
    final key = _openaiKeyController.text.trim();
    if (key.isEmpty) return;

    await ref.read(settingsControllerProvider.notifier).saveOpenAIKey(key);
    _openaiKeyController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ OpenAI API key saved')),
    );
  }

  void _connectInstagram() async {
    try {
      await _instagramOAuth.authorize();
      // TODO: Handle OAuth callback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening Instagram authorization...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e')),
      );
    }
  }

  void _refreshInstagramToken() async {
    // TODO: Implement token refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Refreshing Instagram token...')),
    );
  }

  void _disconnectInstagram() async {
    await ref.read(settingsControllerProvider.notifier).disconnectInstagram();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Instagram disconnected')),
    );
  }

  void _clearAllSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Settings?'),
        content: const Text('This will remove all API keys and preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(settingsControllerProvider.notifier).clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ All settings cleared')),
      );
    }
  }

  void _resetSetup(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Riavvia Setup?'),
        content: const Text(
          'Questo riavvierà il wizard di configurazione iniziale. '
          'Le tue impostazioni attuali rimarranno salvate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Riavvia Setup'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Reset setup completion flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_completed', false);

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/setup-wizard',
          (route) => false,
        );
      }
    }
  }
}
