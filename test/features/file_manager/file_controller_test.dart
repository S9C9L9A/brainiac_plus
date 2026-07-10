import 'dart:io';

import 'package:brainiac_plus/core/platform/file_service.dart';
import 'package:brainiac_plus/features/file_manager/controllers/file_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileService extends FileService {
  final listedPaths = <String>[];
  bool failNextDelete = false;

  @override
  Future<List<FileItem>> listFiles(
    String path, {
    bool showHidden = false,
  }) async {
    listedPaths.add(path);
    return [
      FileItem(
        name: 'docs',
        path: '$path/docs',
        isDirectory: true,
        size: 0,
        modified: DateTime(2026),
        permissions: 'rwxr-xr-x',
      ),
    ];
  }

  @override
  Future<void> delete(String path) async {
    if (failNextDelete) throw Exception('permission denied');
  }
}

void main() {
  late FakeFileService service;

  FileManagerController controller({String? initialPath}) =>
      FileManagerController(fileService: service, initialPath: initialPath);

  setUp(() {
    service = FakeFileService();
  });

  test('starts in the real home directory by default', () {
    final c = controller();
    // Resolved at runtime from the environment — never the compile-time
    // 'user' fallback that pointed to a non-existent /home/user.
    expect(c.state.currentPath, Platform.environment['HOME']);
    expect(c.state.currentPath, isNot('/home/user'));
  });

  test('honors an explicit initial path and loads it', () async {
    final c = controller(initialPath: '/tmp');
    await Future<void>.delayed(Duration.zero);

    expect(c.state.currentPath, '/tmp');
    expect(service.listedPaths, contains('/tmp'));
    expect(c.state.files.single.name, 'docs');
  });

  test('navigateUp walks to the parent and stops at root', () async {
    final c = controller(initialPath: '/home/tester/documents');
    await Future<void>.delayed(Duration.zero);

    await c.navigateUp();
    expect(c.state.currentPath, '/home/tester');

    await c.navigateUp();
    expect(c.state.currentPath, '/home');

    await c.navigateUp();
    expect(c.state.currentPath, '/');

    await c.navigateUp();
    expect(c.state.currentPath, '/');
  });

  test('navigateBack returns to the previous directory', () async {
    final c = controller(initialPath: '/tmp');
    await Future<void>.delayed(Duration.zero);

    await c.navigateTo('/tmp/sub');
    expect(c.state.currentPath, '/tmp/sub');

    await c.navigateBack();
    expect(c.state.currentPath, '/tmp');
  });

  test('failed delete surfaces the error', () async {
    final c = controller(initialPath: '/tmp');
    await Future<void>.delayed(Duration.zero);

    service.failNextDelete = true;
    await c.deleteItem('/tmp/locked');

    expect(c.state.error, contains('Failed to delete'));
  });
}
