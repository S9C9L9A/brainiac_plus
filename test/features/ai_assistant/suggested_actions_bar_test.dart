import 'package:brainiac_plus/features/ai_assistant/models/agent_task.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/suggested_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    List<AgentAction> actions, {
    required List<String> pushedLog,
    void Function(AgentAction)? onStateAction,
  }) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        pushedLog.add(settings.name ?? '');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('target')),
        );
      },
      home: Scaffold(
        body: SuggestedActionsBar(
          actions: actions,
          onStateAction: onStateAction,
        ),
      ),
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

  testWidgets('hides unsupported actions and renders nothing when empty', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      host(const [
        AgentAction(
          id: 'not_a_real_action',
          label: 'Mystery Action',
          domain: 'dashboard',
        ),
      ], pushedLog: log),
    );

    expect(find.text('Mystery Action'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('state actions render a chip and invoke the callback on tap', (
    tester,
  ) async {
    final log = <String>[];
    final executed = <String>[];
    await tester.pumpWidget(
      host(
        const [
          AgentAction(
            id: 'refresh_metrics',
            label: 'Refresh System Metrics',
            domain: 'dashboard',
          ),
        ],
        pushedLog: log,
        onStateAction: (a) => executed.add(a.id),
      ),
    );

    await tester.tap(find.text('Refresh System Metrics'));
    await tester.pumpAndSettle();

    expect(executed, ['refresh_metrics']);
    expect(log, isEmpty); // no navigation happened
  });

  testWidgets('state actions are hidden when no callback is provided', (
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
  });

  testWidgets('navigation passes action params as route arguments', (
    tester,
  ) async {
    final log = <String>[];
    Object? receivedArguments;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          log.add(settings.name ?? '');
          receivedArguments = settings.arguments;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('target')),
          );
        },
        home: Scaffold(
          body: SuggestedActionsBar(
            actions: const [
              AgentAction(
                id: 'new_task',
                label: 'Create New Automation Task',
                domain: 'automation',
                params: {'cron': '0 9 * * *'},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Create New Automation Task'));
    await tester.pumpAndSettle();

    expect(log, contains('/automation/create'));
    expect(receivedArguments, {'cron': '0 9 * * *'});
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
