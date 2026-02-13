import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';
import '../controllers/automation_controller.dart';
import 'automation_detail_screen.dart';
import '../models/automation.dart';
import '../models/automation_enums.dart';

class ActiveAutomationsTab extends ConsumerWidget {
  const ActiveAutomationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(automationControllerProvider);

    if (state.activeAutomations.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      itemCount: state.activeAutomations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAutomationCard(
          context,
          ref,
          state.activeAutomations[index],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No active automations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start by creating your first automation\nor browse templates',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(
    BuildContext context,
    WidgetRef ref,
    Automation automation,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getServiceGradient(automation.service),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    automation.service.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        automation.description,
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
                Switch(
                  value: automation.isActive,
                  onChanged: (value) {
                    ref.read(automationControllerProvider.notifier)
                        .toggleAutomation(automation.id);
                  },
                  activeColor: AppColors.systemGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(automation.status),
                const SizedBox(width: 8),
                _buildModeChip(automation.preferredMode),
                const Spacer(),
                if (automation.executionCount > 0)
                  Text(
                    '${automation.successCount}/${automation.executionCount} ✅',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (automation.nextRun != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Next run: ${_formatDateTime(automation.nextRun!)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run Now'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.systemBlue,
                  ),
                  onPressed: () {
                    ref.read(automationControllerProvider.notifier)
                        .runAutomation(automation.id);
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  onPressed: () {
                    // TODO: Navigate to edit screen
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AutomationStatus status) {
    Color color;
    switch (status) {
      case AutomationStatus.running:
        color = AppColors.systemGreen;
        break;
      case AutomationStatus.paused:
        color = AppColors.systemYellow;
        break;
      case AutomationStatus.failed:
        color = AppColors.systemRed;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(AutomationMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mode.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            mode.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getServiceGradient(ServiceProvider service) {
    switch (service) {
      case ServiceProvider.instagram:
        return [const Color(0xFFE1306C), const Color(0xFFFD1D1D)];
      case ServiceProvider.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF42B0FF)];
      case ServiceProvider.twitter:
        return [const Color(0xFF1DA1F2), const Color(0xFF0E71C8)];
      case ServiceProvider.linkedin:
        return [const Color(0xFF0077B5), const Color(0xFF00A0DC)];
      case ServiceProvider.youtube:
        return [const Color(0xFFFF0000), const Color(0xFFFF4444)];
      default:
        return [Colors.purple, Colors.blue];
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}
