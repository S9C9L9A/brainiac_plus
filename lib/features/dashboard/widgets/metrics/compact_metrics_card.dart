import 'package:brainiac_plus/core/services/gpu_metrics_service.dart';
import 'package:brainiac_plus/core/theme/app_icons.dart';
import 'package:brainiac_plus/features/dashboard/controllers/gpu_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/controllers/system_metrics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact horizontal metrics card showing CPU, RAM, Disk (and GPU when
/// present) in a single row
class CompactMetricsCard extends ConsumerWidget {
  const CompactMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get real system metrics from provider
    final metrics = ref.watch(systemMetricsProvider);
    final gpu = ref.watch(gpuMetricsProvider);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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

              // GPU (only when an amdgpu card is detected)
              if (gpu != null) ...[
                _buildDivider(),
                Expanded(
                  child: _MetricItem(
                    icon: AppIcons.gpu,
                    label: 'GPU',
                    value: gpu.busyPercent != null
                        ? '${gpu.busyPercent}%'
                        : '—',
                    color: _getMetricColor((gpu.busyPercent ?? 0).toDouble()),
                    onTap: () => _showGpuDetails(context, gpu),
                  ),
                ),
              ],
            ],
          ),
          if (metrics.loadAverages.isNotEmpty) _buildFootnote(metrics),
        ],
      ),
    );
  }

  /// A slim footnote under the metrics: system load average, and swap when any
  /// is in use — small "at a glance" signals for the machine's real pressure.
  Widget _buildFootnote(SystemMetrics metrics) {
    final load = metrics.loadAverages
        .map((v) => v.toStringAsFixed(2))
        .join('  ');
    final swap = metrics.swapUsedMB > 0
        ? '   ·   swap ${metrics.swapUsagePercent.toStringAsFixed(0)}%'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            'load  $load$swap',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet with the full GPU snapshot (VRAM, temperature, power).
  void _showGpuDetails(BuildContext context, GpuMetrics gpu) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.gpu, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'GPU ${gpu.cardId}${gpu.pciId != null ? ' · ${gpu.pciId}' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GpuDetailRow(
              label: 'Usage',
              value: gpu.busyPercent != null ? '${gpu.busyPercent}%' : 'N/A',
            ),
            _GpuDetailRow(
              label: 'VRAM',
              value: gpu.vramUsedMB != null && gpu.vramTotalMB != null
                  ? '${gpu.vramUsedMB} / ${gpu.vramTotalMB} MB'
                  : 'N/A',
            ),
            _GpuDetailRow(
              label: 'Temperature',
              value: gpu.temperatureC != null
                  ? '${gpu.temperatureC!.toStringAsFixed(1)}°C'
                  : 'N/A',
            ),
            _GpuDetailRow(
              label: 'Power',
              value: gpu.powerWatts != null
                  ? '${gpu.powerWatts!.toStringAsFixed(1)} W'
                  : 'N/A',
            ),
          ],
        ),
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

class _GpuDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _GpuDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
              child: Icon(icon, color: color, size: 20),
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
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
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
