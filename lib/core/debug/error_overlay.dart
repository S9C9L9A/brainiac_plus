import 'package:flutter/material.dart';
import 'error_reporter.dart';

class ErrorOverlay extends StatelessWidget {
  final Widget child;

  const ErrorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ErrorEntry>>(
      valueListenable: ErrorReporter.instance.errors,
      builder: (context, errors, _) {
        if (errors.isEmpty) return child;

        final latest = errors.last;
        return Stack(
          children: [
            child,
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ErrorBanner(entry: latest),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final ErrorEntry entry;

  const _ErrorBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[900]?.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatEntry(entry),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _showDetails(context, entry),
              child: const Text(
                'Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: ErrorReporter.instance.clear,
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEntry(ErrorEntry entry) {
    final time = entry.timestamp.toIso8601String().split('T').last;
    return '[${entry.context}] $time - ${entry.error}';
  }

  void _showDetails(BuildContext context, ErrorEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error details'),
        content: SingleChildScrollView(
          child: SelectableText(
            '${entry.error}\n\n${entry.stackTrace ?? 'No stack trace'}',
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
}
