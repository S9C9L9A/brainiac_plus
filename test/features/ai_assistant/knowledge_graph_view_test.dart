import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph.dart';
import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph_controller.dart';
import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeds the graph controller with a fixed graph and no persistence.
class SeededGraph extends KnowledgeGraphController {
  SeededGraph(KnowledgeGraph graph) : super() {
    state = graph;
  }
}

Widget host(KnowledgeGraph graph) {
  return ProviderScope(
    overrides: [
      knowledgeGraphProvider.overrideWith((ref) => SeededGraph(graph)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 800, height: 600, child: KnowledgeGraphView()),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there is no memory', (tester) async {
    await tester.pumpWidget(host(KnowledgeGraph()));
    expect(find.text('MEMORY EMPTY'), findsOneWidget);
  });

  testWidgets('renders a chip per node with its label', (tester) async {
    final g = KnowledgeGraph();
    g.upsertNode(
      const GraphNode(id: 'task:1', type: NodeType.task, label: 'build app'),
    );
    g.upsertNode(
      const GraphNode(id: 'file:a', type: NodeType.file, label: 'main.dart'),
    );
    g.addEdge('task:1', 'file:a', EdgeRelation.wrote);

    await tester.pumpWidget(host(g));

    expect(find.text('build app'), findsOneWidget);
    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('MEMORY EMPTY'), findsNothing);
  });
}
