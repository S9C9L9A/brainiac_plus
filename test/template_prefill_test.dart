import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/features/automation/models/automation_templates.dart';
import 'package:brainiac_plus/features/automation/models/automation_enums.dart';
import 'package:brainiac_plus/features/automation/providers/automation_template_selection_provider.dart';
import 'package:brainiac_plus/features/automation/screens/create_automation_tab.dart';

void main() {
  testWidgets('Create tab pre-fills when template is selected', (tester) async {
    final container = ProviderContainer();
    final template = const AutomationTemplate(
      id: 'tmpl_test',
      name: 'Test Template',
      description: 'Template description',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.instagram,
      requiredFields: ['Caption', 'Hashtags'],
    );

    container.read(automationTemplateSelectionProvider.notifier).state = template;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CreateAutomationTab()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Template selected'), findsOneWidget);
    expect(find.text('Template Inputs'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);
    expect(find.text('Hashtags'), findsOneWidget);
  });
}