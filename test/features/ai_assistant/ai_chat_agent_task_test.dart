import 'dart:io';

import 'package:brainiac_plus/core/services/ollama_service.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_tool_executor.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agentic_runner.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_registry.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_response_parser.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_guardrails_service.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_orchestrator_service.dart';
import 'package:flutter_test/flutter_test.dart';

class OfflineOllama extends OllamaService {
  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  late Directory workspace;

  setUp(() => workspace = Directory.systemTemp.createTempSync('agent_task'));
  tearDown(() => workspace.deleteSync(recursive: true));

  AgenticRunner scriptedRunner(List<String> replies) {
    var i = 0;
    return AgenticRunner(
      chat: (_) async => i < replies.length ? replies[i++] : 'stuck',
      executor: AgentToolExecutor(
        workspaceRoot: workspace.path,
        runCommand: (cmd) async => 'ran: $cmd',
      ),
    );
  }

  final recorded = <String>[];
  setUp(() => recorded.clear());

  AiChatController buildController(AgenticRunner runner) {
    return AiChatController(
      OfflineOllama(),
      AiOrchestratorService(
        registry: AgentRegistry(),
        guardrails: AiGuardrailsService(),
      ),
      AgentResponseParser(),
      agentRunner: runner,
      onAgentRun: (taskId, request, steps) => recorded.add(request),
    );
  }

  test('agentEnabled reflects whether a runner was injected', () {
    expect(buildController(scriptedRunner(const [])).agentEnabled, isTrue);
  });

  test(
    'sendAgentTask runs the loop, creates files and posts a summary',
    () async {
      final controller = buildController(
        scriptedRunner([
          'Creating.\n```tool\n{"tool":"write_file","path":"rainbow/main.dart","content":"void main(){}"}\n```',
          'Done.\n```tool\n{"tool":"done","summary":"Rainbow app ready"}\n```',
        ]),
      );

      await controller.sendAgentTask('crea una app rainbow di test');

      expect(File('${workspace.path}/rainbow/main.dart').existsSync(), isTrue);

      final texts = controller.state.messages.map((m) => m.content).join('\n');
      expect(texts, contains('crea una app rainbow'));
      expect(texts, contains('Wrote rainbow/main.dart'));
      expect(texts, contains('Rainbow app ready'));
      expect(controller.state.isLoading, isFalse);
      // The completed run is recorded into the knowledge graph.
      expect(recorded, contains('crea una app rainbow di test'));
    },
  );

  test('a follow-up task sees the previous task in its history, so the '
      'agent remembers what it just did', () async {
    final conversations = <List<AgentTurn>>[];
    var i = 0;
    final replies = [
      'Creating.\n```tool\n{"tool":"write_file","path":"a/main.dart","content":"void main(){}"}\n```',
      'Done.\n```tool\n{"tool":"done","summary":"Made the app"}\n```',
      'Sure.\n```tool\n{"tool":"done","summary":"answered"}\n```',
    ];
    final runner = AgenticRunner(
      chat: (conversation) async {
        conversations.add(List.of(conversation));
        return i < replies.length ? replies[i++] : 'stuck';
      },
      executor: AgentToolExecutor(
        workspaceRoot: workspace.path,
        runCommand: (cmd) async => 'ran: $cmd',
      ),
    );
    final controller = buildController(runner);

    await controller.sendAgentTask('crea una app');
    await controller.sendAgentTask('cosa hai modificato?');

    // The second task's first LLM call must carry the first task's memory:
    // the user's original request and a digest naming the file it wrote.
    final followUp = conversations.last;
    final joined = followUp.map((t) => t.content).join('\n');
    expect(joined, contains('crea una app'));
    expect(joined, contains('a/main.dart'));
    expect(followUp.last.content, 'cosa hai modificato?');
  });

  test(
    'clearChat wipes the agent memory so the next task starts cold',
    () async {
      final conversations = <List<AgentTurn>>[];
      final runner = AgenticRunner(
        chat: (conversation) async {
          conversations.add(List.of(conversation));
          return 'Done.\n```tool\n{"tool":"done","summary":"ok"}\n```';
        },
        executor: AgentToolExecutor(
          workspaceRoot: workspace.path,
          runCommand: (cmd) async => '',
        ),
      );
      final controller = buildController(runner);

      await controller.sendAgentTask('first task');
      controller.clearChat();
      await controller.sendAgentTask('second task');

      // After clearing, the second task's conversation is just system + request.
      final second = conversations.last;
      expect(second.where((t) => t.content.contains('first task')), isEmpty);
      expect(second.last.content, 'second task');
    },
  );

  test('a blocked pipeline request never reaches the agent loop', () async {
    var chatCalls = 0;
    final runner = AgenticRunner(
      chat: (_) async {
        chatCalls++;
        return 'should not run';
      },
      executor: AgentToolExecutor(
        workspaceRoot: workspace.path,
        runCommand: (cmd) async => '',
      ),
    );
    final controller = buildController(runner);

    await controller.sendAgentTask('rm -rf / please');

    expect(chatCalls, 0);
    expect(controller.state.messages.last.content, contains('Blocked'));
  });
}
