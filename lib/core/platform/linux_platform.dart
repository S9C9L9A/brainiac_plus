import 'dart:io';

/// Linux Platform Integration
/// Provides system information via /proc filesystem and shell commands
class LinuxPlatform {
  /// Get CPU usage percentage
  Future<double> getCpuUsage() async {
    try {
      // Read /proc/stat for CPU stats
      final statFile = File('/proc/stat');
      final lines = await statFile.readAsLines();
      
      // First line contains overall CPU stats
      final cpuLine = lines.firstWhere((line) => line.startsWith('cpu '));
      final values = cpuLine.split(RegExp(r'\s+'));
      
      // Calculate CPU usage (simplified)
      final user = int.parse(values[1]);
      final nice = int.parse(values[2]);
      final system = int.parse(values[3]);
      final idle = int.parse(values[4]);
      
      final total = user + nice + system + idle;
      final used = user + nice + system;
      
      return (used / total) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get RAM usage information
  Future<Map<String, dynamic>> getRamUsage() async {
    try {
      final memFile = File('/proc/meminfo');
      final lines = await memFile.readAsLines();
      
      int? memTotal;
      int? memAvailable;
      
      for (var line in lines) {
        if (line.startsWith('MemTotal:')) {
          memTotal = int.parse(line.split(RegExp(r'\s+'))[1]);
        } else if (line.startsWith('MemAvailable:')) {
          memAvailable = int.parse(line.split(RegExp(r'\s+'))[1]);
        }
      }
      
      if (memTotal != null && memAvailable != null) {
        final used = memTotal - memAvailable;
        final percentage = (used / memTotal) * 100;
        
        return {
          'total': memTotal,
          'used': used,
          'available': memAvailable,
          'percentage': percentage,
          'totalGB': (memTotal / 1024 / 1024).toStringAsFixed(2),
          'usedGB': (used / 1024 / 1024).toStringAsFixed(2),
        };
      }
    } catch (e) {
      // Fallback
    }
    
    return {
      'total': 0,
      'used': 0,
      'available': 0,
      'percentage': 0.0,
      'totalGB': '0',
      'usedGB': '0',
    };
  }

  /// Get disk usage for all mounted partitions
  Future<Map<String, dynamic>> getDiskUsage() async {
    try {
      final result = await Process.run('bash', [
        '-c',
        'df -h --output=source,fstype,size,used,avail,pcent,target | grep -E "^/dev/"'
      ]);
      
      final lines = result.stdout.toString().split('\n');
      final partitions = <Map<String, dynamic>>[];
      
      double totalSizeGB = 0.0;
      double totalUsedGB = 0.0;
      int totalPercentage = 0;
      int validPartitions = 0;
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 7) {
          final sizeStr = parts[2];
          final usedStr = parts[3];
          final percentStr = parts[5].replaceAll('%', '');
          
          // Convert to GB for aggregation
          final sizeGB = _convertToGB(sizeStr);
          final usedGB = _convertToGB(usedStr);
          
          totalSizeGB += sizeGB;
          totalUsedGB += usedGB;
          totalPercentage += int.tryParse(percentStr) ?? 0;
          validPartitions++;
          
          partitions.add({
            'filesystem': parts[0],
            'fstype': parts[1],
            'size': parts[2],
            'used': parts[3],
            'available': parts[4],
            'percentage': int.tryParse(percentStr) ?? 0,
            'mountpoint': parts[6],
          });
        }
      }
      
      // Return aggregated info for dashboard card
      if (validPartitions > 0) {
        final avgPercentage = totalPercentage ~/ validPartitions;
        return {
          'filesystem': '${validPartitions} device(s)',
          'size': '${totalSizeGB.toStringAsFixed(1)}G',
          'used': '${totalUsedGB.toStringAsFixed(1)}G',
          'available': '${(totalSizeGB - totalUsedGB).toStringAsFixed(1)}G',
          'percentage': avgPercentage,
          'mountpoint': 'multiple',
          'partitions': partitions,
          'totalGB': totalSizeGB,
          'usedGB': totalUsedGB,
        };
      }
    } catch (e) {
      // Fallback to single partition
      try {
        final result = await Process.run('df', ['-h', Platform.environment['HOME'] ?? '/']);
        final lines = result.stdout.toString().split('\n');
        
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          
          return {
            'filesystem': parts[0],
            'size': parts[1],
            'used': parts[2],
            'available': parts[3],
            'percentage': int.parse(parts[4].replaceAll('%', '')),
            'mountpoint': parts[5],
          };
        }
      } catch (e2) {
        // Ignore
      }
    }
    
    return {
      'filesystem': '/',
      'size': '0G',
      'used': '0G',
      'available': '0G',
      'percentage': 0,
      'mountpoint': '/',
    };
  }

  /// Helper to convert size string to GB
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

  /// Get all system stats
  Future<Map<String, dynamic>> getSystemStats() async {
    final cpu = await getCpuUsage();
    final ram = await getRamUsage();
    final disk = await getDiskUsage();
    
    return {
      'cpu': cpu,
      'ram': ram,
      'disk': disk,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Execute shell command
  Future<String> executeCommand(String command, {bool sudo = false}) async {
    try {
      final actualCommand = sudo ? 'sudo $command' : command;
      final result = await Process.run('bash', ['-c', actualCommand]);
      
      if (result.exitCode != 0) {
        throw Exception('Command failed: ${result.stderr}');
      }
      
      return result.stdout.toString();
    } catch (e) {
      throw Exception('Failed to execute command: $e');
    }
  }
}
