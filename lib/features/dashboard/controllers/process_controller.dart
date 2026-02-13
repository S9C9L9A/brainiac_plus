import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/shell_service.dart';

class ProcessInfo {
  final String pid;
  final String user;
  final String cpu;
  final String mem;
  final String command;

  ProcessInfo({
    required this.pid,
    required this.user,
    required this.cpu,
    required this.mem,
    required this.command,
  });

  factory ProcessInfo.fromPsLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 11) {
      return ProcessInfo(
        pid: 'N/A',
        user: 'N/A',
        cpu: '0.0',
        mem: '0.0',
        command: 'Unknown',
      );
    }

    return ProcessInfo(
      pid: parts[1],
      user: parts[0],
      cpu: parts[2],
      mem: parts[3],
      command: parts.sublist(10).join(' '),
    );
  }
}

class DiskInfo {
  final String size;
  final String path;

  DiskInfo({
    required this.size,
    required this.path,
  });

  factory DiskInfo.fromDuLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return DiskInfo(size: '0', path: 'Unknown');
    }
    return DiskInfo(
      size: parts[0],
      path: parts.sublist(1).join(' '),
    );
  }

  double get sizeInGB {
    if (size.isEmpty) return 0.0;
    final value = double.tryParse(size.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (size.contains('G')) return value;
    if (size.contains('M')) return value / 1024;
    if (size.contains('K')) return value / (1024 * 1024);
    return value;
  }
}

class ProcessController extends StateNotifier<AsyncValue<List<ProcessInfo>>> {
  final ShellService _shellService = ShellService();

  ProcessController() : super(const AsyncValue.loading());

  Future<void> loadTopCpuProcesses() async {
    state = const AsyncValue.loading();
    try {
      final output = await _shellService.executeSync('ps aux --sort=-%cpu | head -21');
      final lines = output.split('\n');
      final processes = lines
          .skip(1)
          .where((line) => line.trim().isNotEmpty)
          .map((line) => ProcessInfo.fromPsLine(line))
          .toList();
      state = AsyncValue.data(processes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadTopMemProcesses() async {
    state = const AsyncValue.loading();
    try {
      final output = await _shellService.executeSync('ps aux --sort=-%mem | head -21');
      final lines = output.split('\n');
      final processes = lines
          .skip(1)
          .where((line) => line.trim().isNotEmpty)
          .map((line) => ProcessInfo.fromPsLine(line))
          .toList();
      state = AsyncValue.data(processes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> killProcess(String pid) async {
    try {
      final output = await _shellService.executeSync('kill $pid');
      return !output.toLowerCase().contains('error');
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _shellService.dispose();
    super.dispose();
  }
}

class DiskController extends StateNotifier<AsyncValue<List<DiskInfo>>> {
  final ShellService _shellService = ShellService();

  DiskController() : super(const AsyncValue.loading());

  Future<void> loadTopDirectories() async {
    state = const AsyncValue.loading();
    try {
      final output = await _shellService.executeSync(
        'du -h --max-depth=1 /home 2>/dev/null | sort -hr | head -20'
      );
      final lines = output.split('\n');
      final directories = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => DiskInfo.fromDuLine(line))
          .toList();
      state = AsyncValue.data(directories);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _shellService.dispose();
    super.dispose();
  }
}

final processControllerProvider = StateNotifierProvider<ProcessController, AsyncValue<List<ProcessInfo>>>((ref) {
  return ProcessController();
});

final diskControllerProvider = StateNotifierProvider<DiskController, AsyncValue<List<DiskInfo>>>((ref) {
  return DiskController();
});
