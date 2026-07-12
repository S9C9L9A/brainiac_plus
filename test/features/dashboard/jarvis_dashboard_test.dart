import 'package:brainiac_plus/core/services/gpu_metrics_service.dart';
import 'package:brainiac_plus/features/dashboard/controllers/gpu_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/controllers/system_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/widgets/hud/hud_ring_gauge.dart';
import 'package:brainiac_plus/features/dashboard/widgets/hud/jarvis_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticMetrics extends SystemMetricsNotifier {
  _StaticMetrics(this._value);
  final SystemMetrics _value;
  @override
  SystemMetrics get state => _value;
}

void main() {
  testWidgets('renders a ring gauge per core vital with live values', (
    tester,
  ) async {
    final metrics = SystemMetrics(
      cpuUsage: 42,
      memoryUsage: 63,
      diskUsage: 28,
      totalMemoryMB: 128000,
      usedMemoryMB: 80000,
      freeMemoryMB: 48000,
      totalDiskGB: 3600,
      usedDiskGB: 1000,
      freeDiskGB: 2600,
      lastUpdate: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          systemMetricsProvider.overrideWith((ref) => _StaticMetrics(metrics)),
          // No GPU in this test: point the reader at a missing sysfs root.
          gpuMetricsServiceProvider.overrideWithValue(
            GpuMetricsService(drmRoot: '/nonexistent-drm'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: JarvisDashboard())),
      ),
    );
    await tester.pump();

    // CPU / MEM / DISK gauges (no GPU in this environment).
    expect(find.byType(HudRingGauge), findsNWidgets(3));
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.text('CORE ONLINE'), findsOneWidget);

    // Dispose the animated gauges cleanly.
    await tester.pumpWidget(const SizedBox());
  });
}
