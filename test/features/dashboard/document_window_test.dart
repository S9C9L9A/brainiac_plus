import 'dart:convert';
import 'dart:io';

import 'package:brainiac_plus/features/dashboard/screens/document_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentWindowApp.fromArgument', () {
    test('parses path and title from the JSON argument', () {
      final app = DocumentWindowApp.fromArgument(
        jsonEncode({'path': '/tmp/a/main.dart', 'title': 'main.dart'}),
      );
      expect(app.path, '/tmp/a/main.dart');
      expect(app.title, 'main.dart');
    });

    test('falls back to the file name when title is missing', () {
      final app = DocumentWindowApp.fromArgument(
        jsonEncode({'path': '/tmp/a/widget.dart'}),
      );
      expect(app.title, 'widget.dart');
    });

    test('malformed argument does not throw', () {
      final app = DocumentWindowApp.fromArgument('not json');
      expect(app.path, '');
      expect(app.title, 'Document');
    });
  });

  testWidgets('the document window shows the file and can edit it', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('doc_win');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/main.dart')
      ..writeAsStringSync('void main() {}');

    await tester.pumpWidget(
      DocumentWindowApp(path: file.path, title: 'main.dart'),
    );
    await tester.pump();

    // Title, path and the file's content are shown; Save starts disabled.
    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('void main() {}'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    // Editing enables Save.
    await tester.enterText(find.byType(TextField), 'void main() { print(1); }');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });
}
