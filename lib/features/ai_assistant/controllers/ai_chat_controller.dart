import 'dart:math' show min;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_message.dart';
import '../../../core/services/ollama_service.dart';
import '../../settings/providers/extended_settings_provider.dart';
import '../services/agent_registry.dart';
import '../services/ai_guardrails_service.dart';
import '../services/ai_orchestrator_service.dart';
import '../services/agent_response_parser.dart';

/// Provider for Ollama service
final ollamaServiceProvider = Provider<OllamaService>((ref) {
  final settings = ref.watch(extendedSettingsProvider);
  return OllamaService(
    baseUrl: settings.ollamaEndpoint,
    model: settings.ollamaModelName,
  );
});

final ollamaAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(ollamaServiceProvider);
  return service.isAvailable();
});

final agentRegistryProvider = Provider<AgentRegistry>((ref) {
  return AgentRegistry();
});

final aiGuardrailsProvider = Provider<AiGuardrailsService>((ref) {
  return AiGuardrailsService();
});

final agentResponseParserProvider = Provider<AgentResponseParser>((ref) {
  return AgentResponseParser();
});

final aiOrchestratorProvider = Provider<AiOrchestratorService>((ref) {
  return AiOrchestratorService(
    registry: ref.watch(agentRegistryProvider),
    guardrails: ref.watch(aiGuardrailsProvider),
  );
});

/// Provider for AI chat controller
final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
  return AiChatController(
    ref.watch(ollamaServiceProvider),
    ref.watch(aiOrchestratorProvider),
    ref.watch(agentResponseParserProvider),
  );
});

/// AI Chat State
class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// AI Chat Controller
class AiChatController extends StateNotifier<AiChatState> {
  final OllamaService _ollamaService;
  final AiOrchestratorService _orchestrator;
  final AgentResponseParser _responseParser;

  AiChatController(
    this._ollamaService,
    this._orchestrator,
    this._responseParser,
  ) : super(AiChatState()) {
    _initialize();
  }

  void _initialize() {
    // Add system message
    final systemMsg = AiMessage(
      id: 'system',
      role: 'assistant',
      content: '👋 Hi! I\'m BrainiacPlus AI Assistant. I can help you add features, fix bugs, or automate tasks. What would you like to build today?',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [systemMsg]);
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMsg = userMessage(content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // Check if Ollama is available before proceeding
      final isAvailable = await _ollamaService.isAvailable();
      if (!isAvailable) {
        final errorMsg = errorMessage(
          '❌ Ollama is not available.\n\n'
          'Please ensure:\n'
          '1. Ollama is installed and running\n'
          '2. The endpoint is correct (default: http://localhost:11434)\n'
          '3. Check your network connection\n\n'
          'Run: ollama serve',
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isLoading: false,
          error: 'Ollama unavailable',
        );
        return;
      }

      final decision = _orchestrator.route(content);
      final chatMessages = _buildChatHistory(decision.systemPrompt);
      final response = await _ollamaService.chat(chatMessages);
      final assistantMsg = _buildAssistantMessage(decision, response);

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = errorMessage(
        '⚠️ Error: ${e.toString()}\n\n'
        'Troubleshooting:\n'
        '• Verify Ollama is running: ollama serve\n'
        '• Check endpoint: http://localhost:11434\n'
        '• Try again in a moment',
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Send a message with streaming response
  Future<void> sendMessageStream(String content) async {
    if (content.trim().isEmpty) return;

    // Check Ollama availability first
    final isAvailable = await _ollamaService.isAvailable();
    if (!isAvailable) {
      final userMsg = userMessage(content);
      final errorMsg = errorMessage(
        '❌ Ollama Service Unavailable\n\n'
        'The AI assistant requires Ollama to be running.\n\n'
        'To start Ollama:\n'
        '1. Open a terminal\n'
        '2. Run: ollama serve\n'
        '3. Ensure it\'s accessible at: http://localhost:11434\n\n'
        'Then try your message again.',
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, errorMsg],
        isLoading: false,
        error: 'Ollama unavailable',
      );
      return;
    }

    final decision = _orchestrator.route(content);
    final userMsg = userMessage(content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    final chatMessages = _buildChatHistory(decision.systemPrompt);
    final streamMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    var streamContent = '';
    var receivedChunk = false;

    try {
      await for (final chunk in _ollamaService.chatStream(chatMessages)) {
        receivedChunk = true;
        streamContent += chunk;

        final updatedMsg = AiMessage(
          id: streamMsgId,
          role: 'assistant',
          content: streamContent,
          timestamp: DateTime.now(),
          agentId: decision.agent.id,
          intent: decision.intent,
        );

        final messages =
            state.messages.where((m) => m.id != streamMsgId).toList();
        messages.add(updatedMsg);

        state = state.copyWith(messages: messages);
      }

      final parsedResponse = _responseParser.parse(streamContent);
      final sanitizedPaths = _orchestrator.sanitizePaths(
        decision,
        parsedResponse.filesPaths,
      );

      final finalizedMsg = assistantMessage(
        parsedResponse.content,
        codeSnippet: parsedResponse.codeSnippet,
        filesPaths: sanitizedPaths,
        agentId: decision.agent.id,
        intent: decision.intent,
      );

      final messages =
          state.messages.where((m) => m.id != streamMsgId).toList();
      messages.add(finalizedMsg);

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      // If no chunks received, try fallback to non-streaming
      if (!receivedChunk) {
        try {
          final response = await _ollamaService.chat(chatMessages);
          final parsedResponse = _responseParser.parse(response);
          final sanitizedPaths = _orchestrator.sanitizePaths(
            decision,
            parsedResponse.filesPaths,
          );

          final fallbackMsg = assistantMessage(
            parsedResponse.content,
            codeSnippet: parsedResponse.codeSnippet,
            filesPaths: sanitizedPaths,
            agentId: decision.agent.id,
            intent: decision.intent,
          );

          final messages =
              state.messages.where((m) => m.id != streamMsgId).toList();
          messages.add(fallbackMsg);

          state = state.copyWith(
            messages: messages,
            isLoading: false,
          );
          return;
        } catch (fallbackError) {
          // Fallback also failed - show detailed error
          final errorMsg = errorMessage(
            '⚠️ Failed to get AI response\n\n'
            'Error: ${_extractErrorMessage(e)}\n\n'
            'Possible causes:\n'
            '• Ollama service crashed or stopped\n'
            '• Network connectivity issues\n'
            '• Model not loaded in Ollama\n\n'
            'Try:\n'
            '1. Restart Ollama: ollama serve\n'
            '2. Check terminal for errors\n'
            '3. Reload the app',
          );
          state = state.copyWith(
            messages: [...state.messages, errorMsg],
            isLoading: false,
            error: e.toString(),
          );
          return;
        }
      }

      // Chunks were received but stream failed mid-way
      final errorMsg = errorMessage(
        '⚠️ Stream interrupted\n\n'
        'The connection was lost while receiving the response.\n\n'
        'Partial response shown above.\n\n'
        'Try again or restart Ollama.',
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Extract readable error message from exception
  String _extractErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('not available')) {
      return 'Ollama service not available';
    } else if (msg.contains('endpoint not found')) {
      return 'Cannot reach Ollama endpoint';
    } else if (msg.contains('Connection refused')) {
      return 'Connection refused - Ollama not running?';
    } else if (msg.contains('timeout')) {
      return 'Request timeout - Ollama might be slow';
    }
    return msg.substring(0, min(msg.length, 100));
  }

  AiMessage _buildAssistantMessage(RoutingDecision decision, String response) {
    final parsedResponse = _responseParser.parse(response);
    final sanitizedPaths = _orchestrator.sanitizePaths(
      decision,
      parsedResponse.filesPaths,
    );

    return assistantMessage(
      parsedResponse.content,
      codeSnippet: parsedResponse.codeSnippet,
      filesPaths: sanitizedPaths,
      agentId: decision.agent.id,
      intent: decision.intent,
    );
  }

  /// Build chat history for Ollama API
  List<ChatMessage> _buildChatHistory(String systemPrompt) {
    final history = <ChatMessage>[
      ChatMessage.system(systemPrompt),
    ];

    // Add last 10 messages for context
    final recentMessages = state.messages.reversed.take(10).toList().reversed;
    for (final msg in recentMessages) {
      if (msg.role == 'user') {
        history.add(ChatMessage.user(msg.content));
      } else if (msg.role == 'assistant' && !msg.isError) {
        history.add(ChatMessage.assistant(msg.content));
      }
    }

    return history;
  }

  /// Clear chat history
  void clearChat() {
    _initialize();
  }

  /// Delete a message
  void deleteMessage(String id) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != id).toList(),
    );
  }
}