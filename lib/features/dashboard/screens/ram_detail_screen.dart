import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/theme/app_icons.dart';
import '../controllers/process_controller.dart';

class RamDetailScreen extends ConsumerStatefulWidget {
  const RamDetailScreen({super.key});

  @override
  ConsumerState<RamDetailScreen> createState() => _RamDetailScreenState();
}

class _RamDetailScreenState extends ConsumerState<RamDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(processControllerProvider.notifier).loadTopMemProcesses());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final processesAsync = ref.watch(processControllerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(AppIcons.arrowBack, color: Colors.white, size: AppIcons.defaultSize),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.systemPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(AppIcons.memory, color: AppColors.systemPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RAM Usage',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Top processes by memory',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.refresh, color: Colors.white, size: AppIcons.defaultSize),
                      onPressed: () {
                        ref.read(processControllerProvider.notifier).loadTopMemProcesses();
                      },
                    ),
                  ],
                ),
              ),

              // Process List
              Expanded(
                child: processesAsync.when(
                  data: (processes) {
                    if (processes.isEmpty) {
                      return Center(
                        child: Text(
                          'No processes found',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: processes.length,
                      itemBuilder: (context, index) {
                        final process = processes[index];
                        return _buildProcessCard(context, process, isDark);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.systemPurple),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.error, color: AppColors.systemRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading processes',
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessCard(BuildContext context, ProcessInfo process, bool isDark) {
    final cpuValue = double.tryParse(process.cpu) ?? 0.0;
    final memValue = double.tryParse(process.mem) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        process.command.length > 40
                            ? '${process.command.substring(0, 40)}...'
                            : process.command,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PID: ${process.pid} • User: ${process.user}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close, color: AppColors.systemRed, size: AppIcons.defaultSize),
                  onPressed: () => _confirmKillProcess(context, process),
                  tooltip: 'Kill process',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetric('Memory', '${memValue.toStringAsFixed(1)}%', AppColors.systemPurple, memValue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetric('CPU', '${cpuValue.toStringAsFixed(1)}%', AppColors.systemBlue, cpuValue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmKillProcess(BuildContext context, ProcessInfo process) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: const Text('Kill Process?'),
        content: Text('Are you sure you want to kill process "${process.command}"?\n\nPID: ${process.pid}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.systemRed),
            child: const Text('Kill'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(processControllerProvider.notifier).killProcess(process.pid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Process killed successfully' : 'Failed to kill process'),
            backgroundColor: success ? AppColors.systemGreen : AppColors.systemRed,
          ),
        );
        if (success) {
          ref.read(processControllerProvider.notifier).loadTopMemProcesses();
        }
      }
    }
  }
}
