import '../../automation/services/schedule_parser.dart';
import '../models/agent_task.dart';

/// Maps user intents to concrete [AgentAction]s executable within the app.
class ActionAgent {
  static const String id = 'action';
  // Intent keyword → (domain, action-id, label)
  static const _actionMap = <String, List<List<String>>>{
    'dashboard': [
      ['dashboard', 'open_dashboard', 'Open Dashboard'],
      ['dashboard', 'refresh_metrics', 'Refresh System Metrics'],
    ],
    'metrics': [
      ['dashboard', 'refresh_metrics', 'Refresh System Metrics'],
    ],
    'cpu': [
      ['dashboard', 'show_cpu', 'Show CPU Details'],
    ],
    'processore': [
      ['dashboard', 'show_cpu', 'Show CPU Details'],
    ],
    'ram': [
      ['dashboard', 'show_ram', 'Show RAM Details'],
    ],
    'memoria': [
      ['dashboard', 'show_ram', 'Show RAM Details'],
    ],
    'disk': [
      ['dashboard', 'show_disk', 'Show Disk Details'],
    ],
    'disco': [
      ['dashboard', 'show_disk', 'Show Disk Details'],
    ],
    'gpu': [
      ['dashboard', 'show_gpu', 'Show GPU Metrics'],
    ],
    'terminal': [
      ['terminal', 'open_terminal', 'Open Terminal'],
    ],
    'shell': [
      ['terminal', 'open_terminal', 'Open Terminal'],
    ],
    'install': [
      ['packages', 'open_packages', 'Open Package Manager'],
    ],
    'package': [
      ['packages', 'open_packages', 'Open Package Manager'],
    ],
    'apt': [
      ['packages', 'open_packages', 'Open Package Manager'],
    ],
    'pacchett': [
      ['packages', 'open_packages', 'Open Package Manager'],
    ],
    'automation': [
      ['automation', 'open_automation', 'Open Automation Manager'],
      ['automation', 'new_task', 'Create New Automation Task'],
    ],
    'automazion': [
      ['automation', 'open_automation', 'Open Automation Manager'],
      ['automation', 'new_task', 'Create New Automation Task'],
    ],
    'schedule': [
      ['automation', 'new_task', 'Create New Automation Task'],
    ],
    'pianifica': [
      ['automation', 'new_task', 'Create New Automation Task'],
    ],
    'file': [
      ['file_manager', 'open_file_manager', 'Open File Manager'],
    ],
    'folder': [
      ['file_manager', 'open_file_manager', 'Open File Manager'],
    ],
    'cartella': [
      ['file_manager', 'open_file_manager', 'Open File Manager'],
    ],
    'settings': [
      ['settings', 'open_settings', 'Open Settings'],
    ],
    'impostazion': [
      ['settings', 'open_settings', 'Open Settings'],
    ],
    'ollama': [
      ['settings', 'open_ai_settings', 'Configure Ollama Settings'],
    ],
    'ai': [
      ['ai_assistant', 'open_chat', 'Open AI Assistant Chat'],
    ],
    'chat': [
      ['ai_assistant', 'open_chat', 'Open AI Assistant Chat'],
    ],
    'backup': [
      ['automation', 'new_backup_task', 'Create Backup Automation'],
    ],
    'instagram': [
      ['automation', 'open_instagram', 'Open Instagram Automation'],
    ],
    'facebook': [
      ['automation', 'open_facebook', 'Open Facebook Automation'],
    ],
  };

  /// Whether [key] occurs in [input] as a word (or word stem).
  ///
  /// Keys of up to 3 characters must match a whole word ('ai' must not fire
  /// on Italian 'hai'/'mai'); longer keys match as prefixes at a word start,
  /// so 'terminal' also covers Italian 'terminale' and 'install' covers
  /// 'installa' — but 'file' no longer fires inside 'profile'.
  static bool _matches(String input, String key) {
    final escaped = RegExp.escape(key);
    final pattern = key.length <= 3 ? '\\b$escaped\\b' : '\\b$escaped';
    return RegExp(pattern).hasMatch(input);
  }

  AgentTask evaluate(AgentTask task) {
    final lower = task.userInput.toLowerCase();
    final actions = <AgentAction>[];
    final seen = <String>{};
    final newFindings = <AgentFinding>[...task.findings];
    // A schedule phrased in the request ("ogni giorno alle 9") becomes a
    // cron param on scheduling actions, so the create screen can prefill it.
    final cron = ScheduleParser().tryParse(task.userInput);
    const schedulingActions = {'new_task', 'new_backup_task'};

    for (final entry in _actionMap.entries) {
      if (_matches(lower, entry.key)) {
        for (final actionDef in entry.value) {
          final actionId = actionDef[1];
          if (seen.add(actionId)) {
            actions.add(
              AgentAction(
                id: actionId,
                label: actionDef[2],
                domain: actionDef[0],
                params: cron != null && schedulingActions.contains(actionId)
                    ? {'cron': cron}
                    : const {},
              ),
            );
          }
        }
      }
    }
    if (actions.isNotEmpty) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.info,
          message:
              'Suggested ${actions.length} action(s): ${actions.map((a) => a.label).join(', ')}.',
        ),
      );
    }
    return task.copyWith(
      findings: newFindings,
      suggestedActions: [...task.suggestedActions, ...actions],
    );
  }
}
