import 'package:brainiac_plus/core/theme/app_icons.dart';
import 'package:brainiac_plus/features/ai_assistant/models/chat_composition.dart';
import 'package:brainiac_plus/features/ai_assistant/services/mention_source.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The message composer: plain prose plus first-class context. Type `@` to
/// mention a file, agent or skill; use the `＋` button to attach an image
/// (screenshot), a file, or a link. Everything the user pins shows as a
/// removable chip and travels with the message as structured context, so the
/// assistant acts on exact references instead of guessing.
class ChatInputBar extends ConsumerStatefulWidget {
  final void Function(ChatComposition) onSend;
  final bool enabled;

  const ChatInputBar({super.key, required this.onSend, this.enabled = true});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _attachments = <ChatAttachment>[];

  OverlayEntry? _mentionOverlay;

  /// The text typed after the active `@`, or null when no mention is in flight.
  String? _mentionQuery;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;

  void _handleSubmit() {
    if (!_hasContent || !widget.enabled) return;
    _removeOverlay();
    widget.onSend(
      ChatComposition(
        text: _controller.text.trim(),
        attachments: List.unmodifiable(_attachments),
      ),
    );
    _controller.clear();
    setState(() {
      _attachments.clear();
      _mentionQuery = null;
    });
  }

  void _addAttachment(ChatAttachment a) {
    setState(() {
      if (!_attachments.contains(a)) _attachments.add(a);
    });
  }

  void _removeAttachment(ChatAttachment a) {
    setState(() => _attachments.remove(a));
  }

  // ── Mention autocomplete ──────────────────────────────────────────────

  /// Recomputes the active mention from the text before the caret: the query
  /// is whatever follows the last `@` when no whitespace separates it from the
  /// cursor. Drives the popup on/off.
  void _onChanged(String text) {
    final sel = _controller.selection.baseOffset;
    final upToCaret = sel < 0 ? text : text.substring(0, sel);
    final at = upToCaret.lastIndexOf('@');
    final valid = at >= 0 && !upToCaret.substring(at).contains(RegExp(r'\s'));
    setState(() => _mentionQuery = valid ? upToCaret.substring(at + 1) : null);
    if (_mentionQuery == null) {
      _removeOverlay();
    } else {
      _showOverlay();
      _mentionOverlay?.markNeedsBuild();
    }
  }

  void _pickMention(MentionCandidate c) {
    final text = _controller.text;
    final sel = _controller.selection.baseOffset;
    final caret = sel < 0 ? text.length : sel;
    final at = text.substring(0, caret).lastIndexOf('@');
    if (at >= 0) {
      final next = text.replaceRange(at, caret, '');
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: at),
      );
    }
    _addAttachment(c.toAttachment());
    setState(() => _mentionQuery = null);
    _removeOverlay();
    _focusNode.requestFocus();
  }

  void _showOverlay() {
    if (_mentionOverlay != null) return;
    _mentionOverlay = OverlayEntry(builder: _buildMentionPopup);
    Overlay.of(context).insert(_mentionOverlay!);
  }

  void _removeOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
  }

  Widget _buildMentionPopup(BuildContext context) {
    final results = ref.read(mentionSourceProvider).query(_mentionQuery ?? '');
    return Positioned(
      width: 340,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, -8),
        followerAnchor: Alignment.bottomLeft,
        targetAnchor: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: const Color(0xFF15151C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                ),
              ],
            ),
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matches',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, i) => _mentionTile(results[i]),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _mentionTile(MentionCandidate c) {
    return InkWell(
      onTap: () => _pickMention(c),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(_kindIcon(c.kind), size: 16, color: _kindColor(c.kind)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (c.sublabel != null && c.sublabel != c.label)
                    Text(
                      c.sublabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kindColor(c.kind).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                c.kind.label.toLowerCase(),
                style: TextStyle(color: _kindColor(c.kind), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Attach menu (image / file / link) ─────────────────────────────────

  Future<void> _attachMedia({required bool imageOnly}) async {
    _removeOverlay();
    final result = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.any,
      withData: false,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return;
    _addAttachment(
      ChatAttachment(
        kind: imageOnly ? AttachmentKind.image : AttachmentKind.file,
        value: path,
      ),
    );
  }

  Future<void> _attachLink() async {
    _removeOverlay();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => const _LinkDialog(),
    );
    if (url == null || url.trim().isEmpty) return;
    _addAttachment(
      ChatAttachment(kind: AttachmentKind.link, value: url.trim()),
    );
  }

  void _openAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF15151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _attachOption(
              icon: Icons.image_outlined,
              color: Colors.tealAccent,
              title: 'Attach screenshot / image',
              subtitle: 'Pin an image the assistant can reference by path',
              onTap: () {
                Navigator.pop(context);
                _attachMedia(imageOnly: true);
              },
            ),
            _attachOption(
              icon: Icons.attach_file,
              color: Colors.amberAccent,
              title: 'Attach file',
              subtitle: 'Any file on disk',
              onTap: () {
                Navigator.pop(context);
                _attachMedia(imageOnly: false);
              },
            ),
            _attachOption(
              icon: Icons.link,
              color: Colors.lightBlueAccent,
              title: 'Attach link',
              subtitle: 'A URL the assistant can fetch and read',
              onTap: () {
                Navigator.pop(context);
                _attachLink();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_attachments.isNotEmpty) _buildAttachmentChips(),
            Row(
              children: [
                _buildAttachButton(),
                const SizedBox(width: 8),
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask, or type @ to mention a file, agent…',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onChanged: _onChanged,
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _attachments.map((a) {
          return Container(
            padding: const EdgeInsets.only(
              left: 8,
              right: 4,
              top: 3,
              bottom: 3,
            ),
            decoration: BoxDecoration(
              color: _kindColor(a.kind).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _kindColor(a.kind).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_kindIcon(a.kind), size: 13, color: _kindColor(a.kind)),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    a.display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _removeAttachment(a),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.close, size: 13, color: Colors.white54),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachButton() {
    return Material(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: widget.enabled ? _openAttachMenu : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            color: widget.enabled ? Colors.white70 : Colors.grey.shade600,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final active = _hasContent && widget.enabled;
    return Material(
      color: active ? Colors.purple : Colors.grey.shade800,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: active ? _handleSubmit : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            AppIcons.send,
            color: active ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
      ),
    );
  }

  IconData _kindIcon(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.file:
        return Icons.insert_drive_file_outlined;
      case AttachmentKind.image:
        return Icons.image_outlined;
      case AttachmentKind.agent:
        return Icons.smart_toy_outlined;
      case AttachmentKind.skill:
        return Icons.auto_awesome_outlined;
      case AttachmentKind.link:
        return Icons.link;
    }
  }

  Color _kindColor(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.file:
        return Colors.amberAccent;
      case AttachmentKind.image:
        return Colors.tealAccent;
      case AttachmentKind.agent:
        return Colors.purpleAccent;
      case AttachmentKind.skill:
        return Colors.orangeAccent;
      case AttachmentKind.link:
        return Colors.lightBlueAccent;
    }
  }
}

/// Small modal to paste/type a URL to attach.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15151C),
      title: const Text('Attach link', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'https://…',
          hintStyle: TextStyle(color: Colors.white38),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Attach'),
        ),
      ],
    );
  }
}
