import 'package:brainiac_plus/features/ai_assistant/services/agent_registry.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_guardrails_service.dart';
import 'package:brainiac_plus/features/ai_assistant/services/ai_orchestrator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes package requests to packages agent', () {
    final registry = AgentRegistry();
    final guardrails = AiGuardrailsService();
    final orchestrator = AiOrchestratorService(
      registry: registry,
      guardrails: guardrails,
    );

    final decision = orchestrator.route('Please install a package with apt');
    expect(decision.agent.id, 'packages');
  });

  test('filters file paths outside agent allowlist', () {
    final registry = AgentRegistry();
    final guardrails = AiGuardrailsService();
    final orchestrator = AiOrchestratorService(
      registry: registry,
      guardrails: guardrails,
    );

    final decision = orchestrator.route('Update dashboard metrics');
    final paths = [
      'lib/features/dashboard/widgets/metric_card.dart',
      'lib/core/theme/app_theme.dart',
    ];

    final sanitized = orchestrator.sanitizePaths(decision, paths);
    expect(sanitized, ['lib/features/dashboard/widgets/metric_card.dart']);
  });
}
