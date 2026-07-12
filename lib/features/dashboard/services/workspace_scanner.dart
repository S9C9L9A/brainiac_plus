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

/// Scans the agent workspace for buildable projects, so the dashboard can show
/// what the assistant has created. Cheap directory listing — a folder counts
/// as a project when it contains a pubspec.yaml.
class WorkspaceScanner {
  final String rootPath;

  WorkspaceScanner(this.rootPath);

  Future<List<WorkspaceProject>> scan() async {
    final root = Directory(rootPath);
    if (!root.existsSync()) return const [];

    final List<FileSystemEntity> entries;
    try {
      entries = root.listSync(followLinks: false);
    } catch (_) {
      return const [];
    }

    final projects = <WorkspaceProject>[];
    for (final entity in entries) {
      if (entity is! Directory) continue;
      final pubspec = File('${entity.path}/pubspec.yaml');
      if (!pubspec.existsSync()) continue;

      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      projects.add(
        WorkspaceProject(
          name: name,
          path: entity.path,
          description: _readDescription(pubspec),
          hasLib: Directory('${entity.path}/lib').existsSync(),
        ),
      );
    }

    projects.sort((a, b) => a.name.compareTo(b.name));
    return projects;
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
