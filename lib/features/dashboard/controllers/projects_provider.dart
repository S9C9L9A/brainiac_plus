import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workspace_scanner.dart';

/// Scanner over the places the user works: the agent sandbox (where the
/// assistant builds apps) plus `~/sviluppo`, the user's development folder —
/// anything with a pubspec there is a project you work on. Overridable in
/// tests.
final workspaceScannerProvider = Provider<WorkspaceScanner>((ref) {
  final home = Platform.environment['HOME'] ?? Directory.current.path;
  // Both roots are ABSOLUTE (anchored to $home). agent_workspace used to be
  // '${Directory.current.path}/agent_workspace' — relative to the launch CWD —
  // so it vanished whenever the dashboard was started from a folder other than
  // ~/BrainiacPlus. Anchoring it to $home makes it resolve regardless of CWD.
  return WorkspaceScanner.roots([
    '$home/BrainiacPlus/agent_workspace',
    '$home/sviluppo',
  ]);
});

/// Projects/apps the assistant has built, for the dashboard panel.
final workspaceProjectsProvider = FutureProvider<List<WorkspaceProject>>((
  ref,
) async {
  return ref.watch(workspaceScannerProvider).scan();
});
