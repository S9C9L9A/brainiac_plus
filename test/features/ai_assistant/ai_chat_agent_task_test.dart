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
