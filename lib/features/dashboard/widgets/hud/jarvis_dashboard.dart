import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/gpu_metrics_service.dart';
import '../../../../routes/app_routes.dart';
import '../../controllers/gpu_metrics_provider.dart';
import '../../controllers/system_metrics_provider.dart';
import 'hud_ring_gauge.dart';
import 'hud_theme.dart';
import 'projects_panel.dart';
import 'socials_panel.dart';

/// The Jarvis-style command HUD: live system vitals as arc-reactor ring gauges
/// over a technical grid, with a status ribbon and a telemetry strip. Tapping
/// a gauge opens its detail screen.
class JarvisDashboard extends ConsumerWidget {
  const JarvisDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(systemMetricsProvider);
    final gpu = ref.watch(gpuMetricsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        _StatusRibbon(online: true),
        const SizedBox(height: 24),
        _GaugeCluster(metrics: m, gpu: gpu),
        const SizedBox(height: 24),
        _TelemetryStrip(metrics: m, gpu: gpu),
        const SizedBox(height: 20),
        // Below the vitals: what the assistant has built and who it posts to.
        const _PanelRow(),
      ],
    );
  }
}

/// Projects and socials, side by side on desktop and stacked when narrow.
class _PanelRow extends StatelessWidget {
  const _PanelRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return const Column(
            children: [ProjectsPanel(), SizedBox(height: 20), SocialsPanel()],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ProjectsPanel()),
            SizedBox(width: 20),
            Expanded(child: SocialsPanel()),
          ],
        );
      },
    );
  }
}

class _StatusRibbon extends StatelessWidget {
  final bool online;
  const _StatusRibbon({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: HudTheme.panel.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _pulseDot(online ? HudTheme.cyan : HudTheme.danger),
          const SizedBox(width: 12),
          Text(
            online ? 'CORE ONLINE' : 'CORE OFFLINE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            'ALL SYSTEMS MONITORED',
            style: TextStyle(
              color: HudTheme.cyan.withValues(alpha: 0.6),
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseDot(Color color) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
      ],
    ),
  );
}

class _GaugeCluster extends StatelessWidget {
  final SystemMetrics metrics;
  final GpuMetrics? gpu;

  const _GaugeCluster({required this.metrics, this.gpu});

  @override
  Widget build(BuildContext context) {
    final ramUsedGb = (metrics.usedMemoryMB / 1024).toStringAsFixed(1);
    final ramTotalGb = (metrics.totalMemoryMB / 1024).toStringAsFixed(0);

    final gauges = <Widget>[
      _tappable(
        context,
        AppRoutes.cpuDetail,
        HudRingGauge(
          label: 'CPU',
          percent: metrics.cpuUsage,
          value: '${metrics.cpuUsage.round()}%',
          detail: HudTheme.statusLabel(metrics.cpuUsage),
        ),
      ),
      _tappable(
        context,
        AppRoutes.ramDetail,
        HudRingGauge(
          label: 'MEM',
          percent: metrics.memoryUsage,
          value: '${metrics.memoryUsage.round()}%',
          detail: '$ramUsedGb / $ramTotalGb G',
        ),
      ),
      _tappable(
        context,
        AppRoutes.diskDetail,
        HudRingGauge(
          label: 'DISK',
          percent: metrics.diskUsage,
          value: '${metrics.diskUsage.round()}%',
          detail: '${metrics.usedDiskGB} / ${metrics.totalDiskGB} G',
        ),
      ),
    ];

    if (gpu != null) {
      final busy = (gpu!.busyPercent ?? 0).toDouble();
      gauges.add(
        _tappable(
          context,
          AppRoutes.gpuDetail,
          HudRingGauge(
            label: 'GPU',
            percent: busy,
            value: '${busy.round()}%',
            detail: gpu!.temperatureC != null
                ? '${gpu!.temperatureC!.toStringAsFixed(0)}°C'
                : null,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 28,
      runSpacing: 28,
      children: gauges,
    );
  }

  Widget _tappable(BuildContext context, String route, Widget child) {
    return InkWell(
      borderRadius: BorderRadius.circular(120),
      onTap: () => AppRoutes.navigateTo(context, route),
      child: child,
    );
  }
}

class _TelemetryStrip extends StatelessWidget {
  final SystemMetrics metrics;
  final GpuMetrics? gpu;

  const _TelemetryStrip({required this.metrics, this.gpu});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('MEMORY', '${metrics.usedMemoryMB} / ${metrics.totalMemoryMB} MB'),
      ('STORAGE', '${metrics.usedDiskGB} / ${metrics.totalDiskGB} GB'),
      if (gpu != null && gpu!.vramTotalMB != null)
        ('VRAM', '${gpu!.vramUsedMB ?? 0} / ${gpu!.vramTotalMB} MB'),
      if (gpu != null && gpu!.powerWatts != null)
        ('GPU PWR', '${gpu!.powerWatts!.toStringAsFixed(0)} W'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: HudTheme.panel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.12)),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          for (final (label, value) in rows)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: HudTheme.cyan.withValues(alpha: 0.55),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
