import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../settings/models/extended_settings.dart';
import '../../settings/screens/modern_settings_screen.dart';
import '../models/automation_templates.dart';
import '../models/automation_enums.dart';

class TemplateDetailsBottomSheet extends ConsumerWidget {
  final AutomationTemplate template;

  const TemplateDetailsBottomSheet({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(extendedSettingsProvider);
    final isServiceConfigured = settings.isServiceConfigured(template.service);
    final missingConfigs = _getMissingConfigurations(settings);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getCategoryGradient(),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        template.service.icon,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildCategoryBadge(),
                              const SizedBox(width: 8),
                              if (template.isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.systemOrange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  template.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Status indicator
                if (!isServiceConfigured)
                  _buildWarningCard(
                    '⚠️ Service Not Connected',
                    'Connect ${template.service.label} to use this template',
                    context,
                  )
                else
                  _buildSuccessCard(
                    '✅ Ready to Use',
                    '${template.service.label} is connected',
                  ),
                const SizedBox(height: 24),

                // Required Configurations
                const Text(
                  'Required Configurations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...template.requiredFields.map((field) {
                  final isConfigured = !missingConfigs.contains(field);
                  return _buildConfigItem(field, isConfigured);
                }),
                const SizedBox(height: 24),

                // Example Preview
                _buildExampleSection(),
                const SizedBox(height: 24),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: template.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (!isServiceConfigured)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings),
                      label: Text('Connect ${template.service.label}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.systemOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        // Use navigation service to switch to Settings tab
                        NavigationService().navigateToTab(
                          context,
                          NavigationService.tabSettings,
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Create Automation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.systemBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to Create tab with this template
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Creating automation from ${template.name}...'),
                            backgroundColor: AppColors.systemBlue,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(template.category.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            template.category.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String title, String subtitle, BuildContext context) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.systemOrange.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.systemOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.systemOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildSuccessCard(String title, String subtitle) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.systemGreen.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.systemGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.systemGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildConfigItem(String field, bool isConfigured) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isConfigured ? AppColors.systemGreen : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field,
              style: TextStyle(
                color: isConfigured ? Colors.white : Colors.white60,
                fontSize: 14,
                decoration: isConfigured ? null : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'How it works',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExampleStep('1', 'Configure your ${template.service.label} credentials'),
            _buildExampleStep('2', 'Set automation triggers and conditions'),
            _buildExampleStep('3', 'Define actions and content'),
            _buildExampleStep('4', 'Activate and monitor results'),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.systemBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.systemBlue.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: AppColors.systemBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getMissingConfigurations(ExtendedAppSettings settings) {
    final missingConfigs = <String>[];
    
    for (final field in template.requiredFields) {
      // Check if the field is configured based on service
      if (!settings.isServiceConfigured(template.service)) {
        missingConfigs.add(field);
      }
    }
    
    return missingConfigs;
  }

  List<Color> _getCategoryGradient() {
    switch (template.category) {
      case AutomationCategory.socialMedia:
        return [const Color(0xFFE1306C), const Color(0xFFFD1D1D)];
      case AutomationCategory.productivity:
        return [AppColors.systemBlue, AppColors.systemBlue.withOpacity(0.6)];
      case AutomationCategory.communication:
        return [AppColors.systemGreen, AppColors.systemGreen.withOpacity(0.6)];
      case AutomationCategory.marketing:
        return [AppColors.systemOrange, AppColors.systemOrange.withOpacity(0.6)];
      default:
        return [Colors.purple, Colors.blue];
    }
  }

  static void show(BuildContext context, AutomationTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplateDetailsBottomSheet(template: template),
    );
  }
}
