import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';

class CommandSuggestions {
  static final List<String> commonCommands = [
    'ls',
    'ls -la',
    'cd',
    'pwd',
    'cat',
    'grep',
    'find',
    'ps',
    'ps aux',
    'top',
    'htop',
    'df -h',
    'du -h',
    'free -h',
    'uname -a',
    'whoami',
    'which',
    'man',
    'apt update',
    'apt upgrade',
    'apt install',
    'apt remove',
    'apt search',
    'systemctl status',
    'systemctl start',
    'systemctl stop',
    'systemctl restart',
    'journalctl -f',
    'git status',
    'git log',
    'git add',
    'git commit',
    'git push',
    'git pull',
    'docker ps',
    'docker images',
    'docker run',
    'docker stop',
    'flutter run',
    'flutter build',
    'npm install',
    'npm run',
    'python3',
    'java -version',
  ];

  static const _maxSuggestions = 5;

  /// Prefix-matching suggestions for [input]. Commands the user actually ran
  /// ([history], oldest→newest as recorded by ShellService) rank first, most
  /// recent on top, deduplicated against the static common list.
  static List<String> getSuggestions(
    String input, {
    List<String> history = const [],
  }) {
    if (input.isEmpty) return [];

    final seen = <String>{};
    final results = <String>[];

    for (final cmd in history.reversed) {
      final trimmed = cmd.trim();
      if (trimmed.startsWith(input) && seen.add(trimmed)) {
        results.add(trimmed);
        if (results.length == _maxSuggestions) return results;
      }
    }
    for (final cmd in commonCommands) {
      if (cmd.startsWith(input) && seen.add(cmd)) {
        results.add(cmd);
        if (results.length == _maxSuggestions) break;
      }
    }
    return results;
  }
}

class SuggestionsList extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelected;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((suggestion) {
          return InkWell(
            onTap: () => onSelected(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.chevronRight,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
