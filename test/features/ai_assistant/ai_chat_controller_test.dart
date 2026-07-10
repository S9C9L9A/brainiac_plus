import 'package:brainiac_plus/core/services/ollama_service.dart';
import 'package:brainiac_plus/features/activity/models/activity_entry.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_registry.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_response_parser.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_guardrails_service.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_orchestrator_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ollama is never reachable in tests; sendMessage exits on the
/// availability check, after the pipeline and activity logging ran.
class OfflineOllamaService extends OllamaService {
  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  late List<ActivityEntry> logged;
  late AiChatController controller;

  setUp(() {
    logged = [];
    controller = AiChatController(
      OfflineOllamaService(),
      AiOrchestratorService(
        registry: AgentRegistry(),
        guardrails: AiGuardrailsService(),
      ),
      AgentResponseParser(),
      onActivity: logged.add,
    );
  });

  tearDown(() => controller.dispose());

  test('user queries are reported to the activity log', () async {
    await controller.sendMessage('che tempo fa domani?');

    expect(logged, hasLength(1));
    expect(logged.single.type, ActivityType.ai);
    expect(logged.single.title, 'AI query');
    expect(logged.single.description, 'che tempo fa domani?');
  });

  test('pipeline-blocked queries are logged as blocked', () async {
    await controller.sendMessage('rm -rf / please');

    expect(logged, hasLength(1));
    expect(logged.single.title, contains('blocked'));
  });

  test('empty messages are not logged', () async {
    await controller.sendMessage('   ');

    expect(logged, isEmpty);
  });
}
