import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/gpu_metrics_service.dart';

/// Service used to read live GPU metrics. Overridable in tests to point the
/// reader at a fake sysfs tree.
final gpuMetricsServiceProvider = Provider<GpuMetricsService>((ref) {
  return GpuMetricsService();
});

/// Polls the primary GPU every 2 seconds, mirroring [SystemMetricsNotifier].
/// State is null when the host has no supported GPU, so the UI can simply
/// hide the card.
class GpuMetricsNotifier extends StateNotifier<GpuMetrics?> {
  final GpuMetricsService _service;
  Timer? _refreshTimer;

  GpuMetricsNotifier(this._service) : super(null) {
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  Future<void> _load() async {
    final gpu = await _service.readPrimary();
    if (mounted) state = gpu;
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final gpuMetricsProvider =
    StateNotifierProvider<GpuMetricsNotifier, GpuMetrics?>((ref) {
      return GpuMetricsNotifier(ref.watch(gpuMetricsServiceProvider));
    });
