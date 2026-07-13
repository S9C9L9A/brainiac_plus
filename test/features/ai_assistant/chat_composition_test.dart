import 'package:brainiac_plus/features/ai_assistant/models/chat_composition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatComposition', () {
    test('plain text with no attachments serializes to just the text', () {
      const c = ChatComposition(text: '  hello world  ');
      expect(c.toPrompt(), 'hello world');
      expect(c.isNotEmpty, isTrue);
    });

    test('is empty when text is blank and there are no attachments', () {
      expect(const ChatComposition(text: '   ').isEmpty, isTrue);
      expect(const ChatComposition().isEmpty, isTrue);
    });

    test('is not empty when it has an attachment but no text', () {
      const c = ChatComposition(
        attachments: [
          ChatAttachment(kind: AttachmentKind.file, value: 'lib/main.dart'),
        ],
      );
      expect(c.isEmpty, isFalse);
    });

    test('serializes each attachment kind with its usage hint', () {
      const c = ChatComposition(
        text: 'fix the header',
        attachments: [
          ChatAttachment(
            kind: AttachmentKind.file,
            value: 'lib/features/dashboard/header.dart',
          ),
          ChatAttachment(
            kind: AttachmentKind.link,
            value: 'https://x.test/api',
          ),
          ChatAttachment(kind: AttachmentKind.agent, value: 'dashboard'),
          ChatAttachment(
            kind: AttachmentKind.skill,
            value: 'engineering:code-review',
          ),
          ChatAttachment(kind: AttachmentKind.image, value: '/tmp/shot.png'),
        ],
      );

      final prompt = c.toPrompt();
      expect(prompt, startsWith('fix the header'));
      expect(prompt, contains('File: lib/features/dashboard/header.dart'));
      expect(prompt, contains('use read_file'));
      expect(prompt, contains('Link: https://x.test/api'));
      expect(prompt, contains('use fetch'));
      expect(prompt, contains('Agent: dashboard'));
      expect(prompt, contains('Skill: engineering:code-review'));
      expect(prompt, contains('Image: /tmp/shot.png'));
    });

    test('chip display shortens file/image paths but keeps ids and urls', () {
      expect(
        const ChatAttachment(
          kind: AttachmentKind.file,
          value: 'lib/core/theme/app_icons.dart',
        ).display,
        'app_icons.dart',
      );
      expect(
        const ChatAttachment(
          kind: AttachmentKind.agent,
          value: 'terminal',
        ).display,
        'terminal',
      );
      expect(
        const ChatAttachment(
          kind: AttachmentKind.link,
          value: 'https://a.test',
        ).display,
        'https://a.test',
      );
    });

    test('forFile classifies images vs generic files by extension', () {
      expect(
        ChatAttachment.forFile('/tmp/shot.PNG').kind,
        AttachmentKind.image,
      );
      expect(
        ChatAttachment.forFile('/home/me/photo.jpeg').kind,
        AttachmentKind.image,
      );
      expect(
        ChatAttachment.forFile('/src/main.dart').kind,
        AttachmentKind.file,
      );
      expect(
        ChatAttachment.forFile('/data/README').kind, // no extension
        AttachmentKind.file,
      );
      // The full path is preserved as the machine-facing value.
      expect(ChatAttachment.forFile('/a/b.png').value, '/a/b.png');
    });

    test('attachments are equal by kind and value (dedup-friendly)', () {
      const a = ChatAttachment(kind: AttachmentKind.file, value: 'a.dart');
      const b = ChatAttachment(
        kind: AttachmentKind.file,
        value: 'a.dart',
        label: 'different label',
      );
      expect(a, equals(b));
      expect({a, b}, hasLength(1));
    });
  });
}
