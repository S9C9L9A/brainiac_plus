import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shell_service.dart';
import '../../ai_assistant/knowledge/knowledge_graph.dart';
import '../services/project_git_service.dart';
import '../services/project_graph_builder.dart';

/// Source-file graph for a project, built once and cached per path (keeps the
/// synchronous filesystem scan off the widget build path).
final projectGraphProvider = Provider.family<KnowledgeGraph, String>((
  ref,
  path,
) {
  final name = path.split('/').where((s) => s.isNotEmpty).last;
  return ProjectGraphBuilder.build(path, name: name);
});

/// Shell runner behind the project git reads. Overridable in tests so they
/// never spawn real `git` subprocesses.
final projectCommandRunnerProvider = Provider<CommandRunner>((ref) {
  return ShellService().executeSync;
});

final _gitServiceProvider = Provider.family<ProjectGitService, String>((
  ref,
  path,
) {
  return ProjectGitService(
    path,
    runCommand: ref.watch(projectCommandRunnerProvider),
  );
});

/// Recent commits for a project directory.
final projectCommitsProvider = FutureProvider.family<List<GitCommit>, String>((
  ref,
  path,
) {
  return ref.watch(_gitServiceProvider(path)).recentCommits(limit: 8);
});

/// Uncommitted changes for a project directory.
final projectChangesProvider = FutureProvider.family<List<GitChange>, String>((
  ref,
  path,
) {
  return ref.watch(_gitServiceProvider(path)).changedFiles();
});
