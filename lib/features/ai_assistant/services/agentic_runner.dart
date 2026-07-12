import '../models/agent_tool_call.dart';
import 'agent_tool_executor.dart';
import 'tool_call_parser.dart';

/// Sends the running conversation to the model and returns its raw reply.
/// Kept as a bare function so the runner is trivially testable and decoupled
/// from the concrete LLM client.
typedef AgentChat = Future<String> Function(List<AgentTurn> conversation);

/// One message in the agentic conversation.
class AgentTurn {
  final String role; // 'system' | 'user' | 'assistant'
  final String content;
  const AgentTurn(this.role, this.content);
}

/// One iteration of the loop: what the model said, and what its tool calls did.
class AgentStep {
  final String assistantText;
  final List<ToolResult> results;
  const AgentStep({required this.assistantText, required this.results});
}

/// Final outcome of an agentic run.
class AgentRunResult {
  final List<AgentStep> steps;
  final bool completed;
  final int iterations;
  final String? summary;

  const AgentRunResult({
    required this.steps,
    required this.completed,
    required this.iterations,
    this.summary,
  });
}

/// Drives the local AI through a tool-use loop so it can carry a task from
/// request to result on its own: think → act (write files / run commands) →
/// observe results → repeat, until it emits `done` or hits [maxIterations].
///
/// This is what turns the assistant from "suggests a chip" into "builds the
/// thing" — the missing execution loop behind the AGI-assistant vision.
class AgenticRunner {
  final AgentChat chat;
  final AgentToolExecutor executor;
  final ToolCallParser parser;
  final int maxIterations;

  /// Extra context appended to the system prompt — e.g. a brief of the project
  /// the assistant is scoped to (its files, from the knowledge graph), so it
  /// knows the codebase before the user's first message.
  final String? projectContext;

  AgenticRunner({
    required this.chat,
    required this.executor,
    ToolCallParser? parser,
    this.maxIterations = 12,
    this.projectContext,
  }) : parser = parser ?? ToolCallParser();

  /// System prompt teaching the tool protocol. Kept explicit so smaller local
  /// models still emit parseable blocks.
  static const systemPrompt = '''
You are BrainiacPlus, an autonomous AI developer operating the user's machine.
You do not merely describe work — you perform it, one step at a time.

To act, emit a fenced block exactly like this (one JSON object per block):
```tool
{"tool": "write_file", "path": "relative/path.dart", "content": "file contents"}
```
```tool
{"tool": "run", "command": "a shell command"}
```
```tool
{"tool": "fetch", "url": "https://example.com"}
```
Use `fetch` to read documentation, APIs or any page from the internet
before acting — you have live web access.
When the task is fully complete, finish with:
```tool
{"tool": "done", "summary": "what you accomplished"}
```

You work inside a clean, empty sandbox directory. It is NOT an existing
project — there is no pubspec, no lib/main.dart, nothing to modify.

Rules:
- To build an app, create it in its OWN new subfolder (e.g. "rainbow_app/")
  and write every file it needs from scratch. Never assume a file exists.
- Paths are relative to the sandbox; never write outside it, and never
  target project files like pubspec.yaml or lib/main.dart.
- Take ONE step per message, then wait for the result before the next.
- After each command you receive its output; use it to decide what to do.
- Do NOT run long-running or interactive commands (servers, "flutter run",
  file watchers) — they never return. Prefer one-shot commands that finish.
- If you only need to answer a question, reply in plain text with no tool block.
''';

  Future<AgentRunResult> run(
    String userRequest, {
    void Function(AgentStep step)? onStep,
  }) async {
    final system = projectContext == null
        ? systemPrompt
        : '$systemPrompt\n\nPROJECT CONTEXT (you are working inside this '
              'project; you MAY edit its existing files):\n$projectContext';
    final conversation = <AgentTurn>[
      AgentTurn('system', system),
      AgentTurn('user', userRequest),
    ];
    final steps = <AgentStep>[];
    String? summary;
    var completed = false;
    var iterations = 0;

    while (iterations < maxIterations) {
      iterations++;
      final reply = await chat(conversation);
      conversation.add(AgentTurn('assistant', reply));

      final calls = parser.parse(reply);
      if (calls.isEmpty) {
        // Plain answer — the model chose to talk, not act. Done.
        final step = AgentStep(assistantText: reply, results: const []);
        steps.add(step);
        onStep?.call(step);
        completed = true;
        break;
      }

      final results = <ToolResult>[];
      var reachedDone = false;
      for (final call in calls) {
        final result = await executor.execute(call);
        results.add(result);
        if (AgentToolExecutor.isTerminal(call)) {
          reachedDone = true;
          summary = call.summary;
        }
      }

      final step = AgentStep(assistantText: reply, results: results);
      steps.add(step);
      onStep?.call(step);

      if (reachedDone) {
        completed = true;
        break;
      }

      // Feed the tool outcomes back so the model can plan the next step.
      conversation.add(AgentTurn('user', _formatResults(results)));
    }

    return AgentRunResult(
      steps: steps,
      completed: completed,
      iterations: iterations,
      summary: summary,
    );
  }

  String _formatResults(List<ToolResult> results) {
    final buf = StringBuffer('Tool results:\n');
    for (final r in results) {
      final status = r.ok ? 'OK' : 'ERROR';
      buf.writeln('[$status] ${r.output}');
    }
    buf.writeln('Continue with the next step, or emit "done" if finished.');
    return buf.toString();
  }
}
