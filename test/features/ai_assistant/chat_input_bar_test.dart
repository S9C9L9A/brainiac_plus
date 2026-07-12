import 'package:brainiac_plus/core/theme/app_icons.dart';
import 'package:brainiac_plus/features/ai_assistant/models/agent_profile.dart';
import 'package:brainiac_plus/features/ai_assistant/models/chat_composition.dart';
import 'package:brainiac_plus/features/ai_assistant/services/mention_source.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/chat_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const source = MentionSource(
    agents: [
      AgentProfile(
        id: 'dashboard',
        name: 'Dashboard Agent',
        description: 'Metrics.',
      ),
    ],
    skills: ['engineering:code-review'],
    files: ['lib/main.dart'],
  );

  Widget host(void Function(ChatComposition) onSend) {
    return ProviderScope(
      overrides: [mentionSourceProvider.overrideWithValue(source)],
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(onSend: onSend),
          ),
        ),
      ),
    );
  }

  testWidgets('typing text and tapping send emits a composition', (
    tester,
  ) async {
    ChatComposition? sent;
    await tester.pumpWidget(host((c) => sent = c));

    await tester.enterText(find.byType(TextField), 'add a battery widget');
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.text, 'add a battery widget');
    expect(sent!.attachments, isEmpty);
  });

  testWidgets('send is inert while the composer is empty', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host((_) => calls++));

    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('typing @ shows the mention popup and picking one adds a chip', (
    tester,
  ) async {
    ChatComposition? sent;
    await tester.pumpWidget(host((c) => sent = c));

    await tester.enterText(find.byType(TextField), 'fix @dash');
    await tester.pump();

    // The popup surfaces the matching agent.
    expect(find.text('Dashboard Agent'), findsOneWidget);

    await tester.tap(find.text('Dashboard Agent'));
    await tester.pump();

    // The @query is stripped from the field and a chip appears.
    expect(find.text('dashboard'), findsOneWidget); // chip label
    expect(find.text('Dashboard Agent'), findsNothing); // popup gone

    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.text, 'fix');
    expect(sent!.attachments.single.kind, AttachmentKind.agent);
    expect(sent!.attachments.single.value, 'dashboard');
  });

  testWidgets('a message with only an attachment can still be sent', (
    tester,
  ) async {
    ChatComposition? sent;
    await tester.pumpWidget(host((c) => sent = c));

    await tester.enterText(find.byType(TextField), '@main');
    await tester.pump();
    await tester.tap(find.text('main.dart'));
    await tester.pump();

    // Field is now empty but the file chip remains → send is active.
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.text, isEmpty);
    expect(sent!.attachments.single.value, 'lib/main.dart');
  });
}
