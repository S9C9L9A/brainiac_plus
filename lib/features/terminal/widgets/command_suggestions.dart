import 'package:flutter/material.dart';

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

  static List<String> getSuggestions(String input) {
    if (input.isEmpty) return [];
    
    return commonCommands
        .where((cmd) => cmd.startsWith(input))
        .take(5)
        .toList();
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
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((suggestion) {
          return InkWell(
            onTap: () => onSelected(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_forward,
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
