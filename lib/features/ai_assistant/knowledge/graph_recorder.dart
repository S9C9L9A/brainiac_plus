import '../models/agent_tool_call.dart';
import '../services/agentic_runner.dart';
import 'knowledge_graph.dart';

/// Maps a completed agentic run into the [KnowledgeGraph]: the task becomes a
/// node linked to the files it wrote and the commands it ran, so the graph
/// accumulates a persistent, queryable memory of what the assistant has done.
///
/// Files are keyed by path, so touching the same file across tasks yields one
/// shared node with edges from each task — that shared structure is the point
/// of a graph over a flat log.
class GraphRecorder {
  GraphRecorder._();

  static void recordRun(
    KnowledgeGraph graph, {
    required String taskId,
    required String request,
    required List<AgentStep> steps,
  }) {
    graph.upsertNode(
      GraphNode(id: taskId, type: NodeType.task, label: _truncate(request, 80)),
    );

    for (final step in steps) {
      for (final result in step.results) {
        if (!result.ok) continue; // only successful actions enter memory
        final call = result.call;
        switch (call.tool) {
          case ToolType.writeFile:
            final path = call.path;
            if (path == null || path.isEmpty) break;
            final id = 'file:$path';
            graph.upsertNode(
              GraphNode(
                id: id,
                type: NodeType.file,
                label: path.split('/').last,
                props: {'path': path},
              ),
            );
            graph.addEdge(taskId, id, EdgeRelation.wrote);
          case ToolType.run:
            final cmd = call.command;
            if (cmd == null || cmd.isEmpty) break;
            final id = 'command:$cmd';
            graph.upsertNode(
              GraphNode(
                id: id,
                type: NodeType.command,
                label: _truncate(cmd, 60),
              ),
            );
            graph.addEdge(taskId, id, EdgeRelation.ran);
          case ToolType.readFile:
          case ToolType.fetch:
          case ToolType.done:
          case ToolType.unknown:
            break;
        }
      }
    }
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}…';
}
