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

  group('ProjectRunner.packageName', () {
    test('reads the name field', () {
      expect(ProjectRunner.packageName('name: rainbow_arc\n'), 'rainbow_arc');
    });
    test('null when absent', () {
      expect(ProjectRunner.packageName('description: x'), isNull);
    });
  });

  group('ProjectRunner.builtExecutable', () {
    test('finds a built debug bundle executable', () {
      final proj = Directory.systemTemp.createTempSync('built');
      addTearDown(() => proj.deleteSync(recursive: true));
      final bundle = Directory('${proj.path}/build/linux/x64/debug/bundle')
        ..createSync(recursive: true);
      final exe = File('${bundle.path}/myapp')..writeAsStringSync('bin');
      Process.runSync('chmod', ['+x', exe.path]);
      // A .so next to it must be ignored.
      File('${bundle.path}/libflutter_linux_gtk.so').writeAsStringSync('so');

      final found = ProjectRunner.builtExecutable(proj.path);
      expect(found, exe.path);
    });

    test('null when nothing is built', () {
      final proj = Directory.systemTemp.createTempSync('nobuild');
      addTearDown(() => proj.deleteSync(recursive: true));
      expect(ProjectRunner.builtExecutable(proj.path), isNull);
    });
  });

  group('ProjectRunner.commandFor', () {
    Directory makeProject({required bool flutter, required bool built}) {
      final proj = Directory.systemTemp.createTempSync('cmd');
      File('${proj.path}/pubspec.yaml').writeAsStringSync(
        'name: demo\n${flutter ? 'dependencies:\n  flutter:\n    sdk: flutter\n' : ''}',
      );
      if (built) {
        final bundle = Directory('${proj.path}/build/linux/x64/debug/bundle')
          ..createSync(recursive: true);
        final exe = File('${bundle.path}/demo')..writeAsStringSync('bin');
        Process.runSync('chmod', ['+x', exe.path]);
      }
      return proj;
    }

    test('launches the built bundle directly when present', () {
      final proj = makeProject(flutter: true, built: true);
      addTearDown(() => proj.deleteSync(recursive: true));

      final cmd = ProjectRunner.commandFor(proj.path);
      expect(cmd, contains('bundle'));
      expect(cmd, contains('./demo'));
      expect(cmd, isNot(contains('flutter build')));
    });

    test('builds then launches a flutter project that is not built', () {
      final proj = makeProject(flutter: true, built: false);
      addTearDown(() => proj.deleteSync(recursive: true));

      final cmd = ProjectRunner.commandFor(proj.path);
      expect(cmd, contains('flutter build linux'));
      expect(cmd, contains('bundle'));
      expect(cmd, contains('./demo'));
    });

    test('uses dart run for a plain dart project', () {
      final proj = makeProject(flutter: false, built: false);
      addTearDown(() => proj.deleteSync(recursive: true));

      final cmd = ProjectRunner.commandFor(proj.path);
      expect(cmd, contains('dart run'));
      expect(cmd, isNot(contains('flutter')));
    });
  });
}
