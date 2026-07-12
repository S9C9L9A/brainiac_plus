import 'package:brainiac_plus/features/ai_assistant/models/agent_tool_call.dart';
import 'package:brainiac_plus/features/ai_assistant/services/agent_tool_executor.dart';
import 'package:brainiac_plus/features/ai_assistant/services/tool_call_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolCallParser — fetch', () {
    test('parses a fetch tool call with a url', () {
      final calls = ToolCallParser().parse(
        '```tool\n{"tool":"fetch","url":"https://example.com/api"}\n```',
      );
      expect(calls.single.tool, ToolType.fetch);
      expect(calls.single.url, 'https://example.com/api');
    });
  });

  group('AgentToolExecutor — fetch', () {
    AgentToolExecutor executor({UrlFetcher? fetch}) => AgentToolExecutor(
      workspaceRoot: '/tmp',
      runCommand: (_) async => '',
      fetchUrl: fetch,
    );

    test('fetches a url and returns its (truncated) body', () async {
      final e = executor(fetch: (url) async => 'BODY of $url');
      final r = await e.execute(
        const AgentToolCall(tool: ToolType.fetch, url: 'https://a.test'),
      );
      expect(r.ok, isTrue);
      expect(r.output, contains('BODY of https://a.test'));
    });

    test('truncates very large responses', () async {
      final big = 'x' * 20000;
      final e = executor(fetch: (_) async => big);
      final r = await e.execute(
        const AgentToolCall(tool: ToolType.fetch, url: 'https://a.test'),
      );
      expect(r.output.length, lessThan(9000));
      expect(r.output, contains('truncated'));
    });

    test('rejects non-http(s) urls', () async {
      final e = executor(fetch: (_) async => 'x');
      final r = await e.execute(
        const AgentToolCall(tool: ToolType.fetch, url: 'file:///etc/passwd'),
      );
      expect(r.ok, isFalse);
      expect(r.output.toLowerCase(), contains('http'));
    });

    test('reports when fetching is unavailable', () async {
      final r = await executor().execute(
        const AgentToolCall(tool: ToolType.fetch, url: 'https://a.test'),
      );
      expect(r.ok, isFalse);
    });
  });

  group('ToolCallParser — search', () {
    test('parses a search tool call with a query', () {
      final calls = ToolCallParser().parse(
        '```tool\n{"tool":"search","query":"flutter riverpod"}\n```',
      );
      expect(calls.single.tool, ToolType.search);
      expect(calls.single.query, 'flutter riverpod');
    });
  });

  group('AgentToolExecutor — search', () {
    test(
      'runs the injected searcher and returns its formatted output',
      () async {
        final e = AgentToolExecutor(
          workspaceRoot: '/tmp',
          runCommand: (_) async => '',
          webSearch: (q) async => 'Results for $q:\n• Foo\n  https://foo',
        );
        final r = await e.execute(
          const AgentToolCall(tool: ToolType.search, query: 'foo'),
        );
        expect(r.ok, isTrue);
        expect(r.output, contains('https://foo'));
      },
    );

    test('rejects an empty query', () async {
      final e = AgentToolExecutor(
        workspaceRoot: '/tmp',
        runCommand: (_) async => '',
        webSearch: (_) async => 'x',
      );
      final r = await e.execute(
        const AgentToolCall(tool: ToolType.search, query: '  '),
      );
      expect(r.ok, isFalse);
    });

    test('reports when search is unavailable', () async {
      final r = await AgentToolExecutor(
        workspaceRoot: '/tmp',
        runCommand: (_) async => '',
      ).execute(const AgentToolCall(tool: ToolType.search, query: 'foo'));
      expect(r.ok, isFalse);
      expect(r.output.toLowerCase(), contains('not available'));
    });

    test('empty search results are reported clearly', () async {
      final e = AgentToolExecutor(
        workspaceRoot: '/tmp',
        runCommand: (_) async => '',
        webSearch: (_) async => '',
      );
      final r = await e.execute(
        const AgentToolCall(tool: ToolType.search, query: 'zzz'),
      );
      expect(r.ok, isTrue);
      expect(r.output.toLowerCase(), contains('no results'));
    });
  });
}
