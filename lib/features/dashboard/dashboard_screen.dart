import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../file_manager/file_manager_screen.dart';
import 'controllers/resource_controller.dart';
import 'widgets/metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(resourceControllerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'BrainiacPlus',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      // TODO: Navigate to settings
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome text
                    Text(
                      'System Monitor',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time performance metrics',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 30),

                    // Metrics Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        
                        if (isWide) {
                          // Desktop layout - 3 columns
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildCpuCard(stats)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRamCard(stats)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDiskCard(stats)),
                            ],
                          );
                        } else {
                          // Mobile layout - stacked
                          return Column(
                            children: [
                              _buildCpuCard(stats),
                              const SizedBox(height: 16),
                              _buildRamCard(stats),
                              const SizedBox(height: 16),
                              _buildDiskCard(stats),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          context,
                          'Terminal',
                          Icons.terminal,
                          AppColors.systemBlue,
                          () {
                            // TODO: Navigate to terminal
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Files',
                          Icons.folder,
                          AppColors.systemOrange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FileManagerScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Packages',
                          Icons.apps,
                          AppColors.systemGreen,
                          () {
                            // TODO: Navigate to packages
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Automation',
                          Icons.autorenew,
                          AppColors.systemPurple,
                          () {
                            // TODO: Navigate to automation
                          },
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCpuCard(SystemStats stats) {
    return MetricCard(
      title: 'CPU Usage',
      value: '${stats.cpuUsage.toStringAsFixed(1)}%',
      subtitle: 'Processor activity',
      icon: Icons.memory,
      percentage: stats.cpuUsage,
      color: AppColors.systemBlue,
    );
  }

  Widget _buildRamCard(SystemStats stats) {
    final ramPercent = stats.ramUsage['percentage'] as double;
    final usedGB = stats.ramUsage['usedGB'] as String;
    final totalGB = stats.ramUsage['totalGB'] as String;

    return MetricCard(
      title: 'Memory',
      value: '${ramPercent.toStringAsFixed(1)}%',
      subtitle: '$usedGB GB / $totalGB GB',
      icon: Icons.storage,
      percentage: ramPercent,
      color: AppColors.systemPurple,
    );
  }

  Widget _buildDiskCard(SystemStats stats) {
    final diskPercent = stats.diskUsage['percentage'] as int;
    final used = stats.diskUsage['used'] as String;
    final size = stats.diskUsage['size'] as String;

    return MetricCard(
      title: 'Disk Space',
      value: '$diskPercent%',
      subtitle: '$used / $size',
      icon: Icons.sd_storage,
      percentage: diskPercent.toDouble(),
      color: AppColors.systemOrange,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
