import 'dart:io';

/// Builds the shell command that launches a workspace project. The command is
/// run in the embedded terminal so the user sees real output (builds, errors),
/// instead of a detached process that could fail silently.
///
/// Strategy, in order:
///   1. A pre-built Linux bundle exists → launch that executable directly
///      (instant, reliable).
///   2. A Flutter project not yet built → `flutter build linux` then launch
///      the produced bundle (first run is slow; output is visible).
///   3. A plain Dart project → `dart run`.
class ProjectRunner {
  ProjectRunner._();

  /// True when the pubspec declares a Flutter dependency or SDK constraint.
  static bool isFlutterProject(String pubspecContent) {
    return RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(pubspecContent);
  }

  /// The package name declared in a pubspec, or null.
  static String? packageName(String pubspecContent) {
    final m = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspecContent);
    return m?.group(1);
  }

  /// Path to an already-built Linux executable (release preferred), or null.
  static String? builtExecutable(String projectPath) {
    for (final mode in ['release', 'debug']) {
      final bundle = Directory('$projectPath/build/linux/x64/$mode/bundle');
      if (!bundle.existsSync()) continue;
      try {
        for (final entity in bundle.listSync()) {
          if (entity is! File) continue;
          if (entity.path.endsWith('.so')) continue;
          // Executable bit set?
          if (entity.statSync().modeString().contains('x')) return entity.path;
        }
      } catch (_) {
        // ignore unreadable bundle dirs
      }
    }
    return null;
  }

  /// The shell command to run [projectPath].
  static String commandFor(String projectPath) {
    final pubspec = File('$projectPath/pubspec.yaml');
    final content = pubspec.existsSync() ? pubspec.readAsStringSync() : '';

    final exe = builtExecutable(projectPath);
    if (exe != null) {
      final dir = File(exe).parent.path;
      final name = exe.split('/').where((s) => s.isNotEmpty).last;
      return 'cd "$dir" && "./$name"';
    }

    if (isFlutterProject(content)) {
      final pkg =
          packageName(content) ??
          projectPath.split('/').where((s) => s.isNotEmpty).last;
      return 'cd "$projectPath" && flutter build linux --debug && '
          'cd build/linux/x64/debug/bundle && "./$pkg"';
    }

    return 'cd "$projectPath" && dart run';
  }
}
