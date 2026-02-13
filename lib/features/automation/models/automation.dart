import 'automation_enums.dart';

/// Advanced automation model with dual-mode support
class Automation {
  final String id;
  final String name;
  final String description;
  final AutomationCategory category;
  final ServiceProvider service;
  final AutomationMode preferredMode;
  final TriggerType triggerType;
  final AutomationStatus status;
  final Map<String, dynamic> config;
  final String? cronSchedule;
  final DateTime? nextRun;
  final DateTime? lastRun;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isTemplate;
  final int executionCount;
  final int successCount;
  final int failureCount;
  final List<String> tags;

  const Automation({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.service,
    this.preferredMode = AutomationMode.hybrid,
    this.triggerType = TriggerType.manual,
    this.status = AutomationStatus.idle,
    this.config = const {},
    this.cronSchedule,
    this.nextRun,
    this.lastRun,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isTemplate = false,
    this.executionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.tags = const [],
  });

  double get successRate {
    if (executionCount == 0) return 0.0;
    return (successCount / executionCount) * 100;
  }

  bool get hasSchedule => cronSchedule != null && cronSchedule!.isNotEmpty;

  bool get isRunning => status == AutomationStatus.running;
  bool get isPaused => status == AutomationStatus.paused;
  bool get isScheduled => status == AutomationStatus.scheduled;

  Automation copyWith({
    String? id,
    String? name,
    String? description,
    AutomationCategory? category,
    ServiceProvider? service,
    AutomationMode? preferredMode,
    TriggerType? triggerType,
    AutomationStatus? status,
    Map<String, dynamic>? config,
    String? cronSchedule,
    DateTime? nextRun,
    DateTime? lastRun,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isTemplate,
    int? executionCount,
    int? successCount,
    int? failureCount,
    List<String>? tags,
  }) {
    return Automation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      service: service ?? this.service,
      preferredMode: preferredMode ?? this.preferredMode,
      triggerType: triggerType ?? this.triggerType,
      status: status ?? this.status,
      config: config ?? this.config,
      cronSchedule: cronSchedule ?? this.cronSchedule,
      nextRun: nextRun ?? this.nextRun,
      lastRun: lastRun ?? this.lastRun,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isTemplate: isTemplate ?? this.isTemplate,
      executionCount: executionCount ?? this.executionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'service': service.name,
      'preferredMode': preferredMode.name,
      'triggerType': triggerType.name,
      'status': status.name,
      'config': config,
      'cronSchedule': cronSchedule,
      'nextRun': nextRun?.toIso8601String(),
      'lastRun': lastRun?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'isTemplate': isTemplate ? 1 : 0,
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'tags': tags.join(','),
    };
  }

  factory Automation.fromMap(Map<String, dynamic> map) {
    return Automation(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: AutomationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AutomationCategory.custom,
      ),
      service: ServiceProvider.values.firstWhere(
        (e) => e.name == map['service'],
        orElse: () => ServiceProvider.custom,
      ),
      preferredMode: AutomationMode.values.firstWhere(
        (e) => e.name == map['preferredMode'],
        orElse: () => AutomationMode.hybrid,
      ),
      triggerType: TriggerType.values.firstWhere(
        (e) => e.name == map['triggerType'],
        orElse: () => TriggerType.manual,
      ),
      status: AutomationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AutomationStatus.idle,
      ),
      config: map['config'] as Map<String, dynamic>? ?? {},
      cronSchedule: map['cronSchedule'] as String?,
      nextRun: map['nextRun'] != null ? DateTime.parse(map['nextRun']) : null,
      lastRun: map['lastRun'] != null ? DateTime.parse(map['lastRun']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isActive: map['isActive'] == 1,
      isTemplate: map['isTemplate'] == 1,
      executionCount: map['executionCount'] as int? ?? 0,
      successCount: map['successCount'] as int? ?? 0,
      failureCount: map['failureCount'] as int? ?? 0,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    );
  }
}

/// Automation execution log
class AutomationLog {
  final String id;
  final String automationId;
  final AutomationMode executionMode;
  final AutomationStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? errorMessage;
  final Map<String, dynamic>? result;
  final List<String> steps;

  const AutomationLog({
    required this.id,
    required this.automationId,
    required this.executionMode,
    required this.status,
    required this.startTime,
    this.endTime,
    this.errorMessage,
    this.result,
    this.steps = const [],
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isSuccess => status == AutomationStatus.completed;
  bool get isFailed => status == AutomationStatus.failed;
  bool get isRunning => status == AutomationStatus.running;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'automationId': automationId,
      'executionMode': executionMode.name,
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'errorMessage': errorMessage,
      'result': result,
      'steps': steps.join('|'),
    };
  }

  factory AutomationLog.fromMap(Map<String, dynamic> map) {
    return AutomationLog(
      id: map['id'] as String,
      automationId: map['automationId'] as String,
      executionMode: AutomationMode.values.firstWhere(
        (e) => e.name == map['executionMode'],
        orElse: () => AutomationMode.api,
      ),
      status: AutomationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AutomationStatus.idle,
      ),
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      errorMessage: map['errorMessage'] as String?,
      result: map['result'] as Map<String, dynamic>?,
      steps: (map['steps'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? [],
    );
  }
}
