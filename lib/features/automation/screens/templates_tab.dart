import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../settings/screens/modern_settings_screen.dart';
import '../models/automation_templates.dart';
import '../models/automation_enums.dart';
import '../widgets/template_details_bottom_sheet.dart';

class TemplatesTab extends ConsumerStatefulWidget {
  const TemplatesTab({super.key});

  @override
  ConsumerState<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends ConsumerState<TemplatesTab> {
  AutomationCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(extendedSettingsProvider);
    final templates = AutomationTemplates.all;
    final filteredTemplates = _selectedCategory == null
        ? templates
        : templates.where((t) => t.category == _selectedCategory).toList();
    
    final availableTemplates = filteredTemplates
        .where((t) => settings.isServiceConfigured(t.service))
        .toList();
    final lockedTemplates = filteredTemplates
        .where((t) => !settings.isServiceConfigured(t.service))
        .toList();

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, kBottomNavHeight),
            children: [
              if (availableTemplates.isNotEmpty) ...[
                const Text(
                  '✅ Ready to Use',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...availableTemplates.map((template) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTemplateCard(template, isLocked: false),
                  );
                }),
              ],
              if (lockedTemplates.isNotEmpty) ...[
                if (availableTemplates.isNotEmpty) const SizedBox(height: 24),
                const Text(
                  '🔒 Connect Service to Use',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...lockedTemplates.map((template) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTemplateCard(template, isLocked: true),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: AutomationCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = AutomationCategory.values[index];
          final isSelected = _selectedCategory == category;

          return FilterChip(
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
              setState(() {
                _selectedCategory = selected ? category : null;
              });
            },
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            selectedColor: Colors.purple.withValues(alpha: 0.3),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? Colors.purple.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(AutomationTemplate template, {required bool isLocked}) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Stack(
        children: [
          GlassCard(
            child: InkWell(
              onTap: () => _showTemplateDetails(template),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getCategoryGradient(template.category),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.service.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    template.category.icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      template.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isLocked)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.settings, size: 18),
                            label: Text('Connect ${template.service.label}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.systemOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _goToSettings(),
                          )
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.systemBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showTemplateDetails(template),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.systemOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getCategoryGradient(AutomationCategory category) {
    switch (category) {
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

  void _showTemplateDetails(AutomationTemplate template) {
    TemplateDetailsBottomSheet.show(context, template);
  }

  void _useTemplate(AutomationTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Setting up ${template.name}...'),
        backgroundColor: AppColors.systemBlue,
      ),
    );
  }

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModernSettingsScreen(),
      ),
    );
  }
}
