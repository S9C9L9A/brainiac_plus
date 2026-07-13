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
}
