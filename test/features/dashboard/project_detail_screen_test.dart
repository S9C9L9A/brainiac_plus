import 'dart:io';

import 'package:brainiac_plus/features/dashboard/controllers/project_detail_provider.dart';
import 'package:brainiac_plus/features/dashboard/screens/project_detail_screen.dart';
import 'package:brainiac_plus/features/dashboard/services/workspace_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _fakeGit = <Override>[
  projectCommandRunnerProvider.overrideWithValue((cmd) async => ''),
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
    await tester.pumpAndSettle();
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

  testWidgets('the work-in-chat button invokes the callback', (tester) async {
    var worked = false;
    final project = WorkspaceProject(
      name: 'demo',
      path: proj.path,
      hasLib: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _fakeGit,
        child: MaterialApp(
          home: ProjectDetailScreen(
            project: project,
            onWorkInChat: (_) => worked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Work in chat'));
    await tester.pump();

    expect(worked, isTrue);
  });
}
