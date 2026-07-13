import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workspace_scanner.dart';

/// Scanner over the places the user works: the agent sandbox (where the
/// assistant builds apps) plus `~/sviluppo`, the user's development folder —
/// anything with a pubspec there is a project you work on. Overridable in
/// tests.
final workspaceScannerProvider = Provider<WorkspaceScanner>((ref) {
  final home = Platform.environment['HOME'] ?? Directory.current.path;
  return WorkspaceScanner.roots([
    '${Directory.current.path}/agent_workspace',
    '$home/sviluppo',
  ]);
});

/// Projects/apps the assistant has built, for the dashboard panel.
final workspaceProjectsProvider = FutureProvider<List<WorkspaceProject>>((
  ref,
) async {
  return ref.watch(workspaceScannerProvider).scan();
});
