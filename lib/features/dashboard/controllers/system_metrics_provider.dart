import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/system_metrics_service.dart';

// Re-export for backwards compatibility
export '../../../core/services/system_metrics_service.dart'
    show RealtimeSystemMetrics;

/// Wrapper compatibility class for existing code
class SystemMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int freeMemoryMB;
  final int totalDiskGB;
  final int usedDiskGB;
  final int freeDiskGB;
  final DateTime lastUpdate;

  const SystemMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.freeMemoryMB,
    required this.totalDiskGB,
    required this.usedDiskGB,
    required this.freeDiskGB,
    required this.lastUpdate,
  });

  factory SystemMetrics.fromRealtime(RealtimeSystemMetrics realtime) {
    return SystemMetrics(
      cpuUsage: realtime.cpuUsagePercent,
      memoryUsage: realtime.memoryUsagePercent,
      diskUsage: realtime.diskUsagePercent,
      totalMemoryMB: realtime.totalMemoryMB,
      usedMemoryMB: realtime.usedMemoryMB,
      freeMemoryMB: realtime.freeMemoryMB,
      totalDiskGB: realtime.totalDiskGB,
      usedDiskGB: realtime.usedDiskGB,
      freeDiskGB: realtime.freeDiskGB,
      lastUpdate: realtime.lastUpdate,
    );
  }

  factory SystemMetrics.initial() {
    return SystemMetrics(
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      diskUsage: 0.0,
      totalMemoryMB: 0,
      usedMemoryMB: 0,
      freeMemoryMB: 0,
      totalDiskGB: 0,
      usedDiskGB: 0,
      freeDiskGB: 0,
      lastUpdate: DateTime.now(),
    );
  }

  SystemMetrics copyWith({
    double? cpuUsage,
    double? memoryUsage,
    double? diskUsage,
    int? totalMemoryMB,
    int? usedMemoryMB,
    int? freeMemoryMB,
    int? totalDiskGB,
    int? usedDiskGB,
    int? freeDiskGB,
    DateTime? lastUpdate,
  }) {
    return SystemMetrics(
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      totalMemoryMB: totalMemoryMB ?? this.totalMemoryMB,
      usedMemoryMB: usedMemoryMB ?? this.usedMemoryMB,
      freeMemoryMB: freeMemoryMB ?? this.freeMemoryMB,
      totalDiskGB: totalDiskGB ?? this.totalDiskGB,
      usedDiskGB: usedDiskGB ?? this.usedDiskGB,
      freeDiskGB: freeDiskGB ?? this.freeDiskGB,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// System metrics provider notifier - now using consolidates service
class SystemMetricsNotifier extends StateNotifier<SystemMetrics> {
  final SystemMetricsService _service = SystemMetricsService();
  Timer? _refreshTimer;

  SystemMetricsNotifier() : super(SystemMetrics.initial()) {
    _loadMetrics();
    _startAutoRefresh();
  }

  /// Start auto-refresh every 2 seconds
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadMetrics();
    });
  }

  /// Load system metrics using consolidate service
  Future<void> _loadMetrics() async {
    final realtime = await _service.loadMetrics();
    state = SystemMetrics.fromRealtime(realtime);
  }

  /// Manual refresh
  Future<void> refresh() async {
    await _loadMetrics();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for system metrics (backwards compatible)
final systemMetricsProvider =
    StateNotifierProvider<SystemMetricsNotifier, SystemMetrics>((ref) {
      return SystemMetricsNotifier();
    });

// Also expose the realtime service for new code
final systemMetricsServiceProvider = Provider<SystemMetricsService>((ref) {
  return SystemMetricsService();
});

/// Helper to format bytes to human readable
String formatBytes(int bytes) {
  return RealtimeSystemMetrics.formatBytes(bytes);
}

void debugPrint(String message) {
  // Simple debug print function
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    print('[SystemMetrics] $message');
  }
}
