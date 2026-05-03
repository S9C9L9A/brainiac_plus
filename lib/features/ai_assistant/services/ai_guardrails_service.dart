import '../models/agent_profile.dart';

class AiGuardrailsService {
  static const List<String> _blockedPaths = [
    'pubspec.yaml',
    'pubspec.lock',
    'lib/main.dart',
    'android/',
    'ios/',
    'linux/',
    'macos/',
    'windows/',
    '.dart_tool/',
    'build/',
  ];

  List<String>? filterFilePaths(AgentProfile agent, List<String>? paths) {
    if (paths == null || paths.isEmpty) return paths;

    final filtered = paths.where((path) => _isAllowed(agent, path)).toList();
    return filtered.isEmpty ? null : filtered;
  }

  bool _isAllowed(AgentProfile agent, String path) {
    for (final blocked in _blockedPaths) {
      if (path == blocked || path.startsWith(blocked)) {
        return false;
      }
    }

    for (final allowed in agent.allowedPaths) {
      if (path.startsWith(allowed)) {
        return true;
      }
    }

    return false;
  }
}
