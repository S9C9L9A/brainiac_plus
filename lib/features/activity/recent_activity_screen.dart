import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/app_icons.dart';
import '../dashboard/dashboard_screen.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildActivityList(),
              ),
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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

  Widget _buildActivityList() {
    // Mock data for now - will be replaced with real activity tracking
    final activities = [
      ActivityItem(
        icon: Icons.terminal,
        title: 'Terminal Command Executed',
        description: 'ls -la /home/user',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: ActivityType.terminal,
      ),
      ActivityItem(
        icon: Icons.folder_open,
        title: 'File Accessed',
        description: 'brainiac_plus/lib/main.dart',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: ActivityType.file,
      ),
      ActivityItem(
        icon: Icons.auto_awesome,
        title: 'AI Query Processed',
        description: 'How to optimize Flutter performance?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: ActivityType.ai,
      ),
      ActivityItem(
        icon: Icons.play_circle,
        title: 'Automation Started',
        description: 'Instagram Post Automation',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: ActivityType.automation,
      ),
      ActivityItem(
        icon: Icons.settings,
        title: 'Settings Updated',
        description: 'API keys configured',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: ActivityType.settings,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, kBottomNavHeight),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildActivityItem(activities[index]);
      },
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
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
                activity.icon,
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(activity.timestamp),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white60,
            ),
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
        return [AppColors.systemOrange, AppColors.systemOrange.withOpacity(0.6)];
      case ActivityType.settings:
        return [Colors.grey.shade700, Colors.grey.shade600];
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

class ActivityItem {
  final IconData icon;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType {
  terminal,
  file,
  ai,
  automation,
  settings,
}
