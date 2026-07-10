import 'package:brainiac_plus/features/ai_assistant/models/agent_task.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/suggested_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(List<AgentAction> actions, {required List<String> pushedLog}) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        pushedLog.add(settings.name ?? '');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('target')),
        );
      },
      home: Scaffold(body: SuggestedActionsBar(actions: actions)),
    );
  }

  testWidgets('renders one chip per navigable action', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      host(const [
        AgentAction(
          id: 'open_terminal',
          label: 'Open Terminal',
          domain: 'terminal',
        ),
        AgentAction(
          id: 'open_packages',
          label: 'Open Package Manager',
          domain: 'packages',
        ),
      ], pushedLog: log),
    );

    expect(find.text('Open Terminal'), findsOneWidget);
    expect(find.text('Open Package Manager'), findsOneWidget);
  });

  testWidgets('hides non-navigable actions and renders nothing when empty', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      host(const [
        AgentAction(
          id: 'refresh_metrics',
          label: 'Refresh System Metrics',
          domain: 'dashboard',
        ),
      ], pushedLog: log),
    );

    expect(find.text('Refresh System Metrics'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('tapping a chip navigates to the mapped route', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      host(const [
        AgentAction(
          id: 'open_terminal',
          label: 'Open Terminal',
          domain: 'terminal',
        ),
      ], pushedLog: log),
    );

    await tester.tap(find.text('Open Terminal'));
    await tester.pumpAndSettle();

    expect(log, contains('/terminal'));
    expect(find.text('target'), findsOneWidget);
  });
}
