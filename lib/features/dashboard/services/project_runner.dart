import 'dart:io';

import 'package:flutter/material.dart';

/// Where to run a project. Maps to a `flutter run` device.
enum RunTarget { linux, web, android }

extension RunTargetX on RunTarget {
  /// The `flutter run -d <id>` device id.
  String get deviceId => switch (this) {
    RunTarget.linux => 'linux',
    RunTarget.web => 'chrome',
    RunTarget.android => 'android',
  };

  String get label => switch (this) {
    RunTarget.linux => 'Linux',
    RunTarget.web => 'Web',
    RunTarget.android => 'Android',
  };

  IconData get icon => switch (this) {
    RunTarget.linux => Icons.desktop_windows,
    RunTarget.web => Icons.language,
    RunTarget.android => Icons.phone_android,
  };
}

/// Builds the shell command that runs a workspace project. The command is run
/// inside the project's own console panel so its log streams live and can be
/// stopped — `flutter run -d <device>` for Flutter apps (Linux/Web/Android),
/// `dart run` for plain Dart.
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

  /// The shell command to run [projectPath] on [target].
  static String commandFor(
    String projectPath, {
    RunTarget target = RunTarget.linux,
  }) {
    final pubspec = File('$projectPath/pubspec.yaml');
    final content = pubspec.existsSync() ? pubspec.readAsStringSync() : '';

    // `exec` replaces the shell with the runner process, so stopping the
    // console (which kills the shell) actually kills flutter/dart too.
    if (isFlutterProject(content)) {
      return _withFlutterPath(
        'cd "$projectPath" && exec flutter run -d ${target.deviceId}',
      );
    }
    return _withFlutterPath('cd "$projectPath" && exec dart run');
  }

  /// Command that clears a project's build artifacts (`flutter clean`). Useful
  /// when a moved or stale build has a mismatched CMake cache.
  static String cleanCommand(String projectPath) {
    return _withFlutterPath('cd "$projectPath" && exec flutter clean');
  }

  /// Prepends the flutter bin to PATH when we can locate it, so `flutter`/
  /// `dart` resolve even when the app was launched from a GUI session whose
  /// PATH doesn't include the SDK (the cause of "command not found" / 127).
  static String _withFlutterPath(String command) {
    final dir = flutterBinDir();
    return dir != null ? 'export PATH="$dir:\$PATH" && $command' : command;
  }

  /// Best-effort location of the Flutter SDK's bin directory, or null.
  static String? flutterBinDir() {
    final home = Platform.environment['HOME'] ?? '';
    final candidates = [
      '$home/flutter/bin',
      '$home/development/flutter/bin',
      '$home/snap/flutter/common/flutter/bin',
      '$home/fvm/default/bin',
      '/opt/flutter/bin',
      '/usr/local/flutter/bin',
    ];
    for (final c in candidates) {
      if (File('$c/flutter').existsSync()) return c;
    }
    return null;
  }

  /// Path to an already-built artifact for [target], or null when the project
  /// hasn't been built for it yet.
  ///   Linux  → the bundle executable
  ///   Web    → build/web (a served directory)
  ///   Android→ the flutter-apk output
  static String? builtArtifact(String projectPath, RunTarget target) {
    switch (target) {
      case RunTarget.linux:
        return _linuxExecutable(projectPath);
      case RunTarget.web:
        final index = File('$projectPath/build/web/index.html');
        return index.existsSync() ? '$projectPath/build/web' : null;
      case RunTarget.android:
        for (final apk in ['app-release.apk', 'app-debug.apk']) {
          final f = File('$projectPath/build/app/outputs/flutter-apk/$apk');
          if (f.existsSync()) return f.path;
        }
        return null;
    }
  }

  /// True when a fast (no-rebuild) launch is possible for [target].
  static bool canFastLaunch(String projectPath, RunTarget target) =>
      builtArtifact(projectPath, target) != null;

  /// Command that launches the already-built artifact for [target] without
  /// recompiling, or null when nothing is built. Runs in the project console.
  static String? fastLaunchCommand(String projectPath, RunTarget target) {
    final artifact = builtArtifact(projectPath, target);
    if (artifact == null) return null;

    switch (target) {
      case RunTarget.linux:
        final dir = File(artifact).parent.path;
        final name = artifact.split('/').where((s) => s.isNotEmpty).last;
        return 'cd "$dir" && exec "./$name"';
      case RunTarget.web:
        // Serve the built output and open the browser at it.
        const port = 8091;
        return 'cd "$artifact" && '
            '(sleep 1 && xdg-open "http://localhost:$port" >/dev/null 2>&1 &) && '
            'exec python3 -m http.server $port';
      case RunTarget.android:
        // Install the APK on the connected device.
        return 'adb install -r "$artifact"';
    }
  }

  /// Executable in the Linux release/debug bundle, or null.
  static String? _linuxExecutable(String projectPath) {
    for (final mode in ['release', 'debug']) {
      final bundle = Directory('$projectPath/build/linux/x64/$mode/bundle');
      if (!bundle.existsSync()) continue;
      try {
        for (final entity in bundle.listSync()) {
          if (entity is! File || entity.path.endsWith('.so')) continue;
          if (entity.statSync().modeString().contains('x')) return entity.path;
        }
      } catch (_) {
        // ignore unreadable bundle dirs
      }
    }
    return null;
  }
}
