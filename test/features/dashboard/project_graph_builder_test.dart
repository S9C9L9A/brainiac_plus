import 'dart:io';

import 'package:brainiac_plus/features/ai_assistant/knowledge/knowledge_graph.dart';
import 'package:brainiac_plus/features/dashboard/services/project_graph_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory proj;

  setUp(() {
    proj = Directory.systemTemp.createTempSync('proj_graph');
    Directory('${proj.path}/lib/widgets').createSync(recursive: true);
    File('${proj.path}/lib/main.dart').writeAsStringSync('void main() {}');
    File('${proj.path}/lib/widgets/button.dart').writeAsStringSync('// btn');
    File('${proj.path}/pubspec.yaml').writeAsStringSync('name: demo');
  });

  tearDown(() => proj.deleteSync(recursive: true));

  test('builds a project node linked to each dart file under lib', () {
    final g = ProjectGraphBuilder.build(proj.path, name: 'demo');

    final project = g.nodesOfType(NodeType.project);
    expect(project, hasLength(1));
    expect(project.single.label, 'demo');

    final files = g.nodesOfType(NodeType.file).map((n) => n.label).toSet();
    expect(files, containsAll(['main.dart', 'button.dart']));

    // Every file hangs off the project node.
    final neighbours = g.neighbors(project.single.id).map((n) => n.label);
    expect(neighbours, containsAll(['main.dart', 'button.dart']));
  });

  test('caps the number of file nodes', () {
    for (var i = 0; i < 60; i++) {
      File('${proj.path}/lib/f$i.dart').writeAsStringSync('//');
    }
    final g = ProjectGraphBuilder.build(proj.path, name: 'demo', maxFiles: 20);
    expect(g.nodesOfType(NodeType.file).length, lessThanOrEqualTo(20));
  });

  test('a project with no lib yields just the project node', () {
    final empty = Directory.systemTemp.createTempSync('empty_proj');
    addTearDown(() => empty.deleteSync(recursive: true));

    final g = ProjectGraphBuilder.build(empty.path, name: 'empty');
    expect(g.nodesOfType(NodeType.project), hasLength(1));
    expect(g.nodesOfType(NodeType.file), isEmpty);
  });
}
