import 'package:flutter/material.dart';

import '../../models/agent_task.dart';
import '../../services/agent_action_executor.dart';

/// Horizontal strip of tappable chips for the actions suggested by the
/// multi-agent pipeline, so the assistant can *operate* the app instead of
/// only talking about it.
///
/// Navigation actions push their mapped route; state actions (e.g.
/// refresh_metrics) are delegated to [onStateAction], whose owner has
/// provider access — they are hidden when no callback is supplied. Renders
/// nothing when no action is executable.
class SuggestedActionsBar extends StatelessWidget {
  final List<AgentAction> actions;

  /// Invoked for chips whose action mutates state instead of navigating.
  final void Function(AgentAction action)? onStateAction;

  const SuggestedActionsBar({
    super.key,
    required this.actions,
    this.onStateAction,
  });

  static final _executor = AgentActionExecutor();

  bool _isExecutable(AgentAction action) {
    switch (_executor.kindOf(action)) {
      case AgentActionKind.navigation:
        return true;
      case AgentActionKind.state:
        return onStateAction != null;
      case AgentActionKind.unsupported:
        return false;
    }
  }

  void _execute(BuildContext context, AgentAction action) {
    switch (_executor.kindOf(action)) {
      case AgentActionKind.navigation:
        Navigator.pushNamed(
          context,
          _executor.routeFor(action)!,
          arguments: action.params.isEmpty ? null : action.params,
        );
      case AgentActionKind.state:
        onStateAction?.call(action);
      case AgentActionKind.unsupported:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final executable = actions.where(_isExecutable).toList();
    if (executable.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final action in executable)
            ActionChip(
              label: Text(action.label),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              avatar: Icon(
                _executor.kindOf(action) == AgentActionKind.state
                    ? Icons.refresh_rounded
                    : Icons.play_arrow_rounded,
                size: 16,
                color: Colors.white70,
              ),
              onPressed: () => _execute(context, action),
            ),
        ],
      ),
    );
  }
}
