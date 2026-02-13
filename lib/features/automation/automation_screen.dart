import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import 'controllers/automation_controller.dart';
import 'models/automation_enums.dart';

class AutomationScreen extends ConsumerWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(automationControllerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, state, isDark),
              const SizedBox(height: 20),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildContent(context, state, ref, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AutomationState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            'Automations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${state.activeAutomations.length} Active',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AutomationState state, WidgetRef ref, bool isDark) {
    if (state.activeAutomations.isEmpty && state.templates.isEmpty) {
      return const Center(
        child: Text(
          'No automations yet',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state.activeAutomations.isNotEmpty) ...[
          const Text(
            'Active Automations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...state.activeAutomations.map((automation) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        automation.service.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              automation.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              automation.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(automation.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          automation.status.label,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (automation.hasSchedule) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Schedule: ${automation.cronSchedule}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
        const Text(
          'Suggested Templates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...state.templates.take(10).map((template) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Text(
                  template.category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        template.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () async {
                    await ref
                        .read(automationControllerProvider.notifier)
                        .createFromTemplate(template.id, null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added: ${template.name}')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getStatusColor(AutomationStatus status) {
    switch (status) {
      case AutomationStatus.running:
        return Colors.green;
      case AutomationStatus.scheduled:
        return Colors.blue;
      case AutomationStatus.paused:
        return Colors.orange;
      case AutomationStatus.completed:
        return Colors.teal;
      case AutomationStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
