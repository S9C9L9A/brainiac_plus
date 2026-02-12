import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/automation_database.dart';
import '../../../core/services/task_scheduler.dart';

class AutomationState {
  final List<AutomatedTask> tasks;
  final bool isLoading;
  final String? error;

  AutomationState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  AutomationState copyWith({
    List<AutomatedTask>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return AutomationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AutomationController extends StateNotifier<AutomationState> {
  final TaskScheduler _scheduler = TaskScheduler();
  final TaskExecutor _executor = TaskExecutor();

  AutomationController() : super(AutomationState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasks = await AutomationDatabase.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);

      // Schedule enabled tasks
      for (var task in tasks) {
        if (task.enabled && task.schedule != null) {
          _scheduleTask(task);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createTask(String name, String command, String? schedule) async {
    final task = AutomatedTask(
      name: name,
      command: command,
      schedule: schedule,
      enabled: true,
    );

    final id = await AutomationDatabase.insertTask(task);
    await loadTasks();

    // Schedule if has cron expression
    final createdTask = state.tasks.firstWhere((t) => t.id == id);
    if (createdTask.schedule != null) {
      _scheduleTask(createdTask);
    }
  }

  Future<void> updateTask(AutomatedTask task) async {
    await AutomationDatabase.updateTask(task);
    await loadTasks();

    // Reschedule
    if (task.id != null) {
      _scheduler.cancelTask(task.id!);
      if (task.enabled && task.schedule != null) {
        _scheduleTask(task);
      }
    }
  }

  Future<void> deleteTask(int id) async {
    _scheduler.cancelTask(id);
    await AutomationDatabase.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleTask(int id) async {
    final task = state.tasks.firstWhere((t) => t.id == id);
    final updated = task.copyWith(enabled: !task.enabled);
    await updateTask(updated);
  }

  Future<void> executeTask(int id) async {
    final task = state.tasks.firstWhere((t) => t.id == id);
    
    final result = await _executor.executeTask(task.command);
    
    // Save log
    await AutomationDatabase.insertLog(TaskLog(
      taskId: id,
      output: result['output'],
      status: result['success'] ? 'success' : 'error',
    ));

    // Update last run time
    await AutomationDatabase.updateTask(task.copyWith(lastRun: DateTime.now()));
    await loadTasks();
  }

  void _scheduleTask(AutomatedTask task) {
    if (task.id == null || task.schedule == null) return;

    _scheduler.scheduleTask(task.id!, task.schedule!, () async {
      await executeTask(task.id!);
    });
  }

  @override
  void dispose() {
    _scheduler.cancelAll();
    super.dispose();
  }
}

final automationProvider = StateNotifierProvider<AutomationController, AutomationState>((ref) {
  return AutomationController();
});
