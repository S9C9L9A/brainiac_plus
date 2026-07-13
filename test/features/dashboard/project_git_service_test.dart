import 'package:brainiac_plus/features/dashboard/services/project_git_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fake runner that answers based on the command it receives.
  ProjectGitService service(Map<String, String> responses) {
    return ProjectGitService(
      '/proj',
      runCommand: (cmd) async {
        for (final entry in responses.entries) {
          if (cmd.contains(entry.key)) return entry.value;
        }
        return '';
      },
    );
  }

  group('recentCommits', () {
    test('parses the log into commits', () async {
      final s = service({
        'log -n':
            'a1b2c3Initial commit2 days agoGenna\n'
            'd4e5f6Add rainbow1 hour agoClaude',
      });

      final commits = await s.recentCommits();

      expect(commits, hasLength(2));
      expect(commits.first.hash, 'a1b2c3');
      expect(commits.first.subject, 'Initial commit');
      expect(commits.first.date, '2 days ago');
      expect(commits.first.author, 'Genna');
    });

    test('empty log yields no commits', () async {
      final commits = await service({}).recentCommits();
      expect(commits, isEmpty);
    });
  });

  group('changedFiles', () {
    test('parses porcelain status into path + status code', () async {
      final s = service({
        'status --porcelain':
            ' M lib/main.dart\n?? new_file.dart\nA  added.txt',
      });

      final changes = await s.changedFiles();

      expect(changes, hasLength(3));
      expect(changes[0].path, 'lib/main.dart');
      expect(changes[0].code, 'M');
      expect(changes[1].path, 'new_file.dart');
      expect(changes[1].code, '??');
    });

    test('a clean tree yields no changes', () async {
      final changes = await service({}).changedFiles();
      expect(changes, isEmpty);
    });
  });

  group('isGitRepo', () {
    test('true when rev-parse succeeds', () async {
      final s = service({'rev-parse': 'true'});
      expect(await s.isGitRepo(), isTrue);
    });

    test('false when rev-parse is empty', () async {
      expect(await service({}).isGitRepo(), isFalse);
    });
  });

  group('init', () {
    test('runs git init and returns its output', () async {
      final cmds = <String>[];
      final s = ProjectGitService(
        '/proj',
        runCommand: (cmd) async {
          cmds.add(cmd);
          return 'Initialized empty Git repository';
        },
      );
      final out = await s.init();
      expect(cmds.single, contains('init'));
      expect(out, contains('Initialized'));
    });
  });

  group('sync', () {
    ProjectGitService recording(
      List<String> sink, {
      required bool repo,
      required String staged,
      required String remote,
    }) {
      return ProjectGitService(
        '/proj',
        runCommand: (cmd) async {
          sink.add(cmd);
          if (cmd.contains('is-inside-work-tree')) return repo ? 'true' : '';
          if (cmd.contains('diff --cached')) return staged;
          if (cmd.contains('remote')) return remote;
          return '';
        },
      );
    }

    test(
      'stages, commits, pulls and pushes for a repo with a remote',
      () async {
        final cmds = <String>[];
        await recording(
          cmds,
          repo: true,
          staged: 'lib/main.dart',
          remote: 'origin',
        ).sync(message: 'my sync');

        expect(cmds.any((c) => c.contains('add -A')), isTrue);
        expect(cmds.any((c) => c.contains("commit -m 'my sync'")), isTrue);
        expect(cmds.any((c) => c.contains('pull --rebase')), isTrue);
        expect(cmds.any((c) => c.contains('push')), isTrue);
      },
    );

    test('skips the commit when nothing is staged', () async {
      final cmds = <String>[];
      final out = await recording(
        cmds,
        repo: true,
        staged: '',
        remote: 'origin',
      ).sync(message: 'x');

      expect(cmds.any((c) => c.contains('commit -m')), isFalse);
      expect(out, contains('nothing to commit'));
    });

    test('skips pull/push when there is no remote', () async {
      final cmds = <String>[];
      final out = await recording(
        cmds,
        repo: true,
        staged: 'a',
        remote: '',
      ).sync(message: 'x');

      expect(cmds.any((c) => c.contains('push')), isFalse);
      expect(out, contains('no remote'));
    });

    test('refuses to sync a non-git folder', () async {
      final cmds = <String>[];
      final out = await recording(
        cmds,
        repo: false,
        staged: '',
        remote: '',
      ).sync(message: 'x');
      expect(out, contains('Not a git repository'));
    });

    test('quotes a commit message that contains a single quote', () async {
      final cmds = <String>[];
      await recording(
        cmds,
        repo: true,
        staged: 'a',
        remote: '',
      ).sync(message: "it's a fix");
      expect(cmds.any((c) => c.contains("commit -m 'it'")), isTrue);
    });
  });
}
