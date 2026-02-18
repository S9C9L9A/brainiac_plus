# Automation Template Prefill

When you tap **Create Automation** on a template, the Create tab is prefilled with:

- Name and description
- Category and service
- Preferred mode
- Schedule (if present)

If the template defines `requiredFields`, the Create step shows only those inputs and requires them before proceeding.

## Where this logic lives

- Selection provider: `lib/features/automation/providers/automation_template_selection_provider.dart`
- Apply/pre-fill logic: `lib/features/automation/screens/create_automation_tab.dart`
- Trigger: `lib/features/automation/widgets/template_details_bottom_sheet.dart`
