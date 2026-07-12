import 'package:brainiac_plus/features/ai_assistant/knowledge/graph_layout.dart';
import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph.dart';
import 'package:flutter_test/flutter_test.dart';

KnowledgeGraph sampleGraph() {
  final g = KnowledgeGraph();
  g.upsertNode(const GraphNode(id: 'task:1', type: NodeType.task, label: 't1'));
  g.upsertNode(const GraphNode(id: 'task:2', type: NodeType.task, label: 't2'));
  g.upsertNode(const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'));
  g.upsertNode(
    const GraphNode(id: 'command:x', type: NodeType.command, label: 'x'),
  );
  g.addEdge('task:1', 'file:a', EdgeRelation.wrote);
  g.addEdge('task:2', 'command:x', EdgeRelation.ran);
  return g;
}

void main() {
  group('GraphLayout.positions', () {
    test('places every node within the unit square', () {
      final pos = GraphLayout.positions(sampleGraph());
      expect(pos.keys, hasLength(4));
      for (final p in pos.values) {
        expect(p.dx, inInclusiveRange(0, 1));
        expect(p.dy, inInclusiveRange(0, 1));
      }
    });

    test('is deterministic for the same graph', () {
      final a = GraphLayout.positions(sampleGraph());
      final b = GraphLayout.positions(sampleGraph());
      expect(a, b);
    });

    test('distinct nodes get distinct positions', () {
      final pos = GraphLayout.positions(sampleGraph());
      final points = pos.values.toSet();
      expect(points, hasLength(pos.length));
    });

    test('task nodes sit nearer the centre than artifact nodes', () {
      final pos = GraphLayout.positions(sampleGraph());
      double dist(String id) {
        final p = pos[id]!;
        final dx = p.dx - 0.5, dy = p.dy - 0.5;
        return dx * dx + dy * dy;
      }

      expect(dist('task:1'), lessThan(dist('file:a')));
      expect(dist('task:2'), lessThan(dist('command:x')));
    });

    test('an empty graph yields an empty layout', () {
      expect(GraphLayout.positions(KnowledgeGraph()), isEmpty);
    });

    test('project nodes anchor the centre like tasks', () {
      final g = KnowledgeGraph();
      g.upsertNode(
        const GraphNode(
          id: 'project:app',
          type: NodeType.project,
          label: 'app',
        ),
      );
      g.upsertNode(
        const GraphNode(id: 'file:a', type: NodeType.file, label: 'a'),
      );
      final pos = GraphLayout.positions(g);
      double d(String id) {
        final p = pos[id]!;
        return (p.dx - 0.5) * (p.dx - 0.5) + (p.dy - 0.5) * (p.dy - 0.5);
      }

      expect(d('project:app'), lessThan(d('file:a')));
    });
  });
}
