import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/shell_service.dart';

class TerminalSession {
  final String id;
  final String name;
  final List<String> output;
  final bool isProcessRunning;

  TerminalSession({
    required this.id,
    required this.name,
    this.output = const [],
    this.isProcessRunning = false,
  });

  TerminalSession copyWith({
    String? id,
    String? name,
    List<String>? output,
    bool? isProcessRunning,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      name: name ?? this.name,
      output: output ?? this.output,
      isProcessRunning: isProcessRunning ?? this.isProcessRunning,
    );
  }
}

class TerminalController extends StateNotifier<List<TerminalSession>> {
  final ShellService _shellService = ShellService();
  int _sessionCounter = 0;
  StreamSubscription? _outputSubscription;

  TerminalController() : super([]) {
    _createNewSession();
    _listenToOutput();
  }

  void _listenToOutput() {
    _outputSubscription = _shellService.outputStream.listen((output) {
      if (state.isNotEmpty) {
        final currentSession = state.last;
        final newOutput = [...currentSession.output, output];
        final updatedSession = currentSession.copyWith(output: newOutput);
        final newState = [...state];
        newState[newState.length - 1] = updatedSession;
        state = newState;
      }
    });
  }

  void _createNewSession() {
    _sessionCounter++;
    final session = TerminalSession(
      id: 'session_$_sessionCounter',
      name: 'Terminal $_sessionCounter',
      output: ['Welcome to BrainiacPlus Terminal\n', 'Type your commands below\n\n'],
    );
    state = [...state, session];
  }

  Future<void> executeCommand(String command) async {
    if (state.isEmpty) return;

    final currentSession = state.last;
    final newOutput = [...currentSession.output, '\$ $command\n'];
    final updatedSession = currentSession.copyWith(output: newOutput, isProcessRunning: true);
    
    final newState = [...state];
    newState[newState.length - 1] = updatedSession;
    state = newState;

    await _shellService.executeCommand(command);

    if (state.isNotEmpty) {
      final session = state.last.copyWith(isProcessRunning: false);
      final updatedState = [...state];
      updatedState[updatedState.length - 1] = session;
      state = updatedState;
    }
  }

  List<String> getHistory() => _shellService.history;

  void killProcess() {
    _shellService.killProcess();
    if (state.isNotEmpty) {
      final session = state.last.copyWith(isProcessRunning: false);
      final newState = [...state];
      newState[newState.length - 1] = session;
      state = newState;
    }
  }

  void clearOutput() {
    if (state.isEmpty) return;
    final session = state.last.copyWith(output: []);
    final newState = [...state];
    newState[newState.length - 1] = session;
    state = newState;
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _shellService.dispose();
    super.dispose();
  }
}

final terminalProvider = StateNotifierProvider<TerminalController, List<TerminalSession>>((ref) {
  return TerminalController();
});
