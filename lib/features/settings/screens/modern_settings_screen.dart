import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../automation/models/automation_enums.dart';
import '../models/extended_settings.dart';

// Mock provider - replace with real implementation
final extendedSettingsProvider = StateProvider<ExtendedAppSettings>(
  (ref) => const ExtendedAppSettings(),
);

class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ConnectedServicesTab(),
                    AIServicesTab(),
                    PreferencesTab(),
                    AboutTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Configure your integrations',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Services'),
          Tab(text: 'AI'),
          Tab(text: 'Preferences'),
          Tab(text: 'About'),
        ],
      ),
    );
  }
}

/// Connected Services Tab
class ConnectedServicesTab extends ConsumerWidget {
  const ConnectedServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(extendedSettingsProvider);
    
    final socialServices = [
      ServiceProvider.instagram,
      ServiceProvider.facebook,
      ServiceProvider.twitter,
      ServiceProvider.tiktok,
      ServiceProvider.linkedin,
      ServiceProvider.youtube,
    ];
    
    final productivityServices = [
      ServiceProvider.notion,
      ServiceProvider.google,
    ];
    
    final communicationServices = [
      ServiceProvider.slack,
      ServiceProvider.discord,
      ServiceProvider.telegram,
    ];
    
    final devServices = [
      ServiceProvider.github,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: [
        _buildServiceGroup('Social Media', socialServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup('Productivity', productivityServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup('Communication', communicationServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup('Development', devServices, settings),
      ],
    );
  }

  Widget _buildServiceGroup(
    String title,
    List<ServiceProvider> services,
    ExtendedAppSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...services.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildServiceCard(service, settings),
            )),
      ],
    );
  }

  Widget _buildServiceCard(ServiceProvider service, ExtendedAppSettings settings) {
    final isConnected = settings.isServiceConfigured(service);
    
    return GlassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to service configuration
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isConnected
                      ? LinearGradient(
                          colors: _getServiceGradient(service),
                        )
                      : null,
                  color: isConnected ? null : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppColors.systemGreen
                                : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            color: isConnected
                                ? AppColors.systemGreen
                                : Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        if (service.supportsAPI && isConnected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.systemBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'API',
                              style: TextStyle(
                                color: AppColors.systemBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isConnected ? Icons.check_circle : Icons.add_circle_outline,
                color: isConnected ? AppColors.systemGreen : Colors.white60,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getServiceGradient(ServiceProvider service) {
    switch (service) {
      case ServiceProvider.instagram:
        return [const Color(0xFFE1306C), const Color(0xFFFD1D1D)];
      case ServiceProvider.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF42B0FF)];
      case ServiceProvider.twitter:
        return [const Color(0xFF1DA1F2), const Color(0xFF0E71C8)];
      case ServiceProvider.linkedin:
        return [const Color(0xFF0077B5), const Color(0xFF00A0DC)];
      case ServiceProvider.youtube:
        return [const Color(0xFFFF0000), const Color(0xFFFF4444)];
      case ServiceProvider.tiktok:
        return [const Color(0xFF000000), const Color(0xFF00F2EA)];
      case ServiceProvider.notion:
        return [const Color(0xFF000000), const Color(0xFFFFFFFF)];
      case ServiceProvider.slack:
        return [const Color(0xFF4A154B), const Color(0xFFE01E5A)];
      case ServiceProvider.github:
        return [const Color(0xFF24292E), const Color(0xFF6E40C9)];
      default:
        return [Colors.purple, Colors.blue];
    }
  }
}

/// AI Services Tab
class AIServicesTab extends ConsumerWidget {
  const AIServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(extendedSettingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: [
        _buildAIServiceCard(
          title: 'OpenAI',
          icon: '🤖',
          description: 'GPT-4, DALL-E, and more',
          isConnected: settings.hasOpenAIKey,
          gradient: [const Color(0xFF10A37F), const Color(0xFF1A7F64)],
        ),
        const SizedBox(height: 12),
        _buildAIServiceCard(
          title: 'Higgsfield',
          icon: '🎬',
          description: 'AI video generation',
          isConnected: settings.hasHiggsfieldKey,
          gradient: [Colors.purple, Colors.blue],
        ),
        const SizedBox(height: 12),
        _buildAIServiceCard(
          title: 'Ollama (Local)',
          icon: '🦙',
          description: 'Run AI models locally',
          isConnected: settings.hasOllamaEndpoint,
          gradient: [const Color(0xFF000000), const Color(0xFF444444)],
        ),
      ],
    );
  }

  Widget _buildAIServiceCard({
    required String title,
    required String icon,
    required String description,
    required bool isConnected,
    required List<Color> gradient,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.systemGreen
                              : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Configured' : 'Not configured',
                        style: TextStyle(
                          color: isConnected
                              ? AppColors.systemGreen
                              : Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Configure
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.systemBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isConnected ? 'Edit' : 'Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.systemGreen,
          ),
        ],
      ),
    );
  }
}

/// About Tab
class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.memory,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BrainiacPlus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your AI-powered automation assistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
