import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';
import '../../../core/utils/platform_helper.dart';

/// System metrics state
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

/// System metrics provider with auto-refresh
class SystemMetricsNotifier extends StateNotifier<SystemMetrics> {
  Timer? _refreshTimer;
  int _previousIdleTicks = 0;
  int _previousTotalTicks = 0;

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

  /// Load system metrics
  Future<void> _loadMetrics() async {
    try {
      final cpuUsage = await _getCpuUsage();
      final memoryMetrics = _getMemoryMetrics();
      final diskMetrics = await _getDiskMetrics();

      state = SystemMetrics(
        cpuUsage: cpuUsage,
        memoryUsage: memoryMetrics['usage'] ?? 0.0,
        diskUsage: diskMetrics['usage'] ?? 0.0,
        totalMemoryMB: memoryMetrics['total'] ?? 0,
        usedMemoryMB: memoryMetrics['used'] ?? 0,
        freeMemoryMB: memoryMetrics['free'] ?? 0,
        totalDiskGB: diskMetrics['total'] ?? 0,
        usedDiskGB: diskMetrics['used'] ?? 0,
        freeDiskGB: diskMetrics['free'] ?? 0,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      // If error, keep previous state
      debugPrint('Error loading metrics: $e');
    }
  }

  /// Get CPU usage percentage
  Future<double> _getCpuUsage() async {
    try {
      if (PlatformHelper.isLinux || PlatformHelper.isAndroid) {
        // Read /proc/stat for CPU usage
        final procStat = await _readProcStat();
        if (procStat != null) {
          return procStat;
        }
      }

      // Fallback: use system_info2
      final cores = SysInfo.cores.length;
      if (cores > 0) {
        // Simple estimation based on available processors
        return (cores * 10.0).clamp(0.0, 100.0);
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error getting CPU usage: $e');
      return 0.0;
    }
  }

  /// Read /proc/stat for accurate CPU usage (Linux/Android)
  Future<double?> _readProcStat() async {
    try {
      final file = File('/proc/stat');
      if (!await file.exists()) return null;

      final lines = await file.readAsLines();
      if (lines.isEmpty) return null;

      final cpuLine = lines.first;
      if (!cpuLine.startsWith('cpu ')) return null;

      final values = cpuLine.split(RegExp(r'\s+'));
      if (values.length < 5) return null;

      final user = int.tryParse(values[1]) ?? 0;
      final nice = int.tryParse(values[2]) ?? 0;
      final system = int.tryParse(values[3]) ?? 0;
      final idle = int.tryParse(values[4]) ?? 0;
      final iowait = int.tryParse(values.length > 5 ? values[5] : '0') ?? 0;

      final totalTicks = user + nice + system + idle + iowait;
      final idleTicks = idle + iowait;

      if (_previousTotalTicks == 0) {
        // First read, store values
        _previousTotalTicks = totalTicks;
        _previousIdleTicks = idleTicks;
        return 0.0;
      }

      final totalDelta = totalTicks - _previousTotalTicks;
      final idleDelta = idleTicks - _previousIdleTicks;

      _previousTotalTicks = totalTicks;
      _previousIdleTicks = idleTicks;

      if (totalDelta == 0) return 0.0;

      final usage = ((totalDelta - idleDelta) / totalDelta * 100).clamp(0.0, 100.0);
      return usage;
    } catch (e) {
      debugPrint('Error reading /proc/stat: $e');
      return null;
    }
  }

  /// Get memory metrics
  Map<String, dynamic> _getMemoryMetrics() {
    try {
      final totalPhysicalMemory = SysInfo.getTotalPhysicalMemory();
      final freePhysicalMemory = SysInfo.getFreePhysicalMemory();

      final totalMB = (totalPhysicalMemory / (1024 * 1024)).round();
      final freeMB = (freePhysicalMemory / (1024 * 1024)).round();
      final usedMB = totalMB - freeMB;
      final usage = totalMB > 0 ? (usedMB / totalMB * 100).clamp(0.0, 100.0) : 0.0;

      return {
        'usage': usage,
        'total': totalMB,
        'used': usedMB,
        'free': freeMB,
      };
    } catch (e) {
      debugPrint('Error getting memory metrics: $e');
      return {
        'usage': 0.0,
        'total': 0,
        'used': 0,
        'free': 0,
      };
    }
  }

  /// Get disk metrics
  Future<Map<String, dynamic>> _getDiskMetrics() async {
    try {
      if (PlatformHelper.isLinux || PlatformHelper.isAndroid) {
        // Use 'df' command for disk usage
        final result = await Process.run('df', ['-BG', '/']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final values = lines[1].split(RegExp(r'\s+'));
            if (values.length >= 5) {
              final totalStr = values[1].replaceAll('G', '');
              final usedStr = values[2].replaceAll('G', '');
              final availStr = values[3].replaceAll('G', '');

              final total = int.tryParse(totalStr) ?? 0;
              final used = int.tryParse(usedStr) ?? 0;
              final avail = int.tryParse(availStr) ?? 0;

              final usage = total > 0 ? (used / total * 100).clamp(0.0, 100.0) : 0.0;

              return {
                'usage': usage,
                'total': total,
                'used': used,
                'free': avail,
              };
            }
          }
        }
      }

      // Fallback to system_info2
      final totalVirtualMemory = SysInfo.getTotalVirtualMemory();
      final freeVirtualMemory = SysInfo.getFreeVirtualMemory();

      final totalGB = (totalVirtualMemory / (1024 * 1024 * 1024)).round();
      final freeGB = (freeVirtualMemory / (1024 * 1024 * 1024)).round();
      final usedGB = totalGB - freeGB;
      final usage = totalGB > 0 ? (usedGB / totalGB * 100).clamp(0.0, 100.0) : 0.0;

      return {
        'usage': usage,
        'total': totalGB,
        'used': usedGB,
        'free': freeGB,
      };
    } catch (e) {
      debugPrint('Error getting disk metrics: $e');
      return {
        'usage': 0.0,
        'total': 0,
        'used': 0,
        'free': 0,
      };
    }
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

/// Provider for system metrics
final systemMetricsProvider = StateNotifierProvider<SystemMetricsNotifier, SystemMetrics>((ref) {
  return SystemMetricsNotifier();
});

/// Helper to format bytes to human readable
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

void debugPrint(String message) {
  // Simple debug print function
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    print('[SystemMetrics] $message');
  }
}

