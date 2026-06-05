import '../models/agent_task.dart';
/// Validates operations against locked files and dangerous shell patterns.
/// Produces [AgentVerdict.blocked] for critical violations.
class SafetyAgent {
  static const String id = 'safety';
  static const _lockedPaths = [
    'pubspec.yaml',
    'pubspec.lock',
    'lib/main.dart',
    'android/app/build.gradle.kts',
    'go_backend/.env',
    'android/',
    'ios/',
    '.dart_tool/',
    'build/',
  ];
  static const _dangerousCommands = [
    'rm -rf',
    'git push --force',
    'git push -f',
    'DROP TABLE',
    'DELETE FROM',
    'format c:',
    'dd if=',
    'chmod 777',
    '> /dev/sda',
    'mkfs',
  ];
  static const _secretPatterns = [
    '.env',
    '.pem',
    '.key',
    'secrets/',
    'key.properties',
    'credentials',
  ];
  AgentTask evaluate(AgentTask task) {
    final newFindings = <AgentFinding>[...task.findings];
    // Check referenced files against locked paths
    for (final file in task.referencedFiles) {
      for (final locked in _lockedPaths) {
        if (file == locked || file.startsWith(locked)) {
          newFindings.add(AgentFinding(
            agentId: id,
            severity: FindingSeverity.error,
            message: 'Locked file referenced: "$file" — explicit user approval required (CLAUDE.md §7).',
            file: file,
          ));
        }
      }
      for (final secret in _secretPatterns) {
        if (file.contains(secret)) {
          newFindings.add(AgentFinding(
            agentId: id,
            severity: FindingSeverity.error,
            message: 'Potential secret/credential file: "$file" — never touch without HID (CLAUDE.md §8).',
            file: file,
          ));
        }
      }
    }
    // Check user input for dangerous shell commands
    final lower = task.userInput.toLowerCase();
    for (final cmd in _dangerousCommands) {
      if (lower.contains(cmd.toLowerCase())) {
        newFindings.add(AgentFinding(
          agentId: id,
          severity: FindingSeverity.error,
          message: 'Dangerous operation requested: "$cmd" — requires explicit approval (CLAUDE.md §19).',
        ));
      }
    }
    // Check code snippet for dangerous patterns
    final code = task.codeSnippet;
    if (code != null && code.isNotEmpty) {
      for (final cmd in _dangerousCommands) {
        if (code.contains(cmd)) {
          newFindings.add(AgentFinding(
            agentId: id,
            severity: FindingSeverity.error,
            message: 'Dangerous shell pattern in code: "$cmd"',
          ));
        }
      }
    }
    return task.copyWith(findings: newFindings);
  }
}
