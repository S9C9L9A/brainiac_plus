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

  group('intent inference (Italian + English)', () {
    final orchestrator = AiOrchestratorService(
      registry: AgentRegistry(),
      guardrails: AiGuardrailsService(),
    );

    String intentOf(String message) => orchestrator.route(message).intent;

    test('recognizes bugfix requests', () {
      expect(intentOf('fix the login error'), 'bugfix');
      expect(intentOf('correggi il bug nel terminale'), 'bugfix');
      expect(intentOf('la dashboard non funziona'), 'bugfix');
    });

    test('recognizes refactor requests', () {
      expect(intentOf('refactor this widget'), 'refactor');
      expect(intentOf('rifattorizza il controller'), 'refactor');
      expect(intentOf('semplifica questa classe'), 'refactor');
    });

    test('recognizes review requests', () {
      expect(intentOf('review this diff'), 'review');
      expect(intentOf('verifica questo codice'), 'review');
      expect(intentOf('analizza la qualità del modulo'), 'review');
    });

    test('recognizes test requests', () {
      expect(intentOf('add tests for the service'), 'test');
      expect(intentOf('aggiungi la copertura per il parser'), 'test');
    });

    test('recognizes action requests', () {
      expect(intentOf('apri il terminale'), 'action');
      expect(intentOf('open the dashboard'), 'action');
      expect(intentOf('mostra le metriche'), 'action');
    });

    test('small talk and questions fall back to unknown', () {
      expect(intentOf('ciao, come stai?'), 'unknown');
      expect(intentOf('what do you think about Flutter?'), 'unknown');
    });

    test('build requests default to feature', () {
      expect(intentOf('aggiungi una schermata di export'), 'feature');
      expect(intentOf('build a new onboarding step'), 'feature');
    });

    test('bug wording wins over review wording', () {
      expect(intentOf('verifica perché va in errore'), 'bugfix');
    });
  });
}
