import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/app_icons.dart';
import '../dashboard/dashboard_screen.dart';
import 'controllers/activity_log_controller.dart';
import 'models/activity_entry.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activities = ref.watch(activityLogProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildActivityList(activities)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track all your system activities',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // TODO: Add filter functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<ActivityEntry> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white38, size: 48),
            SizedBox(height: 12),
            Text(
              'No activity yet',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Commands, package operations and automations will appear here.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, kBottomNavHeight),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildActivityItem(activities[index]);
      },
    );
  }

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.terminal:
        return Icons.terminal;
      case ActivityType.file:
        return Icons.folder_open;
      case ActivityType.ai:
        return Icons.auto_awesome;
      case ActivityType.automation:
        return Icons.play_circle;
      case ActivityType.settings:
        return Icons.settings;
      case ActivityType.packages:
        return Icons.inventory_2;
    }
  }

  Widget _buildActivityItem(ActivityEntry activity) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(activity.type),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(activity.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(activity.timestamp),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(ActivityType type) {
    switch (type) {
      case ActivityType.terminal:
        return [AppColors.systemGreen, AppColors.systemGreen.withOpacity(0.6)];
      case ActivityType.file:
        return [AppColors.systemBlue, AppColors.systemBlue.withOpacity(0.6)];
      case ActivityType.ai:
        return [Colors.purple, Colors.blue];
      case ActivityType.automation:
        return [
          AppColors.systemOrange,
          AppColors.systemOrange.withOpacity(0.6),
        ];
      case ActivityType.settings:
        return [Colors.grey.shade700, Colors.grey.shade600];
      case ActivityType.packages:
        return [Colors.teal, Colors.teal.withOpacity(0.6)];
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
