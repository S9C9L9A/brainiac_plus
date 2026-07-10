import 'package:flutter/material.dart';

import '../../models/agent_task.dart';
import '../../services/agent_action_executor.dart';

/// Horizontal strip of tappable chips for the actions suggested by the
/// multi-agent pipeline. Tapping a chip navigates to the mapped screen, so
/// the assistant can *operate* the app instead of only talking about it.
/// Renders nothing when no suggested action is navigable.
class SuggestedActionsBar extends StatelessWidget {
  final List<AgentAction> actions;

  const SuggestedActionsBar({super.key, required this.actions});

  static final _executor = AgentActionExecutor();

  @override
  Widget build(BuildContext context) {
    final navigable = actions.where(_executor.isNavigable).toList();
    if (navigable.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final action in navigable)
            ActionChip(
              label: Text(action.label),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              avatar: const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: Colors.white70,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, _executor.routeFor(action)!),
            ),
        ],
      ),
    );
  }
}
