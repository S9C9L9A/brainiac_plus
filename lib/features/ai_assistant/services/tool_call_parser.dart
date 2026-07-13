import 'dart:convert';

import '../models/agent_tool_call.dart';

/// Extracts executable tool calls from the model's reply.
///
/// The model is instructed to emit one JSON object per ```tool fenced block,
/// e.g. `{"tool": "write_file", "path": "...", "content": "..."}`. A local
/// model, though, routinely produces *invalid* JSON for `write_file` — it drops
/// real (unescaped) newlines and quotes straight into the `content` string
/// because that's how source code looks. Strict `jsonDecode` rejects that, and
/// the fix the model proposed would silently never be written.
///
/// So each block is parsed in two passes: strict JSON first, then a lenient
/// recovery that pulls out `tool` / `path` / `content` / … by hand. Only truly
/// unrecoverable noise is dropped.
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

      final call = _fromJson(raw) ?? _lenient(raw);
      if (call != null) calls.add(call);
    }
    return calls;
  }

  /// Strict pass: a well-formed JSON object.
  AgentToolCall? _fromJson(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final type = AgentToolCall.typeFromName(decoded['tool']?.toString());
    if (type == ToolType.unknown) return null;
    return AgentToolCall(
      tool: type,
      path: decoded['path']?.toString(),
      content: decoded['content']?.toString(),
      command: decoded['command']?.toString(),
      url: decoded['url']?.toString(),
      query: decoded['query']?.toString(),
      summary: decoded['summary']?.toString(),
    );
  }

  /// Lenient pass: recover a tool call from JSON the model got slightly wrong —
  /// most importantly a `write_file` whose `content` contains raw newlines or
  /// quotes. Returns null when there isn't even a recognizable `"tool"`.
  AgentToolCall? _lenient(String raw) {
    final toolName = RegExp(r'"tool"\s*:\s*"(\w+)"').firstMatch(raw)?.group(1);
    final type = AgentToolCall.typeFromName(toolName);
    if (type == ToolType.unknown) return null;

    // `content` is the hard one: take everything from the first `"content":`
    // up to the trailing `"}` at the end of the block, then unescape. Assumes
    // content is the last field, which is how models emit write_file.
    String? content;
    final contentMatch = RegExp(
      r'"content"\s*:\s*"(.*)"\s*}?\s*$',
      dotAll: true,
    ).firstMatch(raw);
    if (contentMatch != null) content = _unescape(contentMatch.group(1)!);

    return AgentToolCall(
      tool: type,
      path: _field(raw, 'path'),
      content: content,
      command: _field(raw, 'command'),
      url: _field(raw, 'url'),
      query: _field(raw, 'query'),
      summary: _field(raw, 'summary'),
    );
  }

  /// Extracts a simple, single-line string field, honoring `\"` escapes.
  String? _field(String raw, String key) {
    final m = RegExp('"$key"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"').firstMatch(raw);
    return m == null ? null : _unescape(m.group(1)!);
  }

  /// Turns JSON escape sequences into their characters. Content that used real
  /// newlines already has them (they pass through untouched); content that used
  /// `\n`/`\"` gets those decoded.
  String _unescape(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == r'\' && i + 1 < s.length) {
        final next = s[i + 1];
        switch (next) {
          case 'n':
            buf.write('\n');
          case 't':
            buf.write('\t');
          case 'r':
            buf.write('\r');
          case '"':
            buf.write('"');
          case r'\':
            buf.write(r'\');
          case '/':
            buf.write('/');
          default:
            buf.write(c);
            buf.write(next);
        }
        i++;
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}
