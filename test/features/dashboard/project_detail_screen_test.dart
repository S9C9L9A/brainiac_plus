import 'dart:io';

import 'package:brainiac_plus/core/providers/inference_telemetry_provider.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/dashboard/controllers/project_detail_provider.dart';
import 'package:brainiac_plus/features/dashboard/screens/project_detail_screen.dart';
import 'package:brainiac_plus/features/dashboard/services/workspace_scanner.dart';
import 'package:brainiac_plus/features/dashboard/widgets/panels/floating_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// The project screen now embeds the live assistant. Silence its background
// pollers (Ollama HTTP check, telemetry timer) so widget tests stay
// deterministic and leave no pending timers.
final _fakeGit = <Override>[
  projectCommandRunnerProvider.overrideWithValue((cmd) async => ''),
  ollamaAvailabilityProvider.overrideWith((ref) => false),
  inferenceTelemetryProvider.overrideWith(
    (ref) => InferenceTelemetryNotifier(
      ref.watch(inferenceTelemetryServiceProvider),
      pollInterval: null,
    ),
  ),
];

void main() {
  late Directory proj;

  setUp(() {
    proj = Directory.systemTemp.createTempSync('proj_detail');
    Directory('${proj.path}/lib').createSync(recursive: true);
    File('${proj.path}/lib/main.dart').writeAsStringSync('void main() {}');
  });

  tearDown(() => proj.deleteSync(recursive: true));

  testWidgets('shows the project name, source map and git sections', (
    tester,
  ) async {
    // Wide surface so the context rail (source map + git) is shown inline
    // beside the assistant, which is the primary panel here.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'rainbow_arc',
      path: proj.path,
      description: 'A rainbow demo',
      hasLib: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    expect(find.text('rainbow_arc'), findsWidgets);
    // One-page content + a collapsible console dock.
    expect(find.text('CONSOLE'), findsOneWidget);
    expect(find.text('SOURCE MAP'), findsOneWidget);
    expect(find.text('RECENT COMMITS'), findsOneWidget);
    // Run target selector offers all three platforms.
    expect(find.text('Linux'), findsOneWidget);
    expect(find.text('Web'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Run'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the assistant is embedded as the primary panel (no FAB)', (
    tester,
  ) async {
    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    // The assistant panel is on screen, and the old floating button is gone.
    expect(find.text('BrainiacPlus Assistant'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders on a wide desktop surface without overflow/crash', (
    tester,
  ) async {
    // Regression: the wide layout used SizedBox(height: infinity) inside a
    // Column, which sent the constellation an infinite canvas and crashed.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'wide',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('SOURCE MAP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the console dock reveals the log when its bar is tapped', (
    tester,
  ) async {
    // A realistic desktop surface: the embedded assistant plus an open console
    // need vertical room (the default 600px is shorter than any real window).
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    const hint = 'Press Run to launch this project and watch its log here.';
    expect(find.text(hint), findsNothing); // collapsed

    await tester.tap(find.text('CONSOLE'));
    // Not pumpAndSettle: the assistant's ambient glow animation repeats
    // forever, so the tree never "settles" — pump past the expand animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(hint), findsOneWidget); // expanded

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Launch (fast) is disabled without a build, enabled with one', (
    tester,
  ) async {
    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );

    Future<void> pump() => tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );

    await pump();
    await tester.pump();
    final fast = find.widgetWithText(OutlinedButton, 'Launch (fast)');
    expect(fast, findsOneWidget);
    expect(tester.widget<OutlinedButton>(fast).onPressed, isNull); // disabled

    // Add a built Linux bundle → the button enables.
    final bundle = Directory('${proj.path}/build/linux/x64/debug/bundle')
      ..createSync(recursive: true);
    final exe = File('${bundle.path}/demo')..writeAsStringSync('bin');
    Process.runSync('chmod', ['+x', exe.path]);

    await pump();
    await tester.pump();
    expect(tester.widget<OutlinedButton>(fast).onPressed, isNotNull); // enabled

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a file node opens its code in the side panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    // The source map shows the scanned file as a node.
    expect(find.text('main.dart'), findsWidgets);
    await tester.tap(find.text('main.dart').first);
    await tester.pump();

    // The side panel shows the file's code and edit controls.
    expect(find.text('void main() {}'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    expect(find.text('Edit with AI'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('popping out the source map floats it, then it re-docks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    expect(find.byType(FloatingPanel), findsNothing);

    // Pop the source map out into a floating window.
    await tester.tap(find.byTooltip('Pop out').first);
    await tester.pump();
    expect(find.byType(FloatingPanel), findsOneWidget);

    // Dock it back.
    await tester.tap(find.byTooltip('Dock'));
    await tester.pump();
    expect(find.byType(FloatingPanel), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('source map and git each have a pop-out; git can float', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    // Two docked, poppable panels: source map and git.
    expect(find.byTooltip('Pop out'), findsNWidgets(2));

    // Pop the git panel (the second one) out.
    await tester.tap(find.byTooltip('Pop out').last);
    await tester.pump();
    expect(find.byType(FloatingPanel), findsOneWidget);
    // Its git content is present in the floating window.
    expect(find.text('RECENT COMMITS'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the context toggle hides the rail for a focused chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(home: ProjectDetailScreen(project: project)),
      ),
    );
    await tester.pump();

    // Context visible inline by default…
    expect(find.text('SOURCE MAP'), findsOneWidget);
    // …tap the header toggle to hide it (focus mode).
    await tester.tap(find.byTooltip('Hide project context'));
    await tester.pump();
    expect(find.text('SOURCE MAP'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
