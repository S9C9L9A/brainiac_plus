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
