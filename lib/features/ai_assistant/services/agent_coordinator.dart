import '../models/agent_task.dart';
import 'code_review_agent.dart';
import 'test_agent.dart';
import 'safety_agent.dart';
import 'action_agent.dart';

/// Coordinates the multi-agent verification pipeline.
///
/// Pipeline order:
///   1. [SafetyAgent]      — block dangerous ops immediately
///   2. [CodeReviewAgent]  — code quality / secrets
///   3. [TestAgent]        — test coverage recommendations
///   4. [ActionAgent]      — map intent to app actions
///   5. Coordinator        — aggregate verdict + summary
class AgentCoordinator {
  final SafetyAgent _safety;
  final CodeReviewAgent _codeReview;
  final TestAgent _test;
  final ActionAgent _action;
  AgentCoordinator({
    SafetyAgent? safety,
    CodeReviewAgent? codeReview,
    TestAgent? test,
    ActionAgent? action,
  }) : _safety = safety ?? SafetyAgent(),
       _codeReview = codeReview ?? CodeReviewAgent(),
       _test = test ?? TestAgent(),
       _action = action ?? ActionAgent();

  /// Run the full pipeline and return the finalized [AgentTask].
  AgentTask run(AgentTask task) {
    var current = task;
    // Stage 1 — Safety (run first, may set blocked verdict)
    current = _safety.evaluate(current);
    // Stage 2 — Code Review
    current = _codeReview.evaluate(current);
    // Stage 3 — Test recommendations
    current = _test.evaluate(current);
    // Stage 4 — Action suggestions
    current = _action.evaluate(current);
    // Stage 5 — Coordinator verdict + summary
    return _finalize(current);
  }

  AgentTask _finalize(AgentTask task) {
    final errors = task.findings
        .where((f) => f.severity == FindingSeverity.error)
        .toList();
    final warnings = task.findings
        .where((f) => f.severity == FindingSeverity.warning)
        .toList();
    final AgentVerdict verdict;
    if (errors.isNotEmpty) {
      verdict = AgentVerdict.blocked;
    } else if (warnings.isNotEmpty) {
      verdict = AgentVerdict.warning;
    } else {
      verdict = AgentVerdict.ok;
    }
    final summary = _buildSummary(task, verdict, errors, warnings);
    return task.copyWith(verdict: verdict, summary: summary);
  }

  String _buildSummary(
    AgentTask task,
    AgentVerdict verdict,
    List<AgentFinding> errors,
    List<AgentFinding> warnings,
  ) {
    final buf = StringBuffer();
    final icon = switch (verdict) {
      AgentVerdict.ok => '✅',
      AgentVerdict.warning => '⚠️',
      AgentVerdict.blocked => '🚫',
    };
    final label = switch (verdict) {
      AgentVerdict.ok => 'All checks passed',
      AgentVerdict.warning =>
        '${warnings.length} warning(s) — review before proceeding',
      AgentVerdict.blocked => '${errors.length} blocker(s) — action required',
    };
    buf.writeln('$icon **Agent Pipeline Report** — $label');
    buf.writeln();
    if (errors.isNotEmpty) {
      buf.writeln('**Blockers (${errors.length}):**');
      for (final e in errors) {
        buf.writeln('• ${e.message}');
      }
      buf.writeln();
    }
    if (warnings.isNotEmpty) {
      buf.writeln('**Warnings (${warnings.length}):**');
      for (final w in warnings) {
        buf.writeln('• ${w.message}');
      }
      buf.writeln();
    }
    final infos = task.findings
        .where((f) => f.severity == FindingSeverity.info)
        .toList();
    if (infos.isNotEmpty) {
      buf.writeln('**Info (${infos.length}):**');
      for (final i in infos) {
        buf.writeln('• ${i.message}');
      }
      buf.writeln();
    }
    if (task.suggestedActions.isNotEmpty) {
      buf.writeln('**Suggested Actions:**');
      for (final a in task.suggestedActions) {
        buf.writeln('• [${a.domain}] ${a.label}');
      }
    }
    return buf.toString().trim();
  }
}
