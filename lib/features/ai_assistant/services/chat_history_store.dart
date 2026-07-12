import 'dart:convert';
import 'dart:io';

import '../models/ai_message.dart';

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
