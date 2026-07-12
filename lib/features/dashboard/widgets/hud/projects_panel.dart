import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_assistant/controllers/ai_chat_controller.dart';
import '../../controllers/projects_provider.dart';
import '../../screens/project_detail_screen.dart';
import '../../services/workspace_scanner.dart';
import 'hud_panel.dart';
import 'hud_theme.dart';

/// Dashboard panel listing the apps the assistant has built in its workspace.
/// Tapping one opens a HUD sheet with its details and an "open folder" action.
class ProjectsPanel extends ConsumerWidget {
  const ProjectsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(workspaceProjectsProvider);

    return HudPanel(
      title: 'BUILT APPS',
      icon: Icons.apps,
      trailing: projects.maybeWhen(
        data: (list) => Text(
          '${list.length}',
          style: TextStyle(
            color: HudTheme.cyan.withValues(alpha: 0.7),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
      child: projects.when(
        data: (list) => list.isEmpty
            ? const _EmptyRow(
                'No apps yet — ask the assistant to build one in Agent mode.',
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final p in list) _ProjectCard(project: p)],
              ),
        loading: () => const _EmptyRow('Scanning workspace…'),
        error: (_, _) => const _EmptyRow('Workspace unavailable.'),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final WorkspaceProject project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            project: project,
            onWorkInChat: (p) =>
                ref.read(activeProjectProvider.notifier).state = p.path,
          ),
        ),
      ),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: HudTheme.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.flutter_dash,
                color: HudTheme.cyanGlow,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    project.description ?? 'Flutter app',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
      ),
    );
  }
}
