import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../automation/models/automation_enums.dart';
import '../models/extended_settings.dart';

class ServiceDetailsBottomSheet extends ConsumerStatefulWidget {
  final ServiceProvider serviceType;
  final ExtendedAppSettings settings;

  const ServiceDetailsBottomSheet({
    super.key,
    required this.serviceType,
    required this.settings,
  });

  @override
  ConsumerState<ServiceDetailsBottomSheet> createState() =>
      _ServiceDetailsBottomSheetState();
}

class _ServiceDetailsBottomSheetState
    extends ConsumerState<ServiceDetailsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final isConnected = widget.settings.isServiceConfigured(widget.serviceType);
    final serviceInfo = _getServiceInfo(widget.serviceType);

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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: serviceInfo['gradient'],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: serviceInfo['gradient'][0]
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FaIcon(
                        serviceInfo['icon'],
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceInfo['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? AppColors.systemGreen
                                          .withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isConnected
                                        ? AppColors.systemGreen
                                        : Colors.white38,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isConnected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isConnected
                                          ? AppColors.systemGreen
                                          : Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isConnected ? 'Connected' : 'Not Connected',
                                      style: TextStyle(
                                        color: isConnected
                                            ? AppColors.systemGreen
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                  serviceInfo['description'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Official Website
                GlassCard(
                  child: InkWell(
                    onTap: () => _launchURL(serviceInfo['website']),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.systemBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.language,
                              color: AppColors.systemBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Official Website',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  serviceInfo['website'],
                                  style: TextStyle(
                                    color: AppColors.systemBlue,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: AppColors.systemBlue,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account Info (if connected)
                if (isConnected) ...[
                  const Text(
                    'Account Information',
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
                          _buildInfoRow(
                              'Username', '@demo_user', Icons.person),
                          const Divider(color: Colors.white24, height: 24),
                          _buildInfoRow(
                              'Connected', '2 weeks ago', Icons.calendar_today),
                          const Divider(color: Colors.white24, height: 24),
                          _buildInfoRow(
                              'Automations', '3 active', Icons.auto_awesome),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Configuration Options
                const Text(
                  'Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...serviceInfo['configOptions'].map<Widget>((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              option['icon'],
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option['subtitle'],
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (option['hasSwitch'])
                              Switch(
                                value: option['value'] ?? false,
                                onChanged: (value) {
                                  // TODO: Update setting
                                },
                                activeColor: AppColors.systemGreen,
                              )
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white38,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),

                // API Information
                if (serviceInfo['hasAPI']) ...[
                  const Text(
                    'API Information',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.api,
                                color: AppColors.systemPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'API Access Available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAPIStatusRow('Rate Limit', '900 / 1000', true),
                          const SizedBox(height: 8),
                          _buildAPIStatusRow('Requests Today', '247', true),
                          const SizedBox(height: 8),
                          _buildAPIStatusRow('Last Request', '2 min ago', true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (isConnected) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: Reconnect
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.systemRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _confirmDisconnect(),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text('Connect Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: serviceInfo['gradient'][0],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _connectService(),
                        ),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
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

  Widget _buildAPIStatusRow(String label, String value, bool isHealthy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isHealthy ? AppColors.systemGreen : AppColors.systemRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _getServiceInfo(ServiceProvider service) {
    switch (service) {
      case ServiceProvider.instagram:
        return {
          'name': 'Instagram',
          'icon': FontAwesomeIcons.instagram,
          'description':
              'Connect your Instagram account to automate posts, stories, and engagement.',
          'website': 'https://www.instagram.com',
          'gradient': [const Color(0xFFE1306C), const Color(0xFFFD1D1D)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Auto-post Stories',
              'subtitle': 'Automatically publish stories',
              'icon': Icons.auto_awesome,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Post Schedule',
              'subtitle': 'Configure posting times',
              'icon': Icons.schedule,
              'hasSwitch': false,
            },
            {
              'title': 'Hashtag Sets',
              'subtitle': 'Manage hashtag collections',
              'icon': Icons.tag,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.facebook:
        return {
          'name': 'Facebook',
          'icon': FontAwesomeIcons.facebook,
          'description':
              'Manage your Facebook pages and automate content publishing.',
          'website': 'https://www.facebook.com',
          'gradient': [const Color(0xFF1877F2), const Color(0xFF0D47A1)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Page Selection',
              'subtitle': 'Choose pages to manage',
              'icon': Icons.pages,
              'hasSwitch': false,
            },
            {
              'title': 'Cross-posting',
              'subtitle': 'Share posts across platforms',
              'icon': Icons.share,
              'hasSwitch': true,
              'value': false,
            },
          ],
        };
      case ServiceProvider.twitter:
        return {
          'name': 'Twitter / X',
          'icon': FontAwesomeIcons.xTwitter,
          'description':
              'Automate tweets, threads, and engagement on Twitter/X.',
          'website': 'https://twitter.com',
          'gradient': [const Color(0xFF000000), const Color(0xFF333333)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Thread Publishing',
              'subtitle': 'Auto-publish tweet threads',
              'icon': Icons.list,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Retweet Automation',
              'subtitle': 'Auto-retweet specific content',
              'icon': Icons.repeat,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.linkedin:
        return {
          'name': 'LinkedIn',
          'icon': FontAwesomeIcons.linkedin,
          'description':
              'Automate professional content sharing on LinkedIn.',
          'website': 'https://www.linkedin.com',
          'gradient': [const Color(0xFF0077B5), const Color(0xFF005582)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Article Publishing',
              'subtitle': 'Auto-publish articles',
              'icon': Icons.article,
              'hasSwitch': true,
              'value': false,
            },
            {
              'title': 'Connection Requests',
              'subtitle': 'Manage connection automation',
              'icon': Icons.people,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.tiktok:
        return {
          'name': 'TikTok',
          'icon': FontAwesomeIcons.tiktok,
          'description': 'Schedule and publish TikTok videos automatically.',
          'website': 'https://www.tiktok.com',
          'gradient': [const Color(0xFF000000), const Color(0xFF00F2EA)],
          'hasAPI': false,
          'configOptions': [
            {
              'title': 'Video Upload',
              'subtitle': 'Schedule video uploads',
              'icon': Icons.videocam,
              'hasSwitch': true,
              'value': false,
            },
          ],
        };
      case ServiceProvider.youtube:
        return {
          'name': 'YouTube',
          'icon': FontAwesomeIcons.youtube,
          'description': 'Manage YouTube videos, playlists, and analytics.',
          'website': 'https://www.youtube.com',
          'gradient': [const Color(0xFFFF0000), const Color(0xFFCC0000)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Video Publishing',
              'subtitle': 'Auto-publish scheduled videos',
              'icon': Icons.video_library,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Playlist Management',
              'subtitle': 'Auto-organize playlists',
              'icon': Icons.playlist_play,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.notion:
        return {
          'name': 'Notion',
          'icon': FontAwesomeIcons.noteSticky,
          'description':
              'Sync data between Notion and other services automatically.',
          'website': 'https://www.notion.so',
          'gradient': [const Color(0xFF000000), const Color(0xFF37352F)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Database Sync',
              'subtitle': 'Auto-sync database entries',
              'icon': Icons.sync,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Page Creation',
              'subtitle': 'Auto-create pages from templates',
              'icon': Icons.note_add,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.google:
        return {
          'name': 'Google',
          'icon': FontAwesomeIcons.google,
          'description':
              'Access Google Drive, Gmail, Calendar, and other services.',
          'website': 'https://www.google.com',
          'gradient': [const Color(0xFF4285F4), const Color(0xFFEA4335)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Drive Sync',
              'subtitle': 'Auto-sync files to Drive',
              'icon': Icons.cloud_upload,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Gmail Automation',
              'subtitle': 'Auto-send emails',
              'icon': Icons.email,
              'hasSwitch': true,
              'value': false,
            },
            {
              'title': 'Calendar Events',
              'subtitle': 'Auto-create calendar events',
              'icon': Icons.calendar_today,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.slack:
        return {
          'name': 'Slack',
          'icon': FontAwesomeIcons.slack,
          'description': 'Automate Slack messages and notifications.',
          'website': 'https://slack.com',
          'gradient': [const Color(0xFF4A154B), const Color(0xFF611f69)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Channel Posting',
              'subtitle': 'Auto-post to channels',
              'icon': Icons.send,
              'hasSwitch': true,
              'value': true,
            },
            {
              'title': 'Bot Responses',
              'subtitle': 'Configure automated responses',
              'icon': Icons.smart_toy,
              'hasSwitch': false,
            },
          ],
        };
      case ServiceProvider.discord:
        return {
          'name': 'Discord',
          'icon': FontAwesomeIcons.discord,
          'description': 'Automate Discord bot actions and messages.',
          'website': 'https://discord.com',
          'gradient': [const Color(0xFF5865F2), const Color(0xFF404EED)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Bot Commands',
              'subtitle': 'Configure bot automation',
              'icon': Icons.terminal,
              'hasSwitch': true,
              'value': false,
            },
          ],
        };
      case ServiceProvider.telegram:
        return {
          'name': 'Telegram',
          'icon': FontAwesomeIcons.telegram,
          'description': 'Send automated messages via Telegram bot.',
          'website': 'https://telegram.org',
          'gradient': [const Color(0xFF0088CC), const Color(0xFF006699)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Bot Messages',
              'subtitle': 'Auto-send bot messages',
              'icon': Icons.message,
              'hasSwitch': true,
              'value': true,
            },
          ],
        };
      case ServiceProvider.github:
        return {
          'name': 'GitHub',
          'icon': FontAwesomeIcons.github,
          'description':
              'Automate GitHub workflows, issues, and pull requests.',
          'website': 'https://github.com',
          'gradient': [const Color(0xFF24292E), const Color(0xFF1B1F23)],
          'hasAPI': true,
          'configOptions': [
            {
              'title': 'Issue Automation',
              'subtitle': 'Auto-create and label issues',
              'icon': Icons.bug_report,
              'hasSwitch': true,
              'value': false,
            },
            {
              'title': 'PR Management',
              'subtitle': 'Auto-merge pull requests',
              'icon': Icons.merge,
              'hasSwitch': false,
            },
          ],
        };
      default:
        return {
          'name': 'Unknown Service',
          'icon': Icons.help_outline,
          'description': 'Service not configured',
          'website': '',
          'gradient': [Colors.grey, Colors.grey.shade700],
          'hasAPI': false,
          'configOptions': [],
        };
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _connectService() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening OAuth flow for ${widget.serviceType.label}...'),
        backgroundColor: AppColors.systemBlue,
      ),
    );
    // TODO: Implement OAuth flow
  }

  void _confirmDisconnect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Service?'),
        content: Text(
            'This will disconnect your ${widget.serviceType.label} account and disable all related automations.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service disconnected'),
                  backgroundColor: AppColors.systemRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static void show(
      BuildContext context, ServiceProvider serviceType, ExtendedAppSettings settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailsBottomSheet(
        serviceType: serviceType,
        settings: settings,
      ),
    );
  }
}
