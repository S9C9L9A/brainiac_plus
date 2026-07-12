import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shell_service.dart';
import '../../ai_assistant/knowledge/knowledge_graph_view.dart';
import '../controllers/project_detail_provider.dart';
import '../controllers/project_run_controller.dart';
import '../services/project_git_service.dart';
import '../services/project_runner.dart';
import '../services/workspace_scanner.dart';
import '../widgets/hud/hud_background.dart';
import '../widgets/hud/hud_panel.dart';
import '../widgets/hud/hud_theme.dart';

/// Rich project view: an Overview tab (source-map constellation + git history)
/// and a Console tab with a live run log. A target selector chooses whether to
/// run on Linux, Web or Android.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final WorkspaceProject project;

  /// Called when the user chooses to work on this project in the assistant.
  final void Function(WorkspaceProject project)? onWorkInChat;

  /// When set, the project is launched on this target as soon as the screen
  /// opens (used by the dashboard's quick-run button).
  final RunTarget? autoRunTarget;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    this.onWorkInChat,
    this.autoRunTarget,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  RunTarget _target = RunTarget.linux;

  WorkspaceProject get project => widget.project;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    if (widget.autoRunTarget != null) {
      _target = widget.autoRunTarget!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _run() {
    final command = ProjectRunner.commandFor(project.path, target: _target);
    ref.read(projectRunProvider(project.path).notifier).start(command);
    _tabs.animateTo(1); // jump to the Console
  }

  void _stop() => ref.read(projectRunProvider(project.path).notifier).stop();

  @override
  Widget build(BuildContext context) {
    final running = ref.watch(projectRunProvider(project.path)).running;

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _actionBar(running),
              TabBar(
                controller: _tabs,
                indicatorColor: HudTheme.cyan,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'CONSOLE'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overview(),
                    _ConsoleTab(path: project.path),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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

  Widget _actionBar(bool running) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Run target selector.
          SegmentedButton<RunTarget>(
            segments: [
              for (final t in RunTarget.values)
                ButtonSegment(
                  value: t,
                  icon: Icon(t.icon, size: 15),
                  label: Text(t.label, style: const TextStyle(fontSize: 12)),
                ),
            ],
            selected: {_target},
            onSelectionChanged: running
                ? null
                : (s) => setState(() => _target = s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? HudTheme.background
                    : Colors.white70,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? HudTheme.cyan
                    : Colors.transparent,
              ),
            ),
          ),
          running
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HudTheme.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop'),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: HudTheme.background,
                  ),
                  onPressed: _run,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Run'),
                ),
          if (widget.onWorkInChat != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                widget.onWorkInChat!(project);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Work in chat'),
            ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            onPressed: () =>
                ShellService().executeCommand('xdg-open "${project.path}"'),
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Folder'),
          ),
        ],
      ),
    );
  }

  Widget _overview() {
    final graph = ref.watch(projectGraphProvider(project.path));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _GitSection(path: project.path),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: HudPanel(
            title: 'SOURCE MAP',
            icon: Icons.hub_outlined,
            expandChild: true,
            child: GraphConstellation(graph: graph),
          ),
        ),
      ],
    );
  }
}

/// Live run log for a project. Streams the process output and auto-scrolls.
class _ConsoleTab extends ConsumerStatefulWidget {
  final String path;
  const _ConsoleTab({required this.path});

  @override
  ConsumerState<_ConsoleTab> createState() => _ConsoleTabState();
}

class _ConsoleTabState extends ConsumerState<_ConsoleTab> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(projectRunProvider(widget.path));

    // Auto-scroll to the newest output.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusDot(run.running),
              const SizedBox(width: 8),
              Text(
                run.running ? 'RUNNING' : 'IDLE',
                style: TextStyle(
                  color: run.running ? HudTheme.cyan : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (run.output.isNotEmpty && !run.running)
                TextButton(
                  onPressed: () => ref
                      .read(projectRunProvider(widget.path).notifier)
                      .clear(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                  child: const Text('CLEAR', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HudTheme.cyan.withValues(alpha: 0.15),
                ),
              ),
              child: run.output.isEmpty
                  ? Center(
                      child: Text(
                        run.running
                            ? 'Starting…'
                            : 'Press Run to launch this project\nand watch its log here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      child: SelectableText(
                        run.output,
                        style: const TextStyle(
                          color: Color(0xFFB6F0C4),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(bool running) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: running ? HudTheme.cyan : Colors.white24,
      shape: BoxShape.circle,
      boxShadow: running
          ? [
              BoxShadow(
                color: HudTheme.cyan.withValues(alpha: 0.7),
                blurRadius: 8,
              ),
            ]
          : null,
    ),
  );
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
