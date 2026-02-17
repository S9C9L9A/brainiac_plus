import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/features/automation/models/automation.dart';
import 'package:brainiac_plus/features/automation/models/automation_enums.dart';

void main() {
  group('Automation model', () {
    late Automation automation;

    setUp(() {
      automation = Automation(
        id: 'test-1',
        name: 'Test Automation',
        description: 'A test automation',
        category: AutomationCategory.socialMedia,
        service: ServiceProvider.instagram,
        preferredMode: AutomationMode.hybrid,
        triggerType: TriggerType.manual,
        status: AutomationStatus.idle,
        config: {'key': 'value'},
        cronSchedule: '@daily',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        isActive: true,
        executionCount: 10,
        successCount: 8,
        failureCount: 2,
        tags: ['social', 'test'],
      );
    });

    test('successRate calculates correctly', () {
      expect(automation.successRate, 80.0);
    });

    test('successRate returns 0 when no executions', () {
      final noExec = automation.copyWith(executionCount: 0, successCount: 0);
      expect(noExec.successRate, 0.0);
    });

    test('hasSchedule returns true when cronSchedule is set', () {
      expect(automation.hasSchedule, true);
    });

    test('hasSchedule returns false when cronSchedule is null', () {
      final noSchedule = Automation(
        id: 'test-2',
        name: 'No Schedule',
        description: 'test',
        category: AutomationCategory.custom,
        service: ServiceProvider.custom,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(noSchedule.hasSchedule, false);
    });

    test('hasSchedule returns false when cronSchedule is empty', () {
      final emptySchedule = automation.copyWith(cronSchedule: '');
      expect(emptySchedule.hasSchedule, false);
    });

    test('isRunning returns true when status is running', () {
      final running = automation.copyWith(status: AutomationStatus.running);
      expect(running.isRunning, true);
    });

    test('isPaused returns true when status is paused', () {
      final paused = automation.copyWith(status: AutomationStatus.paused);
      expect(paused.isPaused, true);
    });

    test('isScheduled returns true when status is scheduled', () {
      final scheduled = automation.copyWith(status: AutomationStatus.scheduled);
      expect(scheduled.isScheduled, true);
    });

    test('trigger returns Manual for manual trigger type', () {
      expect(automation.trigger, 'Manual');
    });

    test('trigger returns cron schedule for scheduled trigger type', () {
      final scheduled = automation.copyWith(triggerType: TriggerType.scheduled);
      expect(scheduled.trigger, '@daily');
    });

    test('trigger returns Event-based for event trigger type', () {
      final event = automation.copyWith(triggerType: TriggerType.event);
      expect(event.trigger, 'Event-based');
    });

    test('trigger returns Conditional for condition trigger type', () {
      final cond = automation.copyWith(triggerType: TriggerType.condition);
      expect(cond.trigger, 'Conditional');
    });

    test('copyWith preserves unchanged values', () {
      final copy = automation.copyWith(name: 'Updated Name');
      expect(copy.name, 'Updated Name');
      expect(copy.id, 'test-1');
      expect(copy.description, 'A test automation');
      expect(copy.category, AutomationCategory.socialMedia);
    });

    test('toMap and fromMap roundtrip', () {
      final map = automation.toMap();
      final restored = Automation.fromMap(map);
      expect(restored.id, automation.id);
      expect(restored.name, automation.name);
      expect(restored.description, automation.description);
      expect(restored.category, automation.category);
      expect(restored.service, automation.service);
      expect(restored.preferredMode, automation.preferredMode);
      expect(restored.triggerType, automation.triggerType);
      expect(restored.status, automation.status);
      expect(restored.isActive, automation.isActive);
      expect(restored.executionCount, automation.executionCount);
      expect(restored.successCount, automation.successCount);
      expect(restored.failureCount, automation.failureCount);
      expect(restored.tags, automation.tags);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 'test-3',
        'name': 'Minimal',
        'description': 'Minimal automation',
        'category': 'custom',
        'service': 'custom',
        'preferredMode': 'hybrid',
        'triggerType': 'manual',
        'status': 'idle',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'isActive': 1,
        'isTemplate': 0,
      };
      final automation = Automation.fromMap(map);
      expect(automation.id, 'test-3');
      expect(automation.config, {});
      expect(automation.cronSchedule, isNull);
      expect(automation.executionCount, 0);
      expect(automation.tags, isEmpty);
    });

    test('fromMap handles unknown enum values with fallback', () {
      final map = {
        'id': 'test-4',
        'name': 'Unknown Enums',
        'description': 'Test unknown enum values',
        'category': 'nonexistent',
        'service': 'nonexistent',
        'preferredMode': 'nonexistent',
        'triggerType': 'nonexistent',
        'status': 'nonexistent',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
        'isActive': 1,
        'isTemplate': 0,
      };
      final automation = Automation.fromMap(map);
      expect(automation.category, AutomationCategory.custom);
      expect(automation.service, ServiceProvider.custom);
      expect(automation.preferredMode, AutomationMode.hybrid);
      expect(automation.triggerType, TriggerType.manual);
      expect(automation.status, AutomationStatus.idle);
    });
  });

  group('AutomationLog model', () {
    test('duration returns null when endTime is null', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.api,
        status: AutomationStatus.running,
        startTime: DateTime(2026, 1, 1, 10, 0),
      );
      expect(log.duration, isNull);
    });

    test('duration calculates correctly when endTime is set', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.api,
        status: AutomationStatus.completed,
        startTime: DateTime(2026, 1, 1, 10, 0),
        endTime: DateTime(2026, 1, 1, 10, 5),
      );
      expect(log.duration, const Duration(minutes: 5));
    });

    test('isSuccess returns true for completed status', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.api,
        status: AutomationStatus.completed,
        startTime: DateTime.now(),
      );
      expect(log.isSuccess, true);
      expect(log.isFailed, false);
    });

    test('isFailed returns true for failed status', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.api,
        status: AutomationStatus.failed,
        startTime: DateTime.now(),
        errorMessage: 'Something went wrong',
      );
      expect(log.isFailed, true);
      expect(log.isSuccess, false);
    });

    test('isRunning returns true for running status', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.api,
        status: AutomationStatus.running,
        startTime: DateTime.now(),
      );
      expect(log.isRunning, true);
    });

    test('toMap and fromMap roundtrip', () {
      final log = AutomationLog(
        id: 'log-1',
        automationId: 'auto-1',
        executionMode: AutomationMode.browser,
        status: AutomationStatus.completed,
        startTime: DateTime(2026, 1, 1, 10, 0),
        endTime: DateTime(2026, 1, 1, 10, 5),
        errorMessage: null,
        steps: ['Step 1', 'Step 2'],
      );
      final map = log.toMap();
      final restored = AutomationLog.fromMap(map);
      expect(restored.id, log.id);
      expect(restored.automationId, log.automationId);
      expect(restored.executionMode, log.executionMode);
      expect(restored.status, log.status);
      expect(restored.steps, log.steps);
    });
  });

  group('AutomationEnums extensions', () {
    test('AutomationMode labels are correct', () {
      expect(AutomationMode.api.label, 'API');
      expect(AutomationMode.browser.label, 'Browser');
      expect(AutomationMode.app.label, 'App');
      expect(AutomationMode.hybrid.label, 'Hybrid');
    });

    test('AutomationMode icons are correct', () {
      expect(AutomationMode.api.icon, '🔌');
      expect(AutomationMode.browser.icon, '🌐');
      expect(AutomationMode.app.icon, '📱');
      expect(AutomationMode.hybrid.icon, '⚡');
    });

    test('AutomationStatus labels are correct', () {
      expect(AutomationStatus.idle.label, 'Idle');
      expect(AutomationStatus.running.label, 'Running');
      expect(AutomationStatus.paused.label, 'Paused');
      expect(AutomationStatus.completed.label, 'Completed');
      expect(AutomationStatus.failed.label, 'Failed');
      expect(AutomationStatus.scheduled.label, 'Scheduled');
    });

    test('ServiceProvider labels are correct', () {
      expect(ServiceProvider.instagram.label, 'Instagram');
      expect(ServiceProvider.github.label, 'GitHub');
      expect(ServiceProvider.custom.label, 'Custom');
    });

    test('ServiceProvider supportsAPI is correct', () {
      expect(ServiceProvider.instagram.supportsAPI, true);
      expect(ServiceProvider.github.supportsAPI, true);
      expect(ServiceProvider.google.supportsAPI, true);
      expect(ServiceProvider.discord.supportsAPI, false);
      expect(ServiceProvider.custom.supportsAPI, false);
    });

    test('ServiceProvider supportsBrowser is always true', () {
      for (final provider in ServiceProvider.values) {
        expect(provider.supportsBrowser, true);
      }
    });

    test('AutomationCategory labels are correct', () {
      expect(AutomationCategory.socialMedia.label, 'Social Media');
      expect(AutomationCategory.productivity.label, 'Productivity');
      expect(AutomationCategory.custom.label, 'Custom');
    });

    test('TriggerType values cover all types', () {
      expect(TriggerType.values.length, 4);
      expect(TriggerType.values, contains(TriggerType.manual));
      expect(TriggerType.values, contains(TriggerType.scheduled));
      expect(TriggerType.values, contains(TriggerType.event));
      expect(TriggerType.values, contains(TriggerType.condition));
    });
  });
}
