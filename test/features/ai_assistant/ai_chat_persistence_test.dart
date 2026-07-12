import 'package:brainiac_plus/core/services/ollama_service.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/ai_assistant/models/ai_message.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_registry.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_response_parser.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_guardrails_service.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_orchestrator_service.dart';
import 'package:brainiac_plus/features/ai_assistant/services/chat_history_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory store so the controller's persistence can be tested without disk.
class FakeChatHistoryStore implements ChatHistoryStore {
  List<AiMessage> saved;
  int clears = 0;
  FakeChatHistoryStore([this.saved = const []]);

  @override
  Future<List<AiMessage>> load() async => saved;

  @override
  Future<void> save(List<AiMessage> messages) async =>
      saved = List.of(messages);

  @override
  Future<void> clear() async {
    clears++;
    saved = const [];
  }
}

class OfflineOllama extends OllamaService {
  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  AiChatController controller(ChatHistoryStore store) => AiChatController(
    OfflineOllama(),
    AiOrchestratorService(
      registry: AgentRegistry(),
      guardrails: AiGuardrailsService(),
    ),
    AgentResponseParser(),
    historyStore: store,
  );

  test('restores a persisted conversation in place of the greeting', () async {
    final store = FakeChatHistoryStore([
      AiMessage(
        id: '1',
        role: 'user',
        content: 'previous question',
        timestamp: DateTime(2026, 7, 13, 9),
      ),
      AiMessage(
        id: '2',
        role: 'assistant',
        content: 'previous answer',
        timestamp: DateTime(2026, 7, 13, 9, 1),
      ),
    ]);

    final c = controller(store);
    // _restore runs asynchronously in the constructor.
    await Future<void>.delayed(Duration.zero);

    final texts = c.state.messages.map((m) => m.content).toList();
    expect(texts, contains('previous question'));
    expect(texts, contains('previous answer'));
  });

  test('an empty store leaves the fresh greeting untouched', () async {
    final c = controller(FakeChatHistoryStore());
    await Future<void>.delayed(Duration.zero);
    expect(c.state.messages, hasLength(1)); // just the greeting
  });

  test('a settled chat turn is written to the store', () async {
    final store = FakeChatHistoryStore();
    final c = controller(store);
    await Future<void>.delayed(Duration.zero);

    await c.sendMessage('hello there');

    // The user's message made it into the persisted copy.
    expect(store.saved.any((m) => m.content == 'hello there'), isTrue);
  });

  test('clearChat wipes the persisted history', () async {
    final store = FakeChatHistoryStore([
      AiMessage(
        id: '1',
        role: 'user',
        content: 'x',
        timestamp: DateTime(2026, 7, 13),
      ),
    ]);
    final c = controller(store);
    await Future<void>.delayed(Duration.zero);

    c.clearChat();

    expect(store.clears, greaterThan(0));
    expect(store.saved, isEmpty);
  });
}
