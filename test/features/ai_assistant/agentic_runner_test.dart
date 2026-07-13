import 'dart:io';

import 'package:brainiac_plus/features/ai_assistant/services/agent_tool_executor.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agentic_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory workspace;
  late AgentToolExecutor executor;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('agentic');
    executor = AgentToolExecutor(
      workspaceRoot: workspace.path,
      runCommand: (cmd) async => 'ran: $cmd',
    );
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  /// Returns scripted assistant replies in order, ignoring the prompt.
  AgentChat scripted(List<String> replies) {
    var i = 0;
    return (_) async => i < replies.length ? replies[i++] : 'stuck';
  }

  test('nudges when the model shows a code block but no write_file', () async {
    // Step 1: shows the fix in a ```yaml block (no tool) → runner nudges.
    // Step 2: complies with a real write_file → it's applied.
    final runner = AgenticRunner(
      chat: scripted([
        'Here is the corrected file:\n```dart\nclass Fixed {}\n```',
        '```tool\n{"tool":"write_file","path":"lib/fixed.dart","content":"class Fixed {}"}\n```',
        '```tool\n{"tool":"done","summary":"fixed"}\n```',
      ]),
      executor: executor,
    );

    final result = await runner.run('fix the widget');

    expect(
      File('${workspace.path}/lib/fixed.dart').existsSync(),
      isTrue,
      reason: 'the nudge should have produced a real write',
    );
    expect(result.completed, isTrue);
  });

  test('a plan-only code block is NOT nudged (plan mode proposes)', () async {
    var calls = 0;
    final runner = AgenticRunner(
      chat: (_) async {
        calls++;
        return 'Proposed change:\n```yaml\nsdk: ^3.12.0\n```';
      },
      executor: executor,
      planMode: true,
    );
    final result = await runner.run('plan the fix');
    // No nudge in plan mode → ends after the single reply.
    expect(calls, 1);
    expect(result.completed, isTrue);
  });

  test(
    'retries once when the model call fails (context overflow → 400)',
    () async {
      var calls = 0;
      final runner = AgenticRunner(
        chat: (_) async {
          calls++;
          if (calls == 1) throw Exception('DioException 400 bad response');
          return '```tool\n{"tool":"done","summary":"ok"}\n```';
        },
        executor: executor,
      );
      final result = await runner.run('do something');
      expect(calls, 2); // failed once, retried and succeeded
      expect(result.completed, isTrue);
    },
  );

  test('drives write → run → done and executes each step', () async {
    final runner = AgenticRunner(
      chat: scripted([
        'Creating the app.\n```tool\n{"tool":"write_file","path":"rainbow/main.dart","content":"void main(){}"}\n```',
        'Running it.\n```tool\n{"tool":"run","command":"dart run rainbow/main.dart"}\n```',
        'Finished.\n```tool\n{"tool":"done","summary":"Rainbow app ready"}\n```',
      ]),
      executor: executor,
    );

    final steps = <AgentStep>[];
    final result = await runner.run(
      'crea una app rainbow di test',
      onStep: steps.add,
    );

    expect(File('${workspace.path}/rainbow/main.dart').existsSync(), isTrue);
    expect(steps, hasLength(3));
    expect(steps[0].results.single.call.path, 'rainbow/main.dart');
    expect(steps[1].results.single.output, contains('ran: dart run'));
    expect(result.completed, isTrue);
    expect(result.summary, 'Rainbow app ready');
  });

  test('stops at maxIterations when the model never finishes', () async {
    final runner = AgenticRunner(
      chat: scripted(
        List.filled(20, '```tool\n{"tool":"run","command":"echo loop"}\n```'),
      ),
      executor: executor,
      maxIterations: 3,
    );

    final result = await runner.run('loop forever');

    expect(result.completed, isFalse);
    expect(result.iterations, 3);
  });

  test('a reply with no tool calls ends the run as a plain answer', () async {
    final runner = AgenticRunner(
      chat: scripted(['Here is my explanation, no actions needed.']),
      executor: executor,
    );

    final result = await runner.run('spiegami come funziona');

    expect(result.completed, isTrue);
    expect(result.steps.single.assistantText, contains('explanation'));
    expect(result.steps.single.results, isEmpty);
  });

  test('prior history is placed between the system prompt and the new '
      'request, giving the agent memory across turns', () async {
    List<AgentTurn>? seen;
    final runner = AgenticRunner(
      chat: (conversation) async {
        seen = List.of(conversation);
        return 'ok';
      },
      executor: executor,
    );

    await runner.run(
      'now show me that file',
      history: const [
        AgentTurn('user', 'create rainbow/main.dart'),
        AgentTurn('assistant', 'Wrote: rainbow/main.dart'),
      ],
    );

    expect(seen, isNotNull);
    expect(seen!.first.role, 'system');
    expect(seen![1].content, 'create rainbow/main.dart');
    expect(seen![2].content, 'Wrote: rainbow/main.dart');
    expect(seen!.last.role, 'user');
    expect(seen!.last.content, 'now show me that file');
  });

  test('read_file returns the file contents to the agent', () async {
    File('${workspace.path}/notes.txt').writeAsStringSync('hello there');
    final runner = AgenticRunner(
      chat: scripted([
        '```tool\n{"tool":"read_file","path":"notes.txt"}\n```',
        '```tool\n{"tool":"done","summary":"read it"}\n```',
      ]),
      executor: executor,
    );

    final result = await runner.run('what is in notes.txt?');

    expect(result.steps.first.results.single.ok, isTrue);
    expect(result.steps.first.results.single.output, contains('hello there'));
  });

  test('failed tool results are fed back and do not abort the run', () async {
    final runner = AgenticRunner(
      chat: scripted([
        '```tool\n{"tool":"write_file","path":"../escape.txt","content":"x"}\n```',
        '```tool\n{"tool":"done","summary":"recovered"}\n```',
      ]),
      executor: executor,
    );

    final result = await runner.run('try something unsafe');

    expect(result.completed, isTrue);
    expect(result.steps.first.results.single.ok, isFalse);
  });
}
