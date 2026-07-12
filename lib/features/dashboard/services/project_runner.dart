import 'dart:io';

/// Spawns a shell command, detached, and returns when it has been started
/// (not when it finishes). Injectable so the launcher is testable.
typedef DetachedSpawn = Future<void> Function(String command);

/// Outcome of a launch attempt.
class LaunchResult {
  final bool started;
  final String message;
  const LaunchResult({required this.started, required this.message});
}

/// Launches a workspace project as a running app. `flutter run -d linux` for
/// Flutter projects, `dart run` for plain Dart — spawned detached so it keeps
/// running independently of BrainiacPlus and never blocks the UI.
class ProjectRunner {
  final DetachedSpawn _spawn;

  ProjectRunner({DetachedSpawn? spawn}) : _spawn = spawn ?? _defaultSpawn;

  /// True when a pubspec declares a Flutter dependency or SDK constraint.
  static bool isFlutterProject(String pubspecContent) {
    final flutterDep = RegExp(
      r'^\s*flutter\s*:',
      multiLine: true,
    ).hasMatch(pubspecContent);
    return flutterDep;
  }

  /// The shell command that launches the project.
  static String launchCommand(String path, {required bool isFlutter}) {
    final run = isFlutter ? 'flutter run -d linux' : 'dart run';
    return 'cd "$path" && $run';
  }

  /// Reads the project's pubspec to pick the right runner, then launches it.
  Future<LaunchResult> launchPath(String path) async {
    final pubspec = File('$path/pubspec.yaml');
    final isFlutter =
        pubspec.existsSync() && isFlutterProject(pubspec.readAsStringSync());
    return launch(path, isFlutter: isFlutter);
  }

  Future<LaunchResult> launch(String path, {required bool isFlutter}) async {
    try {
      await _spawn(launchCommand(path, isFlutter: isFlutter));
      return LaunchResult(
        started: true,
        message: isFlutter ? 'Launching on Linux desktop…' : 'Running…',
      );
    } catch (e) {
      return LaunchResult(started: false, message: 'Launch failed: $e');
    }
  }

  /// Detaches via setsid so the app outlives this process. Uses a login shell
  /// (bash -lc) so the user's PATH is loaded and flutter/dart are found.
  static Future<void> _defaultSpawn(String command) async {
    await Process.start('setsid', [
      'bash',
      '-lc',
      command,
    ], mode: ProcessStartMode.detached);
  }
}
