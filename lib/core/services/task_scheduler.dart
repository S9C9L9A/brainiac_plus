import 'dart:async';
import 'dart:io';

/// Simple cron-like scheduler
class TaskScheduler {
  final Map<int, Timer> _timers = {};

  /// Schedule a task
  void scheduleTask(int taskId, String cronExpression, Function() callback) {
    cancelTask(taskId);

    final interval = _parseCronExpression(cronExpression);
    if (interval != null) {
      _timers[taskId] = Timer.periodic(interval, (_) => callback());
    }
  }

  void cancelTask(int taskId) {
    _timers[taskId]?.cancel();
    _timers.remove(taskId);
  }

  void cancelAll() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  Duration? _parseCronExpression(String cron) {
    cron = cron.trim();

    switch (cron) {
      case '@hourly': return const Duration(hours: 1);
      case '@daily': return const Duration(days: 1);
      case '@weekly': return const Duration(days: 7);
      case '@monthly': return const Duration(days: 30);
    }

    final everyMinutePattern = RegExp(r'^\*/(\d+)$');
    final match = everyMinutePattern.firstMatch(cron);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      return Duration(minutes: minutes);
    }

    return null;
  }
}

class TaskExecutor {
  Future<Map<String, dynamic>> executeTask(String command) async {
    try {
      final result = await Process.run('bash', ['-c', command]);
      
      return {
        'success': result.exitCode == 0,
        'output': result.stdout.toString() + result.stderr.toString(),
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error: $e',
        'exitCode': -1,
      };
    }
  }
}
