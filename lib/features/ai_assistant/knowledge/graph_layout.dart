import 'dart:math' as math;
import 'dart:ui';

import 'knowledge_graph.dart';

/// Deterministic radial layout for the knowledge graph constellation: task
/// nodes form an inner core ring, everything they produced (files, commands)
/// orbits on an outer ring. Positions are normalized to the unit square, so
/// the view can scale them to any canvas.
///
/// A pure function on purpose — the visual is a projection of the graph, and
/// keeping the placement testable and stable matters more than a physics sim.
class GraphLayout {
  GraphLayout._();

  static const _center = Offset(0.5, 0.5);
  static const _innerRadius = 0.20;
  static const _outerRadius = 0.42;

  static Map<String, Offset> positions(KnowledgeGraph graph) {
    final nodes = graph.nodes;
    if (nodes.isEmpty) return const {};

    // Stable ordering so the layout never jumps between rebuilds.
    final tasks = nodes.where((n) => n.type == NodeType.task).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final others = nodes.where((n) => n.type != NodeType.task).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final result = <String, Offset>{};
    _placeRing(tasks, _innerRadius, result);
    _placeRing(others, _outerRadius, result);

    // A single node reads better dead-centre than clinging to a ring.
    if (nodes.length == 1) {
      result[nodes.first.id] = _center;
    }
    return result;
  }

  static void _placeRing(
    List<GraphNode> ring,
    double radius,
    Map<String, Offset> out,
  ) {
    if (ring.isEmpty) return;
    final n = ring.length;
    for (var i = 0; i < n; i++) {
      // Offset the two rings by a half-step so nodes don't line up radially.
      final phase = radius == _outerRadius ? 0.5 : 0.0;
      final angle = 2 * math.pi * (i + phase) / n - math.pi / 2;
      out[ring[i].id] = Offset(
        _center.dx + radius * math.cos(angle),
        _center.dy + radius * math.sin(angle),
      );
    }
  }
}
