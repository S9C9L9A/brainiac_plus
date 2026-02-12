import 'dart:async';
import 'dart:io';

/// Shell execution service
class ShellService {
  Process? _currentProcess;
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final List<String> _history = [];

  Stream<String> get outputStream => _outputController.stream;
  List<String> get history => List.unmodifiable(_history);

  /// Execute command and stream output
  Future<void> executeCommand(String command, {bool sudo = false}) async {
    if (command.trim().isEmpty) return;

    // Add to history
    _history.add(command);
    if (_history.length > 100) {
      _history.removeAt(0);
    }

    final actualCommand = sudo ? 'sudo -S $command' : command;

    try {
      _currentProcess = await Process.start(
        'bash',
        ['-c', actualCommand],
        mode: ProcessStartMode.normal,
      );

      // Stream stdout
      _currentProcess!.stdout.transform(const SystemEncoding().decoder).listen(
        (data) {
          _outputController.add(data);
        },
        onError: (error) {
          _outputController.add('Error: $error\n');
        },
      );

      // Stream stderr
      _currentProcess!.stderr.transform(const SystemEncoding().decoder).listen(
        (data) {
          _outputController.add(data);
        },
      );

      // Wait for completion
      final exitCode = await _currentProcess!.exitCode;
      if (exitCode != 0) {
        _outputController.add('\nProcess exited with code: $exitCode\n');
      }
    } catch (e) {
      _outputController.add('Failed to execute command: $e\n');
    } finally {
      _currentProcess = null;
    }
  }

  /// Execute command synchronously and return output
  Future<String> executeSync(String command) async {
    try {
      final result = await Process.run('bash', ['-c', command]);
      return result.stdout.toString() + result.stderr.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Write to process stdin (for interactive commands)
  void writeToProcess(String input) {
    if (_currentProcess != null) {
      _currentProcess!.stdin.write('$input\n');
    }
  }

  /// Kill current process
  void killProcess() {
    if (_currentProcess != null) {
      _currentProcess!.kill();
      _outputController.add('\n^C Process killed\n');
      _currentProcess = null;
    }
  }

  /// Check if process is running
  bool get isProcessRunning => _currentProcess != null;

  /// Dispose resources
  void dispose() {
    killProcess();
    _outputController.close();
  }
}
