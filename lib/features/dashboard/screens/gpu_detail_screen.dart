import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gpu_metrics_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../controllers/gpu_metrics_provider.dart';

/// Live detail view for every GPU in the system, refreshed every 2 seconds.
/// Reachable via /gpu-detail and from the chat "Show GPU Metrics" action.
class GpuDetailScreen extends ConsumerWidget {
  const GpuDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpus = ref.watch(gpuListProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: gpus.isEmpty
                    ? const Center(
                        child: Text(
                          'No GPU detected',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: gpus.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) =>
                            _GpuCard(gpu: gpus[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              AppIcons.arrowBack,
              color: Colors.white,
              size: AppIcons.defaultSize,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.systemGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              AppIcons.gpu,
              color: AppColors.systemGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'GPU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GpuCard extends StatelessWidget {
  final GpuMetrics gpu;

  const _GpuCard({required this.gpu});

  @override
  Widget build(BuildContext context) {
    final vramPercent = gpu.vramUsagePercent;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.gpu, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${gpu.cardId}${gpu.pciId != null ? ' · ${gpu.pciId}' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  gpu.busyPercent != null ? '${gpu.busyPercent}%' : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vramPercent != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: vramPercent / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    vramPercent < 75 ? AppColors.systemGreen : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(
                  label: 'VRAM',
                  value: gpu.vramUsedMB != null && gpu.vramTotalMB != null
                      ? '${gpu.vramUsedMB} / ${gpu.vramTotalMB} MB'
                      : 'N/A',
                ),
                _Metric(
                  label: 'Temp',
                  value: gpu.temperatureC != null
                      ? '${gpu.temperatureC!.toStringAsFixed(1)}°C'
                      : 'N/A',
                ),
                _Metric(
                  label: 'Power',
                  value: gpu.powerWatts != null
                      ? '${gpu.powerWatts!.toStringAsFixed(1)} W'
                      : 'N/A',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
