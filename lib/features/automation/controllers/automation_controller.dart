import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/automation.dart';
import '../models/automation_enums.dart';
import '../models/automation_templates.dart';
import '../../../core/services/automation_engine.dart';

/// State for automation management
class AutomationState {
  final List<Automation> activeAutomations;
  final List<Automation> templates;
  final List<AutomationLog> logs;
  final bool isLoading;
  final String? error;

  const AutomationState({
    this.activeAutomations = const [],
    this.templates = const [],
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  AutomationState copyWith({
    List<Automation>? activeAutomations,
    List<Automation>? templates,
    List<AutomationLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return AutomationState(
      activeAutomations: activeAutomations ?? this.activeAutomations,
      templates: templates ?? this.templates,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Automation> get runningAutomations =>
      activeAutomations.where((a) => a.isRunning).toList();

  List<Automation> get scheduledAutomations =>
      activeAutomations.where((a) => a.isScheduled).toList();

  int get todayExecutions {
    final today = DateTime.now();
    return logs.where((log) {
      return log.startTime.year == today.year &&
          log.startTime.month == today.month &&
          log.startTime.day == today.day;
    }).length;
  }
}

/// Controller for automation management
class AutomationController extends StateNotifier<AutomationState> {
  final AutomationEngine _engine;

  AutomationController(this._engine) : super(const AutomationState()) {
    state = state.copyWith(templates: AutomationTemplates.templates);
  }

  Future<void> createFromTemplate(String templateId, Map<String, dynamic>? config) async {
    final template = AutomationTemplates.getTemplateById(templateId);
    if (template == null) return;

    final newAutomation = template.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isTemplate: false,
      config: config ?? template.config,
      status: template.hasSchedule ? AutomationStatus.scheduled : AutomationStatus.idle,
    );

    state = state.copyWith(
      activeAutomations: [...state.activeAutomations, newAutomation],
    );
  }

  Future<void> executeAutomation(String id) async {
    final automation = state.activeAutomations.firstWhere((a) => a.id == id);
    
    final runningAutomation = automation.copyWith(status: AutomationStatus.running);
    final updated = state.activeAutomations.map((a) => a.id == id ? runningAutomation : a).toList();
    state = state.copyWith(activeAutomations: updated);

    try {
      final log = await _engine.execute(automation);
      
      final completedAutomation = automation.copyWith(
        status: log.isSuccess ? AutomationStatus.completed : AutomationStatus.failed,
        executionCount: automation.executionCount + 1,
        successCount: automation.successCount + (log.isSuccess ? 1 : 0),
        failureCount: automation.failureCount + (log.isFailed ? 1 : 0),
        lastRun: DateTime.now(),
      );
      
      final finalUpdated = state.activeAutomations.map((a) => a.id == id ? completedAutomation : a).toList();
      state = state.copyWith(
        activeAutomations: finalUpdated,
        logs: [...state.logs, log],
      );
    } catch (e) {
      final failedAutomation = automation.copyWith(
        status: AutomationStatus.failed,
        executionCount: automation.executionCount + 1,
        failureCount: automation.failureCount + 1,
      );
      final errorUpdated = state.activeAutomations.map((a) => a.id == id ? failedAutomation : a).toList();
      state = state.copyWith(activeAutomations: errorUpdated);
    }
  }

  void toggleAutomation(String id) {
    final automation = state.activeAutomations.firstWhere((a) => a.id == id);
    final toggled = automation.copyWith(isActive: !automation.isActive);
    final updated = state.activeAutomations.map((a) => a.id == id ? toggled : a).toList();
    state = state.copyWith(activeAutomations: updated);
  }

  Future<void> runAutomation(String id) async {
    await executeAutomation(id);
  }
}

/// Provider for automation controller
final automationControllerProvider =
    StateNotifierProvider<AutomationController, AutomationState>((ref) {
  return AutomationController(AutomationEngine());
});
