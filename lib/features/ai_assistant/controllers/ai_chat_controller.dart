import 'dart:io';
import 'dart:math' show min;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_message.dart';
import '../models/agent_task.dart';
import '../../../core/services/ollama_service.dart';
import '../../../core/platform/shell_service.dart';
import '../services/agent_tool_executor.dart';
import '../../activity/controllers/activity_log_controller.dart';
import '../../activity/models/activity_entry.dart';
import '../../settings/providers/extended_settings_provider.dart';
import '../services/agent_registry.dart';
import '../services/agent_coordinator.dart';
import '../services/ai_guardrails_service.dart';
import '../services/ai_orchestrator_service.dart';
import '../services/agent_response_parser.dart';
import '../services/agentic_runner.dart';

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
    coordinator: AgentCoordinator(),
  );
});

/// Builds the agentic runner backing autonomous task execution: the local
/// LLM as the planner, real file/shell tools scoped to the project workspace.
final agentRunnerProvider = Provider<AgenticRunner>((ref) {
  final ollama = ref.watch(ollamaServiceProvider);
  final shell = ShellService();
  return AgenticRunner(
    chat: (turns) => ollama.chat([
      for (final t in turns)
        if (t.role == 'system')
          ChatMessage.system(t.content)
        else if (t.role == 'assistant')
          ChatMessage.assistant(t.content)
        else
          ChatMessage.user(t.content),
    ]),
    executor: AgentToolExecutor(
      workspaceRoot: Directory.current.path,
      runCommand: shell.executeSync,
    ),
  );
});

/// Provider for AI chat controller
final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
      return AiChatController(
        ref.watch(ollamaServiceProvider),
        ref.watch(aiOrchestratorProvider),
        ref.watch(agentResponseParserProvider),
        onActivity: (entry) =>
            ref.read(activityLogProvider.notifier).log(entry),
        agentRunner: ref.watch(agentRunnerProvider),
      );
    });

/// AI Chat State
class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  /// Result of the latest multi-agent pipeline run (null before first message)
  final AgentTask? lastPipelineResult;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastPipelineResult,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
    AgentTask? lastPipelineResult,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastPipelineResult: lastPipelineResult ?? this.lastPipelineResult,
    );
  }
}

/// AI Chat Controller
class AiChatController extends StateNotifier<AiChatState> {
  final OllamaService _ollamaService;
  final AiOrchestratorService _orchestrator;
  final AgentResponseParser _responseParser;

  /// Reports user queries to the app-wide activity log.
  final void Function(ActivityEntry entry)? onActivity;

  /// Agentic loop: when present, [sendAgentTask] lets the assistant actually
  /// carry out multi-step work (write files, run commands) instead of only
  /// replying with text.
  final AgenticRunner? agentRunner;

  AiChatController(
    this._ollamaService,
    this._orchestrator,
    this._responseParser, {
    this.onActivity,
    this.agentRunner,
  }) : super(AiChatState()) {
    _initialize();
  }

  /// Whether the assistant can execute tasks, not just chat about them.
  bool get agentEnabled => agentRunner != null;

  /// Runs [content] as an autonomous task: the assistant plans, writes files
  /// and runs commands step by step, and each step is posted to the chat so
  /// the user can follow the work as it happens.
  Future<void> sendAgentTask(String content) async {
    if (content.trim().isEmpty) return;
    final runner = agentRunner;
    if (runner == null) {
      // No executor available — fall back to a normal chat turn.
      return sendMessageStream(content);
    }

    final userMsg = userMessage(content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    // The safety pipeline still guards the request before any execution.
    final pipelineResult = _orchestrator.runPipeline(content);
    _logQuery(content, pipelineResult);
    if (pipelineResult.verdict == AgentVerdict.blocked) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          errorMessage(
            '🚫 **Action Blocked by Agent Pipeline**\n\n${pipelineResult.summary}',
          ),
        ],
        isLoading: false,
        lastPipelineResult: pipelineResult,
        error: 'Pipeline blocked',
      );
      return;
    }

    if (!await _ollamaService.isAvailable()) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          errorMessage(
            '❌ Local LLM server not available.\n\n'
            'Start it, then try the task again.',
          ),
        ],
        isLoading: false,
        error: 'Ollama unavailable',
      );
      return;
    }

    try {
      final result = await runner.run(
        content,
        onStep: (step) {
          state = state.copyWith(
            messages: [...state.messages, _stepMessage(step)],
          );
        },
      );

      final status = result.completed
          ? '✅ **Task complete**${result.summary != null ? ' — ${result.summary}' : ''}'
          : '⚠️ **Stopped after ${result.iterations} steps** — the task may be unfinished.';
      state = state.copyWith(
        messages: [
          ...state.messages,
          assistantMessage(status, agentId: 'coordinator', intent: 'action'),
        ],
        isLoading: false,
        lastPipelineResult: pipelineResult,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [...state.messages, errorMessage('⚠️ Agent task failed: $e')],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Renders one agent step (the model's prose plus its tool outcomes) as a
  /// single chat message.
  AiMessage _stepMessage(AgentStep step) {
    final buf = StringBuffer();
    final prose = step.assistantText
        .replaceAll(RegExp(r'```tool[\s\S]*?```'), '')
        .trim();
    if (prose.isNotEmpty) buf.writeln(prose);
    for (final r in step.results) {
      final icon = r.ok ? '✓' : '✗';
      final tool = r.call.tool.name;
      buf.writeln('\n`$icon $tool` ${r.output}');
    }
    return assistantMessage(
      buf.toString().trim(),
      agentId: 'action',
      intent: 'action',
    );
  }

  /// Logs the query as soon as the pipeline has judged it — blocked
  /// attempts are part of the audit trail too.
  void _logQuery(String content, AgentTask pipelineResult) {
    onActivity?.call(
      ActivityEntry(
        type: ActivityType.ai,
        title: pipelineResult.verdict == AgentVerdict.blocked
            ? 'AI query blocked'
            : 'AI query',
        description: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _initialize() {
    // Add system message
    final systemMsg = AiMessage(
      id: 'system',
      role: 'assistant',
      content:
          '👋 Hi! I\'m BrainiacPlus AI Assistant. I can help you add features, fix bugs, or automate tasks. What would you like to build today?',
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

    // ── Multi-agent pipeline ─────────────────────────────────────────────
    final pipelineResult = _orchestrator.runPipeline(content);
    _logQuery(content, pipelineResult);
    if (pipelineResult.verdict == AgentVerdict.blocked) {
      final blockedMsg = errorMessage(
        '🚫 **Action Blocked by Agent Pipeline**\n\n${pipelineResult.summary}',
      );
      state = state.copyWith(
        messages: [...state.messages, blockedMsg],
        isLoading: false,
        lastPipelineResult: pipelineResult,
        error: 'Pipeline blocked',
      );
      return;
    }
    // ─────────────────────────────────────────────────────────────────────

    try {
      final isAvailable = await _ollamaService.isAvailable();
      if (!isAvailable) {
        final errorMsg = errorMessage(
          '❌ Local LLM server not available.\n\n'
          'Please ensure:\n'
          '1. The local LLM server is running\n'
          '2. The endpoint is correct (default: http://localhost:8080)\n'
          '3. Check your network connection\n\n'
          'Start it with: ./scripts/local-llm.sh start',
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isLoading: false,
          lastPipelineResult: pipelineResult,
          error: 'Ollama unavailable',
        );
        return;
      }

      final decision = _orchestrator.route(content);
      final chatMessages = _buildChatHistory(decision.systemPrompt);
      final response = await _ollamaService.chat(chatMessages);
      final assistantMsg = _buildAssistantMessage(decision, response);

      final msgs = [...state.messages];
      if (pipelineResult.verdict == AgentVerdict.warning) {
        msgs.add(
          assistantMessage(
            '⚠️ **Pipeline Warnings**\n\n${pipelineResult.summary}',
            agentId: 'coordinator',
            intent: 'review',
          ),
        );
      }
      msgs.add(assistantMsg);

      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        lastPipelineResult: pipelineResult,
      );
    } catch (e) {
      final errorMsg = errorMessage(
        '⚠️ Error: ${e.toString()}\n\n'
        'Troubleshooting:\n'
        '• Verify the local LLM server is running: ./scripts/local-llm.sh start\n'
        '• Check endpoint: http://localhost:8080\n'
        '• Try again in a moment',
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        lastPipelineResult: pipelineResult,
        error: e.toString(),
      );
    }
  }

  /// Send a message with streaming response
  Future<void> sendMessageStream(String content) async {
    if (content.trim().isEmpty) return;

    // ── Multi-agent pipeline ─────────────────────────────────────────────
    final pipelineResult = _orchestrator.runPipeline(content);
    _logQuery(content, pipelineResult);
    if (pipelineResult.verdict == AgentVerdict.blocked) {
      final userMsg = userMessage(content);
      final blockedMsg = errorMessage(
        '🚫 **Action Blocked by Agent Pipeline**\n\n${pipelineResult.summary}',
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, blockedMsg],
        isLoading: false,
        lastPipelineResult: pipelineResult,
        error: 'Pipeline blocked',
      );
      return;
    }
    // ─────────────────────────────────────────────────────────────────────

    final isAvailable = await _ollamaService.isAvailable();
    if (!isAvailable) {
      final userMsg = userMessage(content);
      final errorMsg = errorMessage(
        '❌ Local LLM Server Unavailable\n\n'
        'The AI assistant requires the local LLM server to be running.\n\n'
        'To start it:\n'
        '1. Open a terminal\n'
        '2. Run: ./scripts/local-llm.sh start\n'
        '3. Ensure it\'s accessible at: http://localhost:8080\n\n'
        'Then try your message again.',
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, errorMsg],
        isLoading: false,
        lastPipelineResult: pipelineResult,
        error: 'Ollama unavailable',
      );
      return;
    }

    final decision = _orchestrator.route(content);
    final userMsg = userMessage(content);

    // Inject pipeline warning message before streaming starts
    final preMessages = [...state.messages, userMsg];
    if (pipelineResult.verdict == AgentVerdict.warning) {
      preMessages.add(
        assistantMessage(
          '⚠️ **Pipeline Warnings**\n\n${pipelineResult.summary}',
          agentId: 'coordinator',
          intent: 'review',
        ),
      );
    }

    state = state.copyWith(
      messages: preMessages,
      isLoading: true,
      lastPipelineResult: pipelineResult,
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

        final messages = state.messages
            .where((m) => m.id != streamMsgId)
            .toList();
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

      final messages = state.messages
          .where((m) => m.id != streamMsgId)
          .toList();
      messages.add(finalizedMsg);

      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
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

          final messages = state.messages
              .where((m) => m.id != streamMsgId)
              .toList();
          messages.add(fallbackMsg);

          state = state.copyWith(messages: messages, isLoading: false);
          return;
        } catch (fallbackError) {
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
    final history = <ChatMessage>[ChatMessage.system(systemPrompt)];

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
