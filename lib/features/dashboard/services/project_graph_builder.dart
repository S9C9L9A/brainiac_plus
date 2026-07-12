import 'dart:io';

import '../../ai_assistant/knowledge/knowledge_graph.dart';

/// Builds a knowledge graph of a project's source: a central project node with
/// every Dart file under lib/ hanging off it. Lets the project be navigated as
/// a constellation instead of a folder tree.
class ProjectGraphBuilder {
  ProjectGraphBuilder._();

  static KnowledgeGraph build(
    String projectPath, {
    required String name,
    int maxFiles = 40,
  }) {
    final graph = KnowledgeGraph();
    final projectId = 'project:$name';
    graph.upsertNode(
      GraphNode(id: projectId, type: NodeType.project, label: name),
    );

    final lib = Directory('$projectPath/lib');
    if (!lib.existsSync()) return graph;

    // Recursive listing can throw on permission errors or broken symlinks —
    // never let scanning a project take the whole view down.
    List<File> files;
    try {
      files =
          lib
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
    } catch (_) {
      return graph;
    }

    for (final file in files.take(maxFiles)) {
      final rel = file.path.substring(projectPath.length + 1);
      final id = 'file:$rel';
      graph.upsertNode(
        GraphNode(
          id: id,
          type: NodeType.file,
          label: file.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
          props: {'path': file.path},
        ),
      );
      graph.addEdge(projectId, id, EdgeRelation.partOf);
    }
    return graph;
  }
}
