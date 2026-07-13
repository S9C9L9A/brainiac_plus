import 'dart:io';

import 'package:brainiac_plus/features/ai_assistant/models/ai_message.dart';
import 'package:brainiac_plus/features/ai_assistant/services/chat_history_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chat_hist');
    file = File('${dir.path}/history.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  JsonFileChatHistoryStore store({int maxMessages = 300}) =>
      JsonFileChatHistoryStore(() async => file, maxMessages: maxMessages);

  AiMessage msg(String id, String content) => AiMessage(
    id: id,
    role: 'user',
    content: content,
    timestamp: DateTime(2026, 7, 13, 10, id.hashCode % 60),
  );

  test('load returns empty when no file exists yet', () async {
    expect(await store().load(), isEmpty);
  });

  test('saved messages round-trip back with fields intact', () async {
    final s = store();
    final original = [
      AiMessage(
        id: '1',
        role: 'user',
        content: 'ciao',
        timestamp: DateTime(2026, 7, 13, 10),
      ),
      AiMessage(
        id: '2',
        role: 'assistant',
        content: 'done',
        timestamp: DateTime(2026, 7, 13, 10, 1),
        agentId: 'coordinator',
        intent: 'action',
      ),
    ];
    await s.save(original);

    final loaded = await s.load();
    expect(loaded, hasLength(2));
    expect(loaded[0].content, 'ciao');
    expect(loaded[1].agentId, 'coordinator');
    expect(loaded[1].intent, 'action');
  });

  test('a corrupt file is treated as empty, not a crash', () async {
    await file.writeAsString('{ this is not json ]');
    expect(await store().load(), isEmpty);
  });

  test('a malformed row is skipped but valid rows survive', () async {
    await file.writeAsString(
      '[{"garbage":true},'
      '{"id":"9","role":"user","content":"hi","timestamp":'
      '"2026-07-13T10:00:00.000"}]',
    );
    final loaded = await store().load();
    expect(loaded, hasLength(1));
    expect(loaded.single.content, 'hi');
  });

  test('save caps to the most recent maxMessages', () async {
    final s = store(maxMessages: 3);
    await s.save([for (var i = 0; i < 10; i++) msg('$i', 'm$i')]);
    final loaded = await s.load();
    expect(loaded, hasLength(3));
    expect(loaded.map((m) => m.content), ['m7', 'm8', 'm9']);
  });

  test('clear removes the persisted history', () async {
    final s = store();
    await s.save([msg('1', 'x')]);
    expect(await file.exists(), isTrue);
    await s.clear();
    expect(await file.exists(), isFalse);
    expect(await s.load(), isEmpty);
  });

  group('chatHistoryFileName (per-project scoping)', () {
    test('the global chat uses the base file name', () {
      expect(chatHistoryFileName(null), 'chat_history.json');
      expect(chatHistoryFileName('   '), 'chat_history.json');
    });

    test('a project file is keyed by folder name and is deterministic', () {
      final a = chatHistoryFileName('/home/me/dev/rainbow_arc');
      final b = chatHistoryFileName('/home/me/dev/rainbow_arc');
      expect(a, b); // same path → same file across launches
      expect(a, startsWith('chat_history_rainbow_arc_'));
      expect(a, endsWith('.json'));
    });

    test('different projects get different files', () {
      expect(
        chatHistoryFileName('/home/me/a'),
        isNot(chatHistoryFileName('/home/me/b')),
      );
    });

    test('same folder name in different locations does not collide', () {
      expect(
        chatHistoryFileName('/home/me/x/app'),
        isNot(chatHistoryFileName('/home/me/y/app')),
      );
    });

    test('special characters in the folder name are sanitized', () {
      final name = chatHistoryFileName('/tmp/my project (v2)!');
      expect(
        name,
        matches(r'^chat_history_[A-Za-z0-9._-]+_[0-9a-f]{8}\.json$'),
      );
    });
  });
}
