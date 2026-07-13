import 'package:brainiac_plus/features/dashboard/controllers/project_run_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectRunState.exitCode / failed', () {
    test('parses a non-zero exit code from the output', () {
      const s = ProjectRunState(
        output: 'Resolving dependencies...\nProcess exited with code: 65\n',
      );
      expect(s.exitCode, 65);
      expect(s.failed, isTrue);
    });

    test('output with no explicit code but content means clean exit (0)', () {
      const s = ProjectRunState(output: 'Built app\n');
      expect(s.exitCode, 0);
      expect(s.failed, isFalse);
    });

    test('null while still running', () {
      const s = ProjectRunState(output: 'anything', running: true);
      expect(s.exitCode, isNull);
      expect(s.failed, isFalse);
    });

    test('empty output has no exit code', () {
      const s = ProjectRunState();
      expect(s.exitCode, isNull);
    });

    test('the last exit code wins when a run reports several', () {
      const s = ProjectRunState(
        output:
            'Process exited with code: 1\n'
            '...retried...\n'
            'Process exited with code: 0\n',
      );
      expect(s.exitCode, 0);
      expect(s.failed, isFalse);
    });
  });

  group('buildConsoleResolvePrompt', () {
    test('frames the log as a fix request and includes the exit code', () {
      final p = buildConsoleResolvePrompt(
        'pubspec.yaml has no lower-bound SDK constraint\n'
        'Process exited with code: 65',
        exitCode: 65,
      );
      expect(p, contains('exit code 65'));
      expect(p, contains('read_file'));
      expect(p, contains('write_file'));
      expect(p, contains('pubspec.yaml has no lower-bound'));
    });

    test('caps a very large log to the tail', () {
      final huge = List.generate(2000, (i) => 'line $i').join('\n');
      final p = buildConsoleResolvePrompt(huge);
      expect(p.length, lessThan(4500));
      expect(p, contains('truncated'));
      expect(p, contains('line 1999')); // the tail is kept
    });
  });
}
