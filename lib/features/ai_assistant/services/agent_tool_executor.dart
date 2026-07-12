import 'dart:async';
import 'dart:io';

import '../../terminal/services/command_guard.dart';
import '../models/agent_tool_call.dart';

/// Runs a shell command and returns its combined output. Injectable so the
/// executor can be tested without spawning real processes.
typedef CommandRunner = Future<String> Function(String command);

/// Fetches a URL and returns its body text. Injectable for tests and so the
/// executor doesn't depend on a concrete HTTP client.
typedef UrlFetcher = Future<String> Function(String url);

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

  /// Files that must not be overwritten in this workspace. Defaults to
  /// BrainiacPlus's own locked files; when the agent is scoped to a *user*
  /// project, the caller passes an empty set so the project's own main.dart
  /// and pubspec are editable.
  final Set<String> lockedFiles;

  /// Fetches URLs for the `fetch` tool; null disables internet access.
  final UrlFetcher? _fetch;

  AgentToolExecutor({
    required this.workspaceRoot,
    required CommandRunner runCommand,
    UrlFetcher? fetchUrl,
    this.commandTimeout = const Duration(seconds: 120),
    this.lockedFiles = defaultLockedFiles,
  }) : _run = runCommand,
       _fetch = fetchUrl;

  /// Cap on fetched body size fed back to the model.
  static const _maxFetchChars = 8000;

  /// BrainiacPlus's own protected files. Mirrors the locked-files list in the
  /// project contract.
  static const defaultLockedFiles = <String>{
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
      case ToolType.fetch:
        return _fetchUrl(call);
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
    if (lockedFiles.contains(_normalize(rel))) {
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

  Future<ToolResult> _fetchUrl(AgentToolCall call) async {
    final url = call.url?.trim();
    if (url == null || url.isEmpty) {
      return ToolResult(call: call, ok: false, output: 'Missing url.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return ToolResult(
        call: call,
        ok: false,
        output: 'Only http/https URLs can be fetched: $url',
      );
    }
    final fetch = _fetch;
    if (fetch == null) {
      return ToolResult(
        call: call,
        ok: false,
        output: 'Internet fetching is not available in this context.',
      );
    }
    try {
      final body = await fetch(url).timeout(commandTimeout);
      final out = body.length > _maxFetchChars
          ? '${body.substring(0, _maxFetchChars)}\n…[truncated ${body.length - _maxFetchChars} chars]'
          : body;
      return ToolResult(call: call, ok: true, output: out);
    } on TimeoutException {
      return ToolResult(call: call, ok: false, output: 'Fetch timed out: $url');
    } catch (e) {
      return ToolResult(call: call, ok: false, output: 'Fetch failed: $e');
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
