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
      return 'cd "$projectPath" && exec flutter run -d ${target.deviceId}';
    }
    return 'cd "$projectPath" && exec dart run';
  }
}
