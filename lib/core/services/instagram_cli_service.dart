import 'dart:async';
import 'dart:io';

class InstagramCliResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const InstagramCliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get success => exitCode == 0;
}

class InstagramCliService {
  static const String _binary = 'instagram-cli';
  static const String _envOverride = 'INSTAGRAM_CLI_PATH';
  static const Duration _defaultTimeout = Duration(seconds: 20);

  String? _resolvedBinaryPath;
  bool _resolutionAttempted = false;

  Future<bool> isAvailable({Duration timeout = _defaultTimeout}) async {
    if (!_isDesktop()) return false;
    final result = await runRaw(['--help'], timeout: timeout);
    return result.exitCode == 0;
  }

  Future<InstagramCliResult> runRaw(
    List<String> args, {
    Duration timeout = _defaultTimeout,
    String? workingDirectory,
  }) async {
    if (!_isDesktop()) {
      return const InstagramCliResult(
        exitCode: 1,
        stdout: '',
        stderr: 'instagram-cli is supported only on desktop platforms.',
      );
    }

    final env = _buildEnvironment();
    final binary = await _resolveBinary(timeout: timeout) ?? _binary;

    try {
      final result = await Process.run(
        binary,
        args,
        workingDirectory: workingDirectory,
        environment: env,
      ).timeout(timeout);

      return InstagramCliResult(
        exitCode: result.exitCode,
        stdout: (result.stdout ?? '').toString(),
        stderr: (result.stderr ?? '').toString(),
      );
    } on TimeoutException {
      return const InstagramCliResult(
        exitCode: 124,
        stdout: '',
        stderr: 'instagram-cli timed out.',
      );
    } on ProcessException catch (e) {
      return InstagramCliResult(
        exitCode: 1,
        stdout: '',
        stderr: 'instagram-cli not found in PATH. ${e.message}',
      );
    } on Exception catch (e) {
      return InstagramCliResult(
        exitCode: 1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  Future<String?> _resolveBinary({Duration timeout = _defaultTimeout}) async {
    if (_resolvedBinaryPath != null) return _resolvedBinaryPath;
    if (_resolutionAttempted) return null;
    _resolutionAttempted = true;

    final env = _buildEnvironment();

    final override = env[_envOverride];
    if (override != null && override.trim().isNotEmpty) {
      final candidate = override.trim();
      if (await _isExecutable(candidate)) {
        _resolvedBinaryPath = candidate;
        return candidate;
      }
    }

    try {
      final result = await Process.run(
        'which',
        [_binary],
        environment: env,
      ).timeout(timeout);
      if (result.exitCode == 0) {
        final path = (result.stdout ?? '').toString().trim();
        if (path.isNotEmpty) {
          _resolvedBinaryPath = path;
          return path;
        }
      }
    } on Exception {
      // Ignore and fallback to npm prefix lookup.
    }

    final npmResolved = await _resolveFromNpmPrefix(env, timeout: timeout);
    if (npmResolved != null) {
      _resolvedBinaryPath = npmResolved;
      return npmResolved;
    }

    return null;
  }

  Future<String?> _resolveFromNpmPrefix(
    Map<String, String> env, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final result = await Process.run(
        'npm',
        ['config', 'get', 'prefix'],
        environment: env,
      ).timeout(timeout);
      if (result.exitCode != 0) return null;

      final prefix = (result.stdout ?? '').toString().trim();
      if (prefix.isEmpty) return null;

      final candidate = '$prefix/bin/$_binary';
      if (await _isExecutable(candidate)) {
        return candidate;
      }
    } on Exception {
      return null;
    }

    return null;
  }

  Future<bool> _isExecutable(String path) async {
    try {
      final stat = await File(path).stat();
      return stat.type == FileSystemEntityType.file;
    } on Exception {
      return false;
    }
  }

  Map<String, String> _buildEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    final home = env['HOME'] ?? '';

    final path = env['PATH'] ?? '';
    final extras = <String>[
      if (home.isNotEmpty) '$home/.npm-global/bin',
      if (home.isNotEmpty) '$home/.npm/bin',
      if (home.isNotEmpty) '$home/.local/share/npm/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
    ];

    final mergedPath = <String>[
      if (path.isNotEmpty) path,
      ...extras.where((p) => p.isNotEmpty),
    ].join(':');

    env['PATH'] = mergedPath;
    return env;
  }

  Future<InstagramCliResult> feed() => runRaw(['feed']);

  Future<InstagramCliResult> stories() => runRaw(['stories']);

  Future<InstagramCliResult> notify() => runRaw(['notify']);

  Future<InstagramCliResult> chat({
    required String username,
    String? title,
  }) {
    final args = ['chat', '-u', username];
    if (title != null && title.trim().isNotEmpty) {
      args.addAll(['-t', title]);
    }
    return runRaw(args);
  }

  bool _isDesktop() => Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}