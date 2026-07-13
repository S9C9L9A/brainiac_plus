import 'dart:convert';
import 'dart:io';

import '../models/ai_message.dart';

/// The file name a conversation is persisted under, scoped to [projectPath].
///
/// The global (no-project) chat uses the base name; each project gets its own
/// file keyed by a readable slug of its folder name plus a stable hash of the
/// full path, so two projects — even two with the same folder name in
/// different locations — never share a history.
String chatHistoryFileName(String? projectPath) {
  if (projectPath == null || projectPath.trim().isEmpty) {
    return 'chat_history.json';
  }
  final segments = projectPath
      .split(RegExp(r'[/\\]'))
      .where((s) => s.isNotEmpty);
  final name = segments.isEmpty ? 'project' : segments.last;
  final slug = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final hash = _fnv1a32(projectPath).toRadixString(16).padLeft(8, '0');
  return 'chat_history_${slug}_$hash.json';
}

/// FNV-1a 32-bit hash — small, dependency-free, and deterministic across runs
/// (unlike String.hashCode), so a project maps to the same file every launch.
int _fnv1a32(String s) {
  const prime = 0x01000193;
  var hash = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    hash = (hash ^ unit) & 0xFFFFFFFF;
    hash = (hash * prime) & 0xFFFFFFFF;
  }
  return hash;
}

/// Persists the assistant conversation so it survives an app restart — the
/// difference between a tool that forgets you every launch and one that feels
/// like a continuous assistant.
abstract class ChatHistoryStore {
  Future<List<AiMessage>> load();
  Future<void> save(List<AiMessage> messages);
  Future<void> clear();
}

/// A [ChatHistoryStore] backed by a single JSON file. The file location is
/// resolved lazily (so production can point it at the app-support directory
/// via path_provider while a test points it at a temp file), and every read is
/// defensive: a missing or corrupt file yields an empty history instead of
/// crashing the chat on launch.
class JsonFileChatHistoryStore implements ChatHistoryStore {
  final Future<File> Function() _resolveFile;

  /// Only the most recent [maxMessages] are kept on disk, so a long-running
  /// install can't grow the file without bound.
  final int maxMessages;

  JsonFileChatHistoryStore(this._resolveFile, {this.maxMessages = 300});

  @override
  Future<List<AiMessage>> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return const [];
      final text = await file.readAsString();
      if (text.trim().isEmpty) return const [];
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      final out = <AiMessage>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            out.add(AiMessage.fromJson(item));
          } catch (_) {
            // Skip a single malformed row rather than dropping the whole log.
          }
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<AiMessage> messages) async {
    try {
      final file = await _resolveFile();
      await file.parent.create(recursive: true);
      final capped = messages.length > maxMessages
          ? messages.sublist(messages.length - maxMessages)
          : messages;
      await file.writeAsString(
        jsonEncode(capped.map((m) => m.toJson()).toList()),
      );
    } catch (_) {
      // Persistence is best-effort — a failed save must never break the chat.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _resolveFile();
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore
    }
  }
}
