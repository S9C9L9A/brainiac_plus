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

  /// Get disk usage for home directory
  Future<Map<String, dynamic>> getDiskUsage() async {
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
    } catch (e) {
      // Fallback
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
