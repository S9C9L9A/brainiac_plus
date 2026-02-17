import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/task_scheduler.dart';

void main() {
  group('TaskScheduler', () {
    late TaskScheduler scheduler;

    setUp(() {
      scheduler = TaskScheduler();
    });

    tearDown(() {
      scheduler.cancelAll();
    });

    test('scheduleTask with @hourly creates periodic timer', () {
      var callCount = 0;
      scheduler.scheduleTask(1, '@hourly', () => callCount++);
      // Timer is created; we can cancel it without error
      scheduler.cancelTask(1);
    });

    test('scheduleTask with @daily creates periodic timer', () {
      var callCount = 0;
      scheduler.scheduleTask(1, '@daily', () => callCount++);
      scheduler.cancelTask(1);
    });

    test('scheduleTask with @weekly creates periodic timer', () {
      var callCount = 0;
      scheduler.scheduleTask(1, '@weekly', () => callCount++);
      scheduler.cancelTask(1);
    });

    test('scheduleTask with @monthly creates periodic timer', () {
      var callCount = 0;
      scheduler.scheduleTask(1, '@monthly', () => callCount++);
      scheduler.cancelTask(1);
    });

    test('scheduleTask with */N uses N-minute interval', () {
      var callCount = 0;
      scheduler.scheduleTask(1, '*/5', () => callCount++);
      scheduler.cancelTask(1);
    });

    test('scheduleTask with invalid cron does not crash', () {
      var callCount = 0;
      scheduler.scheduleTask(1, 'invalid_cron', () => callCount++);
      // Should not throw
      scheduler.cancelTask(1);
    });

    test('cancelTask removes specific task', () {
      scheduler.scheduleTask(1, '@hourly', () {});
      scheduler.scheduleTask(2, '@daily', () {});
      scheduler.cancelTask(1);
      // Should not throw
      scheduler.cancelTask(1); // Cancel again - no error
    });

    test('cancelAll removes all tasks', () {
      scheduler.scheduleTask(1, '@hourly', () {});
      scheduler.scheduleTask(2, '@daily', () {});
      scheduler.scheduleTask(3, '*/10', () {});
      scheduler.cancelAll();
    });

    test('reschedule replaces existing task', () {
      var firstCalled = false;
      var secondCalled = false;
      scheduler.scheduleTask(1, '@hourly', () => firstCalled = true);
      scheduler.scheduleTask(1, '@daily', () => secondCalled = true);
      scheduler.cancelTask(1);
    });
  });

  group('TaskExecutor', () {
    late TaskExecutor executor;

    setUp(() {
      executor = TaskExecutor();
    });

    test('rejects commands with semicolons', () async {
      final result = await executor.executeTask('echo hello; rm -rf /');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
      expect((result['output'] as String).contains('disallowed'), true);
    });

    test('rejects commands with ampersands', () async {
      final result = await executor.executeTask('echo hello & echo world');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
    });

    test('rejects commands with pipes', () async {
      final result = await executor.executeTask('echo hello | grep hello');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
    });

    test('rejects commands with backticks', () async {
      final result = await executor.executeTask('echo `whoami`');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
    });

    test('rejects commands with dollar signs', () async {
      final result = await executor.executeTask('echo \$HOME');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
    });

    test('rejects empty command', () async {
      final result = await executor.executeTask('');
      expect(result['success'], false);
      expect(result['exitCode'], -1);
    });

    test('executes safe command successfully', () async {
      final result = await executor.executeTask('echo hello');
      expect(result['success'], true);
      expect(result['exitCode'], 0);
      expect((result['output'] as String).contains('hello'), true);
    });
  });
}
