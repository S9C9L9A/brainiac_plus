import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KnowledgeGraph — nodes and edges', () {
    test('adding a node is idempotent by id and merges props', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(
          id: 'file:rainbow/main.dart',
          type: NodeType.file,
          label: 'main.dart',
        ),
      );
      g.upsertNode(
        const GraphNode(
          id: 'file:rainbow/main.dart',
          type: NodeType.file,
          label: 'main.dart',
          props: {'lines': '12'},
        ),
      );

      expect(g.nodes, hasLength(1));
      expect(g.nodeById('file:rainbow/main.dart')!.props['lines'], '12');
    });

    test('edges connect existing nodes and are deduplicated', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(id: 'task:1', type: NodeType.task, label: 't'),
      );
      g.upsertNode(
        const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'),
      );

      g.addEdge('task:1', 'file:a', EdgeRelation.wrote);
      g.addEdge('task:1', 'file:a', EdgeRelation.wrote);

      expect(g.edges, hasLength(1));
    });

    test('neighbors returns nodes reachable from a node', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(id: 'task:1', type: NodeType.task, label: 't'),
      );
      g.upsertNode(
        const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'),
      );
      g.upsertNode(
        const GraphNode(id: 'cmd:x', type: NodeType.command, label: 'x'),
      );
      g.addEdge('task:1', 'file:a', EdgeRelation.wrote);
      g.addEdge('task:1', 'cmd:x', EdgeRelation.ran);

      final ids = g.neighbors('task:1').map((n) => n.id).toSet();
      expect(ids, {'file:a', 'cmd:x'});
    });

    test('nodesOfType filters by type', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'),
      );
      g.upsertNode(
        const GraphNode(id: 'file:b', type: NodeType.file, label: 'b'),
      );
      g.upsertNode(
        const GraphNode(id: 'task:1', type: NodeType.task, label: 't'),
      );

      expect(g.nodesOfType(NodeType.file), hasLength(2));
    });
  });

  group('KnowledgeGraph — persistence', () {
    test('round-trips through JSON', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(id: 'task:1', type: NodeType.task, label: 't'),
      );
      g.upsertNode(
        const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'),
      );
      g.addEdge('task:1', 'file:a', EdgeRelation.wrote);

      final restored = KnowledgeGraph.fromJson(g.toJson());

      expect(restored.nodes, hasLength(2));
      expect(restored.edges, hasLength(1));
      expect(restored.neighbors('task:1').single.id, 'file:a');
    });
  });
}
