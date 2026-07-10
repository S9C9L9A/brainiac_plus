import '../models/agent_profile.dart';
import '../models/agent_task.dart';
import '../services/agent_registry.dart';
import 'ai_guardrails_service.dart';
import 'agent_coordinator.dart';

class RoutingDecision {
  final AgentProfile agent;
  final String systemPrompt;
  final String intent;
  final String reason;

  const RoutingDecision({
    required this.agent,
    required this.systemPrompt,
    required this.intent,
    required this.reason,
  });
}

class AiOrchestratorService {
  final AgentRegistry registry;
  final AiGuardrailsService guardrails;
  final AgentCoordinator coordinator;

  AiOrchestratorService({
    required this.registry,
    required this.guardrails,
    AgentCoordinator? coordinator,
  }) : coordinator = coordinator ?? AgentCoordinator();

  /// Route user message to a domain agent and return routing info.
  RoutingDecision route(String userContent) {
    final agent = registry.findBestAgent(userContent);
    final intent = _inferIntent(userContent);
    final reason = 'Matched agent by keywords or default.';

    return RoutingDecision(
      agent: agent,
      intent: intent,
      reason: reason,
      systemPrompt: _buildSystemPrompt(agent),
    );
  }

  /// Run the full multi-agent pipeline on user input,
  /// returning a finalized [AgentTask] with verdict + summary.
  AgentTask runPipeline(
    String userContent, {
    String? codeSnippet,
    List<String>? referencedFiles,
  }) {
    final intent = _inferIntent(userContent);
    final task = AgentTask(
      userInput: userContent,
      intent: intent,
      codeSnippet: codeSnippet,
      referencedFiles: referencedFiles ?? [],
    );
    return coordinator.run(task);
  }

  List<String>? sanitizePaths(RoutingDecision decision, List<String>? paths) {
    return guardrails.filterFilePaths(decision.agent, paths);
  }

  /// Intent → keyword stems (Italian + English), in priority order: bug
  /// wording beats review wording, review beats test, and so on. Multi-word
  /// entries match as phrases.
  static const _intentPatterns = <String, List<String>>{
    'bugfix': [
      'fix',
      'bug',
      'error',
      'errore',
      'correggi',
      'aggiusta',
      'crash',
      'non funziona',
      'broken',
      'rotto',
    ],
    'refactor': [
      'refactor',
      'cleanup',
      'rifattorizza',
      'riscrivi',
      'semplifica',
      'pulisci',
    ],
    'review': ['review', 'verifica', 'analizza', 'controlla', 'ispeziona'],
    'test': ['test', 'coverage', 'copertura'],
    'action': [
      'apri',
      'open',
      'esegui',
      'run',
      'launch',
      'avvia',
      'mostra',
      'show',
    ],
    'feature': [
      'aggiungi',
      'add',
      'crea',
      'create',
      'build',
      'implementa',
      'implement',
      'nuova',
      'nuovo',
      'new',
    ],
  };

  /// Same word-boundary semantics as ActionAgent: short keys must be whole
  /// words, longer keys match as word-start stems, phrases as substrings.
  static bool _matchesKeyword(String input, String key) {
    if (key.contains(' ')) return input.contains(key);
    final escaped = RegExp.escape(key);
    final pattern = key.length <= 3 ? '\\b$escaped\\b' : '\\b$escaped';
    return RegExp(pattern).hasMatch(input);
  }

  String _inferIntent(String content) {
    final lower = content.toLowerCase();
    for (final entry in _intentPatterns.entries) {
      if (entry.value.any((key) => _matchesKeyword(lower, key))) {
        return entry.key;
      }
    }
    // Small talk, questions, anything unclassified: let downstream agents
    // skip code-oriented recommendations instead of assuming 'feature'.
    return 'unknown';
  }

  String _buildSystemPrompt(AgentProfile agent) {
    return '''You are the BrainiacPlus Main Agent.

AGENT: ${agent.name}
DOMAIN: ${agent.domainPaths.join(', ')}

ROLE:
${agent.systemPrompt}

RULES:
1. Prefer editing files only in the agent domain.
2. Return concise explanations.
3. If code is included, use Dart code blocks.
4. List affected files using paths like lib/feature/file.dart.
5. Avoid changes to blocked paths.

OUTPUT FORMAT:
- Short explanation
- Optional ```dart code``` blocks
- Optional "Affected files" list
''';
  }
}
