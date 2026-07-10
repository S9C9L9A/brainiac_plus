import '../models/agent_task.dart';

/// Analyzes code snippets for quality issues (smells, secrets, async safety).
class CodeReviewAgent {
  static const String id = 'code_review';
  static const _warningPatterns = [
    'print(',
    'debugPrint(',
    'TODO:',
    'FIXME:',
    'catch (e) {}',
    'catch (_) {}',
    '// ignore:',
    'dynamic ',
  ];
  static const _errorPatterns = [
    'password',
    'secret',
    'api_key',
    'apiKey',
    'token =',
    'TOKEN =',
  ];
  AgentTask evaluate(AgentTask task) {
    final code = task.codeSnippet;
    if (code == null || code.isEmpty) return task;
    final newFindings = <AgentFinding>[...task.findings];
    final lines = code.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final p in _errorPatterns) {
        if (line.toLowerCase().contains(p.toLowerCase())) {
          newFindings.add(
            AgentFinding(
              agentId: id,
              severity: FindingSeverity.error,
              message: 'Potential secret detected: "$p"',
              line: i + 1,
            ),
          );
        }
      }
      for (final p in _warningPatterns) {
        if (line.contains(p)) {
          newFindings.add(
            AgentFinding(
              agentId: id,
              severity: FindingSeverity.warning,
              message: 'Code smell: "$p"',
              line: i + 1,
            ),
          );
        }
      }
    }
    if (!code.contains('try') && code.contains('await ')) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.warning,
          message:
              'Async code without try/catch — unhandled exceptions possible.',
        ),
      );
    }
    if (code.contains('setState(') && code.contains('Provider')) {
      newFindings.add(
        AgentFinding(
          agentId: id,
          severity: FindingSeverity.warning,
          message:
              'Mixing setState with Provider/Riverpod — prefer one state approach.',
        ),
      );
    }
    return task.copyWith(findings: newFindings);
  }
}
