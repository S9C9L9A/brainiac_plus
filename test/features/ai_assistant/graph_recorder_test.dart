import 'package:brainiac_plus/features/ai_assistant/knowledge/graph_recorder.dart';
import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph.dart';
import 'package:brainiac_plus/features/ai_assistant/models/agent_tool_call.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agentic_runner.dart';
import 'package:flutter_test/flutter_test.dart';

ToolResult wrote(String path) => ToolResult(
  call: AgentToolCall(tool: ToolType.writeFile, path: path, content: 'x'),
  ok: true,
  output: 'Wrote $path',
);

ToolResult ran(String cmd) => ToolResult(
  call: AgentToolCall(tool: ToolType.run, command: cmd),
  ok: true,
  output: 'ran',
);

void main() {
  test(
    'records a task node linked to the files it wrote and commands it ran',
    () {
      final graph = KnowledgeGraph();
      GraphRecorder.recordRun(
        graph,
        taskId: 'task:1',
        request: 'crea una app rainbow',
        steps: [
          AgentStep(
            assistantText: 'writing',
            results: [wrote('rainbow/main.dart')],
          ),
          AgentStep(assistantText: 'running', results: [ran('dart run')]),
        ],
      );

      final task = graph.nodeById('task:1');
      expect(task, isNotNull);
      expect(task!.type, NodeType.task);

      final neighborIds = graph.neighbors('task:1').map((n) => n.id).toSet();
      expect(neighborIds, contains('file:rainbow/main.dart'));
      expect(neighborIds.any((id) => id.startsWith('command:')), isTrue);
      expect(graph.nodesOfType(NodeType.file), hasLength(1));
    },
  );

  test('failed tool results are not recorded as edges', () {
    final graph = KnowledgeGraph();
    GraphRecorder.recordRun(
      graph,
      taskId: 'task:2',
      request: 'try unsafe',
      steps: [
        AgentStep(
          assistantText: 'oops',
          results: [
            ToolResult(
              call: const AgentToolCall(
                tool: ToolType.writeFile,
                path: '../escape',
              ),
              ok: false,
              output: 'refused',
            ),
          ],
        ),
      ],
    );

    expect(graph.nodesOfType(NodeType.file), isEmpty);
    expect(graph.neighbors('task:2'), isEmpty);
  });

  test('the same file across tasks is a single shared node', () {
    final graph = KnowledgeGraph();
    for (final id in ['task:a', 'task:b']) {
      GraphRecorder.recordRun(
        graph,
        taskId: id,
        request: 'touch shared',
        steps: [
          AgentStep(assistantText: '', results: [wrote('shared/config.dart')]),
        ],
      );
    }

    expect(graph.nodesOfType(NodeType.file), hasLength(1));
    // Both tasks link to it.
    expect(graph.neighbors('task:a').single.id, 'file:shared/config.dart');
    expect(graph.neighbors('task:b').single.id, 'file:shared/config.dart');
  });
}
