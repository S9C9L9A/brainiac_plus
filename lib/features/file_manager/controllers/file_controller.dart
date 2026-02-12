import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/file_service.dart';

class FileManagerState {
  final String currentPath;
  final List<FileItem> files;
  final bool isLoading;
  final String? error;
  final bool showHidden;
  final List<String> navigationHistory;

  FileManagerState({
    required this.currentPath,
    required this.files,
    this.isLoading = false,
    this.error,
    this.showHidden = false,
    this.navigationHistory = const [],
  });

  FileManagerState copyWith({
    String? currentPath,
    List<FileItem>? files,
    bool? isLoading,
    String? error,
    bool? showHidden,
    List<String>? navigationHistory,
  }) {
    return FileManagerState(
      currentPath: currentPath ?? this.currentPath,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      showHidden: showHidden ?? this.showHidden,
      navigationHistory: navigationHistory ?? this.navigationHistory,
    );
  }

  factory FileManagerState.initial() {
    return FileManagerState(
      currentPath: '/home/${const String.fromEnvironment('USER', defaultValue: 'user')}',
      files: [],
      navigationHistory: ['/home/${const String.fromEnvironment('USER', defaultValue: 'user')}'],
    );
  }
}

class FileManagerController extends StateNotifier<FileManagerState> {
  final FileService _fileService = FileService();

  FileManagerController() : super(FileManagerState.initial()) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final files = await _fileService.listFiles(
        state.currentPath,
        showHidden: state.showHidden,
      );

      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> navigateTo(String path) async {
    final newHistory = [...state.navigationHistory, path];
    state = state.copyWith(currentPath: path, navigationHistory: newHistory);
    await loadFiles();
  }

  Future<void> navigateBack() async {
    if (state.navigationHistory.length > 1) {
      final newHistory = state.navigationHistory.sublist(0, state.navigationHistory.length - 1);
      state = state.copyWith(currentPath: newHistory.last, navigationHistory: newHistory);
      await loadFiles();
    }
  }

  Future<void> navigateUp() async {
    final parts = state.currentPath.split('/')..removeLast();
    if (parts.isEmpty || parts.join('/').isEmpty) {
      await navigateTo('/');
    } else {
      await navigateTo(parts.join('/'));
    }
  }

  Future<void> toggleShowHidden() async {
    state = state.copyWith(showHidden: !state.showHidden);
    await loadFiles();
  }

  Future<void> deleteItem(String path) async {
    try {
      await _fileService.delete(path);
      await loadFiles();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete: $e');
    }
  }

  Future<void> renameItem(String path, String newName) async {
    try {
      await _fileService.rename(path, newName);
      await loadFiles();
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename: $e');
    }
  }

  Future<void> createDirectory(String name) async {
    try {
      final newPath = '${state.currentPath}/$name';
      await _fileService.createDirectory(newPath);
      await loadFiles();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create directory: $e');
    }
  }
}

final fileManagerProvider = StateNotifierProvider<FileManagerController, FileManagerState>((ref) {
  return FileManagerController();
});
