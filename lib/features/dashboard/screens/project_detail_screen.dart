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

/// One-page project workspace: the source-map constellation and git history
/// on top, with a collapsible run console docked at the bottom. A target
/// selector chooses whether to run on Linux, Web or Android.
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

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  RunTarget _target = RunTarget.linux;
  bool _consoleOpen = false;

  WorkspaceProject get project => widget.project;

  @override
  void initState() {
    super.initState();
    if (widget.autoRunTarget != null) {
      _target = widget.autoRunTarget!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  void _run() {
    final command = ProjectRunner.commandFor(project.path, target: _target);
    ref.read(projectRunProvider(project.path).notifier).start(command);
    setState(() => _consoleOpen = true);
  }

  /// Launches the already-built artifact for the selected target, no rebuild.
  void _fastLaunch() {
    final command = ProjectRunner.fastLaunchCommand(project.path, _target);
    if (command == null) return;
    ref.read(projectRunProvider(project.path).notifier).start(command);
    setState(() => _consoleOpen = true);
  }

  void _stop() => ref.read(projectRunProvider(project.path).notifier).stop();

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(projectRunProvider(project.path));

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _actionBar(run.running),
              // One page: overview fills the space, the console docks at the
              // bottom and expands/collapses on a click.
              Expanded(child: _body()),
              _ConsoleDock(
                open: _consoleOpen,
                running: run.running,
                hasOutput: run.output.isNotEmpty,
                onToggle: () => setState(() => _consoleOpen = !_consoleOpen),
                onStop: _stop,
                onClear: () =>
                    ref.read(projectRunProvider(project.path).notifier).clear(),
                child: _ConsoleLog(path: project.path),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final graph = ref.watch(projectGraphProvider(project.path));
    final graphPanel = HudPanel(
      title: 'SOURCE MAP',
      icon: Icons.hub_outlined,
      expandChild: true,
      child: GraphConstellation(graph: graph),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _GitSection(path: project.path),
              const SizedBox(height: 16),
              SizedBox(height: 340, child: graphPanel),
            ],
          );
        }
        // Desktop: git rail on the left, source map as the hero on the right.
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: _GitSection(path: project.path),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: graphPanel),
            ],
          ),
        );
      },
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
          if (running)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: HudTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop'),
            )
          else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: HudTheme.background,
              ),
              onPressed: _run,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Run'),
            ),
            // Fast launch: opens the already-built artifact (no rebuild). The
            // icon reflects the selected target so it's clear where it opens.
            _FastLaunchButton(
              target: _target,
              available: ProjectRunner.canFastLaunch(project.path, _target),
              onPressed: _fastLaunch,
            ),
          ],
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
          PopupMenuButton<String>(
            tooltip: 'More',
            color: HudTheme.panel,
            icon: const Icon(Icons.more_horiz, color: Colors.white70),
            onSelected: (value) {
              switch (value) {
                case 'folder':
                  ShellService().executeCommand('xdg-open "${project.path}"');
                case 'clean':
                  ref
                      .read(projectRunProvider(project.path).notifier)
                      .start(ProjectRunner.cleanCommand(project.path));
                  setState(() => _consoleOpen = true);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'folder',
                child: _MenuRow(Icons.folder_open, 'Open folder'),
              ),
              PopupMenuItem(
                value: 'clean',
                child: _MenuRow(Icons.cleaning_services, 'Clean build'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A menu row: icon + label, in the HUD style.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HudTheme.cyan.withValues(alpha: 0.8)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

/// IDE-style console dock: a slim toggle bar that expands/collapses the live
/// run log with a click. Auto-opens when a run starts.
class _ConsoleDock extends StatelessWidget {
  final bool open;
  final bool running;
  final bool hasOutput;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final Widget child;

  const _ConsoleDock({
    required this.open,
    required this.running,
    required this.hasOutput,
    required this.onToggle,
    required this.onStop,
    required this.onClear,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: HudTheme.cyan.withValues(alpha: 0.18)),
        ),
        color: HudTheme.panel.withValues(alpha: 0.55),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    size: 15,
                    color: HudTheme.cyan.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CONSOLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: running ? HudTheme.cyan : Colors.white24,
                      boxShadow: running
                          ? [
                              BoxShadow(
                                color: HudTheme.cyan.withValues(alpha: 0.7),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    running ? 'running' : 'idle',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  if (running)
                    _barAction(
                      Icons.stop_rounded,
                      'Stop',
                      HudTheme.danger,
                      onStop,
                    )
                  else if (hasOutput)
                    _barAction(
                      Icons.clear_all,
                      'Clear',
                      Colors.white54,
                      onClear,
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: open
                ? SizedBox(height: 300, child: child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _barAction(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }
}

/// Fast-launch control: opens the already-built app for [target] with no
/// rebuild. Its icon identifies the environment; disabled (with a hint) when
/// nothing is built for that target yet.
class _FastLaunchButton extends StatelessWidget {
  final RunTarget target;
  final bool available;
  final VoidCallback onPressed;

  const _FastLaunchButton({
    required this.target,
    required this.available,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: available ? HudTheme.cyanGlow : Colors.white38,
        side: BorderSide(
          color: (available ? HudTheme.cyan : Colors.white24).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      onPressed: available ? onPressed : null,
      icon: Icon(target.icon, size: 16),
      label: const Text('Launch (fast)'),
    );
    return Tooltip(
      message: available
          ? 'Launch the built ${target.label} app instantly'
          : 'No ${target.label} build yet — press Run first to build it',
      child: button,
    );
  }
}

/// Live run log for a project. Streams the process output and auto-scrolls.
/// The header/controls live in the [_ConsoleDock] bar; this is just the log.
class _ConsoleLog extends ConsumerStatefulWidget {
  final String path;
  const _ConsoleLog({required this.path});

  @override
  ConsumerState<_ConsoleLog> createState() => _ConsoleLogState();
}

class _ConsoleLogState extends ConsumerState<_ConsoleLog> {
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.12)),
      ),
      child: run.output.isEmpty
          ? Center(
              child: Text(
                run.running
                    ? 'Starting…'
                    : 'Press Run to launch this project and watch its log here.',
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
