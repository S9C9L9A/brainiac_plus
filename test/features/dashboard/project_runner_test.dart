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

  group('fast launch', () {
    late Directory proj;
    setUp(() => proj = Directory.systemTemp.createTempSync('fast'));
    tearDown(() => proj.deleteSync(recursive: true));

    test('no artifact → cannot fast-launch', () {
      expect(ProjectRunner.canFastLaunch(proj.path, RunTarget.linux), isFalse);
      expect(ProjectRunner.fastLaunchCommand(proj.path, RunTarget.web), isNull);
    });

    test('linux: launches the built bundle executable directly', () {
      final bundle = Directory('${proj.path}/build/linux/x64/debug/bundle')
        ..createSync(recursive: true);
      final exe = File('${bundle.path}/demo')..writeAsStringSync('bin');
      Process.runSync('chmod', ['+x', exe.path]);
      File('${bundle.path}/lib.so').writeAsStringSync('so'); // ignored

      expect(ProjectRunner.canFastLaunch(proj.path, RunTarget.linux), isTrue);
      final cmd = ProjectRunner.fastLaunchCommand(proj.path, RunTarget.linux)!;
      expect(cmd, contains('./demo'));
      expect(cmd, isNot(contains('flutter run')));
    });

    test('web: serves the built output', () {
      Directory('${proj.path}/build/web').createSync(recursive: true);
      File('${proj.path}/build/web/index.html').writeAsStringSync('<html>');

      final cmd = ProjectRunner.fastLaunchCommand(proj.path, RunTarget.web)!;
      expect(cmd, contains('http.server'));
      expect(cmd, contains('build/web'));
    });

    test('android: installs the built apk', () {
      final apkDir = Directory('${proj.path}/build/app/outputs/flutter-apk')
        ..createSync(recursive: true);
      File('${apkDir.path}/app-debug.apk').writeAsStringSync('apk');

      final cmd = ProjectRunner.fastLaunchCommand(
        proj.path,
        RunTarget.android,
      )!;
      expect(cmd, contains('adb install'));
      expect(cmd, contains('app-debug.apk'));
    });
  });
}
