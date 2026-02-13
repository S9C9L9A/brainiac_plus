import 'package:flutter/material.dart';

class TerminalOutput extends StatefulWidget {
  final List<String> lines;
  final ScrollController scrollController;

  const TerminalOutput({
    super.key,
    required this.lines,
    required this.scrollController,
  });

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> {
  @override
  void didUpdateWidget(TerminalOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lines[index];
          final isCommand = line.startsWith('\$ ');
          
          return SelectableText(
            line,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: isCommand ? const Color(0xFF00FF00) : Colors.white,
              fontWeight: isCommand ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          );
        },
      ),
    );
  }
}
