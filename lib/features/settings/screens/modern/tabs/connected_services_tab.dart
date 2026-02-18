import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/glassmorphism.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../automation/models/automation_enums.dart';
import '../../../../dashboard/dashboard_screen.dart';
import '../../../models/extended_settings.dart';
import '../../../providers/extended_settings_provider.dart';

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

    final devServices = [ServiceProvider.github];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: [
        _buildServiceGroup(context, 'Social Media', socialServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup(context, 'Productivity', productivityServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup(context, 'Communication', communicationServices, settings),
        const SizedBox(height: 24),
        _buildServiceGroup(context, 'Development', devServices, settings),
      ],
    );
  }

  Widget _buildServiceGroup(
    BuildContext context,
    String title,
    List<ServiceProvider> services,
    ExtendedAppSettings settings,
  ) {
    final serviceCards = <Widget>[];
    for (final service in services) {
      serviceCards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(context, service, settings),
        ),
      );
    }

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
        ...serviceCards,
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceProvider service,
    ExtendedAppSettings settings,
  ) {
    final isConnected = settings.isServiceConfigured(service);

    return GestureDetector(
      onTap: () {
        debugPrint('[ServiceConfig] Tapping ${service.label}');
        AppRoutes.navigateTo(
          context,
          AppRoutes.serviceConfig,
          arguments: service,
        );
      },
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isConnected
                      ? LinearGradient(colors: _getServiceGradient(service))
                      : null,
                  color: isConnected
                      ? null
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(service.icon, style: const TextStyle(fontSize: 28)),
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
                              color: AppColors.systemBlue.withValues(
                                alpha: 0.2,
                              ),
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
