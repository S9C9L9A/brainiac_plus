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
