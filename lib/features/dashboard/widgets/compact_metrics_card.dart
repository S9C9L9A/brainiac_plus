import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_icons.dart';
import '../controllers/system_metrics_provider.dart';

/// Compact horizontal metrics card showing CPU, RAM, Disk in single row
class CompactMetricsCard extends ConsumerWidget {
  const CompactMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get real system metrics from provider
    final metrics = ref.watch(systemMetricsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // CPU
          Expanded(
            child: _MetricItem(
              icon: AppIcons.cpu,
              label: 'CPU',
              value: '${metrics.cpuUsage.toStringAsFixed(1)}%',
              color: _getMetricColor(metrics.cpuUsage),
              onTap: () {
                Navigator.pushNamed(context, '/cpu-detail');
              },
            ),
          ),
          
          _buildDivider(),
          
          // RAM
          Expanded(
            child: _MetricItem(
              icon: AppIcons.ram,
              label: 'RAM',
              value: '${metrics.memoryUsage.toStringAsFixed(1)}%',
              color: _getMetricColor(metrics.memoryUsage),
              onTap: () {
                Navigator.pushNamed(context, '/ram-detail');
              },
            ),
          ),
          
          _buildDivider(),
          
          // Disk
          Expanded(
            child: _MetricItem(
              icon: AppIcons.disk,
              label: 'Disk',
              value: '${metrics.diskUsage.toStringAsFixed(1)}%',
              color: _getMetricColor(metrics.diskUsage),
              onTap: () {
                Navigator.pushNamed(context, '/disk-detail');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Color _getMetricColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 75) return Colors.orange;
    return Colors.red;
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with subtle glow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Value
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Label
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
