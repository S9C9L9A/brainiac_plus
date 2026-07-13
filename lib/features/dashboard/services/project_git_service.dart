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

  Future<bool> hasRemote() async {
    final out = await _run('git -C "$path" remote 2>/dev/null');
    return out.trim().isNotEmpty;
  }

  /// Initializes a git repository in the project folder, so a plain folder
  /// becomes trackable. Returns the command's output.
  Future<String> init() async {
    final out = await _run('git -C "$path" init 2>&1');
    return out.trim();
  }

  /// Syncs the project: stage everything, commit (only if there's something to
  /// commit), then — when a remote is configured — pull --rebase and push.
  /// Returns a human-readable transcript of what ran. Every step is best-effort
  /// and its output is captured, so a failing push still reports why.
  Future<String> sync({required String message}) async {
    if (!await isGitRepo()) {
      return 'Not a git repository. Initialize git first, then sync.';
    }
    final buf = StringBuffer();

    Future<void> step(String sub) async {
      buf.writeln('\$ git $sub');
      final out = await _run('git -C "$path" $sub 2>&1');
      final trimmed = out.trim();
      if (trimmed.isNotEmpty) buf.writeln(trimmed);
    }

    await step('add -A');

    final staged = await _run(
      'git -C "$path" diff --cached --name-only 2>/dev/null',
    );
    if (staged.trim().isEmpty) {
      buf.writeln('(nothing to commit)');
    } else {
      await step('commit -m ${_quote(message)}');
    }

    if (await hasRemote()) {
      await step('pull --rebase');
      await step('push');
    } else {
      buf.writeln('(no remote configured — skipped pull/push)');
    }

    return buf.toString().trim();
  }

  /// Wraps [s] in single quotes for the shell, escaping embedded single quotes.
  static String _quote(String s) => "'${s.replaceAll("'", r"'\''")}'";
}
