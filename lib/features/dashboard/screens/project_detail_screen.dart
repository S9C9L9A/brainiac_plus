import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shell_service.dart';
import '../../ai_assistant/knowledge/knowledge_graph_view.dart';
import '../controllers/project_detail_provider.dart';
import '../services/project_git_service.dart';
import '../services/workspace_scanner.dart';
import '../widgets/hud/hud_background.dart';
import '../widgets/hud/hud_panel.dart';
import '../widgets/hud/hud_theme.dart';
import '../widgets/hud/run_project.dart';

/// Rich project view: navigate the source as a constellation, read the recent
/// git history and pending changes, and jump into working on it. Replaces the
/// old "just open the folder" behaviour.
class ProjectDetailScreen extends ConsumerWidget {
  final WorkspaceProject project;

  /// Called when the user chooses to work on this project in the assistant.
  final void Function(WorkspaceProject project)? onWorkInChat;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    this.onWorkInChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Built once and cached per path — never on the widget build path.
    final graph = ref.watch(projectGraphProvider(project.path));

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              _actions(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    // Fixed-height graph panel (bounded → the constellation's
                    // LayoutBuilder always gets a finite canvas).
                    Widget graphPanel(double height) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: height,
                        child: HudPanel(
                          title: 'SOURCE MAP',
                          icon: Icons.hub_outlined,
                          expandChild: true,
                          child: GraphConstellation(graph: graph),
                        ),
                      ),
                    );

                    if (!wide) {
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _GitSection(path: project.path),
                          ),
                          graphPanel(360),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: _GitSection(path: project.path),
                          ),
                        ),
                        // Fill the available height with the graph panel;
                        // clamp so a tiny window never yields a negative box.
                        Expanded(
                          child: graphPanel(
                            (constraints.maxHeight - 32).clamp(
                              160,
                              double.infinity,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: HudTheme.cyan.withValues(alpha: 0.8),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Icons.flutter_dash, color: HudTheme.cyanGlow, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  project.description ?? 'Flutter project',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: HudTheme.background,
            ),
            onPressed: () => runProject(context, project.path),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Run'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: HudTheme.cyan.withValues(alpha: 0.9),
              foregroundColor: HudTheme.background,
            ),
            onPressed: onWorkInChat == null
                ? null
                : () {
                    onWorkInChat!(project);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Work on this in chat'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () =>
                ShellService().executeCommand('xdg-open "${project.path}"'),
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Open folder'),
          ),
        ],
      ),
    );
  }
}

class _GitSection extends ConsumerWidget {
  final String path;
  const _GitSection({required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commits = ref.watch(projectCommitsProvider(path));
    final changes = ref.watch(projectChangesProvider(path));

    return Column(
      children: [
        HudPanel(
          title: 'RECENT COMMITS',
          icon: Icons.commit,
          child: commits.when(
            data: (list) => list.isEmpty
                ? _dim('Not a git repository, or no commits yet.')
                : Column(
                    children: [for (final c in list) _CommitRow(commit: c)],
                  ),
            loading: () => _dim('Reading history…'),
            error: (_, _) => _dim('History unavailable.'),
          ),
        ),
        const SizedBox(height: 16),
        HudPanel(
          title: 'PENDING CHANGES',
          icon: Icons.edit_note,
          trailing: changes.maybeWhen(
            data: (l) => Text(
              '${l.length}',
              style: TextStyle(
                color: HudTheme.amber.withValues(alpha: 0.8),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          child: changes.when(
            data: (list) => list.isEmpty
                ? _dim('Working tree clean.')
                : Column(
                    children: [for (final c in list) _ChangeRow(change: c)],
                  ),
            loading: () => _dim('Checking status…'),
            error: (_, _) => _dim('Status unavailable.'),
          ),
        ),
      ],
    );
  }

  Widget _dim(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
      ),
    ),
  );
}

class _CommitRow extends StatelessWidget {
  final GitCommit commit;
  const _CommitRow({required this.commit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commit.hash,
            style: const TextStyle(
              color: HudTheme.cyan,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '${commit.author} · ${commit.date}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final GitChange change;
  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 26,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: HudTheme.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change.code,
              style: const TextStyle(
                color: HudTheme.amber,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              change.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
