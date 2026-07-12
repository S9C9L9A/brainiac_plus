import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/hud/hud_background.dart';
import '../../dashboard/widgets/hud/hud_theme.dart';
import 'knowledge_graph_controller.dart';
import 'knowledge_graph_view.dart';

/// Full-screen view of the assistant's knowledge graph — the memory of every
/// task it has run and what each touched.
class KnowledgeGraphScreen extends ConsumerWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(knowledgeGraphProvider);

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context, graph.nodes.length, graph.edges.length),
              const _Legend(),
              const Expanded(child: KnowledgeGraphView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int nodes, int edges) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: HudTheme.cyan.withValues(alpha: 0.8),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'KNOWLEDGE GRAPH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            '$nodes NODES · $edges LINKS',
            style: TextStyle(
              color: HudTheme.cyan.withValues(alpha: 0.6),
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 20,
        children: [
          item(HudTheme.cyan, 'TASK'),
          item(const Color(0xFF4ADE80), 'FILE'),
          item(HudTheme.amber, 'COMMAND'),
        ],
      ),
    );
  }
}
