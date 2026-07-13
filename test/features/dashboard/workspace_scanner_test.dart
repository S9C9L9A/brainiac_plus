import 'dart:io';

import 'package:brainiac_plus/features/dashboard/services/workspace_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('ws_scan'));
  tearDown(() => root.deleteSync(recursive: true));

  void makeApp(String name, {bool withLib = true, String? description}) {
    final dir = Directory('${root.path}/$name')..createSync(recursive: true);
    File('${dir.path}/pubspec.yaml').writeAsStringSync(
      'name: $name\n${description != null ? 'description: $description\n' : ''}',
    );
    if (withLib) {
      Directory('${dir.path}/lib').createSync();
      File('${dir.path}/lib/main.dart').writeAsStringSync('void main() {}');
    }
  }

  test('lists each subdirectory that holds a pubspec as a project', () async {
    makeApp('rainbow_arc', description: 'A rainbow demo');
    makeApp('hello_word');

    final projects = await WorkspaceScanner(root.path).scan();

    expect(
      projects.map((p) => p.name),
      containsAll(['rainbow_arc', 'hello_word']),
    );
    final rainbow = projects.firstWhere((p) => p.name == 'rainbow_arc');
    expect(rainbow.description, 'A rainbow demo');
    expect(rainbow.hasLib, isTrue);
    expect(rainbow.path, '${root.path}/rainbow_arc');
  });

  test('ignores plain folders without a pubspec', () async {
    Directory('${root.path}/not_an_app').createSync();
    makeApp('real_app');

    final projects = await WorkspaceScanner(root.path).scan();

    expect(projects.map((p) => p.name), ['real_app']);
  });

  test('results are sorted by name', () async {
    makeApp('zebra');
    makeApp('alpha');

    final projects = await WorkspaceScanner(root.path).scan();

    expect(projects.map((p) => p.name), ['alpha', 'zebra']);
  });

  test('a missing workspace yields an empty list', () async {
    final projects = await WorkspaceScanner('${root.path}/nope').scan();
    expect(projects, isEmpty);
  });

  test('scans multiple roots and merges their projects', () async {
    // A second root (e.g. ~/sviluppo) alongside the sandbox.
    final other = Directory.systemTemp.createTempSync('ws_scan_other');
    addTearDown(() => other.deleteSync(recursive: true));
    Directory('${other.path}/sideproject').createSync();
    File(
      '${other.path}/sideproject/pubspec.yaml',
    ).writeAsStringSync('name: sideproject\n');
    makeApp('sandbox_app');

    final projects = await WorkspaceScanner.roots([
      root.path,
      other.path,
      '${root.path}/does_not_exist', // a missing root is skipped, not fatal
    ]).scan();

    expect(
      projects.map((p) => p.name),
      containsAll(['sandbox_app', 'sideproject']),
    );
  });
}
