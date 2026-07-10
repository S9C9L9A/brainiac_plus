import 'package:brainiac_plus/features/terminal/widgets/command_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty input yields no suggestions', () {
    expect(CommandSuggestions.getSuggestions(''), isEmpty);
  });

  test('common commands still match by prefix', () {
    final s = CommandSuggestions.getSuggestions('git s');
    expect(s, contains('git status'));
  });

  test('history entries rank before common commands, most recent first', () {
    final s = CommandSuggestions.getSuggestions(
      'git',
      history: ['git log --oneline', 'git diff HEAD~1'],
    );

    // Most recent history entry first, then older, then the common list.
    expect(s.first, 'git diff HEAD~1');
    expect(s[1], 'git log --oneline');
    expect(s.indexOf('git status'), greaterThan(1));
  });

  test('history entries are deduplicated against common commands', () {
    final s = CommandSuggestions.getSuggestions(
      'ls',
      history: ['ls -la', 'ls -la', 'ls -la'],
    );

    expect(s.where((c) => c == 'ls -la'), hasLength(1));
  });

  test('caps suggestions at five', () {
    final s = CommandSuggestions.getSuggestions(
      'git',
      history: [
        'git one',
        'git two',
        'git three',
        'git four',
        'git five',
        'git six',
      ],
    );

    expect(s, hasLength(5));
  });
}
