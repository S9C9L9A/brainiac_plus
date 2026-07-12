/// What the user attached to a chat message besides plain prose: a file to
/// work on, an agent to route to, a skill to apply, a link to read, or an
/// image/screenshot. These turn a message from "text the model guesses about"
/// into "text plus the exact context it needs to act".
enum AttachmentKind { file, agent, skill, link, image }

extension AttachmentKindMeta on AttachmentKind {
  /// The `@`-mention sigil label shown in the picker and chips.
  String get label {
    switch (this) {
      case AttachmentKind.file:
        return 'File';
      case AttachmentKind.agent:
        return 'Agent';
      case AttachmentKind.skill:
        return 'Skill';
      case AttachmentKind.link:
        return 'Link';
      case AttachmentKind.image:
        return 'Image';
    }
  }
}

/// One piece of context stapled to a message. [value] is the machine-facing
/// reference (a path, an agent id, a URL); [label] is what the user sees on the
/// chip (defaults to a sensible shortening of [value]).
class ChatAttachment {
  final AttachmentKind kind;
  final String value;
  final String? label;

  const ChatAttachment({required this.kind, required this.value, this.label});

  /// Display text for the chip — the label if given, else the last path
  /// segment for files/images, else the raw value.
  String get display {
    if (label != null && label!.isNotEmpty) return label!;
    switch (kind) {
      case AttachmentKind.file:
      case AttachmentKind.image:
        final parts = value.split('/').where((s) => s.isNotEmpty);
        return parts.isEmpty ? value : parts.last;
      case AttachmentKind.agent:
      case AttachmentKind.skill:
      case AttachmentKind.link:
        return value;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ChatAttachment && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// A message the user is composing: the prose plus everything they attached.
/// [toPrompt] flattens it into a single string the assistant receives, so the
/// agent's file/fetch tools and routing have concrete references to act on
/// instead of having to guess what "that file" or "the screenshot" means.
class ChatComposition {
  final String text;
  final List<ChatAttachment> attachments;

  const ChatComposition({this.text = '', this.attachments = const []});

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
  bool get isNotEmpty => !isEmpty;

  ChatComposition copyWith({String? text, List<ChatAttachment>? attachments}) =>
      ChatComposition(
        text: text ?? this.text,
        attachments: attachments ?? this.attachments,
      );

  /// Serializes to the string sent to the model. The prose comes first, then a
  /// compact, labelled context block grouping attachments by kind, with a hint
  /// telling the agent how to use each (read the file, fetch the link, …).
  ///
  /// Kept terse on purpose: file/image references are named, not inlined — the
  /// agent has a `read_file` tool and can pull contents itself, so this never
  /// balloons the prompt with whole files.
  String toPrompt() {
    final prose = text.trim();
    if (attachments.isEmpty) return prose;

    final buf = StringBuffer();
    if (prose.isNotEmpty) buf.writeln(prose);
    buf.writeln('\n--- Context attached to this message ---');

    void section(AttachmentKind kind, String hint) {
      final items = attachments.where((a) => a.kind == kind).toList();
      if (items.isEmpty) return;
      for (final a in items) {
        buf.writeln('• ${kind.label}: ${a.value}');
      }
      buf.writeln('  ($hint)');
    }

    section(AttachmentKind.file, 'use read_file to inspect before changing');
    section(AttachmentKind.image, 'a screenshot saved at this path');
    section(AttachmentKind.link, 'use fetch to read this URL');
    section(AttachmentKind.agent, 'route this work to the named domain agent');
    section(AttachmentKind.skill, 'apply this skill\'s guidance');

    return buf.toString().trimRight();
  }
}
