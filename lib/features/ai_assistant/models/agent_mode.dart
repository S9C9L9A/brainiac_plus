import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How autonomous the assistant is, à la Claude Code:
///
/// - [chat]  — talks only; never touches files or runs commands.
/// - [plan]  — reads the project and proposes changes, but every write/run is
///             *simulated* (read-only); nothing on disk changes.
/// - [agent] — executes: writes files and runs commands (CommandGuard still
///             blocks destructive commands).
enum AgentMode { chat, plan, agent }

extension AgentModeMeta on AgentMode {
  String get label => switch (this) {
    AgentMode.chat => 'Chat',
    AgentMode.plan => 'Plan',
    AgentMode.agent => 'Agent',
  };

  /// True when the assistant should only propose, not modify anything.
  bool get isReadOnly => this == AgentMode.plan;

  /// True when a message should run the agentic tool loop (plan or agent);
  /// chat mode replies without executing.
  bool get executesTools => this != AgentMode.chat;
}

/// The active assistant mode — set from the chat header, read by the agent
/// runner/executor (so the mode gates real execution, not just the UI).
final agentModeProvider = StateProvider<AgentMode>((ref) => AgentMode.agent);
