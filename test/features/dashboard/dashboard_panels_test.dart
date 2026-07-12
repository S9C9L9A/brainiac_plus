import 'package:brainiac_plus/features/dashboard/controllers/projects_provider.dart';
import 'package:brainiac_plus/features/dashboard/services/workspace_scanner.dart';
import 'package:brainiac_plus/features/dashboard/widgets/hud/projects_panel.dart';
import 'package:brainiac_plus/features/dashboard/widgets/hud/socials_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProjectsPanel lists built apps and opens a detail sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProjectsProvider.overrideWith(
            (ref) async => const [
              WorkspaceProject(
                name: 'rainbow_arc',
                path: '/ws/rainbow_arc',
                description: 'A rainbow demo',
                hasLib: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProjectsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BUILT APPS'), findsOneWidget);
    expect(find.text('rainbow_arc'), findsOneWidget);

    await tester.tap(find.text('rainbow_arc'));
    await tester.pumpAndSettle();
    // Sheet-only content confirms it opened.
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('/ws/rainbow_arc'), findsOneWidget);
  });

  testWidgets('ProjectsPanel shows an empty state with no apps', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProjectsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: ProjectsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No apps yet'), findsOneWidget);
  });

  testWidgets('SocialsPanel shows the connect prompt when none are linked', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SocialsPanel())),
      ),
    );
    await tester.pump();

    expect(find.text('SOCIAL FEEDS'), findsOneWidget);
    expect(find.text('CONNECT'), findsOneWidget);
  });
}
