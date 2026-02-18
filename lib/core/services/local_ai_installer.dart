import 'dart:async';
import 'dart:io';

class LocalAiCommandResult {
  final int exitCode;
  final String output;

  const LocalAiCommandResult({
    required this.exitCode,
    required this.output,
  });

  bool get isSuccess => exitCode == 0;
}

enum LocalAiInstallMethod {
  snap,
  script,
}

class LocalAiInstaller {
  const LocalAiInstaller();

  Future<LocalAiCommandResult> installOllama({
    required LocalAiInstallMethod method,
  }) {
    switch (method) {
      case LocalAiInstallMethod.snap:
        return _runCommand(
          ['snap', 'install', 'ollama'],
          usePkexec: true,
        );
      case LocalAiInstallMethod.script:
        return _runCommand(
          ['bash', '-lc', 'curl -fsSL https://ollama.com/install.sh | sh'],
          usePkexec: true,
        );
    }
  }

  Future<LocalAiCommandResult> pullModel({
    required String model,
    required String modelsDir,
  }) {
    return _runCommand(
      ['ollama', 'pull', model],
      env: {'OLLAMA_MODELS': modelsDir},
    );
  }

  Future<LocalAiCommandResult> setEndpointDefaults({
    required String modelsDir,
  }) {
    return _runCommand(
      ['ollama', 'list'],
      env: {'OLLAMA_MODELS': modelsDir},
    );
  }

  Future<LocalAiCommandResult> _runCommand(
    List<String> command, {
    bool usePkexec = false,
    Map<String, String>? env,
  }) async {
    final mergedEnv = {...Platform.environment, if (env != null) ...env};
    final executable = usePkexec ? 'pkexec' : command.first;
    final args = usePkexec ? command : command.sublist(1);

    final process = await Process.start(
      executable,
      args,
      environment: mergedEnv,
      runInShell: true,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutSub = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(stdoutBuffer.write);
    final stderrSub = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(stderrBuffer.write);

    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();

    final output = [stdoutBuffer.toString(), stderrBuffer.toString()]
        .where((chunk) => chunk.trim().isNotEmpty)
        .join('\n');

    return LocalAiCommandResult(exitCode: exitCode, output: output);
  }
}
