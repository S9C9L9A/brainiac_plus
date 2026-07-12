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
    expect(find.text('SOURCE MAP'), findsOneWidget);
    expect(find.text('RECENT COMMITS'), findsOneWidget);
    expect(find.text('PENDING CHANGES'), findsOneWidget);
    // The scanned source file appears as a node in the constellation.
    expect(find.text('main.dart'), findsOneWidget);

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

    await tester.tap(find.text('Work on this in chat'));
    await tester.pump();

    expect(worked, isTrue);
  });
}
