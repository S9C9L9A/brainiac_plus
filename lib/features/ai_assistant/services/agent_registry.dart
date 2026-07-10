import '../models/agent_profile.dart';

class AgentRegistry {
  final List<AgentProfile> _agents = [
    const AgentProfile(
      id: 'dashboard',
      name: 'Dashboard Agent',
      description: 'System metrics and dashboard UI.',
      domainPaths: ['lib/features/dashboard/'],
      allowedPaths: ['lib/features/dashboard/'],
      keywords: ['dashboard', 'metrics', 'cpu', 'ram', 'disk', 'network'],
      systemPrompt: 'You are the Dashboard Agent. Focus on metrics, charts, and dashboard widgets.',
    ),
    const AgentProfile(
      id: 'terminal',
      name: 'Terminal Agent',
      description: 'Shell execution and terminal UI.',
      domainPaths: ['lib/features/terminal/'],
      allowedPaths: ['lib/features/terminal/'],
      keywords: ['terminal', 'shell', 'command', 'ansi', 'output', 'cli'],
      systemPrompt: 'You are the Terminal Agent. Focus on terminal UI and shell command flows.',
    ),
    const AgentProfile(
      id: 'packages',
      name: 'Packages Agent',
      description: 'Package management and system installers.',
      domainPaths: ['lib/features/packages/'],
      allowedPaths: ['lib/features/packages/'],
      keywords: ['package', 'apt', 'snap', 'flatpak', 'install', 'upgrade', 'update'],
      systemPrompt: 'You are the Packages Agent. Focus on package management UI and services.',
    ),
    const AgentProfile(
      id: 'automation',
      name: 'Automation Agent',
      description: 'Automations, schedulers, and workflows.',
      domainPaths: ['lib/features/automation/'],
      allowedPaths: ['lib/features/automation/'],
      keywords: ['automation', 'schedule', 'cron', 'workflow', 'task', 'trigger'],
      systemPrompt: 'You are the Automation Agent. Focus on automation flows and scheduling.',
    ),
    const AgentProfile(
      id: 'file_manager',
      name: 'File Manager Agent',
      description: 'File browsing and file operations.',
      domainPaths: ['lib/features/file_manager/'],
      allowedPaths: ['lib/features/file_manager/'],
      keywords: ['file manager', 'files', 'folders', 'browse', 'upload', 'download'],
      systemPrompt: 'You are the File Manager Agent. Focus on file browsing and operations.',
    ),
    const AgentProfile(
      id: 'ai_assistant',
      name: 'AI Assistant Agent',
      description: 'AI assistant UI and orchestration.',
      domainPaths: ['lib/features/ai_assistant/'],
      allowedPaths: ['lib/features/ai_assistant/', 'docs/'],
      keywords: ['ai', 'assistant', 'chat', 'ollama', 'orchestrator', 'agent'],
      systemPrompt: 'You are the AI Assistant Agent. Focus on chat UI and orchestration logic.',
    ),
    const AgentProfile(
      id: 'core',
      name: 'Core Agent',
      description: 'Shared services, theme, and platform code.',
      domainPaths: ['lib/core/'],
      allowedPaths: ['lib/core/'],
      keywords: ['theme', 'database', 'sqlite', 'platform', 'settings', 'core'],
      systemPrompt: 'You are the Core Agent. Focus on shared services and platform layers.',
    ),
    // ── Specialized pipeline agents ──────────────────────────────────────
    const AgentProfile(
      id: 'code_review',
      name: 'Code Review Agent',
      description: 'Analyzes code for smells, secrets, and async safety.',
      domainPaths: ['lib/'],
      allowedPaths: ['lib/'],
      keywords: ['review', 'verifica', 'analizza', 'smell', 'bug', 'quality', 'codice'],
      systemPrompt: 'You are the Code Review Agent. Analyze code quality, find smells, secrets, and async issues.',
    ),
    const AgentProfile(
      id: 'test',
      name: 'Test Agent',
      description: 'Generates test recommendations and coverage targets.',
      domainPaths: ['test/'],
      allowedPaths: ['test/', 'lib/'],
      keywords: ['test', 'coverage', 'unit test', 'widget test', 'copertura'],
      systemPrompt: 'You are the Test Agent. Recommend tests and enforce coverage targets.',
    ),
    const AgentProfile(
      id: 'safety',
      name: 'Safety Agent',
      description: 'Blocks dangerous operations and locked file access.',
      domainPaths: [],
      allowedPaths: [],
      keywords: ['delete', 'remove', 'rm', 'force push', 'dangerous', 'pericoloso'],
      systemPrompt: 'You are the Safety Agent. Block dangerous operations and enforce locked-file rules.',
    ),
    const AgentProfile(
      id: 'action',
      name: 'Action Agent',
      description: 'Maps user requests to executable app actions.',
      domainPaths: ['lib/features/'],
      allowedPaths: ['lib/features/'],
      keywords: ['apri', 'esegui', 'open', 'run', 'launch', 'avvia', 'show', 'mostra'],
      systemPrompt: 'You are the Action Agent. Map user requests to concrete app operations.',
    ),
    const AgentProfile(
      id: 'coordinator',
      name: 'Coordinator Agent',
      description: 'Orchestrates the full multi-agent verification pipeline.',
      domainPaths: ['lib/'],
      allowedPaths: ['lib/'],
      keywords: ['pipeline', 'verifica tutto', 'check all', 'coordinatore'],
      systemPrompt: 'You are the Coordinator Agent. Run all specialized agents and aggregate results.',
    ),
  ];

  List<AgentProfile> get agents => List.unmodifiable(_agents);

  AgentProfile get defaultAgent => _agents.firstWhere((a) => a.id == 'ai_assistant');

  AgentProfile findBestAgent(String content) {
    final lower = content.toLowerCase();
    AgentProfile? best;
    var bestScore = 0;

    for (final agent in _agents) {
      var score = 0;
      for (final keyword in agent.keywords) {
        if (lower.contains(keyword)) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = agent;
      }
    }

    return best ?? defaultAgent;
  }
}
