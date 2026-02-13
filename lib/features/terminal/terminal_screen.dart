import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import 'controllers/terminal_controller.dart';
import 'widgets/terminal_output.dart';
import 'widgets/command_suggestions.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int _historyIndex = -1;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _commandController.addListener(_onCommandChanged);
  }

  void _onCommandChanged() {
    setState(() {
      _suggestions = CommandSuggestions.getSuggestions(_commandController.text);
    });
  }

  @override
  void dispose() {
    _commandController.removeListener(_onCommandChanged);
    _commandController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateHistory(bool up) {
    final history = ref.read(terminalProvider.notifier).getHistory();
    if (history.isEmpty) return;

    if (up) {
      if (_historyIndex < history.length - 1) {
        _historyIndex++;
        _commandController.text = history[history.length - 1 - _historyIndex];
        _commandController.selection = TextSelection.fromPosition(
          TextPosition(offset: _commandController.text.length),
        );
      }
    } else {
      if (_historyIndex > 0) {
        _historyIndex--;
        _commandController.text = history[history.length - 1 - _historyIndex];
        _commandController.selection = TextSelection.fromPosition(
          TextPosition(offset: _commandController.text.length),
        );
      } else if (_historyIndex == 0) {
        _historyIndex = -1;
        _commandController.clear();
      }
    }
  }

  void _showCommandHistory(BuildContext context) {
    final history = ref.read(terminalProvider.notifier).getHistory();
    
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No command history')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text(
          'Command History',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: history.length,
            reverse: true,
            itemBuilder: (context, index) {
              final command = history[history.length - 1 - index];
              return ListTile(
                leading: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
                title: Text(
                  command,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                onTap: () {
                  _commandController.text = command;
                  Navigator.pop(context);
                  _focusNode.requestFocus();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeCommand() {
    final command = _commandController.text.trim();
    if (command.isNotEmpty) {
      ref.read(terminalProvider.notifier).executeCommand(command);
      _commandController.clear();
      _historyIndex = -1;
      setState(() {
        _suggestions = [];
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = ref.watch(terminalProvider);
    final currentSession = sessions.isNotEmpty ? sessions.last : null;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: currentSession != null
                    ? _buildTerminalView(currentSession)
                    : const Center(child: Text('No terminal session')),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                SuggestionsList(
                  suggestions: _suggestions,
                  onSelected: (suggestion) {
                    _commandController.text = suggestion;
                    _commandController.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.length),
                    );
                    setState(() {
                      _suggestions = [];
                    });
                  },
                ),
              ],
              _buildCommandInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Icon(Icons.terminal, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Terminal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Command History',
              onPressed: () {
                _showCommandHistory(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear Output',
              onPressed: () {
                ref.read(terminalProvider.notifier).clearOutput();
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: AppColors.systemRed),
              tooltip: 'Kill Process',
              onPressed: () {
                ref.read(terminalProvider.notifier).killProcess();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView(TerminalSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: TerminalOutput(
          lines: session.output,
          scrollController: _scrollController,
        ),
      ),
    );
  }

  Widget _buildCommandInput() {
    final sessions = ref.watch(terminalProvider);
    final isRunning = sessions.isNotEmpty ? sessions.last.isProcessRunning : false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              '\$',
              style: TextStyle(
                color: isRunning ? AppColors.systemYellow : AppColors.systemGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey.keyLabel == 'Arrow Up') {
                      _navigateHistory(true);
                    } else if (event.logicalKey.keyLabel == 'Arrow Down') {
                      _navigateHistory(false);
                    }
                  }
                },
                child: TextField(
                  controller: _commandController,
                  focusNode: _focusNode,
                  enabled: !isRunning,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: isRunning ? 'Process running...' : 'Enter command (↑/↓ for history)',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _executeCommand(),
                  autofocus: true,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: isRunning ? AppColors.systemGray : AppColors.systemBlue,
              ),
              onPressed: isRunning ? null : _executeCommand,
            ),
          ],
        ),
      ),
    );
  }
}
