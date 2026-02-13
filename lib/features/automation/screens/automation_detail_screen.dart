import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';
import '../models/automation.dart';
import '../models/automation_enums.dart';

class AutomationDetailScreen extends ConsumerStatefulWidget {
  final Automation automation;

  const AutomationDetailScreen({
    super.key,
    required this.automation,
  });

  @override
  ConsumerState<AutomationDetailScreen> createState() =>
      _AutomationDetailScreenState();
}

class _AutomationDetailScreenState
    extends ConsumerState<AutomationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.automation.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.automation.isActive ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _toggleAutomation,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editAutomation,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.systemBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Overview'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'History'),
            Tab(icon: Icon(Icons.error_outline, size: 20), text: 'Errors'),
            Tab(icon: Icon(Icons.data_usage, size: 20), text: 'Data'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0f0c29),
              const Color(0xFF302b63),
              const Color(0xFF24243e),
            ],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildHistoryTab(),
              _buildErrorsTab(),
              _buildDataTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.automation.isActive
                              ? AppColors.systemGreen.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.automation.isActive
                              ? Icons.check_circle
                              : Icons.pause_circle,
                          color: widget.automation.isActive
                              ? AppColors.systemGreen
                              : Colors.white70,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.automation.isActive ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                color: widget.automation.isActive
                                    ? AppColors.systemGreen
                                    : Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.automation.isActive
                                  ? 'Running normally'
                                  : 'Automation is paused',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          '247',
                          'Total Runs',
                          Icons.play_circle_outline,
                          AppColors.systemBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          '98.4%',
                          'Success Rate',
                          Icons.check_circle_outline,
                          AppColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Configuration
          const Text(
            'Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildConfigRow('Service', widget.automation.service.label,
                      widget.automation.service.icon),
                  const Divider(color: Colors.white24, height: 24),
                  _buildConfigRow('Trigger', widget.automation.trigger, '⏰'),
                  const Divider(color: Colors.white24, height: 24),
                  _buildConfigRow('Created', '2 weeks ago', '📅'),
                  const Divider(color: Colors.white24, height: 24),
                  _buildConfigRow('Last Run', '15 minutes ago', '🕐'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Run Now',
                  Icons.play_arrow,
                  AppColors.systemBlue,
                  _runNow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Reset Stats',
                  Icons.refresh,
                  AppColors.systemOrange,
                  _resetStats,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final executions = _getMockExecutions();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      itemCount: executions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final execution = executions[index];
        return GlassCard(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: execution['success']
                    ? AppColors.systemGreen.withValues(alpha: 0.2)
                    : AppColors.systemRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                execution['success'] ? Icons.check : Icons.error_outline,
                color: execution['success']
                    ? AppColors.systemGreen
                    : AppColors.systemRed,
                size: 20,
              ),
            ),
            title: Text(
              execution['action'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              execution['time'],
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: Text(
              execution['duration'],
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorsTab() {
    final errors = _getMockErrors();

    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.systemGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Errors',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This automation is running smoothly',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      itemCount: errors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final error = errors[index];
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getErrorColor(error['severity'])
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getErrorIcon(error['severity']),
                        color: _getErrorColor(error['severity']),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      error['severity'].toUpperCase(),
                      style: TextStyle(
                        color: _getErrorColor(error['severity']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      error['time'],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  error['message'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error['details'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error['details'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('View Logs'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.systemBlue,
                      ),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    TextButton(
                      child: const Text('Dismiss'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics
          const Text(
            'Statistics (Last 30 days)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('247', 'Total Executions', Icons.repeat),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('243', 'Successful', Icons.check_circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('4', 'Failed', Icons.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('2.3s', 'Avg Duration', Icons.timer),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Produced Data
          const Text(
            'Recent Output',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._getMockOutputData().map((data) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: AppColors.systemBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            data['time'],
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['content'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Full'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.systemBlue,
                            ),
                            onPressed: () {},
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.systemBlue,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.systemBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getErrorColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.systemRed;
      case 'warning':
        return AppColors.systemOrange;
      default:
        return AppColors.systemYellow;
    }
  }

  IconData _getErrorIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  List<Map<String, dynamic>> _getMockExecutions() {
    return [
      {
        'action': 'Posted to Instagram',
        'time': '15 minutes ago',
        'duration': '2.3s',
        'success': true
      },
      {
        'action': 'Posted to Instagram',
        'time': '1 hour ago',
        'duration': '1.8s',
        'success': true
      },
      {
        'action': 'Posted to Instagram',
        'time': '2 hours ago',
        'duration': '2.1s',
        'success': false
      },
      {
        'action': 'Posted to Instagram',
        'time': '3 hours ago',
        'duration': '1.9s',
        'success': true
      },
    ];
  }

  List<Map<String, dynamic>> _getMockErrors() {
    return [
      {
        'severity': 'warning',
        'message': 'Rate limit approaching',
        'details': 'You have 3 requests remaining in the next hour',
        'time': '2 hours ago',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockOutputData() {
    return [
      {
        'title': 'Instagram Post #247',
        'time': '15 min ago',
        'content':
            'Successfully posted: "Check out our new product launch! 🚀 #innovation #tech"',
      },
      {
        'title': 'Instagram Post #246',
        'time': '1 hour ago',
        'content': 'Successfully posted: "Morning motivation 💪 #mondayvibes"',
      },
      {
        'title': 'Instagram Post #245',
        'time': '2 hours ago',
        'content': 'Failed: Rate limit exceeded. Will retry in 30 minutes.',
      },
    ];
  }

  void _toggleAutomation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.automation.isActive
            ? 'Automation paused'
            : 'Automation activated'),
        backgroundColor: AppColors.systemBlue,
      ),
    );
  }

  void _editAutomation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit automation (coming soon)'),
        backgroundColor: AppColors.systemBlue,
      ),
    );
  }

  void _runNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running automation...'),
        backgroundColor: AppColors.systemGreen,
      ),
    );
  }

  void _resetStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content:
            const Text('This will clear all execution history and data.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistics reset'),
                  backgroundColor: AppColors.systemOrange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Automation duplicated')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exporting automation...')),
        );
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Automation?'),
        content: const Text(
            'This action cannot be undone. All history and data will be lost.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Automation deleted'),
                  backgroundColor: AppColors.systemRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
