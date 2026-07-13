import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shell_service.dart';
import '../../ai_assistant/controllers/ai_chat_controller.dart';
import '../../ai_assistant/knowledge/knowledge_graph.dart';
import '../../ai_assistant/knowledge/knowledge_graph_view.dart';
import '../../ai_assistant/widgets/chat/ai_chat_panel.dart';
import '../controllers/project_detail_provider.dart';
import '../controllers/project_run_controller.dart';
import '../services/project_git_service.dart';
import '../services/project_runner.dart';
import '../services/workspace_scanner.dart';
import '../widgets/hud/hud_background.dart';
import '../widgets/hud/hud_panel.dart';
import '../widgets/hud/hud_theme.dart';
import '../widgets/panels/floating_panel.dart';
import '../widgets/panels/resizable_split.dart';

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

  /// Desktop: whether the context rail (source map + git) is shown inline.
  bool _railOpen = true;

  /// Narrow screens: whether the context overlay drawer is open.
  bool _drawerOpen = false;

  /// The file node currently open in the code panel, if any.
  GraphNode? _selectedFile;

  /// Ids of panels the user has popped out into floating windows.
  final Set<String> _floating = {};

  static const _pSourceMap = 'sourcemap';
  static const _pCode = 'code';

  WorkspaceProject get project => widget.project;

  /// Below this width the context rail moves to an overlay drawer so the chat
  /// keeps the full width — it's the primary surface here.
  static const _wideBreakpoint = 980.0;

  bool get _isWide => MediaQuery.of(context).size.width >= _wideBreakpoint;

  /// Toggles the project context — inline rail on desktop, overlay drawer on
  /// narrow screens — so the assistant can go full-width for focused work.
  void _toggleContext() {
    setState(() {
      if (_isWide) {
        _railOpen = !_railOpen;
      } else {
        _drawerOpen = !_drawerOpen;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scope the always-present assistant to this project: its file/command
      // tools and briefing now target this folder.
      ref.read(activeProjectProvider.notifier).state = project.path;
      if (widget.autoRunTarget != null) {
        _target = widget.autoRunTarget!;
        _run();
      }
    });
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
    final wide = _isWide;

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _header(wide),
                  _actionBar(run.running),
                  // The assistant is the primary surface; project context sits
                  // in a collapsible rail beside it, the console docks below.
                  Expanded(child: _workspace(wide)),
                  _ConsoleDock(
                    open: _consoleOpen,
                    running: run.running,
                    hasOutput: run.output.isNotEmpty,
                    onToggle: () =>
                        setState(() => _consoleOpen = !_consoleOpen),
                    onStop: _stop,
                    onClear: () => ref
                        .read(projectRunProvider(project.path).notifier)
                        .clear(),
                    child: _ConsoleLog(path: project.path),
                  ),
                ],
              ),
              // Narrow screens: context as a right-side overlay drawer.
              if (!wide && _drawerOpen)
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _drawerOpen = false),
                          child: Container(color: Colors.black54),
                        ),
                      ),
                      SizedBox(
                        width: 340,
                        child: Container(
                          color: HudTheme.background,
                          padding: const EdgeInsets.all(12),
                          child: _dockedContext(),
                        ),
                      ),
                    ],
                  ),
                ),
              // Panels the user popped out into floating windows.
              ..._floatingPanels(),
            ],
          ),
        ),
      ),
    );
  }

  /// The working area: assistant (primary) beside a resizable context rail.
  Widget _workspace(bool wide) {
    final chat = Padding(
      padding: EdgeInsets.fromLTRB(16, 4, wide && _railOpen ? 4 : 16, 8),
      child: const AiChatPanel(),
    );

    if (!wide || !_railOpen) {
      // Narrow, or focus mode: the assistant takes the whole width.
      return chat;
    }

    // A draggable divider lets the user trade width between chat and context.
    return ResizableSplit(
      initialFraction: 0.62,
      minFraction: 0.35,
      maxFraction: 0.85,
      first: chat,
      second: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 16, 8),
        child: _dockedContext(),
      ),
    );
  }

  /// The docked context: source map, git history and (when a file is open) the
  /// code panel, stacked with draggable dividers. Popped-out panels drop out of
  /// this stack and reappear as floating windows.
  Widget _dockedContext() {
    // Source map + git share the lower part of the rail.
    final side = <Widget>[];
    if (!_floating.contains(_pSourceMap)) side.add(_sourceMapCard());
    side.add(
      HudPanel(
        title: 'GIT',
        icon: Icons.commit,
        expandChild: true,
        child: SingleChildScrollView(child: _GitSection(path: project.path)),
      ),
    );
    final sideStack = _verticalStack(side);

    // When a file is open, the code panel takes the top half — it's what the
    // user is working on — with the source map / git below it.
    if (_selectedFile != null && !_floating.contains(_pCode)) {
      return ResizableSplit(
        axis: Axis.vertical,
        initialFraction: 0.5,
        minFraction: 0.25,
        maxFraction: 0.75,
        first: _codeCard(),
        second: sideStack,
      );
    }
    return sideStack;
  }

  /// Stacks panels vertically with a draggable divider between each pair.
  Widget _verticalStack(List<Widget> panels) {
    if (panels.length == 1) return panels.first;
    return ResizableSplit(
      axis: Axis.vertical,
      initialFraction: 1 / panels.length,
      minFraction: 0.15,
      maxFraction: 0.85,
      first: panels.first,
      second: _verticalStack(panels.sublist(1)),
    );
  }

  Widget _sourceMapCard() => HudPanel(
    title: 'SOURCE MAP',
    icon: Icons.hub_outlined,
    expandChild: true,
    trailing: _popOutButton(_pSourceMap),
    child: _constellation(),
  );

  Widget _codeCard() => HudPanel(
    title: _selectedFile?.label ?? 'CODE',
    icon: Icons.description_outlined,
    expandChild: true,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _popOutButton(_pCode),
        _iconAction(
          Icons.close,
          'Close',
          Colors.white54,
          () => setState(() => _selectedFile = null),
        ),
      ],
    ),
    child: _codeEditor(),
  );

  Widget _constellation() {
    final graph = ref.watch(projectGraphProvider(project.path));
    return GraphConstellation(
      graph: graph,
      selectedNodeId: _selectedFile?.id,
      onNodeTap: (node) {
        if (node.type == NodeType.file && node.props['path'] != null) {
          setState(() => _selectedFile = node);
        }
      },
    );
  }

  Widget _codeEditor() {
    final node = _selectedFile;
    if (node == null) return const SizedBox.shrink();
    return _CodeEditor(
      key: ValueKey(node.id),
      node: node,
      onEditWithAi: () => setState(() => _selectedFile = null),
    );
  }

  /// The floating windows for any popped-out panels.
  List<Widget> _floatingPanels() {
    final panels = <Widget>[];
    var i = 0;
    Offset offsetFor() => Offset(120.0 + i * 36, 90.0 + i++ * 36);

    if (_floating.contains(_pSourceMap)) {
      panels.add(
        FloatingPanel(
          title: 'SOURCE MAP',
          icon: Icons.hub_outlined,
          initialOffset: offsetFor(),
          initialSize: const Size(460, 380),
          onDock: () => setState(() => _floating.remove(_pSourceMap)),
          child: _constellation(),
        ),
      );
    }
    if (_selectedFile != null && _floating.contains(_pCode)) {
      panels.add(
        FloatingPanel(
          title: _selectedFile!.label,
          icon: Icons.description_outlined,
          initialOffset: offsetFor(),
          initialSize: const Size(560, 460),
          onDock: () => setState(() => _floating.remove(_pCode)),
          onClose: () => setState(() {
            _floating.remove(_pCode);
            _selectedFile = null;
          }),
          child: _codeEditor(),
        ),
      );
    }
    return panels;
  }

  Widget _popOutButton(String id) => _iconAction(
    Icons.open_in_new,
    'Pop out',
    HudTheme.cyan.withValues(alpha: 0.8),
    () => setState(() => _floating.add(id)),
  );

  Widget _iconAction(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
    return IconButton(
      icon: Icon(icon, size: 15),
      tooltip: tooltip,
      color: color,
      onPressed: onTap,
      splashRadius: 14,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _header(bool wide) {
    final contextShown = wide ? _railOpen : _drawerOpen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
          // Toggle the project context so the assistant can fill the width.
          IconButton(
            tooltip: contextShown
                ? 'Hide project context'
                : 'Show project context',
            onPressed: _toggleContext,
            icon: Icon(
              contextShown
                  ? Icons.vertical_split
                  : Icons.vertical_split_outlined,
              color: contextShown
                  ? HudTheme.cyanGlow
                  : Colors.white.withValues(alpha: 0.55),
              size: 20,
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

/// The code panel's body: previews a file, allows manual editing + save, and
/// can hand the file to the assistant. Frame-less — it lives inside a docked
/// [HudPanel] or a [FloatingPanel], which supply the title bar and close.
class _CodeEditor extends StatefulWidget {
  final GraphNode node;
  final VoidCallback onEditWithAi;

  const _CodeEditor({
    super.key,
    required this.node,
    required this.onEditWithAi,
  });

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  final _controller = TextEditingController();
  String? _error;
  bool _dirty = false;

  String get _path => widget.node.props['path'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_CodeEditor old) {
    super.didUpdateWidget(old);
    if (old.node.id != widget.node.id) {
      _dirty = false;
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load() {
    try {
      _controller.text = File(_path).readAsStringSync();
      _error = null;
    } catch (e) {
      _controller.text = '';
      _error = 'Cannot open this file (binary or unreadable).';
    }
    if (mounted) setState(() {});
  }

  void _save() {
    try {
      File(_path).writeAsStringSync(_controller.text);
      setState(() => _dirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved ${widget.node.label}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: HudTheme.cyan.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
            if (_dirty)
              Container(
                margin: const EdgeInsets.only(left: 6),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: HudTheme.amber,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) {
                      if (!_dirty) setState(() => _dirty = true);
                    },
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      color: Color(0xFFCDE7FF),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
        ),
        // Actions.
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dirty ? HudTheme.cyan : Colors.white24,
                  foregroundColor: HudTheme.background,
                ),
                onPressed: (_dirty && _error == null) ? _save : null,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: HudTheme.cyanGlow,
                  side: BorderSide(color: HudTheme.cyan.withValues(alpha: 0.5)),
                ),
                onPressed: widget.onEditWithAi,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Edit with AI'),
              ),
            ],
          ),
        ),
      ],
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
