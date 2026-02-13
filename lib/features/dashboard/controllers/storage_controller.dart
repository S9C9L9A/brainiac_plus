import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/shell_service.dart';

/// Represents a mounted storage device/partition
class MountPoint {
  final String device;
  final String fsType;
  final String size;
  final String used;
  final String available;
  final int percentage;
  final String mountPoint;

  MountPoint({
    required this.device,
    required this.fsType,
    required this.size,
    required this.used,
    required this.available,
    required this.percentage,
    required this.mountPoint,
  });

  factory MountPoint.fromDfLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 7) {
      return MountPoint(
        device: 'Unknown',
        fsType: 'unknown',
        size: '0G',
        used: '0G',
        available: '0G',
        percentage: 0,
        mountPoint: '/',
      );
    }

    return MountPoint(
      device: parts[0],
      fsType: parts[1],
      size: parts[2],
      used: parts[3],
      available: parts[4],
      percentage: int.tryParse(parts[5].replaceAll('%', '')) ?? 0,
      mountPoint: parts[6],
    );
  }

  /// Get icon based on device type
  String get deviceType {
    if (device.contains('nvme') || device.contains('sda') || device.contains('sdb')) {
      return 'disk';
    } else if (device.contains('usb') || device.contains('sd') && !device.contains('sda')) {
      return 'usb';
    } else if (device.contains('nfs') || device.contains('cifs')) {
      return 'network';
    } else if (device.contains('loop')) {
      return 'loop';
    }
    return 'disk';
  }

  /// Get color based on usage percentage
  String get usageLevel {
    if (percentage < 70) return 'green';
    if (percentage < 85) return 'yellow';
    return 'red';
  }

  /// Check if device is removable (USB, external)
  bool get isRemovable {
    return deviceType == 'usb' || 
           mountPoint.contains('/media') || 
           mountPoint.contains('/mnt');
  }

  /// Convert size to GB for calculations
  double get sizeInGB {
    return _convertToGB(size);
  }

  double get usedInGB {
    return _convertToGB(used);
  }

  double get availableInGB {
    return _convertToGB(available);
  }

  double _convertToGB(String value) {
    if (value.isEmpty) return 0.0;
    final numStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final num = double.tryParse(numStr) ?? 0.0;
    
    if (value.contains('T')) return num * 1024;
    if (value.contains('G')) return num;
    if (value.contains('M')) return num / 1024;
    if (value.contains('K')) return num / (1024 * 1024);
    return num;
  }
}

/// Directory information with size
class DirectoryInfo {
  final String path;
  final String size;

  DirectoryInfo({
    required this.path,
    required this.size,
  });

  factory DirectoryInfo.fromDuLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return DirectoryInfo(size: '0', path: 'Unknown');
    }
    return DirectoryInfo(
      size: parts[0],
      path: parts.sublist(1).join(' '),
    );
  }

  double get sizeInGB {
    if (size.isEmpty) return 0.0;
    final numStr = size.replaceAll(RegExp(r'[^0-9.]'), '');
    final value = double.tryParse(numStr) ?? 0.0;
    
    if (size.contains('T')) return value * 1024;
    if (size.contains('G')) return value;
    if (size.contains('M')) return value / 1024;
    if (size.contains('K')) return value / (1024 * 1024);
    return value;
  }
}

/// Storage overview data
class StorageOverview {
  final double totalGB;
  final double usedGB;
  final double availableGB;
  final int averagePercentage;

  StorageOverview({
    required this.totalGB,
    required this.usedGB,
    required this.availableGB,
    required this.averagePercentage,
  });

  factory StorageOverview.fromMountPoints(List<MountPoint> mountPoints) {
    if (mountPoints.isEmpty) {
      return StorageOverview(
        totalGB: 0,
        usedGB: 0,
        availableGB: 0,
        averagePercentage: 0,
      );
    }

    final total = mountPoints.fold<double>(0, (sum, mp) => sum + mp.sizeInGB);
    final used = mountPoints.fold<double>(0, (sum, mp) => sum + mp.usedInGB);
    final available = mountPoints.fold<double>(0, (sum, mp) => sum + mp.availableInGB);
    final avgPercentage = mountPoints.fold<int>(0, (sum, mp) => sum + mp.percentage) ~/ mountPoints.length;

    return StorageOverview(
      totalGB: total,
      usedGB: used,
      availableGB: available,
      averagePercentage: avgPercentage,
    );
  }
}

/// Storage controller for managing disk/mount point data
class StorageController extends StateNotifier<AsyncValue<List<MountPoint>>> {
  final ShellService _shellService = ShellService();

  StorageController() : super(const AsyncValue.loading());

  /// Load all mount points from system
  Future<void> loadAllMountPoints() async {
    state = const AsyncValue.loading();
    try {
      final output = await _shellService.executeSync(
        'df -h --output=source,fstype,size,used,avail,pcent,target | grep -E "^/dev/"'
      );
      
      final lines = output.split('\n');
      final mountPoints = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => MountPoint.fromDfLine(line))
          .toList();
      
      state = AsyncValue.data(mountPoints);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get storage overview from current mount points
  StorageOverview getOverview() {
    return state.when(
      data: (mountPoints) => StorageOverview.fromMountPoints(mountPoints),
      loading: () => StorageOverview(totalGB: 0, usedGB: 0, availableGB: 0, averagePercentage: 0),
      error: (_, __) => StorageOverview(totalGB: 0, usedGB: 0, availableGB: 0, averagePercentage: 0),
    );
  }

  @override
  void dispose() {
    _shellService.dispose();
    super.dispose();
  }
}

/// Controller for directory sizes in a specific mount point
class DirectorySizesController extends StateNotifier<AsyncValue<List<DirectoryInfo>>> {
  final ShellService _shellService = ShellService();

  DirectorySizesController() : super(const AsyncValue.loading());

  /// Load top directories for a specific mount point
  Future<void> loadDirectorySizes(String mountPoint) async {
    state = const AsyncValue.loading();
    try {
      final output = await _shellService.executeSync(
        'du -h --max-depth=1 "$mountPoint" 2>/dev/null | sort -hr | head -20'
      );
      
      final lines = output.split('\n');
      final directories = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => DirectoryInfo.fromDuLine(line))
          .toList();
      
      state = AsyncValue.data(directories);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _shellService.dispose();
    super.dispose();
  }
}

/// Device operations controller
class DeviceOperationsController {
  final ShellService _shellService = ShellService();

  /// Eject/unmount a removable device
  Future<bool> ejectDevice(String devicePath) async {
    try {
      final output = await _shellService.executeSync(
        'udisksctl unmount -b "$devicePath" && udisksctl power-off -b "$devicePath"'
      );
      return !output.toLowerCase().contains('error');
    } catch (e) {
      return false;
    }
  }

  /// Get detailed device information
  Future<Map<String, String>> getDeviceInfo(String devicePath) async {
    try {
      final output = await _shellService.executeSync(
        'lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL,UUID "$devicePath"'
      );
      
      final lines = output.split('\n');
      if (lines.length > 1) {
        final headers = lines[0].trim().split(RegExp(r'\s+'));
        final values = lines[1].trim().split(RegExp(r'\s+'));
        
        final info = <String, String>{};
        for (var i = 0; i < headers.length && i < values.length; i++) {
          info[headers[i]] = values[i];
        }
        return info;
      }
    } catch (e) {
      // Ignore errors
    }
    return {};
  }

  void dispose() {
    _shellService.dispose();
  }
}

// Providers
final storageControllerProvider = StateNotifierProvider<StorageController, AsyncValue<List<MountPoint>>>((ref) {
  return StorageController();
});

final directorySizesControllerProvider = StateNotifierProvider<DirectorySizesController, AsyncValue<List<DirectoryInfo>>>((ref) {
  return DirectorySizesController();
});

final deviceOperationsProvider = Provider<DeviceOperationsController>((ref) {
  return DeviceOperationsController();
});
