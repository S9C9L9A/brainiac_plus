import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/linux_platform.dart';

/// System stats data model
class SystemStats {
  final double cpuUsage;
  final Map<String, dynamic> ramUsage;
  final Map<String, dynamic> diskUsage;
  final DateTime timestamp;

  SystemStats({
    required this.cpuUsage,
    required this.ramUsage,
    required this.diskUsage,
    required this.timestamp,
  });

  factory SystemStats.empty() {
    return SystemStats(
      cpuUsage: 0.0,
      ramUsage: {
        'total': 0,
        'used': 0,
        'available': 0,
        'percentage': 0.0,
        'totalGB': '0',
        'usedGB': '0',
      },
      diskUsage: {
        'filesystem': '/',
        'size': '0G',
        'used': '0G',
        'available': '0G',
        'percentage': 0,
        'mountpoint': '/',
      },
      timestamp: DateTime.now(),
    );
  }
}

/// Resource monitoring controller
class ResourceController extends StateNotifier<SystemStats> {
  final LinuxPlatform _platform = LinuxPlatform();
  Timer? _timer;

  ResourceController() : super(SystemStats.empty()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchStats();
    });
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _platform.getSystemStats();
      
      state = SystemStats(
        cpuUsage: stats['cpu'] as double,
        ramUsage: stats['ram'] as Map<String, dynamic>,
        diskUsage: stats['disk'] as Map<String, dynamic>,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final resourceControllerProvider =
    StateNotifierProvider<ResourceController, SystemStats>((ref) {
  return ResourceController();
});
