import 'dart:io';
import 'system_metrics_service.dart';

/// Hardware information for model recommendations
class HardwareInfo {
  final int totalMemoryMB;
  final int cpuCores;
  final String cpuModel;
  final String osName;
  final String osVersion;
  final bool hasGpu;
  final int? gpuMemoryMB;

  HardwareInfo({
    required this.totalMemoryMB,
    required this.cpuCores,
    required this.cpuModel,
    required this.osName,
    required this.osVersion,
    this.hasGpu = false,
    this.gpuMemoryMB,
  });

  /// Get available memory for models (conservative estimate)
  int get availableForModel {
    // Reserve ~30% for system + app overhead
    return (totalMemoryMB * 0.7).toInt();
  }

  /// Classify device tier based on resources
  String get deviceTier {
    if (totalMemoryMB < 2048) return 'low';
    if (totalMemoryMB < 8192) return 'medium';
    if (totalMemoryMB < 16384) return 'high';
    return 'extreme';
  }

  @override
  String toString() =>
      'HardwareInfo(RAM: ${totalMemoryMB}MB, CPU: $cpuCores cores, OS: $osName $osVersion)';
}

/// Service for detecting hardware capabilities
class HardwareDetectionService {
  static final _instance = HardwareDetectionService._();
  static HardwareInfo? _cachedInfo;

  factory HardwareDetectionService() {
    return _instance;
  }

  HardwareDetectionService._();

  /// Get hardware information (cached)
  /// Delega a SystemMetricsService per evitare duplicazioni
  Future<HardwareInfo> getHardwareInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    try {
      // Usa SystemMetricsService come singola fonte di verità
      final metrics = await _systemMetricsService.loadMetrics();

      _cachedInfo = HardwareInfo(
        totalMemoryMB: metrics.totalMemoryMB,
        cpuCores: metrics.cpuCores,
        cpuModel: metrics.cpuModel,
        osName: metrics.osName,
        osVersion: Platform.operatingSystemVersion,
        hasGpu: metrics.hasGpu,
        gpuMemoryMB: metrics.gpuMemoryMB,
      );

      return _cachedInfo!;
    } catch (e) {
      return _getDefaultInfo();
    }
  }

  late final SystemMetricsService _systemMetricsService =
      SystemMetricsService();

  /// Get default hardware info
  HardwareInfo _getDefaultInfo() {
    return HardwareInfo(
      totalMemoryMB: 8192, // Conservative default
      cpuCores: 4,
      cpuModel: 'Unknown',
      osName: Platform.operatingSystem,
      osVersion: 'Unknown',
    );
  }

  /// Clear cache
  static void clearCache() {
    _cachedInfo = null;
  }
}
