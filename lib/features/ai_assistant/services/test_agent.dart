import '../models/agent_task.dart';

/// Generates test recommendations based on the code under review.
class TestAgent {
  static const String id = 'test';
  static const _criticalPatterns = [
    'auth',
    'login',
    'jwt',
    'oauth',
    'password',
    'token',
    'payment',
    'database',
    'sqlite',
  ];
  AgentTask evaluate(AgentTask task) {
    final code = task.codeSnippet;
    final newFindings = <AgentFinding>[...task.findings];
    if (code == null || code.isEmpty) {
      if (task.intent == 'feature' || task.intent == 'bugfix') {
        newFindings.add(
          AgentFinding(
            agentId: id,
            severity: FindingSeverity.info,
            message:
                'No code snippet found — remember to add tests for any new or changed logic.',
          ),
        );
      }
      return task.copyWith(findings: newFindings);
    }
    final lower = code.toLowerCase();
    // Check if this is critical code that needs >= 90% coverage
    final isCritical = _criticalPatterns.any((p) => lower.contains(p));
    if (isCritical) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.warning,
          message:
              'Critical code area detected (auth/DB/payments) — target ≥90% test coverage per CLAUDE.md §12.',
        ),
      );
    }
    // Check if public methods lack tests
    final publicMethods = RegExp(
      r'^\s{0,4}(?:Future<|Stream<|void|String|bool|int|List|Map)\s+\w+\(',
      multiLine: true,
    ).allMatches(code).length;
    if (publicMethods > 2) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.info,
          message:
              'Found ~$publicMethods public methods — ensure each has a corresponding unit test.',
        ),
      );
    }
    // Check async functions
    if (lower.contains('future<') || lower.contains('async ')) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.info,
          message:
              'Async code detected — add tests for success, timeout, and error paths.',
        ),
      );
    }
    // Check stream usage
    if (lower.contains('stream<') || lower.contains('streamcontroller')) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.info,
          message:
              'Stream detected — test emission order, errors, and close events.',
        ),
      );
    }
    return task.copyWith(findings: newFindings);
  }
}
