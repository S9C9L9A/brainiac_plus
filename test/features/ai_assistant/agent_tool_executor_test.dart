import 'dart:async';
import 'dart:io';

import 'package:brainiac_plus/features/ai_assistant/models/agent_tool_call.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_tool_executor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory workspace;
  late AgentToolExecutor executor;
  late List<String> ranCommands;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('agent_exec');
    ranCommands = [];
    executor = AgentToolExecutor(
      workspaceRoot: workspace.path,
      runCommand: (cmd) async {
        ranCommands.add(cmd);
        return 'output of: $cmd';
      },
    );
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  group('write_file', () {
    test('writes a file within the workspace and reports success', () async {
      final result = await executor.execute(
        const AgentToolCall(
          tool: ToolType.writeFile,
          path: 'test_apps/rainbow/main.dart',
          content: 'void main() {}',
        ),
      );

      expect(result.ok, isTrue);
      final file = File('${workspace.path}/test_apps/rainbow/main.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), 'void main() {}');
    });

    test('rejects paths that escape the workspace', () async {
      final result = await executor.execute(
        const AgentToolCall(
          tool: ToolType.writeFile,
          path: '../../etc/passwd',
          content: 'x',
        ),
      );

      expect(result.ok, isFalse);
      expect(result.output.toLowerCase(), contains('outside'));
    });

    test('accepts an absolute path that points inside the workspace', () async {
      // Models often emit the full path; it must still write, not be rejected.
      final abs = '${workspace.path}/lib/widget.dart';
      final result = await executor.execute(
        AgentToolCall(
          tool: ToolType.writeFile,
          path: abs,
          content: 'class W {}',
        ),
      );

      expect(result.ok, isTrue);
      expect(File(abs).existsSync(), isTrue);
      expect(File(abs).readAsStringSync(), 'class W {}');
    });

    test('rejects an absolute path outside the workspace', () async {
      final result = await executor.execute(
        const AgentToolCall(
          tool: ToolType.writeFile,
          path: '/etc/passwd',
          content: 'x',
        ),
      );
      expect(result.ok, isFalse);
      expect(result.output.toLowerCase(), contains('outside'));
    });

    test(
      'an empty locked set allows editing main.dart (project-scoped)',
      () async {
        final scoped = AgentToolExecutor(
          workspaceRoot: workspace.path,
          runCommand: (_) async => '',
          lockedFiles: const {},
        );
        final result = await scoped.execute(
          const AgentToolCall(
            tool: ToolType.writeFile,
            path: 'lib/main.dart',
            content: 'void main() {}',
          ),
        );
        expect(result.ok, isTrue);
      },
    );

    test('rejects writing locked project files', () async {
      for (final locked in [
        'pubspec.yaml',
        'lib/main.dart',
        'go_backend/.env',
      ]) {
        final result = await executor.execute(
          AgentToolCall(tool: ToolType.writeFile, path: locked, content: 'x'),
        );
        expect(result.ok, isFalse, reason: locked);
        expect(result.output.toLowerCase(), contains('protected'));
      }
    });
  });

  group('run', () {
    test('executes a safe command and returns its output', () async {
      final result = await executor.execute(
        const AgentToolCall(tool: ToolType.run, command: 'dart --version'),
      );

      expect(result.ok, isTrue);
      expect(ranCommands, ['dart --version']);
      expect(result.output, contains('dart --version'));
    });

    test('blocks destructive commands via the command guard', () async {
      final result = await executor.execute(
        const AgentToolCall(tool: ToolType.run, command: 'rm -rf /'),
      );

      expect(result.ok, isFalse);
      expect(ranCommands, isEmpty);
      expect(result.output.toLowerCase(), contains('blocked'));
    });
  });

  group('command timeout', () {
    test('a command that never returns fails instead of hanging', () async {
      final hangingExecutor = AgentToolExecutor(
        workspaceRoot: workspace.path,
        runCommand: (_) => Completer<String>().future, // never completes
        commandTimeout: const Duration(milliseconds: 50),
      );

      final result = await hangingExecutor.execute(
        const AgentToolCall(tool: ToolType.run, command: 'sleep 999'),
      );

      expect(result.ok, isFalse);
      expect(result.output.toLowerCase(), contains('timed out'));
    });
  });

  group('done', () {
    test('reports the summary and is terminal', () async {
      final result = await executor.execute(
        const AgentToolCall(
          tool: ToolType.done,
          summary: 'Rainbow app created',
        ),
      );

      expect(result.ok, isTrue);
      expect(result.output, contains('Rainbow app created'));
      expect(AgentToolExecutor.isTerminal(result.call), isTrue);
    });
  });
}
