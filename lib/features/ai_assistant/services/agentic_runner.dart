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

  /// Base tool protocol, shared by both modes.
  static const _toolProtocol = '''
You are BrainiacPlus, an autonomous AI developer operating the user's machine.
You do not merely describe work — you perform it, one step at a time.

Tools — emit a fenced block, one JSON object per block:
```tool
{"tool": "read_file", "path": "relative/path.dart"}
```
```tool
{"tool": "write_file", "path": "relative/path.dart", "content": "full new file contents"}
```
```tool
{"tool": "run", "command": "a one-shot shell command"}
```
```tool
{"tool": "fetch", "url": "https://example.com"}
```
```tool
{"tool": "search", "query": "how to do X"}
```
```tool
{"tool": "status"}
```
When the task is fully complete, finish with:
```tool
{"tool": "done", "summary": "what you accomplished"}
```

Rules:
- To CHANGE a file you MUST emit a write_file tool block. Describing the fix,
  or showing the code in a normal ```dart block, does NOT change anything on
  disk — only write_file does. Never say you edited a file without a
  write_file block in the SAME message.
- To EDIT an existing file: FIRST read_file it, then write_file the COMPLETE
  modified contents (the original file with your change applied). Do not write
  a short/minimal placeholder — that would destroy the user's code.
- Follow the user's instructions exactly. If they ask for a specific change,
  make that exact change; don't substitute a simpler or unrelated one.
- Take ONE step per message, then wait for its result before the next.
- write_file replaces the WHOLE file — include the complete new contents.
- In write_file, put the file's code in the JSON "content" field and keep
  "content" the LAST field in the object.
- Use `search` to find pages on the web, then `fetch` a result URL to read it.
- Use `status` to check the machine's live state (GPU, VRAM, inference speed).
- Use `fetch` for docs/APIs from the internet (live web access).
- Do NOT run long-running/interactive commands (servers, "flutter run",
  watchers) — they never return. Prefer commands that finish.
- Plain question? Reply in plain text with no tool block.''';

  /// Sandbox mode — building fresh apps.
  static const _sandboxRules = '''

You work inside a clean, empty sandbox. To build an app, create it in its
own new subfolder and write every file from scratch.''';

  /// Full sandbox-mode prompt (no active project). Public for reference/tests.
  static const systemPrompt = '$_toolProtocol$_sandboxRules';

  Future<AgentRunResult> run(
    String userRequest, {
    void Function(AgentStep step)? onStep,
    List<AgentTurn> history = const [],
  }) async {
    // In project mode the workspace is an existing codebase, not an empty
    // sandbox — read files before changing them.
    final system = projectContext == null
        ? systemPrompt
        : '$_toolProtocol\n\nYou are working INSIDE an existing project. Its '
              'files already exist — use read_file to inspect a file before '
              'you write_file to change it. Paths are relative to the project '
              'root.\n\nPROJECT CONTEXT:\n$projectContext';
    final conversation = <AgentTurn>[
      AgentTurn('system', system),
      // Prior turns give the assistant memory of what it already did, so
      // follow-ups ("show me what you changed") have context.
      ...history,
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
