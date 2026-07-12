import 'dart:io';

import 'package:brainiac_plus/features/dashboard/services/project_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectRunner.isFlutterProject', () {
    test('detects a flutter dependency/sdk in the pubspec', () {
      expect(
        ProjectRunner.isFlutterProject(
          'dependencies:\n  flutter:\n    sdk: flutter',
        ),
        isTrue,
      );
    });
    test('a pure dart pubspec is not flutter', () {
      expect(
        ProjectRunner.isFlutterProject(
          'name: cli\ndependencies:\n  args: ^2.0',
        ),
        isFalse,
      );
    });
  });

  group('RunTarget device mapping', () {
    test('each target maps to a flutter device id', () {
      expect(RunTarget.linux.deviceId, 'linux');
      expect(RunTarget.web.deviceId, 'chrome');
      expect(RunTarget.android.deviceId, 'android');
    });
  });

  group('ProjectRunner.commandFor', () {
    Directory makeProject({required bool flutter}) {
      final proj = Directory.systemTemp.createTempSync('cmd');
      File('${proj.path}/pubspec.yaml').writeAsStringSync(
        'name: demo\n${flutter ? 'dependencies:\n  flutter:\n    sdk: flutter\n' : ''}',
      );
      return proj;
    }

    test('runs a flutter project on the chosen target', () {
      final proj = makeProject(flutter: true);
      addTearDown(() => proj.deleteSync(recursive: true));

      expect(
        ProjectRunner.commandFor(proj.path, target: RunTarget.linux),
        contains('flutter run -d linux'),
      );
      expect(
        ProjectRunner.commandFor(proj.path, target: RunTarget.web),
        contains('flutter run -d chrome'),
      );
      expect(
        ProjectRunner.commandFor(proj.path, target: RunTarget.android),
        contains('flutter run -d android'),
      );
    });

    test('uses dart run for a plain dart project', () {
      final proj = makeProject(flutter: false);
      addTearDown(() => proj.deleteSync(recursive: true));

      final cmd = ProjectRunner.commandFor(proj.path);
      expect(cmd, contains('dart run'));
      expect(cmd, isNot(contains('flutter')));
    });
  });
}
