import 'package:brainiac_plus/core/platform/shell_service.dart';
import 'package:brainiac_plus/features/terminal/controllers/terminal_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records executed commands instead of spawning real processes.
class FakeShellService extends ShellService {
  final executed = <String>[];

  @override
  Future<void> executeCommand(String command, {bool sudo = false}) async {
    executed.add(command);
  }
}

void main() {
  late FakeShellService shell;
  late TerminalController controller;

  setUp(() {
    shell = FakeShellService();
    controller = TerminalController(shellService: shell);
  });

  tearDown(() {
    controller.dispose();
  });

  test('safe commands are executed immediately', () async {
    await controller.executeCommand('ls -la');
    expect(shell.executed, ['ls -la']);
  });

  test(
    'dangerous commands are blocked with a warning on first attempt',
    () async {
      await controller.executeCommand('rm -rf /tmp/x');

      expect(shell.executed, isEmpty);
      expect(controller.state.last.output.join(), contains('⚠️'));
      expect(controller.state.last.isProcessRunning, isFalse);
    },
  );

  test(
    'repeating the same dangerous command confirms and executes it',
    () async {
      await controller.executeCommand('rm -rf /tmp/x');
      await controller.executeCommand('rm -rf /tmp/x');

      expect(shell.executed, ['rm -rf /tmp/x']);
    },
  );

  test(
    'a different command in between cancels the pending confirmation',
    () async {
      await controller.executeCommand('rm -rf /tmp/x');
      await controller.executeCommand('ls');
      await controller.executeCommand('rm -rf /tmp/x');

      // 'ls' ran, but the dangerous command was re-blocked, not executed.
      expect(shell.executed, ['ls']);
      expect(controller.state.last.output.join(), contains('⚠️'));
    },
  );
}
