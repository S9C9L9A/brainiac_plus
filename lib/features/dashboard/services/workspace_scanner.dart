import 'dart:io';

/// A project the assistant has built (or the user has placed) in the agent
/// workspace — any folder that holds a pubspec.
class WorkspaceProject {
  final String name;
  final String path;
  final String? description;
  final bool hasLib;

  const WorkspaceProject({
    required this.name,
    required this.path,
    this.description,
    required this.hasLib,
  });
}

/// Scans one or more roots for buildable projects, so the dashboard can show
/// everything the user works on — the assistant's own sandbox plus any project
/// folders under the user's development directory. Cheap directory listing: a
/// direct subfolder counts as a project when it contains a pubspec.yaml.
class WorkspaceScanner {
  /// Roots whose immediate subfolders are inspected for projects.
  final List<String> roots;

  WorkspaceScanner(String rootPath) : roots = [rootPath];

  /// Scans several roots and merges the results (deduped by path).
  WorkspaceScanner.roots(this.roots);

  Future<List<WorkspaceProject>> scan() async {
    // Keyed by path so a folder reachable from two roots appears once.
    final projects = <String, WorkspaceProject>{};

    for (final rootPath in roots) {
      final root = Directory(rootPath);
      if (!root.existsSync()) continue;

      final List<FileSystemEntity> entries;
      try {
        entries = root.listSync(followLinks: false);
      } catch (_) {
        continue;
      }

      for (final entity in entries) {
        if (entity is! Directory) continue;
        final pubspec = File('${entity.path}/pubspec.yaml');
        if (!pubspec.existsSync()) continue;

        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        projects[entity.path] = WorkspaceProject(
          name: name,
          path: entity.path,
          description: _readDescription(pubspec),
          hasLib: Directory('${entity.path}/lib').existsSync(),
        );
      }
    }

    final list = projects.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String? _readDescription(File pubspec) {
    try {
      for (final line in pubspec.readAsLinesSync()) {
        final match = RegExp(r'^description:\s*(.+)$').firstMatch(line.trim());
        if (match != null) {
          var value = match.group(1)!.trim();
          // Strip a single pair of surrounding quotes, if present.
          if (value.length >= 2 &&
              (value.startsWith('"') && value.endsWith('"') ||
                  value.startsWith("'") && value.endsWith("'"))) {
            value = value.substring(1, value.length - 1);
          }
          return value;
        }
      }
    } catch (_) {}
    return null;
  }
}
