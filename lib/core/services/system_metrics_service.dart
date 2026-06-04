import 'dart:io';
import 'package:system_info2/system_info2.dart';
import 'gpu_detection_service.dart';

/// Classe unificata per metriche di sistema in tempo reale
class RealtimeSystemMetrics {
  // CPU
  final double cpuUsagePercent;

  // Memory
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int freeMemoryMB;
  final double memoryUsagePercent;

  // Disk
  final int totalDiskGB;
  final int usedDiskGB;
  final int freeDiskGB;
  final double diskUsagePercent;

  // Hardware Info
  final int cpuCores;
  final String cpuModel;
  final bool hasGpu;
  final int? gpuMemoryMB;

  // Metadata
  final DateTime lastUpdate;
  final String osName;

  RealtimeSystemMetrics({
    required this.cpuUsagePercent,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.freeMemoryMB,
    required this.memoryUsagePercent,
    required this.totalDiskGB,
    required this.usedDiskGB,
    required this.freeDiskGB,
    required this.diskUsagePercent,
    required this.cpuCores,
    required this.cpuModel,
    required this.hasGpu,
    required this.gpuMemoryMB,
    required this.lastUpdate,
    required this.osName,
  });

  factory RealtimeSystemMetrics.initial() {
    return RealtimeSystemMetrics(
      cpuUsagePercent: 0.0,
      totalMemoryMB: 0,
      usedMemoryMB: 0,
      freeMemoryMB: 0,
      memoryUsagePercent: 0.0,
      totalDiskGB: 0,
      usedDiskGB: 0,
      freeDiskGB: 0,
      diskUsagePercent: 0.0,
      cpuCores: 0,
      cpuModel: 'Unknown',
      hasGpu: false,
      gpuMemoryMB: null,
      lastUpdate: DateTime.now(),
      osName: Platform.operatingSystem,
    );
  }

  /// Get available memory for models
  int get availableForModelsMB {
    return (usedMemoryMB * 0.7).toInt();
  }

  /// Device tier based on resources
  String get deviceTier {
    if (totalMemoryMB < 2048) return 'low';
    if (totalMemoryMB < 8192) return 'medium';
    if (totalMemoryMB < 16384) return 'high';
    return 'extreme';
  }

  /// Utility: format bytes
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() =>
      'SystemMetrics(CPU: ${cpuUsagePercent.toStringAsFixed(1)}%, RAM: ${memoryUsagePercent.toStringAsFixed(1)}%, Disk: ${diskUsagePercent.toStringAsFixed(1)}%)';
}

/// Service centralizzato per metriche di sistema
class SystemMetricsService {
  static final _instance = SystemMetricsService._();

  int _previousIdleTicks = 0;
  int _previousTotalTicks = 0;

  final GpuDetectionService _gpuDetector = GpuDetectionService();

  static final _isLinux = Platform.isLinux;
  static final _isAndroid = Platform.isAndroid;

  factory SystemMetricsService() {
    return _instance;
  }

  SystemMetricsService._();

  /// Load all system metrics at once
  Future<RealtimeSystemMetrics> loadMetrics() async {
    try {
      final cpuUsage = await _getCpuUsage();
      final memoryMetrics = _getMemoryMetrics();
      final diskMetrics = await _getDiskMetrics();
      final hardwareInfo = await _getHardwareInfo();

      return RealtimeSystemMetrics(
        cpuUsagePercent: cpuUsage,
        totalMemoryMB: memoryMetrics['total'] ?? 0,
        usedMemoryMB: memoryMetrics['used'] ?? 0,
        freeMemoryMB: memoryMetrics['free'] ?? 0,
        memoryUsagePercent: memoryMetrics['usage'] ?? 0.0,
        totalDiskGB: diskMetrics['total'] ?? 0,
        usedDiskGB: diskMetrics['used'] ?? 0,
        freeDiskGB: diskMetrics['free'] ?? 0,
        diskUsagePercent: diskMetrics['usage'] ?? 0.0,
        cpuCores: hardwareInfo['cores'] ?? 1,
        cpuModel: hardwareInfo['model'] ?? 'Unknown',
        hasGpu: hardwareInfo['hasGpu'] ?? false,
        gpuMemoryMB: hardwareInfo['gpuMemory'],
        lastUpdate: DateTime.now(),
        osName: Platform.operatingSystem,
      );
    } catch (e) {
      _debugPrint('Error loading metrics: $e');
      return RealtimeSystemMetrics.initial();
    }
  }

  /// === CPU METRICS ===

  Future<double> _getCpuUsage() async {
    try {
      if (_isLinux || _isAndroid) {
        final procStat = await _readProcStat();
        if (procStat != null) return procStat;
      }

      // Fallback
      final cores = SysInfo.cores.length;
      return cores > 0 ? (cores * 10.0).clamp(0.0, 100.0) : 0.0;
    } catch (e) {
      _debugPrint('Error getting CPU usage: $e');
      return 0.0;
    }
  }

  /// Read /proc/stat for accurate CPU usage
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
        _previousTotalTicks = totalTicks;
        _previousIdleTicks = idleTicks;
        return 0.0;
      }

      final totalDelta = totalTicks - _previousTotalTicks;
      final idleDelta = idleTicks - _previousIdleTicks;

      _previousTotalTicks = totalTicks;
      _previousIdleTicks = idleTicks;

      if (totalDelta == 0) return 0.0;

      return ((totalDelta - idleDelta) / totalDelta * 100).clamp(0.0, 100.0);
    } catch (e) {
      _debugPrint('Error reading /proc/stat: $e');
      return null;
    }
  }

  /// === MEMORY METRICS ===

  Map<String, dynamic> _getMemoryMetrics() {
    try {
      final totalPhysicalMemory = SysInfo.getTotalPhysicalMemory();
      final freePhysicalMemory = SysInfo.getFreePhysicalMemory();

      final totalMB = (totalPhysicalMemory / (1024 * 1024)).round();
      final freeMB = (freePhysicalMemory / (1024 * 1024)).round();
      final usedMB = totalMB - freeMB;
      final usage = totalMB > 0
          ? (usedMB / totalMB * 100).clamp(0.0, 100.0)
          : 0.0;

      return {'usage': usage, 'total': totalMB, 'used': usedMB, 'free': freeMB};
    } catch (e) {
      _debugPrint('Error getting memory metrics: $e');
      return {'usage': 0.0, 'total': 0, 'used': 0, 'free': 0};
    }
  }

  /// === DISK METRICS ===

  Future<Map<String, dynamic>> _getDiskMetrics() async {
    try {
      if (_isLinux || _isAndroid) {
        final result = await Process.run('df', ['-BG', '/']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final values = lines[1].split(RegExp(r'\s+'));
            if (values.length >= 5) {
              final total = int.tryParse(values[1].replaceAll('G', '')) ?? 0;
              final used = int.tryParse(values[2].replaceAll('G', '')) ?? 0;
              final avail = int.tryParse(values[3].replaceAll('G', '')) ?? 0;
              final usage = total > 0
                  ? (used / total * 100).clamp(0.0, 100.0)
                  : 0.0;

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

      // Fallback
      final totalVirtualMemory = SysInfo.getTotalVirtualMemory();
      final freeVirtualMemory = SysInfo.getFreeVirtualMemory();

      final totalGB = (totalVirtualMemory / (1024 * 1024 * 1024)).round();
      final freeGB = (freeVirtualMemory / (1024 * 1024 * 1024)).round();
      final usedGB = totalGB - freeGB;
      final usage = totalGB > 0
          ? (usedGB / totalGB * 100).clamp(0.0, 100.0)
          : 0.0;

      return {'usage': usage, 'total': totalGB, 'used': usedGB, 'free': freeGB};
    } catch (e) {
      _debugPrint('Error getting disk metrics: $e');
      return {'usage': 0.0, 'total': 0, 'used': 0, 'free': 0};
    }
  }

  /// === HARDWARE INFO ===

  Future<Map<String, dynamic>> _getHardwareInfo() async {
    try {
      final cores = SysInfo.cores.length;
      var model = 'Unknown';

      if (_isLinux) {
        // Read CPU model from /proc/cpuinfo
        try {
          final file = File('/proc/cpuinfo');
          if (file.existsSync()) {
            final lines = file.readAsLinesSync();
            final modelLine = lines.firstWhere(
              (line) => line.startsWith('model name'),
              orElse: () => '',
            );
            if (modelLine.isNotEmpty) {
              model = modelLine.split(':').last.trim();
            }
          }
        } catch (_) {}
      }

      // Detect GPU across AMD (ROCm) and NVIDIA via GpuDetectionService.
      final gpu = await _gpuDetector.detect();

      return {
        'cores': cores,
        'model': model,
        'hasGpu': gpu.hasGpu,
        'gpuMemory': gpu.memoryMB,
      };
    } catch (e) {
      _debugPrint('Error getting hardware info: $e');
      return {
        'cores': 1,
        'model': 'Unknown',
        'hasGpu': false,
        'gpuMemory': null,
      };
    }
  }

  void _debugPrint(String message) {
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      print('[SystemMetrics] $message');
    }
  }
}
