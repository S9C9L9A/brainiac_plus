import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/package_service.dart';
import '../../activity/controllers/activity_log_controller.dart';
import '../../activity/models/activity_entry.dart';

class PackageManagerState {
  final List<PackageInfo> packages;
  final bool isLoading;
  final String? error;

  /// Outcome of the last install/remove operation, for user feedback.
  final String? lastOperationMessage;
  final String filter;
  final String source; // all, apt, snap

  PackageManagerState({
    this.packages = const [],
    this.isLoading = false,
    this.error,
    this.lastOperationMessage,
    this.filter = '',
    this.source = 'all',
  });

  PackageManagerState copyWith({
    List<PackageInfo>? packages,
    bool? isLoading,
    String? error,
    String? lastOperationMessage,
    String? filter,
    String? source,
  }) {
    return PackageManagerState(
      packages: packages ?? this.packages,
      isLoading: isLoading ?? this.isLoading,
      // Like error, the message is transient: cleared unless re-supplied.
      error: error,
      lastOperationMessage: lastOperationMessage,
      filter: filter ?? this.filter,
      source: source ?? this.source,
    );
  }

  List<PackageInfo> get filteredPackages {
    var filtered = packages;

    if (source != 'all') {
      filtered = filtered.where((p) => p.source == source).toList();
    }

    if (filter.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(filter.toLowerCase()) ||
                (p.description?.toLowerCase().contains(filter.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    return filtered;
  }
}

class PackageController extends StateNotifier<PackageManagerState> {
  final PackageService _packageService;

  /// Reports install/remove outcomes to the app-wide activity log.
  final void Function(ActivityEntry entry)? onActivity;

  PackageController({PackageService? packageService, this.onActivity})
    : _packageService = packageService ?? PackageService(),
      super(PackageManagerState()) {
    loadPackages();
  }

  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final aptPackages = await _packageService.listAptPackages();
      final snapPackages = await _packageService.listSnapPackages();

      final allPackages = [...aptPackages, ...snapPackages];

      state = state.copyWith(packages: allPackages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSource(String source) {
    state = state.copyWith(source: source);
  }

  Future<void> installPackage(String name, String source) async {
    state = state.copyWith(isLoading: true);
    final result = await _packageService.installPackage(name, source);
    _logOperation('Package install', '$name ($source): $result');
    if (result.toLowerCase().contains('success')) {
      await loadPackages();
      state = state.copyWith(lastOperationMessage: result);
    } else {
      // Failure: keep the current list, make the reason visible.
      state = state.copyWith(isLoading: false, error: result);
    }
  }

  Future<void> removePackage(String name, String source) async {
    state = state.copyWith(isLoading: true);
    final result = await _packageService.removePackage(name, source);
    _logOperation('Package removal', '$name ($source): $result');
    if (result.toLowerCase().contains('success')) {
      await loadPackages();
      state = state.copyWith(lastOperationMessage: result);
    } else {
      state = state.copyWith(isLoading: false, error: result);
    }
  }

  /// Both successes and failures are logged — the log is an audit trail.
  void _logOperation(String title, String description) {
    onActivity?.call(
      ActivityEntry(
        type: ActivityType.packages,
        title: title,
        description: description,
        timestamp: DateTime.now(),
      ),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> updateLists() async {
    state = state.copyWith(isLoading: true);
    final result = await _packageService.updatePackageLists();
    _logOperation('Package lists update', result);
    if (result.toLowerCase().contains('updated')) {
      await loadPackages();
      state = state.copyWith(lastOperationMessage: result);
    } else {
      state = state.copyWith(isLoading: false, error: result);
    }
  }

  Future<void> upgradeAll() async {
    state = state.copyWith(isLoading: true);
    final result = await _packageService.upgradePackages();
    _logOperation('Package upgrade', result);
    if (result.toLowerCase().contains('success')) {
      await loadPackages();
      state = state.copyWith(lastOperationMessage: result);
    } else {
      state = state.copyWith(isLoading: false, error: result);
    }
  }
}

final packageProvider =
    StateNotifierProvider<PackageController, PackageManagerState>((ref) {
      return PackageController(
        onActivity: (entry) =>
            ref.read(activityLogProvider.notifier).log(entry),
      );
    });
