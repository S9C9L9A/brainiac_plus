import 'dart:async';
import 'package:cron/cron.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/automation/models/social_media_task.dart';
import '../../features/automation/controllers/social_media_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';

/// Provider for task scheduler
final taskSchedulerProvider = Provider<TaskSchedulerService>((ref) {
  return TaskSchedulerService(ref);
});

/// Task Scheduler using cron
class TaskSchedulerService {
  final Ref _ref;
  final Cron _cron = Cron();
  final Map<int, ScheduledTaskInfo> _scheduledTasks = {};

  TaskSchedulerService(this._ref);

  /// Schedule a social media task
  void scheduleTask(SocialMediaTask task) {
    if (task.id == null || !task.enabled) return;

    // Cancel existing schedule if any
    cancelTask(task.id!);

    try {
      // Parse cron schedule and create scheduled task
      final cronSchedule = Schedule.parse(task.schedule);
      final cronTask = _cron.schedule(cronSchedule, () async {
        await _executeTask(task);
      });

      _scheduledTasks[task.id!] = ScheduledTaskInfo(
        task: task,
        cronTask: cronTask,
        scheduledAt: DateTime.now(),
      );

      print('✅ Task scheduled: ${task.name} (${task.schedule})');
    } catch (e) {
      print('❌ Failed to schedule task ${task.name}: $e');
    }
  }

  /// Cancel a scheduled task
  void cancelTask(int taskId) {
    final scheduledTask = _scheduledTasks[taskId];
    if (scheduledTask != null) {
      scheduledTask.cronTask.cancel();
      _scheduledTasks.remove(taskId);
      print('🛑 Task cancelled: ${scheduledTask.task.name}');
    }
  }

  /// Execute a task
  Future<void> _executeTask(SocialMediaTask task) async {
    print('⏰ Executing scheduled task: ${task.name}');

    try {
      final controller = _ref.read(socialMediaControllerProvider.notifier);
      await controller.executeTask(task);
      print('✅ Task completed: ${task.name}');
    } catch (e) {
      print('❌ Task failed: ${task.name} - $e');

      // Retry if enabled
      final settings = _ref.read(settingsControllerProvider);
      if (settings.retryFailedTasks) {
        await _retryTask(task, settings.maxRetries);
      }
    }
  }

  /// Retry failed task
  Future<void> _retryTask(SocialMediaTask task, int maxRetries) async {
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      print('🔄 Retry attempt $attempt/$maxRetries for: ${task.name}');
      
      // Exponential backoff: 1min, 2min, 4min
      await Future.delayed(Duration(minutes: 1 << (attempt - 1)));

      try {
        final controller = _ref.read(socialMediaControllerProvider.notifier);
        await controller.executeTask(task);
        print('✅ Task succeeded on retry $attempt: ${task.name}');
        return; // Success, stop retrying
      } catch (e) {
        print('❌ Retry $attempt failed: $e');
        if (attempt == maxRetries) {
          print('❌ Max retries reached for: ${task.name}');
        }
      }
    }
  }

  /// Schedule all enabled tasks
  void scheduleAllTasks(List<SocialMediaTask> tasks) {
    for (final task in tasks) {
      if (task.enabled) {
        scheduleTask(task);
      }
    }
  }

  /// Cancel all scheduled tasks
  void cancelAllTasks() {
    for (final taskId in _scheduledTasks.keys.toList()) {
      cancelTask(taskId);
    }
  }

  /// Get list of scheduled tasks
  List<ScheduledTaskInfo> getScheduledTasks() {
    return _scheduledTasks.values.toList();
  }

  /// Check if task is scheduled
  bool isTaskScheduled(int taskId) {
    return _scheduledTasks.containsKey(taskId);
  }

  /// Dispose scheduler
  void dispose() {
    _cron.close();
    _scheduledTasks.clear();
  }
}

/// Scheduled task wrapper
class ScheduledTaskInfo {
  final SocialMediaTask task;
  final ScheduledTask cronTask;
  final DateTime scheduledAt;
  DateTime? lastRun;

  ScheduledTaskInfo({
    required this.task,
    required this.cronTask,
    required this.scheduledAt,
    this.lastRun,
  });
}
