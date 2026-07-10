/// Severity of an agent finding
enum FindingSeverity { info, warning, error }

/// Overall verdict of the multi-agent pipeline
enum AgentVerdict { ok, warning, blocked }

/// A single finding produced by an agent
class AgentFinding {
  final String agentId;
  final FindingSeverity severity;
  final String message;
  final String? file;
  final int? line;

  const AgentFinding({
    required this.agentId,
    required this.severity,
    required this.message,
    this.file,
    this.line,
  });

  @override
  String toString() {
    final loc = file != null ? ' [$file${line != null ? ':$line' : ''}]' : '';
    final tag = severity.name.toUpperCase();
    return '[$tag]$loc $message';
  }
}

/// A suggested action that the Action Agent can execute
class AgentAction {
  final String id;
  final String label;
  final String domain; // e.g. 'terminal', 'automation', 'file_manager'
  final Map<String, dynamic> params;

  const AgentAction({
    required this.id,
    required this.label,
    required this.domain,
    this.params = const {},
  });
}

/// Shared task object that flows through the agent pipeline
class AgentTask {
  /// Original user input
  final String userInput;

  /// Inferred intent (feature / bugfix / refactor / review / test / action / unknown)
  final String intent;

  /// Code snippet extracted from user message (if any)
  final String? codeSnippet;

  /// File paths mentioned in user message (if any)
  final List<String> referencedFiles;

  /// Accumulated findings from all agents
  final List<AgentFinding> findings;

  /// Suggested actions from Action Agent
  final List<AgentAction> suggestedActions;

  /// Final verdict set by Coordinator
  final AgentVerdict verdict;

  /// Human-readable summary built by Coordinator
  final String summary;

  const AgentTask({
    required this.userInput,
    required this.intent,
    this.codeSnippet,
    this.referencedFiles = const [],
    this.findings = const [],
    this.suggestedActions = const [],
    this.verdict = AgentVerdict.ok,
    this.summary = '',
  });

  AgentTask copyWith({
    String? userInput,
    String? intent,
    String? codeSnippet,
    List<String>? referencedFiles,
    List<AgentFinding>? findings,
    List<AgentAction>? suggestedActions,
    AgentVerdict? verdict,
    String? summary,
  }) {
    return AgentTask(
      userInput: userInput ?? this.userInput,
      intent: intent ?? this.intent,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      referencedFiles: referencedFiles ?? this.referencedFiles,
      findings: findings ?? this.findings,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      verdict: verdict ?? this.verdict,
      summary: summary ?? this.summary,
    );
  }

  /// Worst severity of all findings
  FindingSeverity get worstSeverity {
    if (findings.any((f) => f.severity == FindingSeverity.error)) {
      return FindingSeverity.error;
    }
    if (findings.any((f) => f.severity == FindingSeverity.warning)) {
      return FindingSeverity.warning;
    }
    return FindingSeverity.info;
  }

  /// All findings from a specific agent
  List<AgentFinding> findingsBy(String agentId) =>
      findings.where((f) => f.agentId == agentId).toList();
}
