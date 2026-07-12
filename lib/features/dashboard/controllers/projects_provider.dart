import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workspace_scanner.dart';

/// Scanner over the agent sandbox — the folder where the assistant builds
/// apps. Overridable in tests. Uses the same path convention as the agent
/// executor (Directory.current/agent_workspace).
final workspaceScannerProvider = Provider<WorkspaceScanner>((ref) {
  return WorkspaceScanner('${Directory.current.path}/agent_workspace');
});

/// Projects/apps the assistant has built, for the dashboard panel.
final workspaceProjectsProvider = FutureProvider<List<WorkspaceProject>>((
  ref,
) async {
  return ref.watch(workspaceScannerProvider).scan();
});
