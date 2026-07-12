import 'dart:io';

import 'package:brainiac_plus/features/ai_assistant/models/agent_profile.dart';
import 'package:brainiac_plus/features/ai_assistant/models/chat_composition.dart';
import 'package:brainiac_plus/features/ai_assistant/services/mention_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const source = MentionSource(
    agents: [
      AgentProfile(
        id: 'dashboard',
        name: 'Dashboard Agent',
        description: 'System metrics and dashboard UI.',
      ),
      AgentProfile(
        id: 'terminal',
        name: 'Terminal Agent',
        description: 'Embedded terminal.',
      ),
    ],
    skills: ['engineering:code-review', 'anthropic-skills:docx'],
    files: [
      'lib/main.dart',
      'lib/features/dashboard/dashboard_screen.dart',
      'lib/core/theme/app_icons.dart',
    ],
  );

  group('MentionSource.query', () {
    test('empty query returns candidates from every kind', () {
      final all = source.query('');
      expect(all.any((c) => c.kind == AttachmentKind.agent), isTrue);
      expect(all.any((c) => c.kind == AttachmentKind.skill), isTrue);
      expect(all.any((c) => c.kind == AttachmentKind.file), isTrue);
    });

    test('matches agents by id', () {
      final r = source.query('term');
      expect(r.first.kind, AttachmentKind.agent);
      expect(r.first.value, 'terminal');
    });

    test('matches files by basename', () {
      final r = source.query('app_icons');
      expect(r.any((c) => c.value == 'lib/core/theme/app_icons.dart'), isTrue);
    });

    test('matches skills by substring', () {
      final r = source.query('docx');
      expect(r.single.kind, AttachmentKind.skill);
      expect(r.single.value, 'anthropic-skills:docx');
    });

    test('prefix matches rank ahead of mid-string matches', () {
      // "dash" prefixes the dashboard agent id and appears mid-path in the
      // dashboard file — the agent should come first.
      final r = source.query('dash');
      expect(r.first.value, 'dashboard');
    });

    test('a candidate converts to an attachment of the same kind/value', () {
      final c = source.query('terminal').first;
      final a = c.toAttachment();
      expect(a.kind, AttachmentKind.agent);
      expect(a.value, 'terminal');
    });
  });

  group('scanProjectFiles', () {
    test('returns lib/ dart files as root-relative paths', () {
      final dir = Directory.systemTemp.createTempSync('mention_scan');
      addTearDown(() => dir.deleteSync(recursive: true));
      Directory('${dir.path}/lib/features').createSync(recursive: true);
      File('${dir.path}/lib/main.dart').writeAsStringSync('void main(){}');
      File('${dir.path}/lib/features/x.dart').writeAsStringSync('class X{}');
      File('${dir.path}/lib/notes.txt').writeAsStringSync('ignore me');

      final files = scanProjectFiles(dir.path);
      expect(files, contains('lib/main.dart'));
      expect(files, contains('lib/features/x.dart'));
      expect(files.any((f) => f.endsWith('.txt')), isFalse);
    });

    test('missing lib/ yields an empty list, not a crash', () {
      final dir = Directory.systemTemp.createTempSync('mention_empty');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(scanProjectFiles(dir.path), isEmpty);
    });
  });
}
