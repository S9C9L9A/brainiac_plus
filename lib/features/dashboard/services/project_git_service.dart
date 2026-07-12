/// Runs a shell command and returns its output. Injectable for tests.
typedef CommandRunner = Future<String> Function(String command);

/// A commit in a project's history.
class GitCommit {
  final String hash;
  final String subject;
  final String date; // relative, e.g. "2 days ago"
  final String author;

  const GitCommit({
    required this.hash,
    required this.subject,
    required this.date,
    required this.author,
  });
}

/// An uncommitted change in the working tree.
class GitChange {
  final String code; // porcelain status, e.g. "M", "??", "A"
  final String path;

  const GitChange({required this.code, required this.path});
}

/// Reads a project's git history and working-tree state so the project view
/// can show recent commits and what has changed since. Degrades to empty for
/// non-git folders — every read is best-effort.
class ProjectGitService {
  final String path;
  final CommandRunner _run;

  ProjectGitService(this.path, {required CommandRunner runCommand})
    : _run = runCommand;

  // Unit separators keep the parse robust against spaces in fields.
  static const _fs = ''; // field

  Future<bool> isGitRepo() async {
    final out = await _run(
      'git -C "$path" rev-parse --is-inside-work-tree 2>/dev/null',
    );
    return out.trim() == 'true';
  }

  Future<List<GitCommit>> recentCommits({int limit = 10}) async {
    final fmt = '%h$_fs%s$_fs%cr$_fs%an';
    final out = await _run(
      'git -C "$path" log -n $limit --pretty=format:"$fmt" 2>/dev/null',
    );
    final commits = <GitCommit>[];
    for (final record in out.split('\n')) {
      final line = record.trim();
      if (line.isEmpty) continue;
      final f = line.split(_fs);
      if (f.length < 4) continue;
      commits.add(
        GitCommit(
          hash: f[0].trim(),
          subject: f[1].trim(),
          date: f[2].trim(),
          author: f[3].trim(),
        ),
      );
    }
    return commits;
  }

  Future<List<GitChange>> changedFiles() async {
    final out = await _run('git -C "$path" status --porcelain 2>/dev/null');
    final changes = <GitChange>[];
    for (final line in out.split('\n')) {
      if (line.trim().isEmpty) continue;
      // Porcelain: two status chars, a space, then the path.
      final code = line.substring(0, 2).trim();
      final path = line.length > 3 ? line.substring(3).trim() : '';
      if (path.isEmpty) continue;
      changes.add(GitChange(code: code, path: path));
    }
    return changes;
  }
}
