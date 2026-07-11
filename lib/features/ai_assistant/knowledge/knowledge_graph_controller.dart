import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/agentic_runner.dart';
import 'graph_recorder.dart';
import 'knowledge_graph.dart';

/// Holds the shared knowledge graph and persists it to disk, so the memory of
/// what agents have done survives restarts. Every agentic run is recorded here
/// through [recordRun].
class KnowledgeGraphController extends StateNotifier<KnowledgeGraph> {
  /// File the graph is persisted to; null disables persistence (tests).
  final String? persistPath;

  KnowledgeGraphController({this.persistPath}) : super(KnowledgeGraph()) {
    _load();
  }

  void _load() {
    final path = persistPath;
    if (path == null) return;
    try {
      final file = File(path);
      if (!file.existsSync()) return;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      state = KnowledgeGraph.fromJson(json);
    } catch (e) {
      debugPrint('[KnowledgeGraph] load failed: $e');
    }
  }

  void recordRun(String taskId, String request, List<AgentStep> steps) {
    // The graph is mutated in place; copy it so listeners see a new instance.
    final next = KnowledgeGraph.fromJson(state.toJson());
    GraphRecorder.recordRun(
      next,
      taskId: taskId,
      request: request,
      steps: steps,
    );
    state = next;
    _save();
  }

  void _save() {
    final path = persistPath;
    if (path == null) return;
    try {
      final file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[KnowledgeGraph] save failed: $e');
    }
  }
}

final knowledgeGraphProvider =
    StateNotifierProvider<KnowledgeGraphController, KnowledgeGraph>((ref) {
      return KnowledgeGraphController(
        persistPath: '${Directory.current.path}/.brainiac/knowledge_graph.json',
      );
    });
