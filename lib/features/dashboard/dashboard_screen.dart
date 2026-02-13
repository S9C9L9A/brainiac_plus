import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_icons.dart';
import '../file_manager/file_manager_screen.dart';
import '../terminal/terminal_screen.dart';
import '../packages/packages_screen.dart';
import '../automation/automation_screen.dart';
import 'controllers/resource_controller.dart';
import 'widgets/metric_card.dart';
import 'screens/cpu_detail_screen.dart';
import 'screens/ram_detail_screen.dart';
import 'screens/disk_detail_screen.dart';

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
                    const Icon(AppIcons.brain, color: Colors.white, size: AppIcons.defaultSize),
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
                    icon: const Icon(AppIcons.settings, color: Colors.white, size: AppIcons.defaultSize),
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
                              Expanded(child: _buildCpuCard(context, stats)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRamCard(context, stats)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDiskCard(context, stats)),
                            ],
                          );
                        } else {
                          // Mobile layout - stacked
                          return Column(
                            children: [
                              _buildCpuCard(context, stats),
                              const SizedBox(height: 16),
                              _buildRamCard(context, stats),
                              const SizedBox(height: 16),
                              _buildDiskCard(context, stats),
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
                          AppIcons.terminal,
                          AppColors.systemBlue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TerminalScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Files',
                          AppIcons.folder,
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
                          AppIcons.apps,
                          AppColors.systemGreen,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PackagesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Automation',
                          AppIcons.automation,
                          AppColors.systemPurple,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AutomationScreen(),
                            ),
                          ),
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

  Widget _buildCpuCard(BuildContext context, SystemStats stats) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CpuDetailScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: MetricCard(
        title: 'CPU Usage',
        value: '${stats.cpuUsage.toStringAsFixed(1)}%',
        subtitle: 'Processor activity',
        icon: AppIcons.cpu,
        percentage: stats.cpuUsage,
        color: AppColors.systemBlue,
      ),
    );
  }

  Widget _buildRamCard(BuildContext context, SystemStats stats) {
    final ramPercent = stats.ramUsage['percentage'] as double;
    final usedGB = stats.ramUsage['usedGB'] as String;
    final totalGB = stats.ramUsage['totalGB'] as String;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RamDetailScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: MetricCard(
        title: 'Memory',
        value: '${ramPercent.toStringAsFixed(1)}%',
        subtitle: '$usedGB GB / $totalGB GB',
        icon: AppIcons.memory,
        percentage: ramPercent,
        color: AppColors.systemPurple,
      ),
    );
  }

  Widget _buildDiskCard(BuildContext context, SystemStats stats) {
    final diskPercent = stats.diskUsage['percentage'] as int;
    final used = stats.diskUsage['used'] as String;
    final size = stats.diskUsage['size'] as String;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DiskDetailScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: MetricCard(
        title: 'Disk Space',
        value: '$diskPercent%',
        subtitle: '$used / $size',
        icon: AppIcons.disk,
        percentage: diskPercent.toDouble(),
        color: AppColors.systemOrange,
      ),
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
