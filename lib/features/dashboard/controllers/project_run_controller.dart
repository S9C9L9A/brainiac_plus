import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shell_service.dart';

/// Live state of a project's run console.
class ProjectRunState {
  final String output;
  final bool running;

  const ProjectRunState({this.output = '', this.running = false});

  ProjectRunState copyWith({String? output, bool? running}) => ProjectRunState(
    output: output ?? this.output,
    running: running ?? this.running,
  );

  /// The process exit code, parsed from the output the shell appends on exit
  /// (`Process exited with code: N`). Null while running or if it hasn't
  /// exited with a reported code.
  int? get exitCode {
    if (running) return null;
    final m = RegExp(
      r'Process exited with code:\s*(-?\d+)',
    ).allMatches(output).lastOrNull;
    if (m != null) return int.tryParse(m.group(1)!);
    // A finished run with output but no explicit code exited cleanly (0).
    return output.trim().isEmpty ? null : 0;
  }

  /// True when the last run ended in a non-zero exit.
  bool get failed => (exitCode ?? 0) != 0;
}

/// Builds the prompt sent to the assistant by the console's "Resolve with AI"
/// button: the last run's output (capped to the tail so a huge log doesn't
/// blow the context), framed as a fix request. Pure + testable.
String buildConsoleResolvePrompt(String output, {int? exitCode}) {
  const maxChars = 4000;
  final trimmed = output.trim();
  final tail = trimmed.length > maxChars
      ? '…[earlier output truncated]\n${trimmed.substring(trimmed.length - maxChars)}'
      : trimmed;
  final code = exitCode != null && exitCode != 0
      ? ' (exit code $exitCode)'
      : '';
  return 'The last command run in this project failed$code. Diagnose the error '
      'from this console log and FIX it: use read_file to inspect the relevant '
      'file, then write_file the corrected version. Explain the fix briefly.\n\n'
      'Console log:\n```\n$tail\n```';
}

/// Runs a project's launch command and streams its output into state, so the
/// project screen can show a live console. Owns a [ShellService]; stop() kills
/// the running process (e.g. a `flutter run` session).
class ProjectRunController extends StateNotifier<ProjectRunState> {
  final ShellService _shell;
  StreamSubscription<String>? _sub;

  ProjectRunController({ShellService? shell})
    : _shell = shell ?? ShellService(),
      super(const ProjectRunState()) {
    _sub = _shell.outputStream.listen((data) {
      state = state.copyWith(output: state.output + data);
    });
  }

  /// Starts [command], replacing any previous output. Returns when the process
  /// exits (or is stopped).
  Future<void> start(String command) async {
    state = const ProjectRunState(output: '', running: true);
    try {
      await _shell.executeCommand(command);
    } finally {
      if (mounted) state = state.copyWith(running: false);
    }
  }

  void stop() {
    _shell.killProcess();
    if (mounted) state = state.copyWith(running: false);
  }

  void clear() {
    state = const ProjectRunState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shell.dispose();
    super.dispose();
  }
}

/// One console per project path; auto-disposed when the screen closes (which
/// also kills any process still running).
final projectRunProvider = StateNotifierProvider.autoDispose
    .family<ProjectRunController, ProjectRunState, String>((ref, path) {
      final controller = ProjectRunController();
      ref.onDispose(controller.stop);
      return controller;
    });
