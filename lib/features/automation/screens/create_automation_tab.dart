import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';
import '../models/automation.dart';
import '../models/automation_enums.dart';
import '../controllers/automation_controller.dart';
import '../models/automation_templates.dart';
import '../providers/automation_template_selection_provider.dart';
import '../providers/automation_assistant_provider.dart';
import '../../../core/services/automation_assistant_service.dart';

class CreateAutomationTab extends ConsumerStatefulWidget {
  const CreateAutomationTab({super.key});

  @override
  ConsumerState<CreateAutomationTab> createState() => _CreateAutomationTabState();
}

class _CreateAutomationTabState extends ConsumerState<CreateAutomationTab> {
  int _currentStep = 0;
  late final ProviderSubscription<AutomationTemplate?> _templateSubscription;

  // Form state
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _name = '';
  String _description = '';
  ServiceProvider? _selectedService;
  AutomationCategory? _selectedCategory;
  AutomationMode _selectedMode = AutomationMode.hybrid;
  TriggerType _triggerType = TriggerType.manual;
  String? _cronSchedule;
  AutomationTemplate? _selectedTemplate;
  String? _appliedTemplateId;
  final Map<String, String> _templateFieldValues = {};
  
  // AI Assistant state
  bool _isAiAssisting = false;
  String _aiPrompt = '';
  final _aiPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(automationTemplateSelectionProvider);
    if (initial != null) {
      _applyTemplate(initial);
      Future.microtask(() {
        if (mounted) {
          ref.read(automationTemplateSelectionProvider.notifier).state = null;
        }
      });
    }

    _templateSubscription = ref.listenManual<AutomationTemplate?>(
      automationTemplateSelectionProvider,
      (previous, next) {
        if (next == null) return;
        if (_appliedTemplateId == next.id) return;
        _applyTemplate(next);
        Future.microtask(() {
          if (mounted) {
            ref.read(automationTemplateSelectionProvider.notifier).state = null;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _templateSubscription.close();
    _nameController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      child: Column(
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                          )
                        : null,
                    color: isActive ? null : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 3) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasicInfo();
      case 1:
        return _buildStepSelectService();
      case 2:
        return _buildStepConfiguration();
      case 3:
        return _buildStepReview();
      default:
        return Container();
    }
  }

  Widget _buildStepBasicInfo() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Let\'s start by giving your automation a name and description',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAiAssistantDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('AI Assist'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Automation Name',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., Daily Instagram Post',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.label, color: Colors.white70),
              ),
              onChanged: (value) => setState(() => _name = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Describe what this automation does...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.white70),
              ),
              onChanged: (value) => setState(() => _description = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AutomationCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon),
                      const SizedBox(width: 6),
                      Text(category.label),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  selectedColor: Colors.purple.withValues(alpha: 0.4),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSelectService() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Service',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which service this automation will work with',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: ServiceProvider.values.length,
              itemBuilder: (context, index) {
                final service = ServiceProvider.values[index];
                final isSelected = _selectedService == service;

                return InkWell(
                  onTap: () => setState(() => _selectedService = service),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.purple
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          service.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConfiguration() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTemplate != null) _buildTemplateSummary(),
            if (_selectedTemplate != null) const SizedBox(height: 20),
            if (_selectedTemplate != null) _buildTemplateRequiredFields(),
            if (_selectedTemplate != null) const SizedBox(height: 24),
            const Text(
              'Execution Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...AutomationMode.values.map((mode) {
              final isSelected = _selectedMode == mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedMode = mode),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.systemBlue.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.systemBlue
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.systemBlue
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.systemBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text(mode.icon),
                              const SizedBox(width: 8),
                              Text(
                                mode.label,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Trigger Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...TriggerType.values.map((trigger) {
              final isSelected = _triggerType == trigger;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _triggerType = trigger),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.systemBlue.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.systemBlue
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.systemBlue
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.systemBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          trigger.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepReview() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review & Create',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildReviewItem('Name', _name),
            _buildReviewItem('Description', _description),
            _buildReviewItem('Category', _selectedCategory?.label ?? '-'),
            _buildReviewItem('Service', _selectedService?.label ?? '-'),
            _buildReviewItem('Mode', _selectedMode.label),
            _buildReviewItem('Trigger', _triggerType.name),
            if (_cronSchedule != null && _cronSchedule!.isNotEmpty)
              _buildReviewItem('Schedule', _cronSchedule!),
            if (_selectedTemplate != null && _templateFieldValues.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Template Inputs',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ..._templateFieldValues.entries.map(
                (entry) => _buildReviewItem(entry.key, entry.value),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.systemGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.systemGreen.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.systemGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ready to create! You can configure additional settings after creation.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.systemBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentStep == 3 ? 'Create' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _name.isNotEmpty && _selectedCategory != null;
      case 1:
        return _selectedService != null;
      case 2:
        if (_selectedTemplate == null) return true;
        return _selectedTemplate!.requiredFields.every(
          (field) => (_templateFieldValues[field] ?? '').trim().isNotEmpty,
        );
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep == 3) {
      _createAutomation();
    } else {
      setState(() => _currentStep++);
    }
  }

  void _createAutomation() async {
    if (_selectedCategory == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: AppColors.systemOrange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final templateConfig = _buildTemplateConfig();
    final automation = Automation(
      id: now.millisecondsSinceEpoch.toString(),
      name: _name.trim(),
      description: _description.trim(),
      category: _selectedCategory!,
      service: _selectedService!,
      preferredMode: _selectedMode,
      triggerType: _triggerType,
      status: _triggerType == TriggerType.scheduled
          ? AutomationStatus.scheduled
          : AutomationStatus.idle,
      config: {
        'mode': _selectedMode.name,
        'trigger': _triggerType.name,
        ...templateConfig,
      },
      cronSchedule: _cronSchedule,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      isTemplate: false,
      tags: _selectedTemplate?.tags ?? const [],
    );

    if (!mounted) return;

    try {
      final controller = ref.read(automationControllerProvider.notifier);
      final success = await controller.createAutomation(automation);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Automation created successfully! 🎉'),
            backgroundColor: AppColors.systemGreen,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _currentStep = 0;
          _name = '';
          _description = '';
          _nameController.clear();
          _descriptionController.clear();
          _selectedService = null;
          _selectedCategory = null;
          _selectedMode = AutomationMode.hybrid;
          _triggerType = TriggerType.manual;
          _cronSchedule = null;
          _selectedTemplate = null;
          _appliedTemplateId = null;
          _templateFieldValues.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create automation'),
            backgroundColor: AppColors.systemRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating automation: $e'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _applyTemplate(AutomationTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _appliedTemplateId = template.id;
      _name = template.name;
      _description = template.description;
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedCategory = template.category;
      _selectedService = template.service;
      _selectedMode = template.preferredMode;
      _cronSchedule = template.cronSchedule;
      _triggerType = template.cronSchedule != null && template.cronSchedule!.isNotEmpty
          ? TriggerType.scheduled
          : TriggerType.manual;
      _templateFieldValues
        ..clear()
        ..addEntries(template.requiredFields.map((field) => MapEntry(field, '')));
      _currentStep = 2;
    });
  }

  Map<String, dynamic> _buildTemplateConfig() {
    if (_selectedTemplate == null) return {};
    final config = <String, dynamic>{
      'templateId': _selectedTemplate!.id,
      'requiredFields': _selectedTemplate!.requiredFields,
    };
    for (final entry in _templateFieldValues.entries) {
      config['input:${entry.key}'] = entry.value;
    }
    return config;
  }

  Widget _buildTemplateSummary() {
    final template = _selectedTemplate!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.systemBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.systemBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.systemBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.name,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text('Edit basics'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateRequiredFields() {
    final fields = _selectedTemplate!.requiredFields;
    if (fields.isEmpty) {
      return const Text(
        'No additional template inputs required.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Inputs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...fields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: field,
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _templateFieldValues[field] = value;
                setState(() {});
              },
            ),
          );
        }),
      ],
    );
  }

  /// Show AI assistant dialog to get automation suggestions
  void _showAiAssistantDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Automation Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Describe what you want to automate in natural language:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _aiPromptController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., "Post to Instagram every day at 9am" or "Send a Slack message when I receive an email"',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _aiPrompt = value),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _aiPromptController.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _aiPrompt.trim().isEmpty
                          ? null
                          : () => _getAiSuggestion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get AI suggestion and apply it to the form
  void _getAiSuggestion(BuildContext dialogContext) async {
    final prompt = _aiPrompt.trim();
    if (prompt.isEmpty) return;

    setState(() => _isAiAssisting = true);

    try {
      final assistantService = ref.read(automationAssistantServiceProvider);
      final suggestion = await assistantService.suggestAutomation(prompt);

      if (!mounted) return;

      // Close the dialog
      Navigator.of(dialogContext).pop();

      // Apply the suggestion to the form
      setState(() {
        _name = suggestion.name;
        _description = suggestion.description;
        _nameController.text = suggestion.name;
        _descriptionController.text = suggestion.description;
        _selectedCategory = suggestion.category;
        _selectedService = suggestion.service;
        _selectedMode = suggestion.mode;
        _triggerType = suggestion.trigger;
        _isAiAssisting = false;
      });

      // Clear the prompt
      _aiPromptController.clear();
      _aiPrompt = '';

      // Show success message with confidence indicator
      if (!mounted) return;
      final confidenceEmoji = suggestion.isHighConfidence ? '✨' : '💡';
      final confidenceText = suggestion.isHighConfidence ? 'High confidence' : 'Low confidence';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$confidenceEmoji AI suggestion applied! ($confidenceText: ${(suggestion.confidence * 100).toStringAsFixed(0)}%)',
          ),
          backgroundColor: suggestion.isHighConfidence 
              ? AppColors.systemGreen 
              : AppColors.systemOrange,
          duration: const Duration(seconds: 4),
        ),
      );

      // Optionally advance to next step if high confidence
      if (suggestion.isHighConfidence && _canProceed()) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _currentStep = 1);
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isAiAssisting = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get AI suggestion: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 4),
        ),
      );

      // Close the dialog on error
      Navigator.of(dialogContext).pop();
    }
  }
}
