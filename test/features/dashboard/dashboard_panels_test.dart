import 'package:brainiac_plus/core/providers/inference_telemetry_provider.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/dashboard/controllers/project_detail_provider.dart';
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
    // The detail screen embeds the live assistant — give it a desktop surface
    // and silence its background pollers so the test is deterministic.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
          projectCommandRunnerProvider.overrideWithValue((cmd) async => ''),
          ollamaAvailabilityProvider.overrideWith((ref) => false),
          inferenceTelemetryProvider.overrideWith(
            (ref) => InferenceTelemetryNotifier(
              ref.watch(inferenceTelemetryServiceProvider),
              pollInterval: null,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProjectsPanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BUILT APPS'), findsOneWidget);
    expect(find.text('rainbow_arc'), findsOneWidget);

    await tester.tap(find.text('rainbow_arc'));
    // Not pumpAndSettle: the assistant's ambient glow animation never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Navigates to the rich project detail screen with the assistant embedded
    // as the primary panel and the source map in the context rail.
    expect(find.text('SOURCE MAP'), findsOneWidget);
    expect(find.text('BrainiacPlus Assistant'), findsOneWidget);
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
