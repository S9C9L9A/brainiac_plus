import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_message.dart';
import '../../../core/services/ollama_service.dart';

/// Provider for Ollama service
final ollamaServiceProvider = Provider<OllamaService>((ref) {
  return OllamaService();
});

/// Provider for AI chat controller
final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
  return AiChatController(ref.watch(ollamaServiceProvider));
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

  AiChatController(this._ollamaService) : super(AiChatState()) {
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

    // Add user message
    final userMsg = userMessage(content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // Build conversation history for context
      final chatMessages = _buildChatHistory();

      // Get AI response
      final response = await _ollamaService.chat(chatMessages);

      // Parse response for code snippets
      final parsedResponse = _parseResponse(response);

      // Add assistant message
      final assistantMsg = assistantMessage(
        parsedResponse['content'] as String,
        codeSnippet: parsedResponse['codeSnippet'] as String?,
        filesPaths: parsedResponse['files'] as List<String>?,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = errorMessage('Failed to get response: $e');
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

    // Add user message
    final userMsg = userMessage(content);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      // Build conversation history
      final chatMessages = _buildChatHistory();

      // Create placeholder for streaming response
      final streamMsgId = DateTime.now().millisecondsSinceEpoch.toString();
      var streamContent = '';

      // Stream AI response
      await for (final chunk in _ollamaService.chatStream(chatMessages)) {
        streamContent += chunk;

        // Update message with accumulated content
        final updatedMsg = AiMessage(
          id: streamMsgId,
          role: 'assistant',
          content: streamContent,
          timestamp: DateTime.now(),
        );

        // Replace last message if it's the stream message, otherwise add
        final messages = state.messages.where((m) => m.id != streamMsgId).toList();
        messages.add(updatedMsg);

        state = state.copyWith(messages: messages);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      final errorMsg = errorMessage('Failed to stream response: $e');
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Build chat history for Ollama API
  List<ChatMessage> _buildChatHistory() {
    final history = <ChatMessage>[
      ChatMessage.system(_getSystemPrompt()),
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

  /// System prompt for code generation
  String _getSystemPrompt() {
    return '''You are an AI assistant for BrainiacPlus, a Flutter system monitoring app.

CAPABILITIES:
- Generate Dart/Flutter code for new features
- Debug and fix existing code
- Suggest optimizations and improvements
- Create automation tasks

RULES:
1. Always output VALID Dart code
2. Use Riverpod for state management
3. Use Lucide icons from app_icons.dart
4. Match the glassmorphism theme
5. Follow Flutter best practices
6. Be concise and clear

RESPONSE FORMAT:
- Short explanation first
- Code blocks with ```dart
- List affected files if multiple
- Explain what the code does

AVAILABLE FEATURES:
- Dashboard (system metrics)
- Terminal (command execution)
- File Manager (file operations)
- Packages (apt/snap management)
- Automation (scheduled tasks)

Be helpful and generate production-ready code!''';
  }

  /// Parse response for code snippets and file paths
  Map<String, dynamic> _parseResponse(String response) {
    String content = response;
    String? codeSnippet;
    List<String>? files;

    // Extract code blocks
    final codeRegex = RegExp(r'```dart\n([\s\S]*?)```');
    final codeMatch = codeRegex.firstMatch(response);
    if (codeMatch != null) {
      codeSnippet = codeMatch.group(1)?.trim();
      // Remove code block from content
      content = response.replaceFirst(codeRegex, '[Code snippet attached]');
    }

    // Extract file paths (lib/...)
    final fileRegex = RegExp(r'lib/[\w/]+\.dart');
    final fileMatches = fileRegex.allMatches(response);
    if (fileMatches.isNotEmpty) {
      files = fileMatches.map((m) => m.group(0)!).toList();
    }

    return {
      'content': content,
      'codeSnippet': codeSnippet,
      'files': files,
    };
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
