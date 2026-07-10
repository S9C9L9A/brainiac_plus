import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/features/ai_assistant/models/agent_task.dart';
import 'package:brainiac_plus/features/ai_assistant/services/safety_agent.dart';
import 'package:brainiac_plus/features/ai_assistant/services/code_review_agent.dart';
import 'package:brainiac_plus/features/ai_assistant/services/test_agent.dart';
import 'package:brainiac_plus/features/ai_assistant/services/action_agent.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_coordinator.dart';

AgentTask task({
  String userInput = '',
  String intent = 'unknown',
  String? codeSnippet,
  List<String> referencedFiles = const [],
}) => AgentTask(
  userInput: userInput,
  intent: intent,
  codeSnippet: codeSnippet,
  referencedFiles: referencedFiles,
);

bool hasError(AgentTask t) =>
    t.findings.any((f) => f.severity == FindingSeverity.error);

void main() {
  group('AgentTask', () {
    test('copyWith overrides only provided fields', () {
      final base = task(userInput: 'hi', intent: 'feature');
      final updated = base.copyWith(verdict: AgentVerdict.blocked);

      expect(updated.userInput, 'hi');
      expect(updated.intent, 'feature');
      expect(updated.verdict, AgentVerdict.blocked);
    });

    test('worstSeverity reflects the most severe finding', () {
      final t = task().copyWith(
        findings: const [
          AgentFinding(
            agentId: 'a',
            severity: FindingSeverity.info,
            message: 'i',
          ),
          AgentFinding(
            agentId: 'a',
            severity: FindingSeverity.warning,
            message: 'w',
          ),
        ],
      );
      expect(t.worstSeverity, FindingSeverity.warning);

      final withError = t.copyWith(
        findings: [
          ...t.findings,
          const AgentFinding(
            agentId: 'a',
            severity: FindingSeverity.error,
            message: 'e',
          ),
        ],
      );
      expect(withError.worstSeverity, FindingSeverity.error);
    });

    test('worstSeverity defaults to info when there are no findings', () {
      expect(task().worstSeverity, FindingSeverity.info);
    });

    test('findingsBy filters by agent id', () {
      final t = task().copyWith(
        findings: const [
          AgentFinding(
            agentId: 'x',
            severity: FindingSeverity.info,
            message: '1',
          ),
          AgentFinding(
            agentId: 'y',
            severity: FindingSeverity.info,
            message: '2',
          ),
        ],
      );
      expect(t.findingsBy('x'), hasLength(1));
      expect(t.findingsBy('x').single.message, '1');
    });
  });

  group('SafetyAgent', () {
    final agent = SafetyAgent();

    test('flags an exact locked file as an error', () {
      final out = agent.evaluate(task(referencedFiles: ['pubspec.yaml']));
      expect(hasError(out), isTrue);
      expect(out.findingsBy(SafetyAgent.id), isNotEmpty);
    });

    test('flags files under a locked directory prefix', () {
      final out = agent.evaluate(
        task(referencedFiles: ['android/app/build.gradle']),
      );
      expect(hasError(out), isTrue);
    });

    test('flags secret/credential files', () {
      final out = agent.evaluate(task(referencedFiles: ['config/app.pem']));
      expect(
        out.findings.any((f) => f.message.contains('secret/credential')),
        isTrue,
      );
    });

    test('flags dangerous shell commands in user input', () {
      final out = agent.evaluate(task(userInput: 'please run rm -rf / now'));
      expect(hasError(out), isTrue);
    });

    test('detects dangerous patterns inside a code snippet', () {
      final out = agent.evaluate(
        task(codeSnippet: 'Process.run("DROP TABLE users");'),
      );
      expect(hasError(out), isTrue);
    });

    test('does not flag a safe, ordinary file', () {
      final out = agent.evaluate(
        task(referencedFiles: ['lib/features/dashboard/dashboard_screen.dart']),
      );
      expect(hasError(out), isFalse);
    });
  });

  group('CodeReviewAgent', () {
    final agent = CodeReviewAgent();

    test('returns the task unchanged when there is no code', () {
      final input = task();
      expect(agent.evaluate(input).findings, isEmpty);
    });

    test('flags potential secrets as errors with a line number', () {
      final out = agent.evaluate(task(codeSnippet: 'final apiKey = "abc123";'));
      final secret = out.findings.firstWhere(
        (f) => f.severity == FindingSeverity.error,
      );
      expect(secret.line, 1);
    });

    test('flags code smells as warnings', () {
      final out = agent.evaluate(task(codeSnippet: 'print("debug");'));
      expect(
        out.findings.any((f) => f.severity == FindingSeverity.warning),
        isTrue,
      );
    });

    test('warns about await without try/catch', () {
      final out = agent.evaluate(task(codeSnippet: 'final x = await fetch();'));
      expect(
        out.findings.any((f) => f.message.contains('Async code without')),
        isTrue,
      );
    });

    test('warns when setState is mixed with Provider', () {
      final out = agent.evaluate(
        task(codeSnippet: 'setState((){}); ref.read(myProvider);'),
      );
      expect(
        out.findings.any((f) => f.message.contains('Mixing setState')),
        isTrue,
      );
    });
  });

  group('TestAgent', () {
    final agent = TestAgent();

    test('reminds to add tests for a feature with no code snippet', () {
      final out = agent.evaluate(task(intent: 'feature'));
      expect(out.findings, hasLength(1));
      expect(out.findings.single.severity, FindingSeverity.info);
    });

    test('says nothing for a no-code task with a non-feature intent', () {
      expect(agent.evaluate(task(intent: 'unknown')).findings, isEmpty);
    });

    test('warns about critical code areas (auth/db/payments)', () {
      final out = agent.evaluate(
        task(codeSnippet: 'String validateJwt(String token) => "";'),
      );
      expect(
        out.findings.any((f) => f.severity == FindingSeverity.warning),
        isTrue,
      );
    });

    test('counts public methods across lines (multiline regex)', () {
      const code = '''
void a() {}
String b() {}
int c() {}
''';
      final out = agent.evaluate(task(codeSnippet: code));
      expect(
        out.findings.any((f) => f.message.contains('public methods')),
        isTrue,
      );
    });

    test('flags async code for extra test paths', () {
      final out = agent.evaluate(
        task(codeSnippet: 'Future<int> f() async => 1;'),
      );
      expect(
        out.findings.any((f) => f.message.contains('Async code detected')),
        isTrue,
      );
    });
  });

  group('ActionAgent', () {
    final agent = ActionAgent();

    test('maps a keyword to an in-app action', () {
      final out = agent.evaluate(task(userInput: 'open the terminal please'));
      expect(out.suggestedActions.any((a) => a.id == 'open_terminal'), isTrue);
    });

    test('deduplicates actions shared by multiple keywords', () {
      final out = agent.evaluate(task(userInput: 'open ai chat')); // ai + chat
      final openChat = out.suggestedActions
          .where((a) => a.id == 'open_chat')
          .toList();
      expect(openChat, hasLength(1));
    });

    test('adds an info finding summarizing suggested actions', () {
      final out = agent.evaluate(task(userInput: 'open settings'));
      expect(
        out.findings.any((f) => f.severity == FindingSeverity.info),
        isTrue,
      );
    });

    test('suggests nothing when no keyword matches', () {
      final out = agent.evaluate(task(userInput: 'hello world'));
      expect(out.suggestedActions, isEmpty);
      expect(out.findings, isEmpty);
    });

    test('matches Italian phrasing for common actions', () {
      expect(
        agent
            .evaluate(task(userInput: 'apri il terminale'))
            .suggestedActions
            .any((a) => a.id == 'open_terminal'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'installa un pacchetto'))
            .suggestedActions
            .any((a) => a.id == 'open_packages'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'mostra le impostazioni'))
            .suggestedActions
            .any((a) => a.id == 'open_settings'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'crea una automazione di backup'))
            .suggestedActions
            .any((a) => a.id == 'open_automation'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'apri la cartella dei progetti'))
            .suggestedActions
            .any((a) => a.id == 'open_file_manager'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'quanta memoria sto usando?'))
            .suggestedActions
            .any((a) => a.id == 'show_ram'),
        isTrue,
      );
    });

    test('suggests disk and GPU detail actions', () {
      expect(
        agent
            .evaluate(task(userInput: 'quanto spazio su disco resta?'))
            .suggestedActions
            .any((a) => a.id == 'show_disk'),
        isTrue,
      );
      expect(
        agent
            .evaluate(task(userInput: 'temperatura della gpu?'))
            .suggestedActions
            .any((a) => a.id == 'show_gpu'),
        isTrue,
      );
    });

    test('attaches the parsed cron to scheduling actions', () {
      final out = agent.evaluate(
        task(userInput: 'pianifica un backup ogni giorno alle 9'),
      );

      final newTask = out.suggestedActions.firstWhere(
        (a) => a.id == 'new_task',
      );
      expect(newTask.params['cron'], '0 9 * * *');
    });

    test('scheduling actions carry no cron when none is parseable', () {
      final out = agent.evaluate(task(userInput: 'crea una automazione'));

      final newTask = out.suggestedActions.firstWhere(
        (a) => a.id == 'new_task',
      );
      expect(newTask.params.containsKey('cron'), isFalse);
    });

    test('does not fire on substrings inside other words', () {
      // 'hai'/'mai' must not trigger the short 'ai' keyword.
      expect(
        agent.evaluate(task(userInput: 'cosa hai fatto?')).suggestedActions,
        isEmpty,
      );
      // 'profile' must not trigger the 'file' keyword.
      expect(
        agent
            .evaluate(task(userInput: 'update my profile picture'))
            .suggestedActions,
        isEmpty,
      );
    });
  });

  group('AgentCoordinator', () {
    final coordinator = AgentCoordinator();

    test('blocks when a safety error is present', () {
      final out = coordinator.run(task(userInput: 'rm -rf /'));
      expect(out.verdict, AgentVerdict.blocked);
      expect(out.summary, contains('blocker'));
    });

    test('warns when only warnings are present', () {
      final out = coordinator.run(task(codeSnippet: 'print("x");'));
      expect(out.verdict, AgentVerdict.warning);
      expect(out.summary, contains('warning'));
    });

    test('passes when there are no errors or warnings', () {
      final out = coordinator.run(task(userInput: 'hello world'));
      expect(out.verdict, AgentVerdict.ok);
      expect(out.summary, contains('All checks passed'));
    });

    test('runs all four stages in order', () {
      final out = coordinator.run(
        task(
          userInput: 'open terminal and rm -rf /',
          intent: 'feature',
          codeSnippet: 'final k = "password";',
        ),
      );
      // Safety (dangerous cmd) + CodeReview (secret) => blocked.
      expect(out.verdict, AgentVerdict.blocked);
      // Action agent still suggested an action for "terminal".
      expect(out.suggestedActions, isNotEmpty);
    });
  });
}
