import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/package_service.dart';

class PackageManagerState {
  final List<PackageInfo> packages;
  final bool isLoading;
  final String? error;
  final String filter;
  final String source; // all, apt, snap

  PackageManagerState({
    this.packages = const [],
    this.isLoading = false,
    this.error,
    this.filter = '',
    this.source = 'all',
  });

  PackageManagerState copyWith({
    List<PackageInfo>? packages,
    bool? isLoading,
    String? error,
    String? filter,
    String? source,
  }) {
    return PackageManagerState(
      packages: packages ?? this.packages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(filter.toLowerCase()) ||
        (p.description?.toLowerCase().contains(filter.toLowerCase()) ?? false)
      ).toList();
    }
    
    return filtered;
  }
}

class PackageController extends StateNotifier<PackageManagerState> {
  final PackageService _packageService = PackageService();

  PackageController() : super(PackageManagerState()) {
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
    final result = await _packageService.installPackage(name, source);
    if (result.contains('success')) {
      await loadPackages();
    }
  }

  Future<void> removePackage(String name, String source) async {
    final result = await _packageService.removePackage(name, source);
    if (result.contains('success')) {
      await loadPackages();
    }
  }

  Future<void> updateLists() async {
    await _packageService.updatePackageLists();
    await loadPackages();
  }

  Future<void> upgradeAll() async {
    await _packageService.upgradePackages();
    await loadPackages();
  }
}

final packageProvider = StateNotifierProvider<PackageController, PackageManagerState>((ref) {
  return PackageController();
});
