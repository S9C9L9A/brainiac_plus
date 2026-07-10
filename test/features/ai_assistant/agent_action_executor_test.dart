import 'package:brainiac_plus/features/ai_assistant/models/agent_task.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_action_executor.dart';
import 'package:flutter_test/flutter_test.dart';

AgentAction action(String id) => AgentAction(id: id, label: id, domain: 'test');

void main() {
  final executor = AgentActionExecutor();

  group('AgentActionExecutor.routeFor', () {
    // Every navigable action id emitted by ActionAgent and where it leads.
    const expectedRoutes = <String, String>{
      'open_dashboard': '/dashboard',
      'show_cpu': '/cpu-detail',
      'show_ram': '/ram-detail',
      'open_terminal': '/terminal',
      'open_packages': '/packages',
      'open_automation': '/automation',
      'new_task': '/automation/create',
      'new_backup_task': '/automation/create',
      'open_file_manager': '/file-manager',
      'open_settings': '/settings',
      'open_ai_settings': '/settings/ai',
      'open_chat': '/ai-chat',
      'open_instagram': '/automation',
      'open_facebook': '/automation',
    };

    for (final entry in expectedRoutes.entries) {
      test('maps ${entry.key} to ${entry.value}', () {
        expect(executor.routeFor(action(entry.key)), entry.value);
      });
    }

    test('returns null for non-navigation actions', () {
      expect(executor.routeFor(action('refresh_metrics')), isNull);
    });

    test('returns null for unknown action ids', () {
      expect(executor.routeFor(action('does_not_exist')), isNull);
    });
  });

  group('AgentActionExecutor.isNavigable', () {
    test('true for a routed action, false otherwise', () {
      expect(executor.isNavigable(action('open_terminal')), isTrue);
      expect(executor.isNavigable(action('refresh_metrics')), isFalse);
    });
  });
}
