import 'package:brainiac_plus/features/packages/widgets/package_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message and dismisses on close tap', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PackageErrorBanner(
            message: 'Installation failed: no candidate',
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('Installation failed: no candidate'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });
}
