import 'package:brainiac_plus/features/terminal/services/command_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final guard = CommandGuard();

  group('CommandGuard — dangerous commands', () {
    const dangerous = <String>[
      'rm -rf /',
      'rm -fr ~',
      'sudo rm -rf /var',
      'ls; rm -rf /home',
      'dd if=/dev/zero of=/dev/sda',
      'mkfs.ext4 /dev/sda1',
      'shutdown now',
      'reboot',
      'poweroff',
      'git push --force',
      'git push -f origin main',
      'chmod -R 777 /',
      ':(){ :|:& };:',
      'echo x > /dev/sda',
    ];

    for (final cmd in dangerous) {
      test('flags `$cmd`', () {
        final check = guard.assess(cmd);
        expect(check.isDangerous, isTrue, reason: cmd);
        expect(check.reason, isNotNull);
      });
    }
  });

  group('CommandGuard — safe commands', () {
    const safe = <String>[
      'ls -la',
      'git status',
      'git push',
      'echo hello',
      'rm file.txt',
      'grep -rf patterns.txt .',
      'cat /etc/hostname',
      'flutter test',
      '',
    ];

    for (final cmd in safe) {
      test('allows `$cmd`', () {
        expect(guard.assess(cmd).isDangerous, isFalse, reason: cmd);
      });
    }
  });
}
