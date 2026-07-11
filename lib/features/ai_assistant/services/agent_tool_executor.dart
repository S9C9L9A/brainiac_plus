import 'dart:async';
import 'dart:io';

import '../../terminal/services/command_guard.dart';
import '../models/agent_tool_call.dart';

/// Runs a shell command and returns its combined output. Injectable so the
/// executor can be tested without spawning real processes.
typedef CommandRunner = Future<String> Function(String command);

/// Executes [AgentToolCall]s produced by the local AI, turning the assistant
/// from a talker into a doer while keeping hard safety rails:
///
/// - file writes are confined to the workspace and refuse locked project
///   files (pubspec, main.dart, secrets, native build config);
/// - commands pass through the same [CommandGuard] as the embedded terminal,
///   so `rm -rf /` and friends never run.
class AgentToolExecutor {
  final String workspaceRoot;
  final CommandRunner _run;
  final CommandGuard _guard = CommandGuard();

  /// A single command may not run longer than this — a non-terminating
  /// command (a server, an interactive prompt) would otherwise hang the whole
  /// agent loop and freeze the app.
  final Duration commandTimeout;

  AgentToolExecutor({
    required this.workspaceRoot,
    required CommandRunner runCommand,
    this.commandTimeout = const Duration(seconds: 120),
  }) : _run = runCommand;

  /// Project files the assistant must never overwrite unattended. Mirrors the
  /// locked-files list in the project contract.
  static const _lockedFiles = <String>{
    'pubspec.yaml',
    'pubspec.lock',
    'lib/main.dart',
    'go_backend/.env',
    'android/app/build.gradle.kts',
  };

  static bool isTerminal(AgentToolCall call) => call.tool == ToolType.done;

  Future<ToolResult> execute(AgentToolCall call) async {
    switch (call.tool) {
      case ToolType.writeFile:
        return _writeFile(call);
      case ToolType.run:
        return _runCommand(call);
      case ToolType.done:
        return ToolResult(
          call: call,
          ok: true,
          output: call.summary ?? 'Done.',
        );
      case ToolType.unknown:
        return ToolResult(call: call, ok: false, output: 'Unknown tool.');
    }
  }

  Future<ToolResult> _writeFile(AgentToolCall call) async {
    final rel = call.path?.trim();
    if (rel == null || rel.isEmpty) {
      return ToolResult(call: call, ok: false, output: 'Missing file path.');
    }
    if (_lockedFiles.contains(_normalize(rel))) {
      return ToolResult(
        call: call,
        ok: false,
        output: 'Refused: "$rel" is a protected project file.',
      );
    }

    final root = Directory(workspaceRoot).absolute.path;
    final target = File('$root/$rel').absolute;
    // Reject traversal outside the workspace after resolving '..' segments.
    if (!_isInside(root, target.path)) {
      return ToolResult(
        call: call,
        ok: false,
        output: 'Refused: "$rel" is outside the workspace.',
      );
    }

    try {
      await target.parent.create(recursive: true);
      await target.writeAsString(call.content ?? '');
      return ToolResult(call: call, ok: true, output: 'Wrote $rel');
    } catch (e) {
      return ToolResult(call: call, ok: false, output: 'Write failed: $e');
    }
  }

  Future<ToolResult> _runCommand(AgentToolCall call) async {
    final command = call.command?.trim();
    if (command == null || command.isEmpty) {
      return ToolResult(call: call, ok: false, output: 'Missing command.');
    }

    final check = _guard.assess(command);
    if (check.isDangerous) {
      return ToolResult(
        call: call,
        ok: false,
        output: 'Blocked destructive command (${check.reason}): $command',
      );
    }

    try {
      final out = await _run(command).timeout(commandTimeout);
      return ToolResult(call: call, ok: true, output: out);
    } on TimeoutException {
      return ToolResult(
        call: call,
        ok: false,
        output:
            'Command timed out after ${commandTimeout.inSeconds}s '
            '(did not terminate): $command',
      );
    } catch (e) {
      return ToolResult(call: call, ok: false, output: 'Command failed: $e');
    }
  }

  String _normalize(String path) =>
      path.replaceAll('\\', '/').replaceAll(RegExp(r'^\./'), '');

  bool _isInside(String root, String candidate) {
    final normalizedRoot = root.endsWith('/') ? root : '$root/';
    final resolved = _collapse(candidate);
    return resolved == root || resolved.startsWith(normalizedRoot);
  }

  /// Collapses '.' and '..' segments so traversal cannot escape the root.
  String _collapse(String path) {
    final parts = path.split('/');
    final stack = <String>[];
    for (final part in parts) {
      if (part == '..') {
        if (stack.isNotEmpty) stack.removeLast();
      } else if (part != '.' && part.isNotEmpty) {
        stack.add(part);
      }
    }
    return '/${stack.join('/')}';
  }
}
