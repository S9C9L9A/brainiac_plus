import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/ai_chat_controller.dart'
    show activeProjectProvider, agentRegistryProvider;
import '../models/agent_profile.dart';
import '../models/chat_composition.dart';

/// One row in the `@`-mention picker: a thing the user can pull into a message
/// as context (a file, a domain agent, a skill).
class MentionCandidate {
  final AttachmentKind kind;

  /// Machine-facing reference stored on the resulting [ChatAttachment].
  final String value;

  /// Primary text shown in the picker.
  final String label;

  /// Optional secondary text (a path, a description).
  final String? sublabel;

  const MentionCandidate({
    required this.kind,
    required this.value,
    required this.label,
    this.sublabel,
  });

  /// The chip stays compact: files/images shorten to their basename and
  /// agents/skills/links show their reference, so the friendly picker [label]
  /// is intentionally dropped here.
  ChatAttachment toAttachment() => ChatAttachment(kind: kind, value: value);
}

/// Answers "what can I mention with `@` here?" — files in the current
/// project/workspace, the domain agents, and the skills the assistant knows.
/// Kept as a plain, injectable object (no I/O in [query]) so ranking is unit
/// tested without touching the disk.
class MentionSource {
  final List<AgentProfile> agents;
  final List<String> skills;

  /// Project-relative file paths (e.g. `lib/features/dashboard/x.dart`).
  final List<String> files;

  const MentionSource({
    this.agents = const [],
    this.skills = const [],
    this.files = const [],
  });

  /// The skills the assistant can be pointed at, mirroring the trigger map in
  /// the project contract (§11). Values are the invocable skill names.
  static const curatedSkills = <String>[
    'engineering:code-review',
    'engineering:debug',
    'engineering:architecture',
    'engineering:system-design',
    'engineering:testing-strategy',
    'engineering:documentation',
    'engineering:tech-debt',
    'design:design-critique',
    'design:accessibility-review',
    'design:ux-copy',
    'anthropic-skills:docx',
    'anthropic-skills:pptx',
    'anthropic-skills:pdf',
    'anthropic-skills:xlsx',
    'cowork-senior-agent',
  ];

  /// Candidates matching [raw] (case-insensitive substring), best matches
  /// first. An empty query returns a capped slice of everything so the picker
  /// is useful the instant `@` is typed.
  List<MentionCandidate> query(String raw, {int limit = 24}) {
    final q = raw.trim().toLowerCase();
    final scored = <(int, MentionCandidate)>[];

    void add(MentionCandidate c, String haystack, String secondary) {
      final h = haystack.toLowerCase();
      final s = secondary.toLowerCase();
      if (q.isEmpty) {
        scored.add((2, c));
      } else if (h.startsWith(q)) {
        scored.add((0, c));
      } else if (h.contains(q)) {
        scored.add((1, c));
      } else if (s.contains(q)) {
        scored.add((2, c));
      }
    }

    for (final a in agents) {
      add(
        MentionCandidate(
          kind: AttachmentKind.agent,
          value: a.id,
          label: a.name,
          sublabel: a.description,
        ),
        a.id,
        '${a.name} ${a.description}',
      );
    }
    for (final s in skills) {
      add(
        MentionCandidate(kind: AttachmentKind.skill, value: s, label: s),
        s,
        s,
      );
    }
    for (final f in files) {
      final base = f.split('/').last;
      add(
        MentionCandidate(
          kind: AttachmentKind.file,
          value: f,
          label: base,
          sublabel: f,
        ),
        base,
        f,
      );
    }

    // Stable sort by match quality; keep insertion order within a tier.
    final indexed = scored.indexed.toList()
      ..sort((a, b) {
        final byScore = a.$2.$1.compareTo(b.$2.$1);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    return indexed.map((e) => e.$2.$2).take(limit).toList();
  }
}

/// Scans [root]/lib for Dart files and returns their root-relative paths,
/// guarded and capped so a huge tree can't stall the picker or the UI thread.
List<String> scanProjectFiles(String root, {int cap = 500}) {
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  try {
    final prefix = root.endsWith('/') ? root : '$root/';
    return lib
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map(
          (f) => f.path.startsWith(prefix)
              ? f.path.substring(prefix.length)
              : f.path,
        )
        .take(cap)
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Builds a [MentionSource] for the current context: the active project if one
/// is selected, otherwise the running app's own repo, plus the registered
/// agents and curated skills.
final mentionSourceProvider = Provider<MentionSource>((ref) {
  final registry = ref.watch(agentRegistryProvider);
  final project = ref.watch(activeProjectProvider);
  final root = project != null && Directory(project).existsSync()
      ? project
      : Directory.current.path;
  return MentionSource(
    agents: registry.agents,
    skills: MentionSource.curatedSkills,
    files: scanProjectFiles(root),
  );
});
