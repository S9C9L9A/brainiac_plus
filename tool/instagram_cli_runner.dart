import 'dart:io';

import 'package:args/args.dart';
import '../lib/core/services/instagram_cli_service.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addCommand('check')
    ..addCommand('feed')
    ..addCommand('stories')
    ..addCommand('notify')
    ..addCommand('chat')
    ..addCommand('raw');

  parser.commands['chat']
    ?..addOption('user', abbr: 'u', help: 'Instagram username')
    ..addOption('title', abbr: 't', help: 'Chat title');

  parser.commands['raw']?.addMultiOption(
    'args',
    abbr: 'a',
    help: 'Raw arguments passed to instagram-cli',
    splitCommas: false,
  );

  final result = parser.parse(args);

  if (result['help'] == true || result.command == null) {
    _printUsage(parser);
    exit(0);
  }

  final service = InstagramCliService();

  switch (result.command?.name) {
    case 'check':
      final available = await service.isAvailable();
      stdout.writeln(available ? 'instagram-cli: available' : 'instagram-cli: missing');
      exit(available ? 0 : 1);
    case 'feed':
      await _run(service.feed());
      break;
    case 'stories':
      await _run(service.stories());
      break;
    case 'notify':
      await _run(service.notify());
      break;
    case 'chat':
      final user = result.command?['user'] as String?;
      if (user == null || user.trim().isEmpty) {
        stderr.writeln('Missing --user for chat.');
        exit(2);
      }
      final title = result.command?['title'] as String?;
      await _run(service.chat(username: user, title: title));
      break;
    case 'raw':
      final rawArgs = (result.command?['args'] as List<String>? ?? []).toList();
      if (rawArgs.isEmpty) {
        stderr.writeln('Missing --args for raw.');
        exit(2);
      }
      await _run(service.runRaw(rawArgs));
      break;
    default:
      _printUsage(parser);
      exit(1);
  }
}

Future<void> _run(Future<InstagramCliResult> future) async {
  final result = await future;
  if (result.stdout.isNotEmpty) {
    stdout.write(result.stdout);
  }
  if (result.stderr.isNotEmpty) {
    stderr.write(result.stderr);
  }
  exit(result.exitCode);
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Instagram CLI runner');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart tool/instagram_cli_runner.dart check');
  stdout.writeln('  dart tool/instagram_cli_runner.dart feed');
  stdout.writeln('  dart tool/instagram_cli_runner.dart stories');
  stdout.writeln('  dart tool/instagram_cli_runner.dart notify');
  stdout.writeln('  dart tool/instagram_cli_runner.dart chat --user <username> [--title <title>]');
  stdout.writeln('  dart tool/instagram_cli_runner.dart raw --args <args...>');
  stdout.writeln('');
  stdout.writeln(parser.usage);
}
