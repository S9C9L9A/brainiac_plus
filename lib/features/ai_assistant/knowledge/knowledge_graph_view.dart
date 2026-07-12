import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/hud/hud_theme.dart';
import 'graph_layout.dart';
import 'knowledge_graph.dart';
import 'knowledge_graph_controller.dart';

/// Renders the shared knowledge graph as a Jarvis-style constellation: task
/// nodes glow at the core, the files and commands they produced orbit outside,
/// and relations are drawn as light links between them. Makes the assistant's
/// otherwise-invisible memory tangible.
class KnowledgeGraphView extends ConsumerWidget {
  const KnowledgeGraphView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(knowledgeGraphProvider);
    if (graph.nodes.isEmpty) return const _EmptyState();
    return GraphConstellation(graph: graph);
  }
}

/// Renders any [KnowledgeGraph] as the HUD constellation. Reused by the agent
/// memory view and the per-project graph.
class GraphConstellation extends StatelessWidget {
  final KnowledgeGraph graph;
  const GraphConstellation({super.key, required this.graph});

  @override
  Widget build(BuildContext context) {
    final positions = GraphLayout.positions(graph);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        const pad = 40.0;
        Offset place(Offset norm) => Offset(
          pad + norm.dx * (size.width - 2 * pad),
          pad + norm.dy * (size.height - 2 * pad),
        );

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EdgePainter(
                  edges: graph.edges,
                  points: {
                    for (final e in positions.entries) e.key: place(e.value),
                  },
                ),
              ),
            ),
            for (final node in graph.nodes)
              if (positions[node.id] != null)
                _NodeChip(node: node, center: place(positions[node.id]!)),
          ],
        );
      },
    );
  }
}

Color _nodeColor(NodeType type) {
  switch (type) {
    case NodeType.task:
      return HudTheme.cyan;
    case NodeType.project:
      return HudTheme.cyanGlow;
    case NodeType.file:
      return const Color(0xFF4ADE80); // green
    case NodeType.command:
      return HudTheme.amber;
    default:
      return Colors.white54;
  }
}

IconData _nodeIcon(NodeType type) {
  switch (type) {
    case NodeType.task:
      return Icons.bolt;
    case NodeType.project:
      return Icons.flutter_dash;
    case NodeType.file:
      return Icons.description_outlined;
    case NodeType.command:
      return Icons.terminal;
    default:
      return Icons.circle;
  }
}

class _NodeChip extends StatelessWidget {
  final GraphNode node;
  final Offset center;

  const _NodeChip({required this.node, required this.center});

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(node.type);
    const chipWidth = 132.0;
    return Positioned(
      left: center.dx - chipWidth / 2,
      top: center.dy - 18,
      width: chipWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: HudTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12),
              ],
            ),
            child: Icon(_nodeIcon(node.type), color: color, size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            node.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: 'monospace',
              fontSize: 10,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<GraphEdge> edges;
  final Map<String, Offset> points;

  _EdgePainter({required this.edges, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = HudTheme.cyan.withValues(alpha: 0.28);
    for (final e in edges) {
      final from = points[e.from];
      final to = points[e.to];
      if (from == null || to == null) continue;
      canvas.drawLine(from, to, paint);
      // A small node of light at the target end.
      canvas.drawCircle(
        to,
        2,
        Paint()..color = HudTheme.cyanGlow.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edges != edges || old.points != points;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 56,
            color: HudTheme.cyan.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'MEMORY EMPTY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Run an agent task and its files and\ncommands will map here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
