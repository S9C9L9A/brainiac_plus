import 'package:brainiac_plus/features/dashboard/services/project_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectRunner.launchCommand', () {
    test('runs a Flutter app on the Linux desktop device', () {
      final cmd = ProjectRunner.launchCommand('/ws/rainbow', isFlutter: true);
      expect(cmd, contains('cd "/ws/rainbow"'));
      expect(cmd, contains('flutter run -d linux'));
    });

    test('runs a plain Dart project with dart run', () {
      final cmd = ProjectRunner.launchCommand('/ws/cli', isFlutter: false);
      expect(cmd, contains('cd "/ws/cli"'));
      expect(cmd, contains('dart run'));
      expect(cmd, isNot(contains('flutter')));
    });
  });

  group('ProjectRunner.isFlutterProject', () {
    test('detects the flutter sdk constraint in a pubspec', () {
      expect(
        ProjectRunner.isFlutterProject('name: x\ndependencies:\n  flutter:\n'),
        isTrue,
      );
      expect(
        ProjectRunner.isFlutterProject('environment:\n  flutter: ">=3.0.0"'),
        isTrue,
      );
    });

    test('a pure dart pubspec is not a flutter project', () {
      expect(
        ProjectRunner.isFlutterProject(
          'name: cli\ndependencies:\n  args: ^2.0',
        ),
        isFalse,
      );
    });
  });

  group('ProjectRunner.launch', () {
    test('spawns the launch command detached and reports success', () async {
      final launched = <String>[];
      final runner = ProjectRunner(spawn: (cmd) async => launched.add(cmd));

      final result = await runner.launch('/ws/rainbow', isFlutter: true);

      expect(result.started, isTrue);
      expect(launched.single, contains('flutter run -d linux'));
    });

    test('reports failure when the spawn throws', () async {
      final runner = ProjectRunner(
        spawn: (_) async => throw Exception('no flutter'),
      );

      final result = await runner.launch('/ws/x', isFlutter: true);

      expect(result.started, isFalse);
      expect(result.message.toLowerCase(), contains('failed'));
    });
  });
}
