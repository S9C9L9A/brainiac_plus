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
/// memory view and the per-project graph. [onNodeTap] fires when a node is
/// clicked (e.g. to open a file preview).
class GraphConstellation extends StatelessWidget {
  final KnowledgeGraph graph;
  final void Function(GraphNode node)? onNodeTap;
  final String? selectedNodeId;

  const GraphConstellation({
    super.key,
    required this.graph,
    this.onNodeTap,
    this.selectedNodeId,
  });

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
                _NodeChip(
                  node: node,
                  center: place(positions[node.id]!),
                  selected: node.id == selectedNodeId,
                  onTap: onNodeTap == null ? null : () => onNodeTap!(node),
                ),
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
    case NodeType.config:
      return HudTheme.amber; // config/platform files stand out
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
    case NodeType.config:
      return Icons.settings_outlined;
    case NodeType.command:
      return Icons.terminal;
    default:
      return Icons.circle;
  }
}

class _NodeChip extends StatelessWidget {
  final GraphNode node;
  final Offset center;
  final bool selected;
  final VoidCallback? onTap;

  const _NodeChip({
    required this.node,
    required this.center,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(node.type);
    const chipWidth = 132.0;
    return Positioned(
      left: center.dx - chipWidth / 2,
      top: center.dy - 18,
      width: chipWidth,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: selected ? 30 : 26,
              height: selected ? 30 : 26,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.25)
                    : HudTheme.background,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: selected ? 2.5 : 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: selected ? 0.9 : 0.6),
                    blurRadius: selected ? 18 : 12,
                  ),
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
                color: Colors.white.withValues(alpha: selected ? 1 : 0.85),
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
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
