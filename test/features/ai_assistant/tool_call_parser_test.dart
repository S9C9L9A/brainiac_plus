import 'package:brainiac_plus/features/ai_assistant/models/agent_tool_call.dart';
import 'package:brainiac_plus/features/ai_assistant/services/tool_call_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ToolCallParser();

  test('parses a write_file tool call', () {
    const text = '''
Sure, I'll create the file.
```tool
{"tool": "write_file", "path": "test_apps/rainbow/main.dart", "content": "void main() {}"}
```
''';
    final calls = parser.parse(text);
    expect(calls, hasLength(1));
    expect(calls.single.tool, ToolType.writeFile);
    expect(calls.single.path, 'test_apps/rainbow/main.dart');
    expect(calls.single.content, 'void main() {}');
  });

  test('parses a run tool call', () {
    const text = '''
```tool
{"tool": "run", "command": "dart --version"}
```
''';
    final calls = parser.parse(text);
    expect(calls.single.tool, ToolType.run);
    expect(calls.single.command, 'dart --version');
  });

  test('parses a done tool call with a summary', () {
    const text = '```tool\n{"tool": "done", "summary": "All set"}\n```';
    final calls = parser.parse(text);
    expect(calls.single.tool, ToolType.done);
    expect(calls.single.summary, 'All set');
  });

  test('parses multiple tool calls in order', () {
    const text = '''
```tool
{"tool": "write_file", "path": "a.txt", "content": "x"}
```
then
```tool
{"tool": "run", "command": "ls"}
```
''';
    final calls = parser.parse(text);
    expect(calls.map((c) => c.tool), [ToolType.writeFile, ToolType.run]);
  });

  test('returns empty when there are no tool blocks', () {
    expect(parser.parse('Just a plain chat reply.'), isEmpty);
  });

  test('skips malformed JSON and unknown tools without throwing', () {
    const text = '''
```tool
{not valid json}
```
```tool
{"tool": "explode", "path": "x"}
```
```tool
{"tool": "run", "command": "echo ok"}
```
''';
    final calls = parser.parse(text);
    expect(calls, hasLength(1));
    expect(calls.single.command, 'echo ok');
  });

  test('hasToolCalls reflects presence of a tool block', () {
    expect(parser.hasToolCalls('```tool\n{"tool":"done"}\n```'), isTrue);
    expect(parser.hasToolCalls('no tools here'), isFalse);
  });
}
