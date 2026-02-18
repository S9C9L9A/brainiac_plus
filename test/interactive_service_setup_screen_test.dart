import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/features/settings/screens/interactive_service_setup_screen.dart';
import 'package:brainiac_plus/features/automation/models/automation_enums.dart';

void main() {
  testWidgets('Interactive setup wizard renders welcome step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InteractiveServiceSetupScreen(
          serviceType: ServiceProvider.github,
        ),
      ),
    );

    expect(find.text('Welcome to Setup!'), findsOneWidget);
    expect(find.textContaining('Setup GitHub'), findsOneWidget);
  });
}
