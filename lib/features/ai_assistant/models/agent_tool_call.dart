/// Tools the local AI can invoke to actually get work done, rather than only
/// describing it. Emitted by the model as ```tool JSON blocks and executed by
/// [AgentToolExecutor].
enum ToolType { writeFile, readFile, run, fetch, done, unknown }

/// A single tool invocation parsed from the model's reply.
class AgentToolCall {
  final ToolType tool;

  /// write_file: target path, relative to the workspace root.
  final String? path;

  /// write_file: full file contents.
  final String? content;

  /// run: shell command to execute.
  final String? command;

  /// fetch: URL to retrieve from the internet.
  final String? url;

  /// done: short summary of what was accomplished.
  final String? summary;

  const AgentToolCall({
    required this.tool,
    this.path,
    this.content,
    this.command,
    this.url,
    this.summary,
  });

  static ToolType typeFromName(String? name) {
    switch (name) {
      case 'write_file':
        return ToolType.writeFile;
      case 'read_file':
        return ToolType.readFile;
      case 'run':
        return ToolType.run;
      case 'fetch':
        return ToolType.fetch;
      case 'done':
        return ToolType.done;
      default:
        return ToolType.unknown;
    }
  }
}

/// Outcome of executing one [AgentToolCall], fed back to the model so it can
/// decide the next step.
class ToolResult {
  final AgentToolCall call;
  final bool ok;

  /// Human/model-readable outcome (command output, error, confirmation).
  final String output;

  const ToolResult({
    required this.call,
    required this.ok,
    required this.output,
  });
}
