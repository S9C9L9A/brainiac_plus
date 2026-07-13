import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/hud/hud_theme.dart';

/// The app shown in a detached document window — a real, free OS window (not an
/// in-app overlay). It runs in its own Flutter engine/isolate, so it shares no
/// state with the main app: it simply opens the file at its path, lets the user
/// edit it, and saves back to disk. That self-containment is exactly what a
/// document editor needs, and it lets each open document live in its own
/// window the user can move anywhere on the Linux desktop.
class DocumentWindowApp extends StatelessWidget {
  final String path;
  final String title;

  const DocumentWindowApp({super.key, required this.path, required this.title});

  /// Builds from the JSON argument handed to the sub-window by the launcher.
  factory DocumentWindowApp.fromArgument(String argument) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(argument);
      data = decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      data = const {};
    }
    final path = data['path']?.toString() ?? '';
    final title = data['title']?.toString().isNotEmpty == true
        ? data['title'].toString()
        : (path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'Document');
    return DocumentWindowApp(path: path, title: title);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: HudTheme.background),
      home: _DocumentEditor(path: path, title: title),
    );
  }
}

class _DocumentEditor extends StatefulWidget {
  final String path;
  final String title;
  const _DocumentEditor({required this.path, required this.title});

  @override
  State<_DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<_DocumentEditor> {
  final _controller = TextEditingController();
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load() {
    try {
      _controller.text = File(widget.path).readAsStringSync();
      _error = null;
    } catch (e) {
      _error = 'Cannot open this file (binary or unreadable).';
    }
    if (mounted) setState(() {});
  }

  void _save() {
    try {
      File(widget.path).writeAsStringSync(_controller.text);
      setState(() => _dirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved ${widget.title}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleBar(),
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: HudTheme.cyan.withValues(alpha: 0.12),
                      ),
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
                        fontSize: 13,
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: HudTheme.panel.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: HudTheme.cyan.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF4ADE80),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HudTheme.cyan.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (_dirty)
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HudTheme.amber,
                shape: BoxShape.circle,
              ),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _dirty ? HudTheme.cyan : Colors.white24,
              foregroundColor: HudTheme.background,
            ),
            onPressed: (_dirty && _error == null) ? _save : null,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
