import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import 'controllers/terminal_controller.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                ref.read(terminalProvider.notifier).clearOutput();
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: AppColors.systemRed),
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
    _scrollToBottom();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: session.output.length,
            itemBuilder: (context, index) {
              return SelectableText(
                session.output[index],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              );
            },
          ),
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
                  hintText: isRunning ? 'Process running...' : 'Enter command',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _executeCommand(),
                autofocus: true,
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
