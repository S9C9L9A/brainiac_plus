import 'dart:convert';

import '../models/agent_tool_call.dart';

/// Extracts executable tool calls from the model's reply.
///
/// The model is instructed to emit one JSON object per ```tool fenced block,
/// e.g. `{"tool": "write_file", "path": "...", "content": "..."}`. Malformed
/// blocks and unknown tools are skipped rather than aborting the turn — a
/// local model will occasionally produce noise, and one bad block shouldn't
/// discard the good ones.
class ToolCallParser {
  static final _blockPattern = RegExp(
    r'```tool\s*\n([\s\S]*?)```',
    multiLine: true,
  );

  bool hasToolCalls(String text) => _blockPattern.hasMatch(text);

  List<AgentToolCall> parse(String text) {
    final calls = <AgentToolCall>[];
    for (final match in _blockPattern.allMatches(text)) {
      final raw = match.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;

      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        continue;
      }
      if (decoded is! Map) continue;

      final type = AgentToolCall.typeFromName(decoded['tool']?.toString());
      if (type == ToolType.unknown) continue;

      calls.add(
        AgentToolCall(
          tool: type,
          path: decoded['path']?.toString(),
          content: decoded['content']?.toString(),
          command: decoded['command']?.toString(),
          url: decoded['url']?.toString(),
          summary: decoded['summary']?.toString(),
        ),
      );
    }
    return calls;
  }
}
