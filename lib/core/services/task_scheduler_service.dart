import 'dart:async';
import 'package:cron/cron.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/automation/models/automation.dart';
import '../../features/automation/controllers/automation_controller.dart';

/// Provider for task scheduler
final taskSchedulerProvider = Provider<TaskSchedulerService>((ref) {
  return TaskSchedulerService(ref);
});

/// Task Scheduler using cron for automation scheduling
class TaskSchedulerService {
  final Ref _ref;
  final Cron _cron = Cron();
  final Map<String, ScheduledTask> _scheduledTasks = {};

  TaskSchedulerService(this._ref);

  /// Schedule automation based on its cron expression
  void scheduleAutomation(Automation automation) {
    // Cancel any existing schedule for this automation
    cancelAutomation(automation.id);

    final cronExpression = automation.cronSchedule;
    if (cronExpression == null || cronExpression.isEmpty) {
      debugPrint('⚠️ No cron schedule for automation: ${automation.name}');
      return;
    }

    try {
      final task = _cron.schedule(Schedule.parse(cronExpression), () {
        debugPrint('⏰ Executing scheduled automation: ${automation.name}');
      });
      _scheduledTasks[automation.id] = task;
      debugPrint(
        '📅 Scheduled automation: ${automation.name} with cron: $cronExpression',
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule automation: ${automation.name}: $e');
    }
  }

  /// Cancel a scheduled automation
  void cancelAutomation(String automationId) {
    final task = _scheduledTasks.remove(automationId);
    if (task != null) {
      task.cancel();
      debugPrint('🛑 Cancelled automation: $automationId');
    }
  }

  /// Check if an automation is currently scheduled
  bool isScheduled(String automationId) {
    return _scheduledTasks.containsKey(automationId);
  }

  /// Get count of active scheduled tasks
  int get activeTaskCount => _scheduledTasks.length;

  /// Dispose resources
  void dispose() {
    _scheduledTasks.clear();
    _cron.close();
  }
}
